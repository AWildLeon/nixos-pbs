#!/usr/bin/env bash
# Build and launch the pbs-test-vm with all runtime state kept inside the repo
# (./.vm-state/), so the system disk *and* the secondary datastore disk persist
# across reboots instead of landing in a throwaway /tmp/nix-vm.* directory.
#
# Why the env vars: the generated run-*-vm script normally creates a fresh
# `mktemp -d` for $TMPDIR each launch, `cd`s into it, and writes the
# emptyDiskImages there (empty0.qcow2) -- so they are recreated blank every
# boot. Pinning TMPDIR (+ USE_TMPDIR) and NIX_DISK_IMAGE to ./.vm-state keeps
# them in one stable, persistent place.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.." # repo root

state="$PWD/.vm-state"
mkdir -p "$state"

nix build .#nixosConfigurations.pbs-test-vm.config.system.build.vm -o "$state/vm"

exec env \
  USE_TMPDIR=1 \
  TMPDIR="$state" \
  NIX_DISK_IMAGE="$state/pbs-test.qcow2" \
  "$state/vm/bin/run-pbs-test-vm" "$@"
