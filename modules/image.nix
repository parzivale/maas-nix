{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # --------------------------------------------------------------------------
  # Rootfs tarball — MAAS/curtin handles disk layout + bootloader
  # --------------------------------------------------------------------------
  system.build.rootfs-tarball = pkgs.callPackage (
    { runCommand, closureInfo, pixz }:
    runCommand "nixos-maas-rootfs.tar.xz" {
      nativeBuildInputs = [ pixz ];
      closureInfo = closureInfo {
        rootPaths = [ config.system.build.toplevel ];
      };
    } ''
      # Create the rootfs structure
      mkdir -p rootfs/{nix/store,etc,bin,sbin,root}

      # Copy the entire closure into the rootfs
      while IFS= read -r path; do
        cp -a "$path" rootfs/nix/store/
      done < $closureInfo/store-paths

      # Symlink the system profile
      mkdir -p rootfs/nix/var/nix/profiles
      ln -s ${config.system.build.toplevel} rootfs/nix/var/nix/profiles/system

      # Set up init so the system can boot
      ln -s ${config.system.build.toplevel}/init rootfs/sbin/init

      # Registration info for nix-daemon
      mkdir -p rootfs/nix/var/nix/db
      cp $closureInfo/registration rootfs/nix/var/nix/db/registration

      # Tar it up
      tar -C rootfs -c . | pixz -9 > $out
    ''
  ) {};

  # --------------------------------------------------------------------------
  # Boot — curtin installs the bootloader, we just configure it
  # --------------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Serial console for IPMI/BMC SOL
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  # --------------------------------------------------------------------------
  # Filesystems — dummy entries to satisfy module eval
  # MAAS/curtin defines the actual layout at deploy time
  # --------------------------------------------------------------------------
  fileSystems."/" = {
    device = "none";
    fsType = "ext4";
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_net"
    "ahci" "sd_mod" "sr_mod" "nvme"
  ];
}
