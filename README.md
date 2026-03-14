# Teleblog

Turn Telegram channels into static blogs. Self-hosted, runs anywhere.

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh | bash
```

This downloads and runs the installer. You'll see a log of each step: language selection, folder choice, Docker check/start/install, image pull, container start. Then open http://localhost:7433.

## Stop

```bash
curl -fsSL https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh | bash -s -- --stop
```

## Non-interactive

`curl ... | bash -s -- -y` — skip prompts, use current dir. Env: `TELEBLOG_LANG=ru`, `TELEBLOG_ROOT=/path`

## Version

See [VERSION](VERSION).

## License

Apache-2.0 — see [LICENSE](LICENSE).
