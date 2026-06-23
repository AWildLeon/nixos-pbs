# Non-flake dev shell, via NixOS/flake-compat (pinned in flake.lock).
(import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    node = lock.nodes.flake-compat.locked;
  in
  fetchTarball {
    url = "https://github.com/NixOS/flake-compat/archive/${node.rev}.tar.gz";
    sha256 = node.narHash;
  }
) { src = ./.; }).shellNix
