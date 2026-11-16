---
name: telegram-notify
description: >-
  Evaluate meaningful task events and send Telegram notifications with relevant
  file attachments and a voice-configured Markdown summary. Use when the user
  asks for a Telegram notice or project instructions authorize proactive
  milestone, deliverable, blocker, failure, or action-required notifications.
  Not for routine progress updates or building and administering Telegram bots.
---

# Telegram Notify

Send one useful Telegram update when the event warrants interrupting the recipient. This skill owns the decision, attachments, and wording; `notify.py` only formats and transports them.

## Decide

Send when at least one condition holds:

- The user explicitly asks for a Telegram notification.
- A meaningful milestone or user-facing deliverable is complete.
- A blocker, interrupting failure, or pending user action needs attention.
- Project instructions explicitly authorize another notification event.

Skip routine progress, minor tool results, repeated facts, and events already notified. Proactive delivery requires authorization from the applicable project instructions; explicit invocation alone does not create standing authorization for later events.

## Prepare

1. Read `config.json`. An explicitly requested voice overrides `default_voice`.
2. For a named voice, read `voices/<voice>.json` before drafting. Treat it as a voice bank: follow its fingerprint, modes, rules, and few-shot examples without copying them verbatim. `plain` means concise factual prose and needs no profile. If a profile is missing, use `plain`; styling must not suppress an important fact.
3. Select only files that help the recipient use or verify the result: final documents, reports, exports, images, requested artifacts, or sanitized diagnostic logs.
4. Exclude credentials, secrets, unrelated files, source trees, caches, and unreviewed temporary artifacts. Confirm every selected path exists before sending.
5. Draft a Markdown message that states what happened, the evidence or impact, and any required next action. Preserve exact filenames, commits, counts, statuses, and unresolved limitations. Never turn pending work into completion or invent a successful test, approval, or deployment.

Attachments are optional. Preserve their intended order; the CLI sends every attachment before the message.

## Send

The CLI reads credentials only from the environment:

- `TLG_TOKEN`: required bot token.
- `TLG_GROUP_ID`: required target chat or group ID.
- `TLG_THREAD_ID`: optional forum-topic thread ID.

Call the bundled CLI from this skill directory. Prefer `--message-file` or `--stdin` for multiline Markdown; repeat `--attach` in delivery order.

```bash
TLG_TOKEN="$TLG_TOKEN" \
TLG_GROUP_ID="$TLG_GROUP_ID" \
TLG_THREAD_ID="${TLG_THREAD_ID:-}" \
python3 notify.py \
  --attach path/to/report.pdf \
  --attach path/to/results.csv \
  --message-file path/to/notification.md
```

Do not print credentials, embed them in files, or include them in notification text. The CLI validates all local inputs before its first network request, uploads attachments sequentially, renders Markdown to Telegram-safe HTML, then sends the message.

## Handle outcomes

- Success means the CLI confirms all attachments and the message were sent.
- On failure, report the unsent stage. Do not blindly repeat the full command: earlier attachments may already have arrived.
- Never claim delivery from a preview, local render, or partially successful request.
