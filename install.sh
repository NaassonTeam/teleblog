#!/bin/bash
# Teleblog self-host installer — universal (Linux, Mac, Windows Git Bash/WSL)
# Run from anywhere: language → folder picker → auto Docker → install
#
# Usage:
#   bash install.sh           # interactive
#   bash install.sh --stop   # stop container
#   bash install.sh -y       # skip prompts, use current dir
#
set -e

CONTAINER="teleblog"
LOG_PREFIX="[teleblog]"

log() { echo "$LOG_PREFIX $*"; }
IMAGE="${TELEBLOG_IMAGE:-ghcr.io/naassonteam/teleblog-selfhost:latest}"
ROOT=""
DATA_DIR=""
CHATS_DIR=""
LANG="${TELEBLOG_LANG:-en}"

# ─── i18n (EN, RU, ZH, AR) ───
msg() {
  local k="$1"
  case "$LANG" in
    ru) case "$k" in
          lang_select) echo "Выберите язык / Select language:" ;;
          lang_en) echo "English" ;;
          lang_ru) echo "Русский" ;;
          lang_zh) echo "中文" ;;
          lang_ar) echo "العربية" ;;
          folder_prompt) echo "Выберите папку для данных Teleblog" ;;
          folder_enter) echo "Введите путь (Enter — текущая, p — выбор папки):" ;;
          installer_data) echo "Установщик Teleblog — данные: " ;;
          docker_starting) echo "Запускаем Docker…" ;;
          docker_installing) echo "Устанавливаем Docker…" ;;
          docker_install_prompt) echo "Docker не найден. Установить? [y/N] " ;;
          docker_required) echo "Требуется Docker: https://docs.docker.com/get-docker/" ;;
          docker_not_ready) echo "Docker ещё не готов. Перезапустите терминал или: sudo systemctl start docker" ;;
          pulling) echo "Загружаем образ…" ;;
          open_url) echo "Откройте: http://localhost:7433" ;;
          data_path) echo "Данные: " ;;
          exports_path) echo "Экспорты: ./chats/имя_канала/result.json" ;;
          stopped) echo "Остановлен " ;;
          *) echo "$k" ;;
        esac ;;
    zh) case "$k" in
          lang_select) echo "选择语言 / Select language:" ;;
          lang_en) echo "English" ;;
          lang_ru) echo "Русский" ;;
          lang_zh) echo "中文" ;;
          lang_ar) echo "العربية" ;;
          folder_prompt) echo "选择 Teleblog 数据文件夹" ;;
          folder_enter) echo "输入路径（Enter 当前目录，p 选择文件夹）：" ;;
          installer_data) echo "Teleblog 安装程序 — 数据： " ;;
          docker_starting) echo "正在启动 Docker…" ;;
          docker_installing) echo "正在安装 Docker…" ;;
          docker_install_prompt) echo "未找到 Docker。是否安装？[y/N] " ;;
          docker_required) echo "需要 Docker：https://docs.docker.com/get-docker/" ;;
          docker_not_ready) echo "Docker 尚未就绪。请重启终端或运行：sudo systemctl start docker" ;;
          pulling) echo "正在拉取镜像…" ;;
          open_url) echo "打开：http://localhost:7433" ;;
          data_path) echo "数据： " ;;
          exports_path) echo "导出：./chats/频道名/result.json" ;;
          stopped) echo "已停止 " ;;
          *) echo "$k" ;;
        esac ;;
    ar) case "$k" in
          lang_select) echo "اختر اللغة / Select language:" ;;
          lang_en) echo "English" ;;
          lang_ru) echo "Русский" ;;
          lang_zh) echo "中文" ;;
          lang_ar) echo "العربية" ;;
          folder_prompt) echo "اختر مجلد بيانات Teleblog" ;;
          folder_enter) echo "أدخل المسار (Enter للحالي، p لاختيار مجلد):" ;;
          installer_data) echo "مثبت Teleblog — البيانات: " ;;
          docker_starting) echo "جاري تشغيل Docker…" ;;
          docker_installing) echo "جاري تثبيت Docker…" ;;
          docker_install_prompt) echo "Docker غير موجود. تثبيته؟ [y/N] " ;;
          docker_required) echo "Docker مطلوب: https://docs.docker.com/get-docker/" ;;
          docker_not_ready) echo "Docker غير جاهز. أعد تشغيل الطرفية أو: sudo systemctl start docker" ;;
          pulling) echo "جاري سحب الصورة…" ;;
          open_url) echo "افتح: http://localhost:7433" ;;
          data_path) echo "البيانات: " ;;
          exports_path) echo "التصديرات: ./chats/اسم_القناة/result.json" ;;
          stopped) echo "توقف " ;;
          *) echo "$k" ;;
        esac ;;
    *) case "$k" in
          lang_select) echo "Select language:" ;;
          lang_en) echo "English" ;;
          lang_ru) echo "Русский" ;;
          lang_zh) echo "中文" ;;
          lang_ar) echo "العربية" ;;
          folder_prompt) echo "Select folder for Teleblog data" ;;
          folder_enter) echo "Enter path (Enter for current, p for folder picker):" ;;
          installer_data) echo "Teleblog installer — data: " ;;
          docker_starting) echo "Starting Docker…" ;;
          docker_installing) echo "Installing Docker…" ;;
          docker_install_prompt) echo "Docker not found. Install now? [y/N] " ;;
          docker_required) echo "Docker required: https://docs.docker.com/get-docker/" ;;
          docker_not_ready) echo "Docker not ready. Restart terminal or run: sudo systemctl start docker" ;;
          pulling) echo "Pulling image…" ;;
          open_url) echo "Open: http://localhost:7433" ;;
          data_path) echo "Data: " ;;
          exports_path) echo "Exports: ./chats/channel_name/result.json" ;;
          stopped) echo "Stopped " ;;
          *) echo "$k" ;;
        esac ;;
  esac
}

# ─── Language selection (first step) ───
select_lang() {
  [[ -n "${TELEBLOG_LANG:-}" ]] && LANG="${TELEBLOG_LANG}" && return
  [[ "$1" == "-y" ]] && return
  [[ ! -t 0 ]] && return
  echo ""
  echo "Teleblog"
  echo "$(msg lang_select)"
  echo "  1) $(msg lang_en)"
  echo "  2) $(msg lang_ru)"
  echo "  3) $(msg lang_zh)"
  echo "  4) $(msg lang_ar)"
  echo ""
  local n
  read -p "1-4 [1]: " n
  n="${n:-1}"
  n="${n:0:1}"
  case "$n" in
    1) LANG="en" ;;
    2) LANG="ru" ;;
    3) LANG="zh" ;;
    4) LANG="ar" ;;
    *) LANG="en" ;;
  esac
}

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
  local prompt
  prompt=$(msg folder_prompt)
  local chosen=""

  if [[ "$os" == "mac" ]]; then
    chosen=$(osascript -e "tell application \"System Events\" to return POSIX path of (choose folder with prompt \"$prompt\")" 2>/dev/null)
  elif [[ "$os" == "linux" ]]; then
    if command -v zenity &>/dev/null; then
      chosen=$(zenity --file-selection --directory --title="$prompt" 2>/dev/null)
    elif command -v kdialog &>/dev/null; then
      chosen=$(kdialog --getexistingdirectory "$(pwd)" "$prompt" 2>/dev/null)
    elif command -v yad &>/dev/null; then
      chosen=$(yad --file --directory --title="$prompt" 2>/dev/null)
    fi
  elif [[ "$os" == "win" ]]; then
    chosen=$(powershell.exe -NoProfile -Command "
      Add-Type -AssemblyName System.Windows.Forms
      \$f = New-Object System.Windows.Forms.FolderBrowserDialog
      \$f.Description = '$prompt'
      if (\$f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { \$f.SelectedPath }
    " 2>/dev/null | tr '\\' '/')
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

# ─── Resolve ROOT ───
resolve_root() {
  local cmd="${1:-}"
  [[ "$cmd" == "-y" ]] && { ROOT="$(pwd)"; DATA_DIR="$ROOT/data"; CHATS_DIR="$ROOT/chats"; return; }
  [[ -n "${TELEBLOG_ROOT:-}" ]] && { ROOT="${TELEBLOG_ROOT}"; DATA_DIR="$ROOT/data"; CHATS_DIR="$ROOT/chats"; return; }

  if [[ ! -t 0 ]]; then
    ROOT="$(pwd)"
    log "Using current dir: $ROOT"
  else
    echo ""
    echo "$(msg folder_enter)"
    read -r -e -p "$(pwd)> " input
    input="${input:-$(pwd)}"
    if [[ "$input" == "p" || "$input" == "picker" ]]; then
      log "Opening folder picker..."
      if picked=$(pick_folder 2>/dev/null); then
        ROOT="$picked"
        log "Folder: $ROOT"
      else
        ROOT="$(pwd)"
        log "Using current dir: $ROOT"
      fi
    else
      ROOT="$input"
    fi
  fi

  ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || ROOT="$(pwd)"
  DATA_DIR="$ROOT/data"
  CHATS_DIR="$ROOT/chats"
}

# ─── Start Docker (when installed but not running) ───
start_docker() {
  local os=$(detect_os)
  if [[ "$os" == "mac" ]]; then
    open -a Docker 2>/dev/null || true
  elif [[ "$os" == "win" ]]; then
    powershell.exe -NoProfile -Command "
      \$p = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
      if (Test-Path \$p) { Start-Process \$p }
    " 2>/dev/null || true
  elif [[ "$os" == "linux" ]]; then
    sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
  fi
}

# ─── Check Docker (returns 0=ok, 1=installed not running, 2=not installed) ───
check_docker() {
  if ! command -v docker &>/dev/null; then
    return 2
  fi
  if docker info &>/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ─── Install Docker Linux ───
install_docker_linux() {
  log "$(msg docker_installing)"
  if ! command -v curl &>/dev/null; then
    log "Install curl first: sudo apt install curl"
    exit 1
  fi
  log "Downloading Docker installer..."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  log "Running Docker installer..."
  sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
  sudo usermod -aG docker "$USER" 2>/dev/null || true
  sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
  sleep 2
}

# ─── Install Docker Mac ───
install_docker_mac() {
  log "$(msg docker_installing)"
  if command -v brew &>/dev/null; then
    log "Downloading Docker via Homebrew (may take 5–10 min)..."
    brew install --cask docker
    log "$(msg docker_starting)"
    open -a Docker
    sleep 10
    return 0
  fi
  echo "$(msg docker_required)"
  echo "Mac: brew install --cask docker"
  exit 1
}

# ─── Install Docker Windows ───
install_docker_win() {
  log "$(msg docker_installing)"
  if command -v winget &>/dev/null; then
    log "Downloading Docker Desktop (may take a few min)..."
    winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements 2>/dev/null || true
    log "$(msg docker_starting)"
    if [[ -f "/c/Program Files/Docker/Docker/Docker Desktop.exe" ]]; then
      "/c/Program Files/Docker/Docker/Docker Desktop.exe" &
    fi
    sleep 15
    return 0
  fi
  if command -v choco &>/dev/null; then
    choco install docker-desktop -y
    sleep 15
    return 0
  fi
  echo "$(msg docker_required)"
  echo "Windows: winget install Docker.DockerDesktop"
  exit 1
}

# ─── Wait for Docker to be ready ───
wait_docker() {
  local i=0
  while [[ $i -lt 120 ]]; do
    if docker info &>/dev/null 2>&1; then
      return 0
    fi
    [[ $((i % 10)) -eq 0 ]] && [[ $i -gt 0 ]] && log "Waiting for Docker to start... ${i}s"
    sleep 2
    i=$((i + 2))
  done
  return 1
}

# ─── Main ───
main() {
  local cmd="${1:-}"

  if [[ "$cmd" == "--stop" ]]; then
    log "Stopping container..."
    docker rm -f "$CONTAINER" 2>/dev/null || true
    log "$(msg stopped)$CONTAINER"
    exit 0
  fi

  log "Starting Teleblog installer"
  select_lang "$cmd"
  resolve_root "$cmd"
  log "$(msg installer_data)$DATA_DIR"

  log "Checking Docker..."
  check_docker
  local ret=$?
  while [[ $ret -ne 0 ]]; do
    if [[ $ret -eq 1 ]]; then
      log "$(msg docker_starting)"
      start_docker
      if wait_docker; then
        log "Docker is ready"
        break
      fi
      log "$(msg docker_not_ready)"
      exit 1
    else
      local os=$(detect_os)
      local auto_install=0
      [[ "$cmd" == "-y" ]] && auto_install=1
      [[ "${TELEBLOG_AUTO_INSTALL_DOCKER:-}" == "1" ]] && auto_install=1
      [[ ! -t 0 ]] && auto_install=1

      if [[ $auto_install -eq 0 ]]; then
        echo -n "$(msg docker_install_prompt)"
        read -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || { log "$(msg docker_required)"; exit 1; }
      fi

      case "$os" in
        linux) install_docker_linux ;;
        mac)   install_docker_mac ;;
        win)   install_docker_win ;;
        *)     echo "$(msg docker_required)"; exit 1 ;;
      esac
    fi
    check_docker
    ret=$?
  done

  if ! check_docker; then
    log "$(msg docker_not_ready)"
    exit 1
  fi

  log "Docker OK"
  log "Creating data dirs..."
  mkdir -p "$DATA_DIR" "$CHATS_DIR"
  log "$(msg pulling)"
  log "Downloading Teleblog image (may take 1–2 min)..."
  docker pull "$IMAGE"
  log "Starting container..."
  docker rm -f "$CONTAINER" 2>/dev/null || true

  docker run -d \
    --name "$CONTAINER" \
    -v "$DATA_DIR:/data" \
    -v "$CHATS_DIR:/chats:ro" \
    -p 7433:7433 \
    --restart unless-stopped \
    "$IMAGE"

  log "Done."
  echo ""
  log "$(msg open_url)"
  log "$(msg data_path)$DATA_DIR"
  log "$(msg exports_path)"
}

main "$@"
