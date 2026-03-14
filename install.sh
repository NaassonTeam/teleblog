#!/bin/bash
# Teleblog self-host installer — universal (Linux, Mac, Windows Git Bash/WSL)
# Run from anywhere: folder picker or prompt. Data in chosen folder.
#
# Usage:
#   ./install.sh              # folder picker, then install
#   ./install.sh --stop      # stop container
#   ./install.sh -y           # skip picker, use current dir
#
set -e

CONTAINER="teleblog"
IMAGE="${TELEBLOG_IMAGE:-ghcr.io/naassonteam/teleblog-selfhost:latest}"
ROOT=""
DATA_DIR=""
CHATS_DIR=""

# ─── Detect OS ───
detect_os() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "mac" ;;
    MINGW*|MSYS*|CYGWIN*) echo "win" ;;
    *)        echo "unknown" ;;
  esac
}

# ─── Folder picker (GUI when available) ───
pick_folder() {
  local os=$(detect_os)
  local chosen=""

  if [[ "$os" == "mac" ]]; then
    chosen=$(osascript -e 'tell application "System Events" to return POSIX path of (choose folder with prompt "Select folder for Teleblog data")' 2>/dev/null)
  elif [[ "$os" == "linux" ]]; then
    if command -v zenity &>/dev/null; then
      chosen=$(zenity --file-selection --directory --title="Select folder for Teleblog data" 2>/dev/null)
    elif command -v kdialog &>/dev/null; then
      chosen=$(kdialog --getexistingdirectory "$(pwd)" "Select folder for Teleblog data" 2>/dev/null)
    elif command -v yad &>/dev/null; then
      chosen=$(yad --file --directory --title="Select folder for Teleblog data" 2>/dev/null)
    fi
  elif [[ "$os" == "win" ]]; then
    chosen=$(powershell.exe -NoProfile -Command "
      Add-Type -AssemblyName System.Windows.Forms
      \$f = New-Object System.Windows.Forms.FolderBrowserDialog
      \$f.Description = 'Select folder for Teleblog data'
      if (\$f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { \$f.SelectedPath }
    " 2>/dev/null | tr '\\' '/')
    # Convert C:/path to /c/path for Git Bash
    if [[ -n "$chosen" && "$chosen" =~ ^[A-Za-z]: ]]; then
      local drive="${chosen:0:1}"
      chosen="/$(echo "$drive" | tr '[:upper:]' '[:lower:]')${chosen:2}"
    fi
  fi

  if [[ -n "$chosen" ]]; then
    echo "$chosen"
    return 0
  fi
  return 1
}

# ─── Resolve ROOT (folder for data) ───
resolve_root() {
  local cmd="${1:-}"
  local skip_picker=0
  [[ "$cmd" == "-y" ]] && skip_picker=1
  [[ -n "${TELEBLOG_ROOT:-}" ]] && skip_picker=1

  if [[ -n "${TELEBLOG_ROOT:-}" ]]; then
    ROOT="${TELEBLOG_ROOT}"
  elif [[ $skip_picker -eq 1 ]]; then
    ROOT="$(pwd)"
  elif [[ -t 0 ]]; then
    local picked
    if picked=$(pick_folder); then
      ROOT="$picked"
    else
      echo ""
      echo "Enter folder path for Teleblog data (or press Enter for current):"
      read -r -e -p "$(pwd)> " input
      ROOT="${input:-$(pwd)}"
    fi
  else
    ROOT="$(pwd)"
  fi

  ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || ROOT="$(pwd)"
  DATA_DIR="$ROOT/data"
  CHATS_DIR="$ROOT/chats"
}

# ─── Check Docker ───
check_docker() {
  if command -v docker &>/dev/null; then
    if docker info &>/dev/null 2>&1; then
      return 0
    fi
    echo "Docker is installed but not running. Start Docker Desktop (Mac/Windows) or: sudo systemctl start docker (Linux)"
    return 1
  fi
  return 2
}

# ─── Install Docker (Linux only) ───
install_docker_linux() {
  echo "Installing Docker..."
  if ! command -v curl &>/dev/null; then
    echo "Install curl first: sudo apt install curl  # or yum/dnf"
    exit 1
  fi
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
  if [[ "$(id -u)" != "0" ]]; then
    echo "Adding your user to docker group. You may need to log out and back in."
    sudo usermod -aG docker "$USER" 2>/dev/null || true
  fi
  echo "Docker installed. Starting..."
  sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
  sleep 2
}

# ─── Install instructions for Mac/Windows ───
install_docker_instructions() {
  local os=$(detect_os)
  echo ""
  echo "Install Docker manually:"
  if [[ "$os" == "mac" ]]; then
    echo "  brew install --cask docker"
    echo "  Then open Docker from Applications."
  elif [[ "$os" == "win" ]]; then
    echo "  Download Docker Desktop: https://www.docker.com/products/docker-desktop/"
    echo "  Or use WSL2 and install Docker inside WSL."
  fi
  echo ""
  exit 1
}

# ─── Main ───
main() {
  local cmd="${1:-}"

  if [[ "$cmd" == "--stop" ]]; then
    docker rm -f "$CONTAINER" 2>/dev/null || true
    echo "Stopped $CONTAINER"
    exit 0
  fi

  resolve_root "$cmd"
  echo ""
  echo "Teleblog installer — data: $DATA_DIR"

  # Check Docker
  check_docker
  local ret=$?
  if [[ $ret -ne 0 ]]; then
    if [[ $ret -eq 2 ]]; then
      local os=$(detect_os)
      if [[ "$os" == "linux" ]]; then
        if [[ "${TELEBLOG_AUTO_INSTALL_DOCKER:-}" == "1" ]] || [[ "$cmd" == "-y" ]]; then
          install_docker_linux
        elif [[ -t 0 ]]; then
          read -p "Docker not found. Install now? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_docker_linux
          else
            echo "Docker required. Install: https://docs.docker.com/get-docker/"
            exit 1
          fi
        else
          echo "Docker not found. Run: TELEBLOG_AUTO_INSTALL_DOCKER=1 ./install.sh"
          exit 1
        fi
      else
        install_docker_instructions
      fi
    else
      exit 1
    fi
  fi

  # Re-check Docker
  if ! check_docker; then
    echo "Docker still not ready. Restart terminal or run: sudo systemctl start docker"
    exit 1
  fi

  mkdir -p "$DATA_DIR" "$CHATS_DIR"

  echo "Pulling image..."
  docker pull "$IMAGE"

  docker rm -f "$CONTAINER" 2>/dev/null || true

  docker run -d \
    --name "$CONTAINER" \
    -v "$DATA_DIR:/data" \
    -v "$CHATS_DIR:/chats:ro" \
    -p 7433:7433 \
    --restart unless-stopped \
    "$IMAGE"

  echo ""
  echo "Open: http://localhost:7433"
  echo "Data: $DATA_DIR"
  echo "Exports: $CHATS_DIR (./chats/channel_name/result.json)"
}

main "$@"
