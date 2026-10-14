# Skip Ubuntu's global compinit; .zshrc runs its own
skip_global_compinit=1

# User-installed binaries (claude, poetry, ...); zsh doesn't read ~/.profile
typeset -U path
path=(~/.local/bin $path)
path=(~/.pyenv/bin ~/.npm-global/bin $path)

# Developer Setup (from enable-mcp.sh / setup-wsl.sh)
export SETUP_DIR="$HOME/code/setup"
export BROWSER=wslview
