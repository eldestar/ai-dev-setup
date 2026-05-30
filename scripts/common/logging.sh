init_log() {
  mkdir -p "$REPO_ROOT/logs"
  LOG_PATH="$REPO_ROOT/logs/setup-$(date +%Y%m%d-%H%M%S).log"
  [ "$DRY_RUN" -eq 1 ] || : > "$LOG_PATH"
}

log_line() {
  level="$1"
  message="$2"
  line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
  [ "$DRY_RUN" -eq 1 ] || printf '%s\n' "$line" >> "$LOG_PATH"
  case "$level" in
    HEADER) printf '\n\033[36m=== %s ===\033[0m\n' "$message" ;;
    OK) printf '\033[32m  [OK] %s\033[0m\n' "$message" ;;
    WARN) printf '\033[33m  [!] %s\033[0m\n' "$message" ;;
    ERROR) printf '\033[31m  [ERROR] %s\033[0m\n' "$message" ;;
    *) printf '  %s\n' "$message" ;;
  esac
}

log_header() { log_line HEADER "$1"; }
log_info() { log_line INFO "$1"; }
log_ok() { log_line OK "$1"; }
log_warn() { log_line WARN "$1"; }
log_error() {
  ERRORS+=("$1")
  log_line ERROR "$1"
}

confirm_action() {
  prompt="$1"
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf '%s [y/N] ' "$prompt"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY RUN: $*"
    return 0
  fi
  log_info "Running: $*"
  if [ "$VERBOSE_LOGGING" -eq 1 ]; then
    "$@"
  else
    "$@" >/tmp/ai-dev-setup-command.log 2>&1
  fi
}
