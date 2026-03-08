{ config, lib, pkgs, ... }:

{
  # --------------------------------------------------------------------------
  # Cloud-init — MAAS datasource
  # --------------------------------------------------------------------------
  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = {
      datasource_list = [ "MAAS" ];
      datasource = {
        MAAS = {
          metadata_url = "http://maas.internal/MAAS/metadata/";
          consumer_key = "";
          token_key = "";
          token_secret = "";
        };
      };

      cloud_init_modules = [
        "migrator"
        "seed_random"
        "bootcmd"
        "write-files"
        "growpart"
        "resizefs"
        "disk_setup"
        "mounts"
        "set_hostname"
        "update_hostname"
        "update_etc_hosts"
        "rsyslog"
        "users-groups"
        "ssh"
      ];

      cloud_config_modules = [
        "ssh-import-id"
        "keyboard"
        "locale"
        "set-passwords"
        "ntp"
        "timezone"
        "disable-ec2-metadata"
        "runcmd"
      ];

      cloud_final_modules = [
        "package-update-upgrade-install"
        "scripts-vendor"
        "scripts-per-once"
        "scripts-per-boot"
        "scripts-per-instance"
        "scripts-user"
        "ssh-authkey-fingerprints"
        "keys-to-console"
        "final-message"
      ];

      system_info = {
        distro = "nixos";
        default_user = {
          name = "nixos";
          lock_passwd = true;
          sudo = [ "ALL=(ALL) NOPASSWD:ALL" ];
          shell = "/run/current-system/sw/bin/bash";
        };
      };

      network.renderers = [ "networkd" ];
      manage_etc_hosts = true;
      preserve_hostname = false;
    };
  };

  # MAAS reporting webhook
  environment.etc."cloud/cloud.cfg.d/99-maas.cfg".text = ''
    datasource_list: [ MAAS ]
    reporting:
      maas:
        type: webhook
        endpoint: http://maas.internal/MAAS/metadata/status/{instance_id}
        consumer_key: ''
        token_key: ''
        token_secret: ''
  '';

  # Curtin hooks stub — MAAS uses curtin for disk layout
  environment.etc."curtin/curtin-hooks".source = pkgs.writeShellScript "curtin-hooks" ''
    #!/usr/bin/env bash
    echo "NixOS curtin hooks running..."
    exit 0
  '';

  # --------------------------------------------------------------------------
  # Networking — cloud-init owns this via systemd-networkd
  # --------------------------------------------------------------------------
  networking = {
    hostName = "nixos-maas";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };

  systemd.network.enable = true;
}
