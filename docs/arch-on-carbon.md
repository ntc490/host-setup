* TODO
  - Google Drive
  - Word Processor
 - fonts for exa icons and stuff
     sudo pacman -S ttf-jetbrains-mono-nerd
* Misc
 - install reflector and speedup pacman
     sudo pacman -S reflector
	 sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	 sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
 - yay
     git clone https://aur.archlinux.org/yay
	 cd yay
	 makepkg -si
 - install obsidian from AUR
 - install chromium
   - install bitwarden plugin
   - install adblock plugin
   - install video speed controller plugin
 - microcode updates
     sudo pacman -S intel-ucode
	 sudo grub-mkconfig -o /boot/grub/grub.cfg
 - firewall?
     sudo pacman -S ufw
 - preload for faster app startups
     yay -S preload
	 sudo systemctl enable preload
	 sudo systemctl start preload
 - auto-cpufreq
     git clone 
 - Install fonts
     sudo pacman -S noto-fonts-cjk
* Japanese setup
 - Could change /etc/locale.conf
 - `LANG=ja_JP.utf8 date` will show in Japanese, for example
 - Change the language of Firefox browser in its config page
