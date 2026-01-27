# -----------------------------------------------------
# INIT
# -----------------------------------------------------

set -U fish_greeting

# -----------------------------------------------------
# Exports
# -----------------------------------------------------
export EDITOR=cursor

# -----------------------------------------------------
# PATH
# -----------------------------------------------------
set -U fish_user_paths "~/.local/bin/"

# -----------------------------------------------------
# Secrets (gitignored - see 99-secrets.fish.example)
# -----------------------------------------------------
if test -f "$__fish_config_dir/conf.d/99-secrets.fish"
    source "$__fish_config_dir/conf.d/99-secrets.fish"
else
    echo "⚠️  Warning: secrets file not found at $__fish_config_dir/conf.d/99-secrets.fish"
    echo "   Copy 99-secrets.fish.example to 99-secrets.fish and add your tokens"
end

if test -n "$XDG_RUNTIME_DIR"
    set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end