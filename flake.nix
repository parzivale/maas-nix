{
  description = "NixOS 24.05 MAAS-compatible image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
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
  in {
    nixosConfigurations.maas-image = maasSystem;

    # nix build .#image → raw disk image
    packages.${system} = {
      image = maasSystem.config.system.build.image;

      # nix build .#maas-tgz → tar.gz ready for `maas boot-resources create`
      maas-tgz =
        pkgs.runCommand "nixos-maas.tar.gz" {
          nativeBuildInputs = [pkgs.gnutar pkgs.gzip];
        } ''
          img=${maasSystem.config.system.build.image}/nixos.img
          mkdir -p $out
          # MAAS expects the raw disk image inside a tar.gz
          tar -czf $out/nixos-maas.tar.gz -C ${maasSystem.config.system.build.image} nixos.img
        '';

      default = self.packages.${system}.maas-tgz;
    };

    # Dev shell with MAAS CLI for importing
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        maas
        qemu # for testing with qemu-system
      ];
      shellHook = ''
        echo "NixOS MAAS image builder"
        echo ""
        echo "  nix build            — build MAAS tar.gz"
        echo "  nix build .#image    — build raw disk image"
        echo ""
        echo "  Import:"
        echo "    maas \$PROFILE boot-resources create \\"
        echo "      name='custom/nixos-24.05' \\"
        echo "      architecture='amd64/generic' \\"
        echo "      filetype='tgz' \\"
        echo "      content@=result/nixos-maas.tar.gz"
      '';
    };
  };
}
