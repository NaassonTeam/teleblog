# Teleblog

Turn Telegram channels into static blogs. Self-hosted, runs anywhere.

## Install

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh
chmod +x install.sh
./install.sh
```

The installer flow is deterministic:
1) language -> 2) data folder -> 3) Docker check/install/start -> 4) image pull -> 5) container run.

If something fails, installer prints explicit `ERROR:` and writes structured events to:
- `./teleblog-installer.ndjson` (before folder selection)
- `<selected-folder>/teleblog-installer.ndjson` (after folder selection)

## Stop

```bash
./install.sh --stop
```

## Non-interactive

`./install.sh -y` — skip prompts, use current dir.

Useful env vars:
- `TELEBLOG_LANG=ru|en|zh|ar`
- `TELEBLOG_ROOT=/path/to/folder`
- `BLOG_PORT=7433`
- `TELEBLOG_EVENT_LOG=/path/installer.ndjson`
- `TELEBLOG_DRY_RUN=1` or `./install.sh --dry-run`

## Release Flow (maintainers)

- `tele-blog` = main source repo.
- `teleblog` = public installer repo only.
- Sync to `teleblog` only when installer artifacts changed (`install.sh`, `install-README.md`, `LICENSE`, `VERSION`).

## Version

See [VERSION](VERSION).

## License

Apache-2.0 — see [LICENSE](LICENSE).
