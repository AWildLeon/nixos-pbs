#!/usr/bin/env bash
set -euo pipefail

while true; do 
    nix build .#nixosConfigurations.pbs-test-vm.config.system.build.vm
    ./result/bin/run-pbs-test-vm;
    rm pbs-test.qcow2;
done