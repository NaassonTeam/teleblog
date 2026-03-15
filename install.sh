#!/bin/bash
# Teleblog self-host installer — universal (Linux, Mac, Windows Git Bash/WSL)
# Reliable flow: language -> folder -> docker state machine -> pull -> run.
#
# Usage:
#   bash install.sh                 # interactive
#   bash install.sh -y              # non-interactive (current dir)
#   bash install.sh --stop          # stop container
#   bash install.sh --dry-run       # smoke test without docker side-effects

set -uo pipefail

CONTAINER="teleblog"
IMAGE="${TELEBLOG_IMAGE:-cr.yandex/crpdlb5mvkseemurnl69/teleblog-selfhost:latest}"
BLOG_PORT="${BLOG_PORT:-7433}"
INSTALLER_BUILD="2026.03.14-r1"
RUN_ID="run_$(date +%s)"
LOG_PREFIX="[teleblog]"

ROOT=""
DATA_DIR=""
CHATS_DIR=""
INSTANCE_NAME="${TELEBLOG_INSTANCE_NAME:-}"
LANG="${TELEBLOG_LANG:-en}"
SKIP_PROMPTS=0
DRY_RUN="${TELEBLOG_DRY_RUN:-0}"
DOCKER_RUN_PLATFORM="${TELEBLOG_DOCKER_PLATFORM:-}"

detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "mac" ;;
    MINGW*|MSYS*|CYGWIN*) echo "win" ;;
    *) echo "unknown" ;;
  esac
}

PLATFORM="$(detect_os)"
SHELL_NAME="${SHELL##*/}"
EVENT_LOG="${TELEBLOG_EVENT_LOG:-$(pwd)/teleblog-installer.ndjson}"

now_ms() {
  echo $(( $(date +%s) * 1000 ))
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}

event_log() {
  local event="$1"
  local step="$2"
  local result="$3"
  local error="$4"
  local duration_ms="$5"
  local message="$6"
  local ts
  ts="$(now_ms)"

  printf '{"event":"%s","step":"%s","result":"%s","error":"%s","duration_ms":%s,"platform":"%s","shell":"%s","installer_build":"%s","run_id":"%s","message":"%s","timestamp":%s}\n' \
    "$(json_escape "$event")" \
    "$(json_escape "$step")" \
    "$(json_escape "$result")" \
    "$(json_escape "$error")" \
    "${duration_ms:-0}" \
    "$(json_escape "$PLATFORM")" \
    "$(json_escape "$SHELL_NAME")" \
    "$(json_escape "$INSTALLER_BUILD")" \
    "$(json_escape "$RUN_ID")" \
    "$(json_escape "$message")" \
    "$ts" >> "$EVENT_LOG"
}

log_info() { echo "$LOG_PREFIX $*"; }
log_warn() { echo "$LOG_PREFIX WARN: $*"; }
log_error() { echo "$LOG_PREFIX ERROR: $*" >&2; }

die() {
  local step="$1"
  local msg="$2"
  local code="${3:-1}"
  event_log "fatal" "$step" "error" "$msg" 0 "$msg"
  log_error "$msg"
  exit "$code"
}

STEP_NAME=""
STEP_STARTED_MS=0

step_begin() {
  STEP_NAME="$1"
  STEP_STARTED_MS="$(now_ms)"
  event_log "step" "$STEP_NAME" "start" "" 0 "step start"
}

step_end() {
  local result="$1"
  local error="${2:-}"
  local end_ms duration
  end_ms="$(now_ms)"
  duration=$(( end_ms - STEP_STARTED_MS ))
  event_log "step" "$STEP_NAME" "$result" "$error" "$duration" "step end"
}

msg() {
  local k="$1"
  case "$LANG" in
    ru) case "$k" in
      lang_select) echo "Выберите язык / Select language:" ;;
      folder_enter) echo "Папка для данных (Enter = текущая):" ;;
      instance_enter) echo "Название инстанса для QR (Enter = пропустить):" ;;
      instance_skip) echo "пропустить" ;;
      instance_set) echo "Инстанс:" ;;
      installer_data) echo "Установщик Teleblog — данные:" ;;
      docker_check) echo "Проверяем Docker..." ;;
      docker_starting) echo "Запускаем Docker..." ;;
      docker_installing) echo "Устанавливаем Docker..." ;;
      docker_not_ready) echo "Docker не готов после попыток запуска." ;;
      pulling) echo "Скачиваем образ Teleblog..." ;;
      done) echo "Готово." ;;
      stopped) echo "Контейнер остановлен:" ;;
      *) echo "$k" ;;
    esac ;;
    zh) case "$k" in
      lang_select) echo "选择语言 / Select language:" ;;
      folder_enter) echo "数据目录（Enter=当前目录）:" ;;
      instance_enter) echo "实例名称（用于 QR，Enter=跳过）:" ;;
      instance_skip) echo "跳过" ;;
      instance_set) echo "实例:" ;;
      installer_data) echo "Teleblog 安装目录:" ;;
      docker_check) echo "检查 Docker..." ;;
      docker_starting) echo "启动 Docker..." ;;
      docker_installing) echo "安装 Docker..." ;;
      docker_not_ready) echo "Docker 启动失败。" ;;
      pulling) echo "拉取 Teleblog 镜像..." ;;
      done) echo "完成。" ;;
      stopped) echo "容器已停止:" ;;
      *) echo "$k" ;;
    esac ;;
    ar) case "$k" in
      lang_select) echo "اختر اللغة / Select language:" ;;
      folder_enter) echo "مجلد البيانات (Enter = الحالي):" ;;
      instance_enter) echo "اسم المثيل للـ QR (Enter = تخطي):" ;;
      instance_skip) echo "تخطي" ;;
      instance_set) echo "المثيل:" ;;
      installer_data) echo "مسار بيانات Teleblog:" ;;
      docker_check) echo "جار التحقق من Docker..." ;;
      docker_starting) echo "جار تشغيل Docker..." ;;
      docker_installing) echo "جار تثبيت Docker..." ;;
      docker_not_ready) echo "Docker غير جاهز بعد المحاولات." ;;
      pulling) echo "جار تنزيل صورة Teleblog..." ;;
      done) echo "تم." ;;
      stopped) echo "تم إيقاف الحاوية:" ;;
      *) echo "$k" ;;
    esac ;;
    *) case "$k" in
      lang_select) echo "Select language:" ;;
      folder_enter) echo "Folder for data (Enter = current):" ;;
      instance_enter) echo "Instance name for QR (Enter = skip):" ;;
      instance_skip) echo "skip" ;;
      instance_set) echo "Instance:" ;;
      installer_data) echo "Teleblog installer data path:" ;;
      docker_check) echo "Checking Docker..." ;;
      docker_starting) echo "Starting Docker..." ;;
      docker_installing) echo "Installing Docker..." ;;
      docker_not_ready) echo "Docker is still not ready after retries." ;;
      pulling) echo "Downloading Teleblog image..." ;;
      done) echo "Done." ;;
      stopped) echo "Stopped container:" ;;
      *) echo "$k" ;;
    esac ;;
  esac
}

select_lang() {
  step_begin "language"
  if [[ -n "${TELEBLOG_LANG:-}" ]]; then
    case "$TELEBLOG_LANG" in
      en|ru|zh|ar) LANG="$TELEBLOG_LANG" ;;
      *) LANG="en" ;;
    esac
    step_end "success"
    return
  fi

  if [[ $SKIP_PROMPTS -eq 1 || ! -t 0 ]]; then
    LANG="en"
    step_end "success"
    return
  fi

  echo ""
  echo "Teleblog"
  echo "$(msg lang_select)"
  echo "  1) English"
  echo "  2) Русский"
  echo "  3) 中文"
  echo "  4) العربية"
  printf "1-4 [1]: "
  local raw n
  read -r raw
  n="${raw:-1}"
  n="${n:0:1}"
  case "$n" in
    1) LANG="en" ;;
    2) LANG="ru" ;;
    3) LANG="zh" ;;
    4) LANG="ar" ;;
    *) LANG="en" ;;
  esac
  step_end "success"
}

resolve_root() {
  step_begin "folder"
  if [[ -n "${TELEBLOG_ROOT:-}" ]]; then
    ROOT="$TELEBLOG_ROOT"
  elif [[ $SKIP_PROMPTS -eq 1 || ! -t 0 ]]; then
    ROOT="$(pwd)"
  else
    echo ""
    log_info "Step 2: $(msg folder_enter)"
    printf "[%s]> " "$(pwd)"
    local input
    read -r input
    if printf '%s' "$input" | LC_ALL=C grep -q '[[:cntrl:]]'; then
      log_warn "Detected control characters in path input, using current directory."
      input=""
    fi
    ROOT="${input:-$(pwd)}"
  fi

  if [[ "$ROOT" == "~"* ]]; then
    ROOT="${HOME}${ROOT:1}"
  fi
  if [[ "$ROOT" != /* ]]; then
    ROOT="$(pwd)/$ROOT"
  fi

  mkdir -p "$ROOT" || die "folder" "Cannot create/access directory: $ROOT"
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || die "folder" "Cannot enter directory: $ROOT"

  DATA_DIR="$ROOT/data"
  CHATS_DIR="$ROOT/chats"
  step_end "success"
}

resolve_instance() {
  if [[ -n "${TELEBLOG_INSTANCE_NAME:-}" ]]; then
    INSTANCE_NAME="$TELEBLOG_INSTANCE_NAME"
    return
  fi
  if [[ $SKIP_PROMPTS -eq 1 || ! -t 0 ]]; then
    return
  fi
  echo ""
  log_info "$(msg instance_enter)"
  printf "[%s]> " "$(msg instance_skip)"
  local input
  read -r input
  input="$(printf '%s' "$input" | tr -cd 'a-zA-Z0-9_-' | head -c 32)"
  if [[ -n "$input" ]]; then
    INSTANCE_NAME="$input"
    log_info "$(msg instance_set) $INSTANCE_NAME"
  fi
}

docker_state() {
  if [[ -n "${TELEBLOG_DOCKER_STATE:-}" ]]; then
    echo "$TELEBLOG_DOCKER_STATE"
    return 0
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "no_binary"
    return 0
  fi
  if docker info >/dev/null 2>&1; then
    echo "ok"
  else
    echo "daemon_down"
  fi
}

install_docker_linux() {
  log_info "$(msg docker_installing)"
  if ! command -v curl >/dev/null 2>&1; then
    die "docker_install" "curl is required to install Docker on Linux"
  fi
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh || die "docker_install" "Failed to download Docker installer"
  sh /tmp/get-docker.sh || die "docker_install" "Docker installer failed"
  rm -f /tmp/get-docker.sh
}

install_docker_mac() {
  log_info "$(msg docker_installing)"
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "docker_install" "Homebrew install failed"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  brew install --cask docker-desktop || die "docker_install" "Docker Desktop install failed"
}

install_docker_win() {
  log_info "$(msg docker_installing)"
  if command -v winget >/dev/null 2>&1; then
    winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements || die "docker_install" "winget docker install failed"
    return
  fi
  if command -v choco >/dev/null 2>&1; then
    choco install docker-desktop -y || die "docker_install" "choco docker install failed"
    return
  fi
  die "docker_install" "Neither winget nor choco available for Docker install"
}

start_docker() {
  log_info "$(msg docker_starting)"
  case "$PLATFORM" in
    linux) sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true ;;
    mac) open -a Docker 2>/dev/null || true ;;
    win) powershell.exe -NoProfile -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || true ;;
  esac
}

wait_docker_ready() {
  local waited=0
  while [[ $waited -lt 180 ]]; do
    if [[ "$(docker_state)" == "ok" ]]; then
      return 0
    fi
    sleep 2
    waited=$(( waited + 2 ))
    if (( waited % 10 == 0 )); then
      log_info "Waiting for Docker... ${waited}s"
    fi
  done
  return 1
}

wait_http_ready() {
  local waited=0
  if ! command -v curl >/dev/null 2>&1; then
    log_warn "curl is not available, skip HTTP readiness check."
    return 0
  fi
  while [[ $waited -lt 180 ]]; do
    if ! docker ps --format '{{.Names}}' | LC_ALL=C grep -qx "$CONTAINER"; then
      local tail_logs
      tail_logs="$(docker logs --tail 80 "$CONTAINER" 2>&1 | tr '\n' ' ' | sed 's/"/\\"/g')"
      die "run" "Container '$CONTAINER' exited before HTTP became ready. Logs: $tail_logs"
    fi
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${BLOG_PORT}/" || true)"
    if [[ "$code" =~ ^2|^3 ]]; then
      return 0
    fi
    sleep 2
    waited=$(( waited + 2 ))
    if (( waited % 10 == 0 )); then
      log_info "Waiting for HTTP on :${BLOG_PORT}... ${waited}s"
    fi
  done
  local tail_logs
  tail_logs="$(docker logs --tail 80 "$CONTAINER" 2>&1 | tr '\n' ' ' | sed 's/"/\\"/g')"
  die "run" "HTTP is not ready on :${BLOG_PORT} after 180s. Container logs: $tail_logs"
}

ensure_docker() {
  step_begin "docker"
  log_info "$(msg docker_check)"
  local state attempts
  attempts=0
  while true; do
    state="$(docker_state)"
    case "$state" in
      ok)
        step_end "success"
        return
        ;;
      no_binary)
        if [[ $DRY_RUN -eq 1 ]]; then
          log_info "DRY RUN: skip docker install"
          step_end "success"
          return
        fi
        case "$PLATFORM" in
          linux) install_docker_linux ;;
          mac) install_docker_mac ;;
          win) install_docker_win ;;
          *) die "docker" "Unsupported platform for Docker install: $PLATFORM" ;;
        esac
        ;;
      daemon_down)
        if [[ $DRY_RUN -eq 1 ]]; then
          log_info "DRY RUN: skip docker start"
          step_end "success"
          return
        fi
        start_docker
        wait_docker_ready || true
        ;;
      *)
        die "docker" "Unknown Docker state: $state"
        ;;
    esac

    attempts=$(( attempts + 1 ))
    if [[ $attempts -ge 3 && "$(docker_state)" != "ok" ]]; then
      step_end "error" "$(msg docker_not_ready)"
      die "docker" "$(msg docker_not_ready)"
    fi
  done
}

run_container() {
  step_begin "run"
  log_info "Preparing directories..."
  mkdir -p "$DATA_DIR" "$CHATS_DIR" || die "run" "Cannot create data directories"

  if [[ $DRY_RUN -eq 1 ]]; then
    log_info "DRY RUN: skip docker pull/run"
    step_end "success"
    return
  fi

  log_info "$(msg pulling)"
  local pull_err
  pull_err="$(mktemp)"
  if ! docker pull "$IMAGE" 2>"$pull_err"; then
    local err_text
    err_text="$(tr '\n' ' ' <"$pull_err" | sed 's/"/\\"/g')"
    rm -f "$pull_err"
    if printf '%s' "$err_text" | LC_ALL=C grep -qi "denied"; then
      die "run" "Access denied to image $IMAGE. Login to the corresponding registry (for Yandex: docker login cr.yandex) or set TELEBLOG_IMAGE to a public image. Original error: $err_text"
    fi
    if printf '%s' "$err_text" | LC_ALL=C grep -qi "manifest unknown"; then
      die "run" "Image tag not found: $IMAGE. Set TELEBLOG_IMAGE to existing tag. Original error: $err_text"
    fi
    die "run" "docker pull failed for $IMAGE. Error: $err_text"
  fi
  rm -f "$pull_err"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  # Multi-arch image: Docker auto-selects arm64 on Mac, amd64 elsewhere. Override via TELEBLOG_DOCKER_PLATFORM.
  if [[ "$PLATFORM" == "mac" && "$(uname -m)" == "arm64" ]]; then
    log_info "Apple Silicon: using native arm64 image."
  fi
  local extra_env=""
  [[ -n "${INSTANCE_NAME:-}" ]] && extra_env="-e TELEBLOG_INSTANCE_NAME=$INSTANCE_NAME"
  if [[ -n "$DOCKER_RUN_PLATFORM" ]]; then
    docker run -d --platform "$DOCKER_RUN_PLATFORM" \
      -e BLOG_PORT="$BLOG_PORT" \
      $extra_env \
      --name "$CONTAINER" \
      -v "$DATA_DIR:/data" \
      -v "$CHATS_DIR:/chats:ro" \
      -p "$BLOG_PORT:$BLOG_PORT" \
      --restart unless-stopped \
      "$IMAGE" >/dev/null || die "run" "docker run failed"
  else
    docker run -d \
      -e BLOG_PORT="$BLOG_PORT" \
      $extra_env \
      --name "$CONTAINER" \
      -v "$DATA_DIR:/data" \
      -v "$CHATS_DIR:/chats:ro" \
      -p "$BLOG_PORT:$BLOG_PORT" \
      --restart unless-stopped \
      "$IMAGE" >/dev/null || die "run" "docker run failed"
  fi

  wait_http_ready

  step_end "success"
}

stop_container() {
  step_begin "stop"
  if [[ $DRY_RUN -eq 1 ]]; then
    log_info "DRY RUN: skip docker rm"
    step_end "success"
    return
  fi
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  step_end "success"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y) SKIP_PROMPTS=1 ;;
      --stop) CMD="stop" ;;
      --dry-run) DRY_RUN=1 ;;
      *) die "args" "Unknown argument: $1" 2 ;;
    esac
    shift
  done
}

CMD="install"

main() {
  parse_args "$@"
  event_log "run" "start" "start" "" 0 "installer started"
  log_info "Starting Teleblog installer"
  log_info "Build: $INSTALLER_BUILD"
  log_info "Run ID: $RUN_ID"
  log_info "Event log: $EVENT_LOG"
  log_info "Image: $IMAGE"

  if [[ "$CMD" == "stop" ]]; then
    stop_container
    log_info "$(msg stopped) $CONTAINER"
    event_log "run" "finish" "success" "" 0 "stop completed"
    return
  fi

  select_lang
  log_info "Language: $LANG"
  resolve_root
  resolve_instance
  EVENT_LOG="${TELEBLOG_EVENT_LOG:-$ROOT/teleblog-installer.ndjson}"
  log_info "$(msg installer_data) $DATA_DIR"
  ensure_docker
  run_container

  log_info "$(msg done)"
  echo ""
  log_info "Open: http://localhost:${BLOG_PORT}"
  log_info "Data: $DATA_DIR"
  log_info "Exports: $CHATS_DIR (./chats/channel_name/result.json)"
  event_log "run" "finish" "success" "" 0 "installer completed"
}

main "$@"
