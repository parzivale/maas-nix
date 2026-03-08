{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/channel.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # --------------------------------------------------------------------------
  # Image build config
  # --------------------------------------------------------------------------
  system.build.image = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    diskSize = "auto";
    additionalSpace = "1G";
    format = "raw";
    partitionTableType = "msdos";
  };

  # --------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------
  boot.loader.grub = {
    enable = true;
    device = "nodev";  # make-disk-image handles this
  };

  boot.growPartition = true;

  # Serial console for IPMI/BMC SOL
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  # --------------------------------------------------------------------------
  # Filesystems
  # --------------------------------------------------------------------------
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_net"
    "ahci" "sd_mod" "sr_mod"
  ];
}
