# Non-flake entry point.
#
# Exposes the flake's outputs to systems without flakes enabled, via
# NixOS/flake-compat (pinned in flake.lock). For example:
#
#   nix-build                       # build the default package -> ./result
#   nix-build -A packages.x86_64-linux.proxmox-backup-server
#
#   # from another Nix expression (e.g. configuration.nix)
#   let
#     pbs = import (fetchTarball "https://github.com/AWildLeon/nixos-pbs/archive/main.tar.gz");
#   in {
#     nixpkgs.overlays = [ pbs.overlays.default ];
#     imports = [ pbs.nixosModules.proxmox-backup-server ];
#   }
(import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    node = lock.nodes.flake-compat.locked;
  in
  fetchTarball {
    url = "https://github.com/NixOS/flake-compat/archive/${node.rev}.tar.gz";
    sha256 = node.narHash;
  }
) { src = ./.; }).defaultNix
