* grub install in chroot env
 - Install os-prober, then run grub configuration again
* Extra Packages
     sudo pacman -S wezterm ansible exa fd-find ag firefox p7zip rsync tar gzip emacs-nox htop less bat git alsa-utils
 - fonts for exa icons and stuff
     sudo pacman -S ttf-jetbrains-mono-nerd
 - Bluetooth - was able to pair ear buds in KDE Desktop
     sudo pacman -S bluez blueman bluez-utils
     sudo systemctl enable bluetooth
     sudo systemctl start bluetooth
* Misc
 - yay
     git clone https://aur.archlinux.org/yay
	 cd yay
	 makepkg -si
 - vscode
     yay -S visual-studio-code-bin
 - microcode updates
     sudo pacman -S intel-ucode
	 sudo grub-mkconfig -o /boot/grub/grub.cfg
 - LTS kernel as a backup
     sudo pacman -S lts-kernel lts-kernel-headers
 - firewall?
     sudo pacman -S ufw
 - preload for faster app startups
     yay -S preload
	 sudo systemctl enable preload
	 sudo systemctl start preload
 - auto-cpufreq
     git clone 
 - Japanese sddm config. Add /etc/default/locale with the following lines:
     LANG="ja_JP.UTF-8"
     LC_ALL="ja_JP.UTF-8"
 - Japanese shell setup fonts
   - Uncomment ja_JP.utf8 from /etc/locale.gen and run locale-gen
   - Install fonts
       sudo pacman -S noto-fonts-cjk
 - openssh SSH agent setup
* Clipboard
 - Installed gpaste?
* Sound
 - Did default install w/o sof-firmware with default audio options. There was no device at first. Installed sof firmware and everything came up. At one point was using sof drivers from git repo. Didn't work last time I tried. pacman package works great.
     sudo pacman -S sof-firmware
* Wallpaper
 - clone personal Wallpaper from github repo
     github clone git@github.com:ntc490/wallpaper ~/Wallpaper
* Google-Chrome
 - installed via manual git clone and `makepkg -is`
 - fonts suck (when hyprland config isn't right)
* Installed ansible and ran host-setup main.yml
 - ensured I have latest/greatest emacs setup
* Dark Theme Support for Chrome
 - Go into browser settings and choose dark theme
 - Youtube will follow suit with the "device theme" from the Browser setting
 - Works for Firefox and Chrome
* Browser Setup
 - [X] Bitwarden
 - [X] Ad-blocker
 - [ ] vim keys
 - [ ] emacs keybindings? Firemacs? Dead?
* Terminal
 - Wezterm doesn't seem to be well supported in hyprland? Need to set
   'config.wayland_enable = false'
 - Needed to install nerd font
* Japanese setup
 - Could change /etc/locale.conf
 - `LANG=ja_JP.utf8 date` will show in Japanese, for example
 - Change the language of Firefox browser in its config page
