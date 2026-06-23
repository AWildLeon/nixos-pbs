final: prev: {
  # Base build (FHS paths unmet at runtime; used as input to the -fhs package).
  proxmox-backup-server = final.callPackage ./pkgs/proxmox-backup-server/package.nix { };

  # Runnable PBS: the base package wrapped in an FHS environment.
  proxmox-backup-server-fhs = final.callPackage ./pkgs/proxmox-backup-server-fhs/package.nix { };
}
