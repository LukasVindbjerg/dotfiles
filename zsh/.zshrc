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
alias ll='ls -alF' la='ls -A' l='ls -CF' grep='grep --color=auto'
command -v nvim >/dev/null && alias vim='nvim'
# Quick chats with Claude live in ~/chat, so they stay out of each project's 'claude -r' list
alias chat='(mkdir -p ~/chat && cd ~/chat && claude)'

# --- Sublime (Windows install; converts WSL paths for it) ---
subl() { local a=(); for f in "$@"; do a+=("$(wslpath -w "$f" 2>/dev/null || echo "$f")"); done; "/mnt/c/Program Files/Sublime Text/subl.exe" "${a[@]}"; }

# --- Tools ---
# fzf in Catppuccin Mocha (github.com/catppuccin/fzf)
export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

# --- Inherit what installers add to ~/.bashrc (aliases, PATH, pyenv, ...) ---
# Sources everything below Ubuntu's stock .bashrc, so later additions arrive here too.
_skel=$(wc -l < /etc/skel/.bashrc)
if cmp -s <(head -n $_skel ~/.bashrc) /etc/skel/.bashrc; then
  source <(tail -n +$((_skel + 1)) ~/.bashrc)
else
  print -P "%F{yellow}~/.bashrc stock part changed; not importing setup config%f"
fi
unset _skel

# --- Transient prompt: collapse finished prompts to just ❯ ---
_full_prompt=$PROMPT
_collapse_prompt() { PROMPT='%F{green}❯%f '; zle .reset-prompt }
_restore_prompt() { PROMPT=$_full_prompt }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-finish _collapse_prompt
precmd_functions+=(_restore_prompt)

# --- Windows Terminal: always work inside tmux ---
# Attach to the running tmux, or start it (tmux-continuum then restores the last
# saved workspace). Not in VS Code's terminal, Claude Code's shells, or nested tmux.
if [[ -o interactive && -n $WT_SESSION && -z $TMUX && -z $CLAUDECODE && $TERM_PROGRAM != vscode ]] && command -v tmux >/dev/null; then
  tmux attach 2>/dev/null || tmux new-session
fi
