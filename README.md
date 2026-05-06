# dotfiles

Bootstrapped from the live home directory on 2026-05-07.

Packages:
- `shell`: `.zshrc`, `.p10k.zsh`
- `git`: `.gitconfig`
- `x11`: `.xinitrc`, `.xprofile`, `.Xresources`
- `nvim`: `.config/nvim`
- `i3`: `.config/i3/config`, `monitor-layout.sh`, `swap-panes.sh`
- `terminals`: `alacritty`, `kitty`, `ghostty`, `tmux.conf`
- `desktop`: `rofi`, `picom`, `kanata`
- `yazi`: `keymap.toml`, `yazi.toml`
- `bat`: `Rose-Pine.tmTheme`

Left out on purpose:
- app state and large profiles such as browser data and `Code - OSS`
- secret-bearing config such as `~/.config/gh/hosts.yml`
- caches and generated files such as `__pycache__`, `.ruff_cache`, `node_modules`
- local build or package trees such as `~/.config/i3/yay`, `~/.config/i3/dmenu`, `~/.config/tmux/plugins`

Old broken symlinks were moved to:
- `/home/muggle/.dotfiles-migration-backup-20260507-053810`

Broken links that were not recreated automatically:
- `~/.zshrc.pre-oh-my-zsh`
- `~/.config/bat/config`
- `~/.config/lazygit/config.yml`

Quick start on a new machine:

```bash
git clone https://github.com/NguyenQuangAnh1112/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` will:
- install GNU Stow when a supported package manager is available
- run a dry-run first to catch conflicts safely
- restow all managed packages into `$HOME`

Useful flags:
- `./bootstrap.sh --yes`: skip the install confirmation prompt
- `./bootstrap.sh --skip-install`: fail instead of trying to install GNU Stow

If you prefer to run Stow manually:

```bash
cd ~/dotfiles
stow -nv -t "$HOME" shell git x11 nvim i3 terminals desktop yazi bat
stow -Rv -t "$HOME" shell git x11 nvim i3 terminals desktop yazi bat
```
