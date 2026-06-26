{
  lib,
  buildFHSEnv,
  runCommand,
  iproute2,
  stdenv,
  proxmox-backup-server,
}:

# Runnable PBS: each binary from the base proxmox-backup-server package is wrapped
# in a buildFHSEnv. buildFHSEnv maps the base package's $out/{bin,lib,share} onto
# /usr, giving PBS the Debian FHS paths it hardcodes (web assets at
# /usr/share/javascript/proxmox-backup, helpers at /usr/lib/<multiarch>/proxmox-backup,
# /usr/bin/ip from iproute2). /run and /var are bind-mounted from the host
# automatically; /etc is a private tmpfs that already symlinks the host's
# passwd/group/shadow/ssl. Some target packages provide /etc/pam.d entries,
# which would otherwise shadow the host PAM stack, so we bind the host PAM
# directory back over it. We also bind the writable PBS config dir
# /etc/proxmox-backup, and bind the real host root in at /hostsys so datastores
# can live on arbitrary host paths/mounts (see extraBwrapArgs below).
let
  base = proxmox-backup-server;
  inherit (base) version;

  debianMultiarch = lib.replaceStrings [ "-unknown-" ] [ "-" ] stdenv.hostPlatform.config;
  fhsLibDir = "/usr/lib/${debianMultiarch}/proxmox-backup";

  mkFhs =
    name: exec:
    buildFHSEnv {
      inherit name;
      targetPkgs = pkgs: [
        base
        iproute2
      ];
      runScript = exec;
      extraBwrapArgs = [
        "--ro-bind-try /etc/pam.d /etc/pam.d"
        "--ro-bind-try /etc/ssh /etc/ssh"
        "--bind-try /etc/proxmox-backup /etc/proxmox-backup"
        # buildFHSEnv already auto-binds every top-level host dir (/mnt, /var,
        # /home, custom mounts, ...) into the namespace, so datastores on those
        # paths work as-is. The exception is the bare filesystem root "/": the
        # namespace "/" is an ephemeral FHS root, so a datastore created there
        # writes its chunk store into that throwaway root and "vanishes" on the
        # next request. Bind the real host root in at /hostsys (recursive, so
        # submounts come along) so the top of the host filesystem is reachable
        # explicitly via a datastore path of /hostsys.
        "--bind / /hostsys"
      ];
    };

  # User-facing CLIs (on $PATH) and the daemons the systemd units launch.
  cliNames = [
    "pmt"
    "pmtx"
    "proxmox-tape"
    "pbs3to4"
    "proxmox-backup-debug"
    "proxmox-backup-manager"
  ];
  daemonNames = [
    "proxmox-backup-api"
    "proxmox-backup-proxy"
    "proxmox-daily-update"
  ];

  cliLaunchers = lib.genAttrs cliNames (n: mkFhs n "/usr/bin/${n}");
  daemonLaunchers = lib.genAttrs daemonNames (n: mkFhs n "${fhsLibDir}/${n}");
in

runCommand "proxmox-backup-server-fhs-${version}"
  {
    meta = base.meta // {
      description = "Proxmox Backup Server, wrapped in an FHS environment (runnable)";
      mainProgram = "proxmox-backup-manager";
    };
    passthru = { inherit base; };
  }
  ''
    mkdir -p $out/bin $out/libexec/proxmox-backup

    # CLIs on $PATH.
    ${lib.concatStrings (
      lib.mapAttrsToList (n: w: ''
        ln -s ${lib.getExe' w n} $out/bin/${n}
      '') cliLaunchers
    )}

    # Daemons launched by the systemd units.
    ${lib.concatStrings (
      lib.mapAttrsToList (n: w: ''
        ln -s ${lib.getExe' w n} $out/libexec/proxmox-backup/${n}
      '') daemonLaunchers
    )}

    # Shell completions and other share data from the base package.
    ln -s ${base}/share $out/share
  ''
