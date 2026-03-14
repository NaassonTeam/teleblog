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

The installer opens a folder picker (or asks for a path). Choose where to store data. No need to cd first.

Open http://localhost:7433 — setup wizard will guide you.

## Stop

```bash
curl -fsSL https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh | bash -s -- --stop
```

## Non-interactive

Skip folder picker, use current dir: `./install.sh -y`

Or set folder: `TELEBLOG_ROOT=/path/to/folder ./install.sh`

## Version

See [VERSION](VERSION).

## License

Apache-2.0 — see [LICENSE](LICENSE).
