# NixOS 24.05 → MAAS Image (Flake)

Builds a NixOS 24.05 raw disk image with cloud-init (MAAS datasource) and
packages it as a `.tar.gz` for MAAS import. No Packer needed — just
`nix build`.

## What's in the image

- NixOS 24.05, flake-based
- cloud-init: MAAS datasource, networkd renderer, reporting webhook
- Full MAAS module coverage: network, disk layout (curtin), user/SSH key
  injection, hostname/metadata
- OpenSSH (key-only)
- Serial console (ttyS0 @ 115200)
- MAAS tooling: dmidecode, lshw, ipmitool, curtin
- QEMU guest agent, auto-growing root partition

## Build

```bash
# Build the MAAS tar.gz (default output)
nix build

# Import into MAAS
maas $PROFILE boot-resources create \
  name='custom/nixos-24.05' \
  architecture='amd64/generic' \
  filetype='tgz' \
  content@=result/nixos-maas.tar.gz

# Or just build the raw disk image
nix build .#image
```

## Test locally with QEMU

```bash
nix build .#image
cp result/nixos.img /tmp/nixos-test.img
chmod +w /tmp/nixos-test.img
qemu-system-x86_64 \
  -m 2048 \
  -drive file=/tmp/nixos-test.img,format=raw \
  -nographic
```

## Project structure

```
.
├── flake.nix
├── modules/
│   ├── base.nix          # SSH, packages, users
│   ├── cloud-init.nix    # MAAS datasource, curtin, networkd
│   └── image.nix         # make-disk-image, boot, filesystems
```

## Customization

- **Packages**: `modules/base.nix` → `environment.systemPackages`
- **MAAS metadata URL**: `modules/cloud-init.nix` → `datasource.MAAS.metadata_url`
- **Disk size**: `modules/image.nix` → `additionalSpace`
- **Add flake inputs**: wire through `flake.nix` as usual
