detect_environment() {
  uname_s="$(uname -s)"
  ARCH="$(uname -m)"
  OS_NAME="$uname_s"
  PLATFORM="unknown"

  case "$uname_s" in
    Darwin) PLATFORM="macos"; OS_NAME="$(sw_vers -productName) $(sw_vers -productVersion)" ;;
    Linux)
      PLATFORM="linux"
      if [ -r /etc/os-release ]; then
        OS_NAME="$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-Linux}")"
      fi
      if grep -qi microsoft /proc/version 2>/dev/null; then OS_NAME="$OS_NAME (WSL2)"; fi
      ;;
  esac

  shells=""
  for candidate in pwsh powershell bash zsh fish; do
    if command -v "$candidate" >/dev/null 2>&1; then shells="$shells $candidate"; fi
  done
  SHELLS_DETECTED="$(printf '%s' "$shells" | xargs 2>/dev/null || printf '%s' "$shells")"

  PACKAGE_MANAGER=""
  for candidate in brew apt-get dnf yum pacman zypper; do
    if command -v "$candidate" >/dev/null 2>&1; then PACKAGE_MANAGER="$candidate"; break; fi
  done
}
