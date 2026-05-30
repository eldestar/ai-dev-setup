ensure_node_available() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    log_ok "Node.js and npm are installed"
    return 0
  fi
  return 1
}

install_claude_cli_and_assets() {
  log_header "Claude Code"
  CLAUDE_INSTALLED="no"
  CLAUDE_CONFIGURED="no"
  CLAUDE_ASSETS_INSTALLED="no"

  if command -v claude >/dev/null 2>&1; then
    CLAUDE_INSTALLED="yes"
    log_ok "Claude Code command found"
  elif ensure_node_available && confirm_action "Claude Code was not found. Install @anthropic-ai/claude-code with npm?"; then
    if run_cmd npm install -g @anthropic-ai/claude-code@latest && command -v claude >/dev/null 2>&1; then
      CLAUDE_INSTALLED="yes"
    else
      log_error "Claude Code npm install did not validate."
    fi
  else
    MANUAL_STEPS+=("Install Claude Code from the official Anthropic docs, then run: claude --version")
  fi

  if [ "$CLAUDE_INSTALLED" = "yes" ]; then
    if run_cmd claude --version; then
      CLAUDE_CONFIGURED="yes"
      log_ok "Claude validates with claude --version"
    else
      MANUAL_STEPS+=("Run claude login or review Claude Code authentication, then verify with: claude --version")
    fi
  fi

  claude_home="$HOME/.claude"
  copy_setup_item "$REPO_ROOT/agents/claude/setup-orchestrator.md" "$claude_home/agents/setup-orchestrator.md" && CLAUDE_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/skills/shared/installer-maintenance" "$claude_home/skills/installer-maintenance" && CLAUDE_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/config/claude/commands/adversarial-codex-review.md" "$claude_home/commands/adversarial-codex-review.md" && CLAUDE_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/config/claude/settings.recommended.json" "$HOME/.ai-dev-setup/reference/claude/settings.recommended.json" && CLAUDE_ASSETS_INSTALLED="yes"
  project_root="${TARGET_ROOT:-$REPO_ROOT}"
  copy_setup_item "$REPO_ROOT/config/claude/CLAUDE.md" "$project_root/CLAUDE.md" && CLAUDE_ASSETS_INSTALLED="yes"
}

install_codex_cli_and_assets() {
  log_header "Codex CLI"
  CODEX_INSTALLED="no"
  CODEX_CONFIGURED="no"
  CODEX_ASSETS_INSTALLED="no"

  if command -v codex >/dev/null 2>&1; then
    CODEX_INSTALLED="yes"
    log_ok "Codex command found"
  elif ensure_node_available && confirm_action "Codex CLI was not found. Install @openai/codex with npm?"; then
    if run_cmd npm install -g @openai/codex@latest && command -v codex >/dev/null 2>&1; then
      CODEX_INSTALLED="yes"
    else
      log_error "Codex npm install did not validate."
    fi
  else
    MANUAL_STEPS+=("Install Codex CLI from the official OpenAI docs, then run: codex --version")
  fi

  if [ "$CODEX_INSTALLED" = "yes" ]; then
    if run_cmd codex --version; then
      CODEX_CONFIGURED="yes"
      log_ok "Codex validates with codex --version"
    else
      MANUAL_STEPS+=("Run codex login or review Codex CLI authentication, then verify with: codex --version")
    fi
  fi

  if [ -n "${USER_HOME:-}" ]; then
    codex_home="$HOME/.codex"
  else
    codex_home="${CODEX_HOME:-$HOME/.codex}"
  fi
  agents_home="$HOME/.agents"
  copy_setup_item "$REPO_ROOT/agents/codex/installer-reviewer.toml" "$codex_home/agents/installer-reviewer.toml" && CODEX_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/skills/shared/installer-maintenance" "$agents_home/skills/installer-maintenance" && CODEX_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/config/codex" "$HOME/.ai-dev-setup/reference/codex" && CODEX_ASSETS_INSTALLED="yes"
}
