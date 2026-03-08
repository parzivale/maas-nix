{
  description = "NixOS 24.05 MAAS-compatible image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # The NixOS system configuration for the MAAS image
      maasSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/base.nix
          ./modules/cloud-init.nix
          ./modules/image.nix
        ];
      };
    in
    {
      nixosConfigurations.maas-image = maasSystem;

      packages.${system} = {
        # nix build .#rootfs → rootfs tarball (tar.xz)
        rootfs = maasSystem.config.system.build.rootfs-tarball;

        default = self.packages.${system}.rootfs;
      };

      # Dev shell with MAAS CLI for importing
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          qemu
        ];
        shellHook = ''
          echo "NixOS MAAS image builder"
          echo ""
          echo "  nix build          — build rootfs tarball"
          echo ""
          echo "  Import:"
          echo "    maas \$PROFILE boot-resources create \\"
          echo "      name='custom/nixos-24.05' \\"
          echo "      architecture='amd64/generic' \\"
          echo "      filetype='root-tgz' \\"
          echo "      content@=\$(nix build --print-out-paths)"
        '';
      };
    };
}
