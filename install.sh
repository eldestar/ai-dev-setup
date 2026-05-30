#!/usr/bin/env bash
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
ASSUME_YES=0
VERBOSE_LOGGING=0
TARGET_ROOT=""
MANUAL_STEPS=()
ERRORS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --verbose|-v) VERBOSE_LOGGING=1 ;;
    --target-root=*) TARGET_ROOT="${arg#*=}" ;;
    --help|-h)
      cat <<'HELP'
Usage: ./install.sh [--dry-run] [--yes] [--verbose] [--target-root=/path/to/project]

Installs and validates shared Claude Code + Codex CLI assets on macOS/Linux.
HELP
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/common/logging.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/common/detection.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/common/assets.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/common/ai-tools.sh"

init_log
log_header "Claude + Codex Installer"
log_info "Repo root: $REPO_ROOT"
[ "$DRY_RUN" -eq 1 ] && log_warn "Dry run enabled. No changes will be written."

detect_environment
log_header "Detected Environment"
log_info "OS: $OS_NAME"
log_info "Architecture: $ARCH"
log_info "Shells: ${SHELLS_DETECTED:-none}"
log_info "Package manager: ${PACKAGE_MANAGER:-none}"

case "$PLATFORM" in
  macos)
    # shellcheck source=/dev/null
    . "$REPO_ROOT/scripts/macos/setup.sh"
    install_macos_prerequisites
    ;;
  linux)
    # shellcheck source=/dev/null
    . "$REPO_ROOT/scripts/linux/setup.sh"
    install_linux_prerequisites
    ;;
  *)
    log_error "Unsupported platform for install.sh: $PLATFORM"
    MANUAL_STEPS+=("Use install.ps1 on Windows, or run install.sh from WSL2.")
    ;;
esac

install_repo_assets "$TARGET_ROOT"
install_claude_cli_and_assets
install_codex_cli_and_assets

log_header "Final Summary"
log_info "OS detected: $OS_NAME"
log_info "Shells detected: ${SHELLS_DETECTED:-none}"
log_info "Claude installed/configured: ${CLAUDE_INSTALLED:-no}/${CLAUDE_CONFIGURED:-no}"
log_info "Codex installed/configured: ${CODEX_INSTALLED:-no}/${CODEX_CONFIGURED:-no}"
log_info "Shared assets installed: ${SHARED_ASSETS_INSTALLED:-no}"
log_info "Claude assets installed: ${CLAUDE_ASSETS_INSTALLED:-no}"
log_info "Codex assets installed: ${CODEX_ASSETS_INSTALLED:-no}"

if [ "${#MANUAL_STEPS[@]}" -gt 0 ]; then
  log_warn "Manual steps still required:"
  for step in "${MANUAL_STEPS[@]}"; do log_warn "  - $step"; done
else
  log_ok "No manual fallback steps were recorded."
fi

if [ "${#ERRORS[@]}" -gt 0 ]; then
  log_warn "Errors or skipped items:"
  for err in "${ERRORS[@]}"; do log_warn "  - $err"; done
else
  log_ok "No errors recorded."
fi

log_info "Log file: $LOG_PATH"
