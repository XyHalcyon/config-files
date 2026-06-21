---
name: obsidian
description: Read, search, create, and edit notes in the Obsidian vault.
platforms: [linux, macos, windows]
---

# Obsidian Vault

Use this skill for filesystem-first Obsidian vault work: reading notes, listing notes, searching note files, creating notes, appending content, and adding wikilinks.

## Vault path

Use a known or resolved vault path before calling file tools.

The documented vault-path convention is the `OBSIDIAN_VAULT_PATH` environment variable, for example from `${HERMES_HOME:-~/.hermes}/.env`. If it is unset, use `~/Documents/Obsidian Vault`.

File tools do not expand shell variables. Do not pass paths containing `$OBSIDIAN_VAULT_PATH` to `read_file`, `write_file`, `patch`, or `search_files`; resolve the vault path first and pass a concrete absolute path. Vault paths may contain spaces, which is another reason to prefer file tools over shell commands.

If the vault path is unknown, `terminal` is acceptable for resolving `OBSIDIAN_VAULT_PATH` or checking whether the fallback path exists. Once the path is known, switch back to file tools.

## Read a note

Use `read_file` with the resolved absolute path to the note. Prefer this over `cat` because it provides line numbers and pagination.

## List notes

Use `search_files` with `target: "files"` and the resolved vault path. Prefer this over `find` or `ls`.

- To list all markdown notes, use `pattern: "*.md"` under the vault path.
- To list a subfolder, search under that subfolder's absolute path.

## Search

Use `search_files` for both filename and content searches. Prefer this over `grep`, `find`, or `ls`.

- For filenames, use `search_files` with `target: "files"` and a filename `pattern`.
- For note contents, use `search_files` with `target: "content"`, the content regex as `pattern`, and `file_glob: "*.md"` when you want to restrict matches to markdown notes.

## Create a note

Use `write_file` with the resolved absolute path and the full markdown content. Prefer this over shell heredocs or `echo` because it avoids shell quoting issues and returns structured results.

## Append to a note

Prefer a native file-tool workflow when it is not awkward:

- Read the target note with `read_file`.
- Use `patch` for an anchored append when there is stable context, such as adding a section after an existing heading or appending before a known trailing block.
- Use `write_file` when rewriting the whole note is clearer than constructing a fragile patch.

For an anchored append with `patch`, replace the anchor with the anchor plus the new content.

For a simple append with no stable context, `terminal` is acceptable if it is the clearest safe option.

## Targeted edits

Use `patch` for focused note changes when the current content gives you stable context. Prefer this over shell text rewriting.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, use these to link related content.

## Dashboard Building (DataviewJS + Excalidraw + CSS)

Build rich dashboards using only installed plugins — no extra installs required.
Full patterns for stat cards, folder grids, progress bars, timelines, task
dashboards, and Excalidraw hand-drawn banners are documented in:

→ `references/obsidian-dashboard.md`

### Workflow for dashboard changes

1. Survey installed plugins, current file content, and existing CSS snippets
2. Design a plan with an ASCII layout sketch — list every file to create/modify
3. Get user approval before touching any file
4. Never install new plugins unless the user explicitly asks for one

### Path handling on Windows

When the Obsidian vault is on a Windows drive (`E:\code\obsidian-repo\`):

| Tool | Path format | Notes |
|------|-------------|-------|
| `terminal` (WSL) | `/mnt/e/code/obsidian-repo/` | Primary tool for all file operations |
| `read_file` | `E:\code\obsidian-repo\` | May fail on E: paths — use `terminal cat` |
| `write_file` | `E:\code\obsidian-repo\` | May fail on E: paths — use `terminal` approach below |
| `search_files` | `E:\code\obsidian-repo\` | May fail without ripgrep — use `terminal find` / `ls` |
| `execute_code` | `E:\code\obsidian-repo\` | avoid: passes content through bash, backticks break it |

### Writing files on Windows vaults

`write_file` and `execute_code` often fail on Windows vault paths because content passes through bash, where backticks, dollar signs, and other shell metacharacters cause parse errors.

**Working approach:** use `terminal` with a Python heredoc that has a QUOTED delimiter (`<< 'PYEOF'`). The quoted delimiter disables all shell expansion inside the heredoc:

    terminal: python3 << 'PYEOF'
    import os
    content = """your markdown with `backticks` and $dollar signs"""
    with open('/mnt/e/code/obsidian-repo/.../file.md', 'w', encoding='utf-8') as f:
        f.write(content)
    PYEOF

Key rules:
- Single-quote the heredoc delimiter: `<< 'PYEOF'` not `<< PYEOF`
- Use `/mnt/e/...` WSL paths in terminal, not `E:\...` Windows paths
- Triple-quoted Python strings preserve backticks and most special characters
- Clean up any test files created during the session
