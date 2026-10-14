# Skip Ubuntu's global compinit; .zshrc runs its own
skip_global_compinit=1

# Org setup scripts only write to ~/.profile and ~/.bashrc. Read ~/.profile
# (plain sh) so its PATH entries (~/.local/bin, ~/.npm-global/bin, ...) apply here too.
typeset -U path
[[ -r ~/.profile ]] && emulate sh -c '. ~/.profile'
path=(~/.pyenv/bin $path)

# Mirrors the "Developer Setup configuration" block setup-wsl.sh writes to ~/.bashrc
export SETUP_DIR="$HOME/code/setup"
export BROWSER=wslview
