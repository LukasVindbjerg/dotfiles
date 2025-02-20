# dotfiles
My personal dotfiles

## Setup
## **Step 1: Clone the Repo**
Clone this repository into `~/.dotfiles`:
```sh
git clone <SSH link> ~/.dotfiles
```

## **Step 2: Install `stow`**
If `stow` is not installed, install it:

### **Ubuntu/Debian**
```sh
sudo apt update && sudo apt install stow -y
```

### **macOS (Homebrew)**
```sh
brew install stow
```

## **Step 3: Run `stow` to Symlink Dotfiles**
Navigate into the dotfiles folder:
```sh
cd ~/.dotfiles
```
Then, run `stow` for all the configurations you want:
```sh
stow zsh nvim tmux
```
This will create symlinks for:
- `~/.zshrc` → `~/.dotfiles/zsh/.zshrc`
- `~/.config/nvim/` → `~/.dotfiles/nvim/.config/nvim/`
- `~/.config/tmux/tmux.conf` → `~/.dotfiles/tmux/.config/tmux/tmux.conf`

## **Step 4: Reload Your Shell**
For changes to take effect, restart your terminal or run:
```sh
source ~/.zshrc
```

## **Adding More Dotfiles**
To add more dotfiles, simply place them inside `~/.dotfiles/` and run `stow` again:
```sh
stow <directory-name>
```

## **Removing Symlinks**
If you need to remove symlinks, use:
```sh
stow -D <directory-name>
```
For example:
```sh
stow -D zsh
```
This will remove the symlink but keep the original files in `~/.dotfiles/`.

## **Updating Your Dotfiles**
To update dotfiles on a different machine, pull the latest changes and re-run `stow`:
```sh
cd ~/.dotfiles
git pull
stow zsh nvim tmux
```

