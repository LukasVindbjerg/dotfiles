# Skip Ubuntu's global compinit; .zshrc runs its own
skip_global_compinit=1

# User-installed binaries (claude, poetry, ...); zsh doesn't read ~/.profile
typeset -U path
path=(~/.local/bin $path)
