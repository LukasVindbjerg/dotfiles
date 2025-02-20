PROMPT='%F{green}%n@%m%f %F{blue}%~%f %F{yellow}➜%f '

# Enable command history and append rather than overwrite
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Share history between sessions
setopt SHARE_HISTORY

# Case-insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Enable auto-correction for minor typos in commands
setopt CORRECT

# Use a more intuitive behavior for the backspace key
bindkey -e

# Enable recursive globbing (useful for searching files)
setopt EXTENDED_GLOB

# Set a default editor (change to your preference)
export EDITOR=nvim

# Aliases
alias ll='ls -lah'
alias grep='grep --color=auto'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
