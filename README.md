# Teleblog

Turn Telegram channels into static blogs. Self-hosted, runs anywhere.

## Install

```bash
rm -f install.sh
curl -fL --retry 3 --retry-delay 1 -o install.sh https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh
chmod +x install.sh
./install.sh
```

The installer flow is deterministic:
1) language -> 2) data folder -> 3) Docker check/install/start -> 4) image pull -> 5) docker-compose up.

All data in one folder: `data/` (config), `chats/` (exports), `docker-compose.yml`.

If something fails, installer prints explicit `ERROR:` and writes structured events to:
- `./teleblog-installer.ndjson` (before folder selection)
- `<selected-folder>/teleblog-installer.ndjson` (after folder selection)

## Stop

```bash
./install.sh --stop
```

## Update

Use the **same folder** you chose at install (the one with `data/` and `chats/` inside). If you picked a different path, `cd` there or set `TELEBLOG_ROOT`:

```bash
cd /path/to/your/teleblog/folder
# or: export TELEBLOG_ROOT=/path/to/your/teleblog/folder

rm -f install.sh
curl -fL --retry 3 --retry-delay 1 -o install.sh https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh
chmod +x install.sh
./install.sh -y
```

Or manually (from your data folder):

```bash
cd /path/to/your/teleblog/folder
docker compose pull && docker compose up -d
```

Data, TOTP and config are preserved. The admin panel shows the exact update command (copy button).

## Non-interactive

`./install.sh -y` — skip prompts, use current dir.

Useful env vars:
- `TELEBLOG_IMAGE=cr.yandex/crpdlb5mvkseemurnl69/teleblog-selfhost:latest` (default, multi-arch: native arm64 on Mac)
- `TELEBLOG_DOCKER_SOCKET=1` (mount Docker socket for Restart button in admin panel)
- `TELEBLOG_INSTANCE_NAME=my-blog` (shown in TOTP QR, helps distinguish multiple instances)
- `TELEBLOG_LANG=ru|en|zh|ar`
- `TELEBLOG_ROOT=/path/to/folder`
- `BLOG_PORT=7433` (host and container; nginx listens on this port)
- `TELEBLOG_DOCKER_PLATFORM=linux/amd64` (optional override)
- `TELEBLOG_EVENT_LOG=/path/installer.ndjson`
- `TELEBLOG_DRY_RUN=1` or `./install.sh --dry-run`

Installer now waits until HTTP on `localhost:BLOG_PORT` is actually ready before printing `Done`.

## Version

See [VERSION](VERSION). At startup, `docker logs teleblog` shows build version. If you don't see updates, rebuild locally: `docker build --target selfhost -t your-image .` or pull the latest from registry.

## Telegram Export

Put structured export in `./chats/folder_name/` (result.json + photos/ + files/).
See `docs/telegram-export-format.md` in the repo for structure.

## License

Apache-2.0 — see [LICENSE](LICENSE).
