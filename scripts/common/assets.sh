copy_setup_item() {
  src="$1"
  dest="$2"

  if [ ! -e "$src" ]; then
    log_warn "Source missing, skipping: $src"
    return 1
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log_info "DRY RUN: copy $src -> $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then
    if ! confirm_action "Replace existing $dest after backing it up?"; then
      log_warn "Skipped existing destination: $dest"
      return 1
    fi
    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    log_ok "Backed up $dest to $backup"
  fi

  cp -R "$src" "$dest"
  log_ok "Installed $dest"
}

install_repo_assets() {
  target_root="$1"
  [ -n "$target_root" ] || target_root="$REPO_ROOT"
  home_base="${HOME}/.ai-dev-setup"

  log_header "Shared Repo Assets"
  SHARED_ASSETS_INSTALLED="no"
  copy_setup_item "$REPO_ROOT/config/shared" "$home_base/shared/config" && SHARED_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/agents/shared" "$home_base/shared/agents" && SHARED_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/templates" "$home_base/shared/templates" && SHARED_ASSETS_INSTALLED="yes"
  copy_setup_item "$REPO_ROOT/config/shared/AGENTS.md" "$target_root/AGENTS.md" && SHARED_ASSETS_INSTALLED="yes"
}
