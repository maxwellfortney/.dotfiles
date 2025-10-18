if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Disable fish welcome message
set fish_greeting

# Aliases
alias ls='lsd'
alias grep='grep --color=auto'

# Project aliases
alias xmint-main="cursor /home/maxwell/code/paella/crossmint-main/crossmint-main.code-workspace; and exit"
alias xmint-sdk="cursor /home/maxwell/code/paella/crossmint-sdk/crossmint-sdk.code-workspace; and exit"
alias xmint="xmint-main; or xmint-sdk"

# ASDF configuration code
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims

asdf completion fish > ~/.config/fish/completions/asdf.fish

# Use Starship prompt
starship init fish | source
