# Proxmox Backup Server on NixOS

This is the documentation hub for the **NixOS packaging of Proxmox Backup
Server** ([nixos-pbs](https://github.com/AWildLeon/nixos-pbs)): PBS built as a
native Nix package and run from a systemd service, with no Debian container.

The full upstream PBS manual is bundled and served right next to this page:

> 📖 **[Proxmox Backup Server manual](proxmox/index.html)**

Use the upstream manual for everything about datastores, backups, pruning,
verification, tape, and the API. The rest of this page covers only what is
specific to the NixOS port.

## Heads up: this is an unofficial port

This packaging is **experimental and unofficial**. It is not supported by
Proxmox Server Solutions GmbH, so please do not contact Proxmox support about
it. Report problems on the
[project issue tracker](https://github.com/AWildLeon/nixos-pbs/issues) instead,
and test on something you can afford to lose before trusting it with real
backups.

## How this port differs

- **Service user and group**: PBS runs as `proxmox-backup-server` rather than
  the Debian default `backup`, and keeps its state under
  `/var/lib/proxmox-backup`.

- **FHS-wrapped daemons**: PBS hardcodes Debian-style paths such as
  `/usr/share/javascript/proxmox-backup` and
  `/usr/lib/<multiarch>/proxmox-backup`, so the binaries run inside a bubblewrap
  FHS environment that provides them. Prefer the NixOS module options over
  editing files by hand.

- **Trimmed web UI**: features that cannot work on an immutable NixOS host are
  removed from the interface. APT updates and repositories, network and time
  configuration, and the reboot and shutdown buttons are gone, along with the
  two menus below.

  - **Shell**: there is no host xterm console to attach to.
  - **Storage / Disks**: disk management would write `systemd` mount units into
    `/etc/systemd/system`, which is a read-only nix-store path. The matching API
    endpoints are compiled in but will not work. Mount the filesystem
    declaratively with `fileSystems` instead, then create a datastore on it.

- **Documentation**: this page is served at `/docs`, and the upstream manual
  lives at `/docs/proxmox`. The Documentation button in the top bar opens this
  page.

## Getting started

The web login uses PAM, so you can sign in as `root@pam` with the host's root
password. From there, or from a shell on the host, create your first datastore:

```sh
proxmox-backup-manager datastore create main /var/lib/proxmox-backup/datastores/main
```

The web UI does the same thing through **Add Datastore**. Once a datastore
exists, follow the [upstream manual](proxmox/index.html) for backup clients,
scheduling, pruning, verification, and sync jobs.

To install the port on your own host, or to see the module options, read the
[README](https://github.com/AWildLeon/nixos-pbs#readme).

## Status and limitations

The package builds and the core services run, but several areas still need
real-world testing:

- Backup, restore, sync, and garbage collection under real workloads.
- PAM and authentication beyond a basic `root@pam` login.
- The privileged tape helpers (`pmt`, `pmtx`, `sg-tape-cmd`).
- Anything that assumes a Debian-style host.

Feedback is the fastest way to move this from experimental to trusted. If you
run it, please report results, good or bad, on the
[issue tracker](https://github.com/AWildLeon/nixos-pbs/issues).
