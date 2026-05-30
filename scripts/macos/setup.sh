install_macos_prerequisites() {
  log_header "macOS Prerequisites"

  if ! command -v git >/dev/null 2>&1; then
    MANUAL_STEPS+=("Install Apple command line tools with: xcode-select --install; then verify with: git --version")
  else
    log_ok "Git is installed"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    MANUAL_STEPS+=("Install Homebrew from https://brew.sh, then verify with: brew --version")
  else
    log_ok "Homebrew is installed"
  fi

  if ! ensure_node_available; then
    if command -v brew >/dev/null 2>&1 && confirm_action "Node.js/npm were not found. Install node with Homebrew?"; then
      run_cmd brew install node
    else
      MANUAL_STEPS+=("Install Node.js LTS, then verify with: node --version and npm --version")
    fi
  fi
}
