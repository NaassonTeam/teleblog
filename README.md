# Teleblog

Turn Telegram channels into static blogs. Self-hosted, runs anywhere.

## Install

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/NaassonTeam/teleblog/main/install.sh
chmod +x install.sh
./install.sh
```

Step 1 downloads the script. Step 2 makes it executable. Step 3 runs it. The script will ask for language, then open a folder picker (fzf: arrows, type to search). Install fzf for the picker: `brew install fzf` (Mac). Then open http://localhost:7433.

## Stop

```bash
./install.sh --stop
```

## Non-interactive

`./install.sh -y` — skip prompts, use current dir. Env: `TELEBLOG_LANG=ru`, `TELEBLOG_ROOT=/path`

## Version

See [VERSION](VERSION).

## License

Apache-2.0 — see [LICENSE](LICENSE).
