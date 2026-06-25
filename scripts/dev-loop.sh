#!/usr/bin/env bash
# Continuously rebuild + relaunch the pbs-test-vm from a clean slate: each
# iteration wipes the persistent state (system + secondary /dev/vdb disks) and
# then defers to run-vm.sh for the build/launch.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.." # repo root

while true; do
    rm -rf .vm-state # clean slate every iteration
    ./scripts/run-vm.sh
done
