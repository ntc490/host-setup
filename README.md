# Nathan's host-setup

Bash scripts and dotfiles for reproducing my Arch Linux setup on a fresh
machine. (This used to be an Ansible project; it was converted to plain bash
since it only ever ran on localhost and only targets Arch now.)

## Usage

```sh
./setup.sh            # install and configure everything
./setup.sh zsh emacs  # run only the named install scripts
```

`setup.sh` runs every script in `install/` in order. pacman will prompt for
your sudo password the first time it installs something.

Everything is safe to re-run:

- packages use `pacman -S --needed` (skips what's already installed),
- git clones use `git pull --rebase`,
- dotfiles are symlinked with `stow --restow` (and any pre-existing real file
  is backed up to `<file>.bak.<timestamp>` before linking),
- the shell change and docker group add are guarded so they only run when
  needed.

## Layout

```
setup.sh        top-level orchestrator
lib/common.sh   shared helpers (logging, pacman, clone-or-update, stow, vendor)
install/*.sh    one script per tool; each installs its package(s) and stows
                its own dotfiles
dotfiles/<pkg>/ GNU stow packages, laid out relative to $HOME
vendor/         bundled binaries / scripts that aren't config (wconf.py)
```

## What gets installed

- **zsh** — zsh, fastfetch, oh-my-zsh + autosuggestions/syntax-highlighting,
  `.zshrc`, and sets zsh as the login shell
- **emacs** — graphical Emacs (`emacs-wayland`, the pgtk build) + my
  [emacs.d](https://github.com/ntc490/emacs.d) config, built with `make`
- **ag** — the_silver_searcher
- **fd** — fd
- **screen / tmux / tig** — package + dotfile
- **eza / bat / fzf / htop / btop** — everyday shell tools (package only)
- **wezterm** — package + `.wezterm.lua` + the `wconf.py` opacity helper
- **clang-tools** — clang (clang-format, clang-tidy)
- **dev-tools** — base-devel, net-tools, doxygen, graphviz, cmake, clang
- **tldr** — simplified community man pages

## Notes

- Targets Arch only (`pacman`). The scripts abort on non-Arch systems.
- `rtags` and `alacritty` from the old Ansible roles were intentionally dropped
  (rtags is AUR-only; I've moved from alacritty to wezterm). They remain in git
  history if needed.
