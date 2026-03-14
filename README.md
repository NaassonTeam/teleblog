# Teleblog

Turn Telegram channels into static blogs. Self-hosted, runs anywhere.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/NaassonTeam/teleblog.git && cd teleblog && ./install.sh
```

The installer: language selection → folder picker → auto-starts Docker if needed → auto-installs Docker if missing (Mac: brew, Windows: winget, Linux: get.docker.com).

Open http://localhost:7433 — setup wizard will guide you.

## Stop

```bash
curl -fsSL https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh | bash -s -- --stop
```

## Non-interactive

Skip prompts, use current dir: `./install.sh -y`

Env: `TELEBLOG_ROOT=/path ./install.sh`, `TELEBLOG_LANG=ru ./install.sh` (en, ru, zh, ar)

## Version

See [VERSION](VERSION).

## License

Apache-2.0 — see [LICENSE](LICENSE).
