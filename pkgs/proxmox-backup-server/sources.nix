# Pinned upstream sources for the Proxmox Backup Server build.
#
# Split out of package.nix to keep the derivation readable. `repos` are the
# git checkouts fed to cargo; `webAssets` are the prebuilt UI .debs unpacked
# in postInstall.
{ fetchgit, fetchurl }:

{
  repos = {
    proxmox-backup = fetchgit {
      url = "git://git.proxmox.com/git/proxmox-backup.git";
      rev = "be67219cb9a5c6fbbae6b82cc40ae455a0ef5a0c";
      name = "proxmox-backup";
      hash = "sha256-ovxyZifqxDjIUHn7nL0l3kN/Ayf0a9wmTtln63QBljo=";
    };

    proxmox = fetchgit {
      url = "git://git.proxmox.com/git/proxmox.git";
      rev = "0746104b1fa5af3e4fa08725563c4b4d69b67c9d";
      name = "proxmox";
      hash = "sha256-Kl2hyOfnblT5MaIJ2jV9pMj56x0CkpDRfznYXe6D+Wc=";
    };

    proxmox-fuse = fetchgit {
      url = "git://git.proxmox.com/git/proxmox-fuse.git";
      rev = "ac99ac97f7c2eb7ab9ee6ec3b41034e68b1eca7d";
      name = "proxmox-fuse";
      hash = "sha256-pW2xDWCEH9eMWNjbUZ299ooYlFM9Izs963HCxqKkjeo=";
    };

    proxmox-pxar = fetchgit {
      url = "git://git.proxmox.com/git/pxar.git";
      rev = "091a8a382d0d6fc71025351fb35c51b1f3b0074d";
      name = "pxar";
      hash = "sha256-9SFlrz6nuVby6iQ2ELVaioZu2pcs90tSuyzLCWJlcrA=";
    };

    proxmox-pathpatterns = fetchgit {
      url = "git://git.proxmox.com/git/pathpatterns.git";
      rev = "5323cbe49ae5d592eb8a3fa2e215550e83dd7fba";
      name = "pathpatterns";
      hash = "sha256-cEVTDIDKL4K5RtbYR4OQ19LmtSKM7o8IN1jJKGa+9T4=";
    };
  };

  webAssets = [
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/libjs-extjs_7.0.0-5_all.deb";
      hash = "sha256-RhCa4YCVeaChny/eswvsF06/yRj++pfvy6rOSoZ3RLU=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/proxmox-widget-toolkit_5.2.5_all.deb";
      hash = "sha256-Zayi3LC1IRjTc8PrqMlBHrb64ZumrCYBruCLy/D4Cg0=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/pve-xtermjs_6.0.0-1_all.deb";
      hash = "sha256-HwUo+WmOM0d3WIeWvgNVRoTwvAujGXGgnQ2aRjVPioo=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/libjs-qrcodejs_1.20230525-pve1_all.deb";
      hash = "sha256-FldTh4sXnETm9OausJl4KxZKIJRuOsy8TYyFPS46ko0=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/pbs-i18n_3.8.0_all.deb";
      hash = "sha256-qsOW5HnUF+8GaDk+0eb4y/NpTVdjZakUUDIMfXVPiFE=";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/f/fonts-font-awesome/fonts-font-awesome_5.0.10+really4.7.0~dfsg-4.1_all.deb";
      hash = "sha256-Xwnhrc4m1ZYoojnFOIgtU+WJeLlYIzhk/GF76aUQAY4=";
    })
  ];
}
