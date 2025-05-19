* Clipboard
 - Installed gpaste?
* Sound
 - installed pulseaudio, pulseaudio-alsa, alsa-utils, pavucontrol
 - Looked at journalctl output and found link to
 - Download and install driver, then reboot:
   wget https://github.com/thesofproject/sof-bin/releases/download/v2024.09/sof-bin-2024.09.tar.gz
   tar xzvf sof-bin-2024.09.tar.gz
   cd sof-bin-2024.09
   sudo ./install
   sudo reboot
 - Make buttons available
* Special Keyboard Buttons
 - [X] Brightness control
   - had to install brightnessctl   
 - [X] key bindings for sound control
   - use 'amixer set Master toggle', 'amixer -c 0 set Master 3dB+', 'amixer -c 0 set Master 3dB-' instead of pmd
* Suspend/hybernate/restore
  - be patient - press mouse buttons and wait for things to come back?
* Wallpaper
 - cloned personal github repo
 - setup hyprpaper
 - [ ] need to be able to have the wallpaper change periodically
 - [ ] get new wallpapers from Mac machines
 - [X] installed waypaper. Not sure if we needed this. Used yay.
 - [X] installed swww to see what it's like
* Dark Mode for Apps
 - env variable?
* Waybar
 - [ ] Fix icon for charging battery display
 - [ ] Change 'Apps' to search icon
 - [ ] Add desktop indicator on left
 - grabbed sample config off internet
 - needs more work - want minimalistic look and feel
* Google-Chrome
 - installed via manual git clone and `makepkg -is`
 - fonts suck (when hyprland config isn't right)
* Installed ansible and ran host-setup main.yml
 - also installed some other fonts. Not sure if that helped:
   - gnu-free-fonts
 - ensured I have latest/greatest emacs setup
* Hyprland
 - changed hyprland config:
   - Got rid of warning
   - Enabled a few exec-once lines
   - Modified `misc` section to get rid of stock wallpaper and
     hyprland logo
   - Enabled natural_scroll
   - Changed 'auto' to '1' in monitor config line. Fixed font issues
     in Chrome, Wezterm, etc
   - Enable workspace gesture change
   - make menu bar shorter?
 - Add Jetbrains Nerd Font Mono via pacman     
 - install hyprpaper
   - add lines to load one of the wallpapers from my repo
   - change the default line's display to "" and point at pic
   - need to figure out how to make it work better
 - changed opacity in hyperland.conf. How to exclude some windows from
   opacity change?
** Beautiful stuff: https://github.com/mylinuxforwork/dotfiles
 - [ ] sddm conifg
 - [X] rofi setup
 - [X] waybar setup
* Dark Theme Support for Chrome
 - Go into browser settings and choose dark theme
 - Youtube will follow suit with the "device theme" from the Browser setting
 - Works for Firefox and Chrome
* Browser Plugins
 - [X] Bitwarden
 - [X] Ad-blocker
 - [ ] vim keys
 - [ ] emacs keybindings? Firemacs? Dead?
* Terminal
 - Wezterm doesn't seem to be well supported in hyprland? Need to set
   'config.wayland_enable = false'
 - XXX Don't use kitty instead as it doesn't do text background
   transparency
* Japanese setup
 - Install japanese fonts
 - Uncomment ja_JP.utf8 from /etc/locale.gen and run locale-gen
 - Could change /etc/locale.conf
 - `LANG=ja_JP.utf8 date` will show in Japanese, for example
 - Change the language of Firefox browser in its config page
* Kitty config
 - fonts - installed ttf-firacode-nerd for kitty config I scraped off net
 - 'ctrl-shift-a' and then '1' to make completely opaque
   'ctrl-shift-a' and then 'd' to go back to default opacity
 - ctrl key can't be continually pressed
 - image display in shell: `kitten icat image.jpg`
 - used in emacs?
 
   
