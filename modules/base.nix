{ config, lib, pkgs, ... }:

{
  # --------------------------------------------------------------------------
  # SSH
  # --------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # --------------------------------------------------------------------------
  # Packages
  # --------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    cloud-init
    curtin
    python3
    curl
    vim
    git
    htop
    dmidecode    # MAAS hardware inventory
    ipmitool     # BMC management
    lshw         # hardware enumeration
  ];

  # --------------------------------------------------------------------------
  # Users — MAAS injects SSH keys via cloud-init
  # --------------------------------------------------------------------------
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };

  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = false;

  # --------------------------------------------------------------------------
  # System
  # --------------------------------------------------------------------------
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "UTC";
}
