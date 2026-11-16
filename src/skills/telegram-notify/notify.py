#!/usr/bin/env python3
"""Format Markdown, upload attachments, then send a Telegram message.

Python 3.10+ and the standard library only. Decision policy and voice rendering
belong to SKILL.md; this module validates local inputs and transports them.
"""

from __future__ import annotations

import argparse
import html
import json
import mimetypes
import os
from pathlib import Path
import re
import sys
from typing import Mapping, Sequence
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import uuid


TELEGRAM_MAX_LENGTH = 4096
RESPONSE_LIMIT = 100_000


class NotifyError(Exception):
    """Expected configuration, input, or Telegram delivery failure."""


def esc(value: object) -> str:
    return html.escape("" if value is None else str(value), quote=True)


def compact(text: str) -> str:
    """Collapse repeated blank lines while preserving content indentation."""
    output: list[str] = []
    previous_blank = True
    for line in text.splitlines():
        if line.strip():
            output.append(line)
            previous_blank = False
        elif not previous_blank:
            output.append("")
            previous_blank = True
    while output and not output[-1].strip():
        output.pop()
    return "\n".join(output)


MD_FENCE_RE = re.compile(r"```(.+?)```", re.DOTALL)
MD_CODE_RE = re.compile(r"`([^`\n]+)`")
MD_LINK_RE = re.compile(r"\[([^\]\n]+)\]\((https?://[^)\s]+)\)")
MD_BOLD_RE = re.compile(r"\*\*(.+?)\*\*", re.DOTALL)
MD_STRIKE_RE = re.compile(r"~~(.+?)~~", re.DOTALL)
MD_ITALIC_STAR_RE = re.compile(r"\*(\S(?:[^*\n]*?\S)?)\*")
MD_ITALIC_UNDER_RE = re.compile(r"(?<!\w)_([^_\n]+)_(?!\w)")
HEADING_LINE_RE = re.compile(r"^\s*(#{1,6})\s+(.*?)\s*#*\s*$")
BULLET_LINE_RE = re.compile(r"^(\s*)[-*+]\s+(.*)$")
HR_LINE_RE = re.compile(r"^\s*([-*_])\s*(?:\1\s*){2,}$")
QUOTE_PREFIX_RE = re.compile(r"^&gt;\s?")


def markdown_to_html(text: str) -> str:
    """Convert a safe Markdown subset to Telegram-supported HTML."""
    lines: list[str] = []
    in_fence = False
    for line in text.split("\n"):
        if re.match(r"^\s*(```|~~~)", line):
            in_fence = not in_fence
            lines.append(line)
            continue
        if in_fence:
            lines.append(line)
            continue
        if HR_LINE_RE.match(line):
            lines.append("────────────")
            continue
        heading = HEADING_LINE_RE.match(line)
        if heading:
            lines.append(f"**{heading.group(2)}**")
            continue
        bullet = BULLET_LINE_RE.match(line)
        if bullet:
            lines.append(f"{bullet.group(1)}• {bullet.group(2)}")
            continue
        lines.append(line)

    rendered = esc("\n".join(lines))
    sink: list[str] = []

    def placeholder(value: str) -> str:
        sink.append(value)
        return f"\x00{len(sink) - 1}\x00"

    def wrap(tag: str):
        def replace(match: re.Match[str]) -> str:
            return placeholder(f"<{tag}>{match.group(1)}</{tag}>")

        return replace

    def replace_link(match: re.Match[str]) -> str:
        return placeholder(f'<a href="{match.group(2)}">{match.group(1)}</a>')

    rendered = MD_FENCE_RE.sub(wrap("pre"), rendered)
    rendered = MD_CODE_RE.sub(wrap("code"), rendered)
    rendered = MD_LINK_RE.sub(replace_link, rendered)
    rendered = MD_BOLD_RE.sub(wrap("b"), rendered)
    rendered = MD_STRIKE_RE.sub(wrap("s"), rendered)
    rendered = MD_ITALIC_STAR_RE.sub(wrap("i"), rendered)
    rendered = MD_ITALIC_UNDER_RE.sub(wrap("i"), rendered)

    for index in range(len(sink) - 1, -1, -1):
        rendered = rendered.replace(f"\x00{index}\x00", sink[index])

    output: list[str] = []
    quote: list[str] = []
    in_pre = False

    def flush_quote() -> None:
        if quote:
            output.append("<blockquote>" + "\n".join(quote) + "</blockquote>")
            quote.clear()

    for line in rendered.split("\n"):
        if in_pre:
            output.append(line)
            if "</pre>" in line:
                in_pre = False
            continue
        if "<pre>" in line:
            flush_quote()
            output.append(line)
            if "</pre>" not in line:
                in_pre = True
            continue
        stripped = line.lstrip()
        if stripped.startswith("&gt;"):
            indent = line[: len(line) - len(stripped)]
            quote.append(indent + QUOTE_PREFIX_RE.sub("", stripped, count=1))
        else:
            flush_quote()
            output.append(line)
    flush_quote()
    return "\n".join(output)


def render_message(markdown: str) -> str:
    if not markdown.strip():
        raise NotifyError("message is empty")
    rendered = compact(markdown_to_html(markdown))
    if not rendered:
        raise NotifyError("message is empty after formatting")
    if len(rendered) > TELEGRAM_MAX_LENGTH:
        raise NotifyError(
            f"formatted message exceeds Telegram limit: "
            f"{len(rendered)} > {TELEGRAM_MAX_LENGTH} characters"
        )
    return rendered


def load_config(env: Mapping[str, str]) -> tuple[str, str, int | None]:
    token = env.get("TLG_TOKEN", "").strip()
    group_id = env.get("TLG_GROUP_ID", "").strip()
    thread_value = env.get("TLG_THREAD_ID", "").strip()
    if not token:
        raise NotifyError("TLG_TOKEN is required")
    if not group_id:
        raise NotifyError("TLG_GROUP_ID is required")
    thread_id: int | None = None
    if thread_value:
        try:
            thread_id = int(thread_value)
        except ValueError as exc:
            raise NotifyError("TLG_THREAD_ID must be a positive integer") from exc
        if thread_id <= 0:
            raise NotifyError("TLG_THREAD_ID must be a positive integer")
    return token, group_id, thread_id


def validate_attachments(values: Sequence[str]) -> list[Path]:
    attachments: list[Path] = []
    for value in values:
        path = Path(value).expanduser()
        if not path.is_file():
            raise NotifyError(f"attachment is not a file: {path}")
        try:
            with path.open("rb"):
                pass
        except OSError as exc:
            raise NotifyError(f"attachment is not readable: {path}") from exc
        attachments.append(path)
    return attachments


def load_message(args: argparse.Namespace) -> str:
    if args.message is not None:
        return args.message
    if args.message_file is not None:
        path = Path(args.message_file).expanduser()
        if not path.is_file():
            raise NotifyError(f"message file is not a file: {path}")
        try:
            return path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            raise NotifyError(f"cannot read UTF-8 message file: {path}") from exc
    return sys.stdin.read()


def telegram_request(
    method: str,
    token: str,
    body: bytes,
    content_type: str,
) -> dict[str, object]:
    request = Request(
        f"https://api.telegram.org/bot{token}/{method}",
        data=body,
        headers={"Content-Type": content_type, "Content-Length": str(len(body))},
        method="POST",
    )
    try:
        with urlopen(request, timeout=30) as response:
            raw = response.read(RESPONSE_LIMIT)
    except HTTPError as exc:
        try:
            error_data = json.loads(exc.read(RESPONSE_LIMIT).decode("utf-8"))
            detail = str(error_data.get("description", "HTTP error"))
        except (ValueError, UnicodeError, OSError):
            detail = "HTTP error"
        raise NotifyError(f"Telegram {method} failed: {' '.join(detail.split())}") from None
    except (URLError, TimeoutError, OSError):
        raise NotifyError(f"Telegram {method} request failed") from None

    try:
        result = json.loads(raw.decode("utf-8"))
    except (ValueError, UnicodeError) as exc:
        raise NotifyError(f"Telegram {method} returned invalid JSON") from exc
    if not isinstance(result, dict) or not result.get("ok"):
        detail = "unknown API error"
        if isinstance(result, dict):
            detail = str(result.get("description", detail))
        raise NotifyError(f"Telegram {method} failed: {' '.join(detail.split())}")
    return result


def encode_multipart(fields: Mapping[str, str], file_path: Path) -> tuple[bytes, str]:
    boundary = "telegram-notify-" + uuid.uuid4().hex
    boundary_bytes = boundary.encode("ascii")
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.extend(
            [
                b"--" + boundary_bytes + b"\r\n",
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("ascii"),
                value.encode("utf-8"),
                b"\r\n",
            ]
        )

    filename = file_path.name.replace('"', "'").replace("\r", "").replace("\n", "")
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    try:
        file_data = file_path.read_bytes()
    except OSError as exc:
        raise NotifyError(f"cannot read attachment: {file_path}") from exc
    chunks.extend(
        [
            b"--" + boundary_bytes + b"\r\n",
            (
                f'Content-Disposition: form-data; name="document"; filename="{filename}"\r\n'
                f"Content-Type: {content_type}\r\n\r\n"
            ).encode("utf-8"),
            file_data,
            b"\r\n",
            b"--" + boundary_bytes + b"--\r\n",
        ]
    )
    return b"".join(chunks), f"multipart/form-data; boundary={boundary}"


def send_document(
    token: str,
    group_id: str,
    thread_id: int | None,
    path: Path,
) -> None:
    fields = {"chat_id": group_id}
    if thread_id is not None:
        fields["message_thread_id"] = str(thread_id)
    body, content_type = encode_multipart(fields, path)
    telegram_request("sendDocument", token, body, content_type)


def send_message(
    token: str,
    group_id: str,
    thread_id: int | None,
    message: str,
) -> None:
    payload: dict[str, object] = {
        "chat_id": group_id,
        "text": message,
        "parse_mode": "HTML",
        "link_preview_options": {"is_disabled": True},
    }
    if thread_id is not None:
        payload["message_thread_id"] = thread_id
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    telegram_request("sendMessage", token, body, "application/json; charset=utf-8")


def send_notification(
    token: str,
    group_id: str,
    thread_id: int | None,
    attachments: Sequence[Path],
    message: str,
) -> None:
    sent = 0
    for path in attachments:
        try:
            send_document(token, group_id, thread_id, path)
        except NotifyError as exc:
            raise NotifyError(
                f"attachment {sent + 1}/{len(attachments)} failed after {sent} sent; "
                f"message was not sent. {exc}"
            ) from exc
        sent += 1
    try:
        send_message(token, group_id, thread_id, message)
    except NotifyError as exc:
        suffix = f" after {sent} attachment(s) were sent" if sent else ""
        raise NotifyError(f"message failed{suffix}. {exc}") from exc


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Upload Telegram attachments, then send a Markdown message."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("-m", "--message", help="literal Markdown message")
    source.add_argument("-f", "--message-file", help="UTF-8 Markdown file")
    source.add_argument("--stdin", action="store_true", help="read Markdown from stdin")
    parser.add_argument(
        "-a",
        "--attach",
        action="append",
        default=[],
        metavar="FILE",
        help="file to upload before the message; repeat to preserve order",
    )
    return parser


def main(argv: Sequence[str] | None = None, env: Mapping[str, str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        token, group_id, thread_id = load_config(os.environ if env is None else env)
        attachments = validate_attachments(args.attach)
        message = render_message(load_message(args))
        send_notification(token, group_id, thread_id, attachments, message)
        print(f"Sent {len(attachments)} attachment(s) and 1 message.")
        return 0
    except NotifyError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
