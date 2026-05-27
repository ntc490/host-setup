# Nathan's host-setup

Bash scripts and dotfiles for reproducing my setup on a fresh machine.
(This used to be an Ansible project; it was converted to plain bash since it
only ever ran on localhost.)

Supports **Arch** (pacman), **Debian/Ubuntu** (apt), and **Rocky/RHEL/Fedora**
(dnf). The distro is detected from `/etc/os-release`; package names that differ
across distros are mapped automatically, and tools not available in a distro's
repos are skipped with a warning.

## Usage

```sh
./setup.sh            # install and configure everything
./setup.sh zsh emacs  # run only the named install scripts
```

`setup.sh` runs every script in `install/` in order. You'll be prompted for
sudo the first time it installs a package (no prompt if already root).

Everything is safe to re-run:

- packages use the package manager's idempotent install (`pacman -S --needed`,
  `apt-get install`, `dnf install` — all skip what's present),
- git clones use `git pull --rebase`,
- dotfiles are symlinked with `stow --restow` (and any pre-existing real file
  is backed up to `<file>.bak.<timestamp>` before linking),
- the login-shell change is guarded so it only runs when needed.

## Layout

```
setup.sh                  top-level orchestrator
lib/common.sh             shared helpers (distro detection, package install +
                          name mapping, clone-or-update, stow, vendor)
install/*.sh              one script per tool; each installs its package(s)
                          and stows its own dotfiles
dotfiles/<pkg>/           GNU stow packages, laid out relative to $HOME
vendor/                   bundled binaries / scripts that aren't config (wconf.py)
test/run-in-container.sh  run setup.sh in throwaway podman containers per distro
```

## What gets installed

- **zsh** — zsh, fastfetch, oh-my-zsh + autosuggestions/syntax-highlighting,
  `.zshrc`, and sets zsh as the login shell
- **emacs** — graphical Emacs (`emacs-wayland` pgtk build on Arch, `emacs`
  elsewhere) + my [emacs.d](https://github.com/ntc490/emacs.d) config, with its
  tree-sitter grammars compiled into `~/.emacs.d/tree-sitter`
- **ag** — the_silver_searcher
- **fd** — fd
- **screen / tmux / tig** — package + dotfile
- **eza / bat / fzf / htop / btop** — everyday shell tools (package only)
- **wezterm** — package + `.wezterm.lua` + the `wconf.py` opacity helper
- **base-devel / net-tools / doxygen / graphviz / cmake** — development packages
- **clang-tools** — clang (clang-format, clang-tidy)
- **dev-tools** — a *group* (not a package) that runs base-devel, net-tools,
  doxygen, graphviz, cmake, and clang-tools. Call it with `./setup.sh dev-tools`.
- **tldr** — simplified community man pages

## Testing

`test/run-in-container.sh` runs `setup.sh` inside throwaway podman containers so
you can verify changes across distros without touching the host. Each run
executes `setup.sh` twice to confirm idempotency.

```sh
test/run-in-container.sh debian            # CLI-safe subset (default)
test/run-in-container.sh rocky tmux tig    # only the named scripts
test/run-in-container.sh all               # subset on arch, debian, and rocky
test/run-in-container.sh debian full       # everything setup.sh knows about
```

The default subset skips the heavy `emacs` build and the GUI `wezterm`; pass
them explicitly (or `full`) to exercise those too.

## Notes

- Per-distro availability: some tools aren't in every distro's repos and are
  skipped with a warning — e.g. `eza`, `wezterm`, and `fastfetch` on Rocky;
  `eza`/`fastfetch` on Debian 12; `wezterm` on Debian. On Rocky, EPEL + CRB are
  enabled automatically to widen what's available.
- `rtags` and `alacritty` from the old Ansible roles were intentionally dropped
  (rtags is AUR-only; I've moved from alacritty to wezterm). They remain in git
  history if needed.
