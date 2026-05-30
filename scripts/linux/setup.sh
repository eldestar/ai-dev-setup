install_linux_prerequisites() {
  log_header "Linux Prerequisites"

  if ! command -v git >/dev/null 2>&1; then
    if [ "$PACKAGE_MANAGER" = "apt-get" ] && confirm_action "Git was not found. Install git with apt-get?"; then
      run_cmd sudo apt-get update
      run_cmd sudo apt-get install -y git
    else
      MANUAL_STEPS+=("Install Git with your distro package manager, then verify with: git --version")
    fi
  else
    log_ok "Git is installed"
  fi

  if ! ensure_node_available; then
    if [ "$PACKAGE_MANAGER" = "apt-get" ] && confirm_action "Node.js/npm were not found. Install nodejs npm with apt-get?"; then
      run_cmd sudo apt-get update
      run_cmd sudo apt-get install -y nodejs npm
    else
      MANUAL_STEPS+=("Install Node.js LTS and npm, then verify with: node --version and npm --version")
    fi
  fi
}
