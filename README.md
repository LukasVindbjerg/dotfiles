# dotfiles

A terminal setup for WSL Ubuntu: zsh with a minimal starship prompt, tmux,
Neovim (LazyVim) that moves between tmux panes as one program, Claude Code with
a status line, and Catppuccin Mocha colours everywhere.

## Quick start

In WSL Ubuntu:

```sh
git clone https://github.com/LukasVindbjerg/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

It asks for your password for `apt` and to make zsh your default shell. When it
finishes, close and reopen Windows Terminal (and VS Code). Then run `claude` once
to log in.

Clone to `~/dotfiles` exactly; the Claude status line points there.

## What `install.sh` does

| Step | Details |
|---|---|
| apt packages | zsh, git, curl, unzip, stow, tmux, ripgrep, build-essential, python3 |
| Tools into `~/.local/bin` | Neovim, starship, fd, lazygit, tree-sitter, btop: latest GitHub releases, each checked against GitHub's sha256 digest |
| Claude Code | Official installer, if `claude` isn't installed yet |
| Config links | `stow` links `zsh`, `starship`, `tmux`, `nvim` and `claude` into your home folder |
| Plugins | zinit (zsh, plus fzf and zoxide), tpm (tmux), LazyVim plugins and syntax parsers |
| Claude settings | Sets only `theme` and `statusLine` in `~/.claude/settings.json`; your permissions and MCP servers stay |
| Default shell | zsh |
| Windows side | JetBrainsMono Nerd Font and win32yank via winget; Windows Terminal gets the Catppuccin Mocha scheme, the font, your Linux home as start folder, and paste on `Ctrl+Shift+V`; VS Code's terminal gets the font |

It is safe to rerun. Finished steps are skipped. Any file it would replace is
moved to `~/.dotfiles-backup-<time>/` first, and every settings file it edits is
backed up next to itself as `*.bak-<time>`.

Options: `--skip-windows` leaves Windows alone, `--skip-nvim` skips the Neovim
plugin pre-install (plugins then install on first start).

## Not included

- **Your own `~/.bashrc` additions** stay where they are: zsh loads everything
  added below Ubuntu's stock `.bashrc` (aliases, PATH entries and so on).
- **Windows settings files with comments**: if your Windows Terminal or VS Code
  `settings.json` isn't plain JSON, the script skips it and says so. Set the
  font to `JetBrainsMono Nerd Font` and the colour scheme to `Catppuccin Mocha`
  (from `windows/catppuccin-mocha.json`) by hand.

## Day to day

- Edit files in `~/dotfiles`; the links mean changes apply straight away.
  Reload zsh with `exec zsh`, tmux with `Ctrl+Space` then `r`.
- `Ctrl+h/j/k/l` moves between Neovim splits and tmux panes.
- Commit and push from `~/dotfiles` to share changes.

## Layout

| Folder | Linked to |
|---|---|
| `zsh/` | `~/.zshrc`, `~/.zshenv` |
| `starship/` | `~/.config/starship.toml` |
| `tmux/` | `~/.config/tmux/` |
| `nvim/` | `~/.config/nvim/` |
| `claude/` | `~/.claude/themes/claude-orange.json` |
| `btop/` | `~/.config/btop/` (CPU + memory only; tmux prefix + `B` opens it) |
| `bin/` | On `PATH` (via `.zshrc`): `claude-statusline` and helper scripts |
| `scripts/`, `windows/` | Used by `install.sh` only |
