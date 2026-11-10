# Skills

My curated collection of practical skills and rules for agents.

## Codex Installation

Use `codex.sh` to install skills from this repository into Codex using symbolic links.

### Install

Install skills for the current user:

```bash
bash codex.sh install
```

Install skills for a specific project:

```bash
bash codex.sh install /path/to/project
```

Skills are linked individually into `~/.agents/skills/` or `<PROJECT_DIR>/.agents/skills/`.

Existing files and symbolic links are skipped by default. Real directories are never overwritten.

### Uninstall

```bash
bash codex.sh uninstall
```

For a specific project:

```bash
bash codex.sh uninstall /path/to/project
```

Uninstall removes only managed symbolic links pointing into this repository.

### Force installation

```bash
bash codex.sh install --force
```

The `--force` option replaces conflicting files or symbolic links, but preserves real directories.

### Windows (Git Bash)

On Windows, use Git Bash with native symbolic link support:

```bash
MSYS=winsymlinks:nativestrict bash codex.sh install
```

Creating native symbolic links may require Windows Developer Mode or appropriate permissions.

The installer does not modify existing Claude configuration files.

## License

[Property License](LICENSE)

Copyright &copy; 2026 [Hieu Pham](https://github.com/hieupth). All rights reserved.