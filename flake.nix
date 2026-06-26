{
  description = "Experimental native Nix package/module for Proxmox Backup Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  # Used only by default.nix / shell.nix to expose these outputs to
  # consumers without flakes enabled. Pinned here so it lands in flake.lock.
  inputs.flake-compat = {
    url = "github:NixOS/flake-compat";
    flake = false;
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Revision of this packaging repo, surfaced on the PBS dashboard.
      # Clean tree -> self.rev; dirty tree -> self.dirtyRev; neither -> null.
      revision = self.rev or self.dirtyRev or null;
    in
    {
      # Base overlay (overlay.nix) with this repo's revision injected, so the
      # dashboard shows the nixos-pbs commit a consumer pinned.
      overlays.default = nixpkgs.lib.composeExtensions (import ./overlay.nix) (
        final: prev: {
          proxmox-backup-server = prev.proxmox-backup-server.override { inherit revision; };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          default = pkgs.proxmox-backup-server-fhs;
          proxmox-backup-server = pkgs.proxmox-backup-server;
          proxmox-backup-server-fhs = pkgs.proxmox-backup-server-fhs;
        }
      );

      # End-to-end NixOS VM test. Run: nix build .#checks.<system>.integration
      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          integration = import ./tests/integration.nix { inherit self pkgs; };
        }
      );

      nixosModules.proxmox-backup-server = ./modules/proxmox-backup-server.nix;
      nixosModules.default = self.nixosModules.proxmox-backup-server;

      nixosConfigurations.pbs-test-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.proxmox-backup-server
          ({ lib, pkgs, ... }: {
            nixpkgs.overlays = [ self.overlays.default ];

            system.stateVersion = "26.05";

            networking.hostName = "pbs-test";
            networking.firewall.enable = true;

            services.proxmox-backup-server = {
              enable = true;
              openFirewall = true;

              # Declarative config demo: reconciled by proxmox-backup-setup.service
              # on boot. Lives on the root fs so the VM boots without formatting
              # the secondary /dev/vdb disk first.
              ensureDatastores.main = {
                path = "/var/lib/proxmox-backup/datastores/main";
                comment = "Test store";
                gcSchedule = "daily";
              };
              ensurePruneJobs.main-prune = {
                datastore = "main";
                schedule = "daily";
                settings = {
                  keep-daily = 7;
                  keep-weekly = 4;
                };
              };
            };

            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "yes";
            };

            users.users.root.password = "nixos";

            virtualisation.vmVariant = {
              virtualisation = {
                memorySize = 4096;
                cores = 4;
                diskSize = 16384;
                # Extra blank 20 GiB disk (appears as /dev/vdb) for use as a
                # PBS datastore. Format and mount it, then point a datastore there.
                emptyDiskImages = [ 20480 ];
                forwardPorts = [
                  {
                    from = "host";
                    host.port = 8007;
                    guest.port = 8007;
                  }
                  {
                    from = "host";
                    host.port = 2222;
                    guest.port = 22;
                  }
                ];
              };
            };
          })
        ];
      };
    };
}
