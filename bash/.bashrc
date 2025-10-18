#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Helpful message
echo "🐟 For the best experience, use kitty terminal which runs fish shell"
echo "   Run: kitty"
