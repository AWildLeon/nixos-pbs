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
      rev = "035c449897fafc228c8bbf3a5b5ba38564478ac7";
      name = "proxmox-backup";
      hash = "sha256-tfZXmMWQrP0MiBC1uuSenGaghqHi4ljky6T2KtLcjhk=";
    };

    proxmox = fetchgit {
      url = "git://git.proxmox.com/git/proxmox.git";
      rev = "22c4d5ecbfce6eb2fd566181e0b7d23ac2df4f0c";
      name = "proxmox";
      hash = "sha256-rYaLx6Lorry+NkEmc6/xARMY6ZgdnIaCLJqRA0Mnf8o=";
    };

    proxmox-fuse = fetchgit {
      url = "git://git.proxmox.com/git/proxmox-fuse.git";
      rev = "258788a3d66f7a77040a480170fff9890d4939aa";
      name = "proxmox-fuse";
      hash = "sha256-deEPxhg2uyswBYjgYrXcAEBByJ/4ptX7I9y0R3AAFA0=";
    };

    proxmox-pxar = fetchgit {
      url = "git://git.proxmox.com/git/pxar.git";
      rev = "091a8a382d0d6fc71025351fb35c51b1f3b0074d";
      name = "pxar";
      hash = "sha256-9SFlrz6nuVby6iQ2ELVaioZu2pcs90tSuyzLCWJlcrA=";
    };

    proxmox-pathpatterns = fetchgit {
      url = "git://git.proxmox.com/git/pathpatterns.git";
      rev = "42e5e96e30297da878a4d4b3a7fa52b65c1be0ab";
      name = "pathpatterns";
      hash = "sha256-U8EhTg/2iuArQvUNGNYrgVYn1T/jnxxqSKJxfsCMAjs=";
    };
  };

  webAssets = [
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/libjs-extjs_7.0.0-5_all.deb";
      hash = "sha256-RhCa4YCVeaChny/eswvsF06/yRj++pfvy6rOSoZ3RLU=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/proxmox-widget-toolkit_5.0.2_all.deb";
      hash = "sha256-MKTJzDsORFNsU8g05/djZi6sz1Kdi1pgnPmnMovG2bk=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/pve-xtermjs_5.5.0-2_all.deb";
      hash = "sha256-3WisTzWdRo6V8qIFQaE87/c+v4PyFQfI8t3TDhxZdtw=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/libjs-qrcodejs_1.20230525-pve1_all.deb";
      hash = "sha256-FldTh4sXnETm9OausJl4KxZKIJRuOsy8TYyFPS46ko0=";
    })
    (fetchurl {
      url = "http://download.proxmox.com/debian/pbs/dists/trixie/pbs-no-subscription/binary-amd64/pbs-i18n_3.5.0_all.deb";
      hash = "sha256-tu7xMI3G6MiUJkizpVMOFvzEfMZqEpdOD7LPkQlmuL4=";
    })
    (fetchurl {
      url = "http://deb.debian.org/debian/pool/main/f/fonts-font-awesome/fonts-font-awesome_5.0.10+really4.7.0~dfsg-4.1_all.deb";
      hash = "sha256-Xwnhrc4m1ZYoojnFOIgtU+WJeLlYIzhk/GF76aUQAY4=";
    })
  ];
}
