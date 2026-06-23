{ config, lib, pkgs, ... }:

let
  cfg = config.services.proxmox-backup-server;
  package = cfg.package;
in
{
  options.services.proxmox-backup-server = {
    enable = lib.mkEnableOption "Proxmox Backup Server";

    package = lib.mkPackageOption pkgs "proxmox-backup-server-fhs" { };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open TCP port 8007 for the Proxmox Backup web/API proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.proxmox-backup-server = { };
    users.users.proxmox-backup-server = {
      isSystemUser = true;
      group = "proxmox-backup-server";
      extraGroups = [ "tape" ];
      home = "/var/lib/proxmox-backup";
      createHome = true;
    };

    environment.systemPackages = [ package ];

    security.pam.services.proxmox-backup-auth = { };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 8007 ];

    systemd.tmpfiles.rules = [
      "d /etc/proxmox-backup 0700 proxmox-backup-server proxmox-backup-server - -"
      "d /var/lib/proxmox-backup 0750 proxmox-backup-server proxmox-backup-server - -"
      "d /var/log/proxmox-backup 0750 proxmox-backup-server proxmox-backup-server - -"
      "d /var/log/proxmox-backup/api 0750 proxmox-backup-server proxmox-backup-server - -"
      "d /var/cache/proxmox-backup 0750 proxmox-backup-server proxmox-backup-server - -"
      "d /run/proxmox-backup 0750 proxmox-backup-server proxmox-backup-server - -"
    ];

    systemd.services.proxmox-backup = {
      description = "Proxmox Backup API Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "notify";
        # The daemon is FHS-wrapped (bwrap) by the package, so the process that
        # sends sd_notify(READY=1) is a child of the ExecStart process; allow it.
        NotifyAccess = "all";
        ExecStart = "${package}/libexec/proxmox-backup/proxmox-backup-api";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        PIDFile = "/run/proxmox-backup/api.pid";
        Restart = "on-failure";
      };
    };

    systemd.services.proxmox-backup-proxy = {
      description = "Proxmox Backup API Proxy Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "proxmox-backup.service" ];
      requires = [ "proxmox-backup.service" ];
      serviceConfig = {
        Type = "notify";
        NotifyAccess = "all";
        ExecStart = "${package}/libexec/proxmox-backup/proxmox-backup-proxy";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        PIDFile = "/run/proxmox-backup/proxy.pid";
        Restart = "on-failure";
        User = "proxmox-backup-server";
        Group = "proxmox-backup-server";
      };
    };

    systemd.services.proxmox-backup-daily-update = {
      description = "Proxmox Backup daily update jobs";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${package}/libexec/proxmox-backup/proxmox-daily-update";
      };
    };

    systemd.timers.proxmox-backup-daily-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:15:00";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };
  };
}
