#!/usr/bin/env bash
# Set up this terminal environment on WSL Ubuntu: zsh + starship, tmux, Neovim
# (LazyVim), Claude Code theme and status line, and the Windows Terminal look.
#
#   git clone https://github.com/LukasVindbjerg/dotfiles ~/dotfiles && ~/dotfiles/install.sh
#
# Safe to rerun: steps that are already done are skipped, and existing config
# files are moved to ~/.dotfiles-backup-<time>/ before being replaced.
#   --skip-windows   don't touch Windows (font, win32yank, Terminal/VS Code settings)
#   --skip-nvim      don't pre-install Neovim plugins (they install on first start)
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
PACKAGES=(zsh starship tmux nvim claude btop)
SKIP_WINDOWS=0 SKIP_NVIM=0
for a in "$@"; do
  case "$a" in
    --skip-windows) SKIP_WINDOWS=1 ;;
    --skip-nvim) SKIP_NVIM=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
done_(){ printf '  done  %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$DOT" = "$HOME/dotfiles" ] || warn "repo is at $DOT; the Claude status line expects ~/dotfiles"
grep -qi microsoft /proc/version 2>/dev/null || { warn "not WSL: skipping Windows steps"; SKIP_WINDOWS=1; }
mkdir -p "$BIN" "$HOME/.local/opt"
export PATH="$BIN:$PATH"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
step "System packages (apt)"
APT=(zsh git curl unzip stow tmux ripgrep build-essential python3)
missing=(); for p in "${APT[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
if [ ${#missing[@]} -eq 0 ]; then ok "all present"
else sudo apt-get update -qq && sudo apt-get install -y -qq "${missing[@]}" && done_ "installed ${missing[*]}"; fi

# ---------------------------------------------------------------------------
# Download the latest GitHub release asset matching a regex, verified against
# the sha256 digest GitHub publishes for it. Prints the downloaded file path.
gh_asset() {
  local repo=$1 pattern=$2 info url sum file
  info=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | python3 -c '
import json, re, sys
for a in json.load(sys.stdin)["assets"]:
    if re.fullmatch(sys.argv[1], a["name"]):
        print(a["browser_download_url"], (a.get("digest") or "").removeprefix("sha256:")); break
' "$pattern")
  read -r url sum <<<"$info"
  [ -n "${url:-}" ] && [ -n "${sum:-}" ] || { echo "no verifiable asset for $repo" >&2; return 1; }
  file="$TMP/$(basename "$url")"
  curl -fsSL -o "$file" "$url"
  echo "$sum  $file" | sha256sum -c --quiet - >&2 || { echo "checksum mismatch for $file" >&2; return 1; }
  echo "$file"
}

step "Tools from GitHub releases (checksum-verified, into ~/.local)"
nvim_ok() { have nvim && nvim --version | head -1 | grep -qE 'v0\.(1[1-9]|[2-9][0-9])|v[1-9]'; }
if nvim_ok; then ok "neovim $(nvim --version | head -1 | cut -d' ' -f2)"
else
  f=$(gh_asset neovim/neovim 'nvim-linux-x86_64\.tar\.gz')
  rm -rf "$HOME/.local/opt/nvim-linux-x86_64" && tar -xzf "$f" -C "$HOME/.local/opt"
  ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$BIN/nvim" && done_ "neovim"
fi
if have starship; then ok "starship"
else f=$(gh_asset starship/starship 'starship-x86_64-unknown-linux-musl\.tar\.gz') && tar -xzf "$f" -C "$BIN" starship && done_ "starship"; fi
if have fd; then ok "fd"
else f=$(gh_asset sharkdp/fd 'fd-v.*-x86_64-unknown-linux-musl\.tar\.gz') && tar -xzf "$f" -C "$TMP" && install -m755 "$TMP"/fd-*/fd "$BIN/fd" && done_ "fd"; fi
if have lazygit; then ok "lazygit"
else f=$(gh_asset jesseduffield/lazygit 'lazygit_.*_linux_x86_64\.tar\.gz') && tar -xzf "$f" -C "$BIN" lazygit && done_ "lazygit"; fi
if have tree-sitter; then ok "tree-sitter"
else f=$(gh_asset tree-sitter/tree-sitter 'tree-sitter-linux-x64\.gz') && gunzip -c "$f" > "$BIN/tree-sitter" && chmod +x "$BIN/tree-sitter" && done_ "tree-sitter"; fi
if have btop; then ok "btop"
else f=$(gh_asset aristocratos/btop 'btop-x86_64-unknown-linux-musl\.tar\.gz') && tar -xzf "$f" -C "$TMP" && install -m755 "$(find "$TMP" -path '*bin/btop' -type f | head -1)" "$BIN/btop" && done_ "btop"; fi
# fzf and zoxide are installed by zinit from .zshrc on the first zsh start.

# ---------------------------------------------------------------------------
step "Claude Code"
if have claude; then ok "claude $(claude --version 2>/dev/null | cut -d' ' -f1)"
else curl -fsSL https://claude.ai/install.sh | bash && done_ "claude installed (run 'claude' once to log in)"; fi

# ---------------------------------------------------------------------------
step "Link config files (stow)"
backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
# Real parent folders first: otherwise stow links the whole folder (e.g. ~/.claude)
# into this repo, and those apps would write their state into it.
mkdir -p "$HOME/.config" "$HOME/.claude/themes"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r rel; do
    target="$HOME/$rel"
    [ -e "$target" ] || [ -L "$target" ] || continue
    # Already ours: a link into the repo, or a file reached through a linked
    # folder (stow links whole folders such as ~/.config/nvim). Never move those.
    [[ "$(readlink -f "$target")" == "$DOT"/* ]] && continue
    mkdir -p "$backup/$(dirname "$rel")" && mv "$target" "$backup/$rel"
    warn "moved existing ~/$rel to $backup/"
  done < <(cd "$DOT/$pkg" && find . \( -name plugins -prune \) -o \( -type f -o -type l \) -print | sed 's#^\./##')
  stow -d "$DOT" -t "$HOME" "$pkg" && ok "$pkg"
done

# ---------------------------------------------------------------------------
step "zsh plugins and tmux plugins"
zsh -i -c exit >/dev/null 2>&1 && ok "zinit plugins, fzf and zoxide installed" || warn "first zsh start reported an error; open a terminal to see it"
TPM="$HOME/.config/tmux/plugins/tpm"
[ -d "$TPM" ] || git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
tmux -L dotfiles-install new-session -d 2>/dev/null && tmux -L dotfiles-install run-shell "$TPM/bin/install_plugins" >/dev/null 2>&1 \
  && ok "tmux plugins installed" || warn "tmux plugins: press Ctrl+Space then I inside tmux to install"
tmux -L dotfiles-install kill-server 2>/dev/null || true

# ---------------------------------------------------------------------------
if [ "$SKIP_NVIM" = 0 ]; then
  step "Neovim plugins and syntax parsers (a few minutes the first time)"
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 && ok "plugins" || warn "plugin install failed; it retries on first nvim start"
  nvim --headless -c 'lua local ts=require("nvim-treesitter"); ts.install(LazyVim.opts("nvim-treesitter").ensure_installed or {}):wait(600000)' -c qa >/dev/null 2>&1 \
    && ok "syntax parsers" || warn "parser install failed; run :TSUpdate inside nvim"
fi

# ---------------------------------------------------------------------------
step "Claude Code theme and status line"
python3 "$DOT/scripts/merge-claude-settings.py"

# ---------------------------------------------------------------------------
step "Default shell"
if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ]; then ok "zsh"
else chsh -s "$(command -v zsh)" && done_ "zsh is now your default shell"; fi

# ---------------------------------------------------------------------------
if [ "$SKIP_WINDOWS" = 0 ]; then
  step "Windows side: font, clipboard helper, Windows Terminal and VS Code"
  winpath() { wslpath "$(cmd.exe /c "echo %$1%" 2>/dev/null | tr -d '\r')"; }
  winget.exe install -e --id DEVCOM.JetBrainsMonoNerdFont --accept-package-agreements --accept-source-agreements >/dev/null 2>&1 || true
  if ls "$(winpath LOCALAPPDATA)/Microsoft/Windows/Fonts/" /mnt/c/Windows/Fonts/ 2>/dev/null | grep -qi 'JetBrainsMonoNerdFont-'; then
    ok "JetBrainsMono Nerd Font"
  else warn "JetBrainsMono Nerd Font not found; install it from nerdfonts.com"; fi
  winget.exe install -e --id equalsraf.win32yank --accept-package-agreements --accept-source-agreements >/dev/null 2>&1 || true
  yank=$(find "$(winpath LOCALAPPDATA)/Microsoft/WinGet/Packages" -maxdepth 2 -iname win32yank.exe 2>/dev/null | head -1)
  if [ -n "$yank" ]; then ln -sf "$yank" "$BIN/win32yank.exe" && ok "win32yank (shared clipboard for nvim)"
  else warn "win32yank not found; nvim yanks won't reach the Windows clipboard"; fi
  python3 "$DOT/scripts/merge-windows-settings.py" "$DOT/windows/catppuccin-mocha.json" "$(winpath LOCALAPPDATA)" "$(winpath APPDATA)"
fi

# ---------------------------------------------------------------------------
step "Finished"
[ -d "$backup" ] && echo "  Replaced files were saved in $backup"
echo "  Close and reopen Windows Terminal (and VS Code) to load the shell, font and colours."
