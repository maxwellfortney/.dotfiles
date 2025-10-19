# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'

alias cat='bat'
alias grep='rg'

alias c='clear'
alias nf='fastfetch'
alias ff='fastfetch'


# -----------------------------------------------------
# Projects
# -----------------------------------------------------
alias xmint-main="$EDITOR /home/maxwell/code/paella/crossmint-main/crossmint-main.code-workspace; and exit"
alias xmint-sdk="$EDITOR /home/maxwell/code/paella/crossmint-sdk/crossmint-sdk.code-workspace; and exit"
alias xmint="xmint-main; or xmint-sdk"
