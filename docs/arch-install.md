# Arch install — LUKS + btrfs + limine

The from-scratch install that gets a machine to first boot, where `setup.sh`
takes over. Philosophy (see the repo's two-context split):

- **Destructive steps are manual.** Partitioning, LUKS format, and `mkfs` are
  written out here for you to run and *review* — a scripted disk-wipe with the
  wrong `DISK` is the one mistake worth never automating.
- **Fiddly, error-prone steps are scripted** as `bootstrap/` helpers (the btrfs
  subvolume layout, and — soon — mkinitcpio hooks + limine config). These are
  where hand-typing bites you.
- **Everything past first boot lives in `setup.sh`**, not here.

Resulting layout: an encrypted btrfs root with top-level subvolumes
(`@`, `@home`, `@root`, `@srv`, `@cache`, `@tmp`, `@log`, `@snapshots`) so
snapshots of `@` stay clean — see `bootstrap/btrfs-layout.sh` for the rationale.

---

## 0. Config

Decide your `DISK`, `HOSTNAME`, `USERNAME` up front; you'll put them in
`install.conf` at step 2.

## 1. Boot the ISO and get online

```sh
loadkeys us                      # keyboard, if needed
iwctl                            # wifi: `station wlan0 connect <SSID>`, then `exit`
timedatectl set-ntp true
ls /sys/firmware/efi/efivars >/dev/null && echo "UEFI OK"   # must be UEFI
```

## 2. Clone this repo and write your config

```sh
pacman -Sy --noconfirm git
git clone https://github.com/ntc490/host-setup
cd host-setup/bootstrap
cp install.conf.example install.conf
vim install.conf                 # set DISK, HOSTNAME, USERNAME, ...
```

## 3. Partition the disk — DESTRUCTIVE, review every line

GPT with a 1 GiB EFI System Partition and the rest as the LUKS container.
Replace `/dev/nvme0n1` with your `DISK` (use `p1`/`p2` suffixes for nvme/mmc,
`1`/`2` for sd*).

```sh
sgdisk --zap-all /dev/nvme0n1                                   # wipe
sgdisk -n1:0:+1GiB -t1:ef00 -c1:EFI       /dev/nvme0n1          # ESP
sgdisk -n2:0:0     -t2:8309 -c2:cryptroot /dev/nvme0n1          # LUKS
partprobe /dev/nvme0n1
```

## 4. LUKS

```sh
cryptsetup luksFormat /dev/nvme0n1p2          # type YES, set passphrase
cryptsetup open      /dev/nvme0n1p2 cryptroot # -> /dev/mapper/cryptroot
```

## 5. Filesystems

```sh
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs    /dev/mapper/cryptroot
```

## 6. Subvolume layout + mount  ← helper

Creates the subvolumes and mounts the whole tree under `$TARGET` with the right
options. Idempotent; safe to re-run.

```sh
./btrfs-layout.sh                 # reads install.conf
```

Sanity-check the printed `findmnt` tree before continuing.

## 7. pacstrap the base system

```sh
pacstrap -K /mnt \
    base linux linux-lts linux-firmware intel-ucode \
    btrfs-progs cryptsetup \
    limine efibootmgr dosfstools \
    networkmanager wpa_supplicant \
    zsh sudo git vim \
    man-db man-pages
    # optional: linux-headers linux-lts-headers  (DKMS / out-of-tree modules)
    #           sof-firmware                      (ThinkPad X1 audio on first boot)
    #           reflector                         (rank mirrors)
```

Why these:
- `linux-lts` is the fallback kernel; `intel-ucode` is the CPU microcode.
- `cryptsetup` + the `encrypt` initramfs hook (step 9) unlock LUKS at boot;
  `btrfs-progs` is needed in the initramfs to mount the btrfs root.
- `limine` + `efibootmgr` install the bootloader and its UEFI entry;
  `dosfstools` gives `fsck.fat` for the ESP.
- `networkmanager` needs `wpa_supplicant` for wifi — it's only an optional dep,
  so without it NM sees no wireless.
- `zsh` MUST be here: step 9 sets the user's login shell to `/bin/zsh`, so it has
  to exist before first login (the rest of the zsh setup happens in `setup.sh`).
- `mkinitcpio` is pulled in automatically by the `linux` package.

## 8. fstab

```sh
genfstab -U /mnt >> /mnt/etc/fstab
vim /mnt/etc/fstab                # verify every subvol= line is correct
```

This is the payoff of step 6: the subvolume mounts (including `/.snapshots`)
are baked into fstab from the start — no post-install migration.

### 9a. Interactive config (inside the chroot)

The system-identity bits that want a human (timezone, passwords, your user):

```sh
arch-chroot /mnt
```

```sh
# timezone + clock
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime && hwclock --systohc

# locale (install/locale.sh redoes this post-boot; minimally):
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/; s/^#\(ja_JP.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo carbon > /etc/hostname         # your HOSTNAME from install.conf

passwd                              # root password
useradd -m -G wheel -s /bin/zsh ncrapo && passwd ncrapo   # your USERNAME
EDITOR=vim visudo                   # uncomment: %wheel ALL=(ALL:ALL) ALL

systemctl enable NetworkManager
exit                                # back out to the ISO
```

(`zsh` is in the pacstrap list specifically so this `-s /bin/zsh` user can log
in before `setup.sh` runs.)

### 9b. initramfs + bootloader (helpers, from the ISO)

Run these from the ISO (not inside the chroot) — they edit the target and
`arch-chroot` internally as needed:

```sh
cd ~/host-setup/bootstrap            # where you cloned + wrote install.conf
./mkinitcpio-hooks.sh                # sets HOOKS (encrypt+btrfs) and runs mkinitcpio -P
./limine-setup.sh                    # installs limine to the ESP + writes limine.conf
```

`limine-setup.sh` derives the LUKS partition UUID itself and writes both the
`linux` and `linux-lts` boot entries; re-run it later whenever you add or remove
a kernel. It leaves the limine config unthemed — style it afterward if you like.

## 10. Reboot into the new system

```sh
umount -R /mnt
cryptsetup close cryptroot
reboot                              # remove the ISO
```

First login, then hand off to the post-boot setup:

```sh
git clone https://github.com/ntc490/host-setup ~/git/host-setup
cd ~/git/host-setup
./setup.sh                          # packages, dotfiles, services, snapper, ...
```

`install/snapper.sh` will find the `@snapshots` subvolume already in place from
step 6 and just adopt it.
