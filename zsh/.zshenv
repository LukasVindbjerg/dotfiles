# Skip Ubuntu's global compinit; .zshrc runs its own
skip_global_compinit=1

# Installers often only write to ~/.profile and ~/.bashrc. Read ~/.profile
# (plain sh) so its PATH entries (~/.local/bin, ~/.npm-global/bin, ...) apply here too.
typeset -U path
[[ -r ~/.profile ]] && emulate sh -c '. ~/.profile'
path=(~/.pyenv/bin $path)
