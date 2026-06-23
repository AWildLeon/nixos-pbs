{
  lib,
  fetchgit,
  fetchurl,
  rustPlatform,
  pkgconf,
  dpkg,
  python3,
  openssl,
  fuse3,
  acl,
  systemd,
  util-linux,
  libxcrypt,
  sg3_utils,
  apt,
  nettle,
  pam,
  installShellFiles,
  stdenv,
  # git revision of *this* (nixos-pbs) packaging repo, shown on the dashboard.
  # The flake threads in self.rev or self.dirtyRev; null falls back to "unknown".
  revision ? null,
}:

# Base package: builds PBS and lays its binaries and assets out in a standard
# Nix layout ($out/{bin,lib,share}). PBS hardcodes Debian FHS paths at runtime
# (/usr/share/javascript/proxmox-backup, /usr/lib/<multiarch>/proxmox-backup,
# /usr/bin/ip, ...), so the daemons are not run directly from here; the
# `proxmox-backup-server-fhs` package wraps this in a buildFHSEnv that maps these
# $out dirs onto /usr. See pkgs/proxmox-backup-server-fhs/package.nix.
let
  pname = "proxmox-backup-server";
  version = "4.2.2";

  nixosPbsRevision = if revision != null then revision else "unknown";

  sources = import ./sources.nix { inherit fetchgit fetchurl; };
  inherit (sources) repos webAssets;

  debianMultiarch = lib.replaceStrings [ "-unknown-" ] [ "-" ] stdenv.hostPlatform.config;

  # Appended to the upstream "no valid subscription" notices to make clear this
  # is the unofficial NixOS packaging. The two notices differ in their leading
  # text (one carries an <a> tag, the other a {0} placeholder), so we keep the
  # full source strings and reuse the shared note.
  unsupportedNote =
    "<br><br><b>Unsupported NixOS port:</b> this native NixOS setup is experimental and completely unsupported by Proxmox Server Solutions GmbH. Do not contact Proxmox support for issues with this packaging.";
  subscriptionMsgUI =
    ''You do not have a valid subscription for this server. Please visit <a target="_blank" href="https://www.proxmox.com/proxmox-backup-server/pricing">www.proxmox.com</a> to get a list of available options.'';
  subscriptionMsgLib =
    "You do not have a valid subscription for this server. Please visit {0} to get a list of available options.";
in

rustPlatform.buildRustPackage {
  inherit pname version;

  srcs = [
    repos.proxmox-backup
    repos.proxmox
    repos.proxmox-fuse
    repos.proxmox-pxar
    repos.proxmox-pathpatterns
  ];
  sourceRoot = repos.proxmox-backup.name;

  cargoPatches = [ ./0001-cargo-re-route-dependencies-not-available-on-crates..patch ];

  # The web UI is assembled here: install our trimmed-down panel definitions and
  # logo shim, drop the features that don't apply to this NixOS port (xterm.js
  # shell, APT updates/repos, disk/ZFS management, network/time config,
  # reboot/shutdown buttons), then concatenate the ExtJS bundle. The transform
  # scripts and replacement files live alongside this file in ./www.
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
    rm -f .cargo/config.toml

    mkdir -p www/js
    install -m644 ${./www/LogoShim.js} www/LogoShim.js
    install -m644 ${./www/ServerAdministration.js} www/ServerAdministration.js
    install -m644 ${./www/StorageAndDisks.js} www/panel/StorageAndDisks.js
    install -m644 ${./www/SystemConfiguration.js} www/SystemConfiguration.js

    substituteInPlace www/Utils.js \
      --replace-fail \
        '${subscriptionMsgUI}' \
        '${subscriptionMsgUI}${unsupportedNote}'

    python3 ${./www/remove-shell-nav.py}
    python3 ${./www/trim-server-status.py}
    python3 ${./www/swap-repo-status.py}
    python3 ${./www/build-gui-bundle.py}
  '';

  cargoLock.lockFileContents = builtins.readFile ./Cargo.lock;

  cargoBuildFlags = [
    "--package=proxmox-backup-banner" "--bin=proxmox-backup-banner"
    "--package=proxmox-backup" "--bin=pbs3to4"
    "--package=proxmox-backup" "--bin=proxmox-backup-api"
    "--package=proxmox-backup" "--bin=proxmox-backup-debug"
    "--package=proxmox-backup" "--bin=proxmox-backup-manager"
    "--package=proxmox-backup" "--bin=proxmox-backup-proxy"
    "--package=proxmox-backup" "--bin=proxmox-daily-update"
    "--package=proxmox-backup" "--bin=proxmox-tape"
    "--package=proxmox-backup" "--bin=sg-tape-cmd"
    "--package=pbs-tape" "--bin=pmt"
    "--package=pbs-tape" "--bin=pmtx"
  ];

  env = {
    REPOID = repos.proxmox-backup.rev;
    DEB_HOST_MULTIARCH = debianMultiarch;
    NIXOS_PBS_REV = nixosPbsRevision;
  };

  nativeBuildInputs = [
    pkgconf
    rustPlatform.bindgenHook
    installShellFiles
    dpkg
    python3
  ];

  buildInputs = [ openssl fuse3 acl systemd util-linux libxcrypt sg3_utils apt nettle pam ];

  strictDeps = true;
  doCheck = false;

  postInstall = ''
    # Web UI assets, shipped as Debian .debs, all live under usr/share.
    debtmp=$(mktemp -d)
    for deb in ${lib.escapeShellArgs webAssets}; do
      dpkg-deb -x "$deb" "$debtmp"
    done
    mkdir -p $out/share
    cp -a "$debtmp"/usr/share/. $out/share/

    substituteInPlace $out/share/javascript/proxmox-widget-toolkit/proxmoxlib.js \
      --replace-fail \
        '${subscriptionMsgLib}' \
        '${subscriptionMsgLib}${unsupportedNote}'

    # The default Rust installPhase put every binary in $out/bin. The daemons and
    # internal helpers belong in the FHS libexec dir PBS reaches via the hardcoded
    # /usr/lib/<multiarch>/proxmox-backup path; move them there and leave only the
    # user-facing CLIs in $out/bin.
    fhsLib=$out/lib/${debianMultiarch}/proxmox-backup
    mkdir -p $fhsLib
    for bin in proxmox-backup-api proxmox-backup-banner proxmox-backup-proxy proxmox-daily-update sg-tape-cmd; do
      mv $out/bin/$bin $fhsLib/$bin
    done

    install -Dm644 www/index.hbs $out/share/javascript/proxmox-backup/index.hbs
    install -Dm644 www/js/proxmox-backup-gui.js $out/share/javascript/proxmox-backup/js/proxmox-backup-gui.js
    install -Dm644 www/css/ext6-pbs.css $out/share/javascript/proxmox-backup/css/ext6-pbs.css
    cp -r www/images $out/share/javascript/proxmox-backup/images
    # Our compatibility LogoSVG shim is used with prefix: 'widgettoolkit' by PBS.
    # The current proxmox-widget-toolkit Debian package no longer ships this PNG,
    # but PBS still ships it in its own image directory.
    install -Dm644 www/images/proxmox_logo.png $out/share/javascript/proxmox-widget-toolkit/images/proxmox_logo.png
    mkdir -p $out/share/proxmox-backup
    cp -r templates $out/share/proxmox-backup/templates

    installShellCompletion --cmd proxmox-backup-manager --bash debian/proxmox-backup-manager.bc --zsh zsh-completions/_proxmox-backup-manager
    installShellCompletion --cmd proxmox-backup-debug --bash debian/proxmox-backup-debug.bc --zsh zsh-completions/_proxmox-backup-debug
    installShellCompletion --cmd proxmox-tape --bash debian/proxmox-tape.bc --zsh zsh-completions/_proxmox-tape
    installShellCompletion --cmd pmt --bash debian/pmt.bc --zsh zsh-completions/_pmt
    installShellCompletion --cmd pmtx --bash debian/pmtx.bc --zsh zsh-completions/_pmtx
  '';

  meta = {
    description = "Proxmox Backup Server (experimental native NixOS package, base build)";
    longDescription = ''
      The raw PBS build. Because PBS hardcodes Debian FHS paths at runtime, run it
      via the proxmox-backup-server-fhs package (or the NixOS module), not directly.
    '';
    homepage = "https://pbs.proxmox.com/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
