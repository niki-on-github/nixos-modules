# Knowledge Base

## Boot Installed System on other Comupter

1. Liveboot any Linux
2. Idenify Disk with boot partition
3. `sudo efibootmgr -c -d /dev/nvme0nXp1 -l "\EFI\NixOS-boot-efi\grubx64.efi"`
