# --- Plugins (zinit installs itself on first run) ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -d $ZINIT_HOME ]] || git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"

zinit ice from"gh-r" as"program"; zinit light junegunn/fzf
zinit ice from"gh-r" as"program"; zinit light ajeetdsouza/zoxide
zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# --- History ---
HISTFILE=~/.zsh_history HISTSIZE=10000 SAVEHIST=10000
setopt sharehistory hist_ignore_all_dups hist_ignore_space

# --- PATH ---
path=("$HOME/dotfiles/bin" $path)

# --- Keys & completion ---
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no

# --- Aliases ---
alias ls='ls --color' c='clear'
command -v nvim >/dev/null && alias vim='nvim'
alias refresh-mcp='bash $SETUP_DIR/scripts/enable-mcp.sh --force'

# --- Sublime (Windows install; converts WSL paths for it) ---
subl() { local a=(); for f in "$@"; do a+=("$(wslpath -w "$f" 2>/dev/null || echo "$f")"); done; "/mnt/c/Program Files/Sublime Text/subl.exe" "${a[@]}"; }

# --- Tools ---
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# --- Transient prompt: collapse finished prompts to just ❯ ---
_full_prompt=$PROMPT
_collapse_prompt() { PROMPT='%F{green}❯%f '; zle .reset-prompt }
_restore_prompt() { PROMPT=$_full_prompt }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-finish _collapse_prompt
precmd_functions+=(_restore_prompt)
