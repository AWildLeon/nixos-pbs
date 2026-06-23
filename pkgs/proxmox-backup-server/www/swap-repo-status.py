#!/usr/bin/env python3
# The dashboard NodeInfo panel shows an APT "repository status" row that always
# reports "No Proxmox Backup Server repository enabled!" on this NixOS port
# (there are no APT repos here). Replace it with a static "Using NixOS-PBS
# Revision" row showing the git revision of the nixos-pbs packaging repo this
# was built from (NIXOS_PBS_REV, set from the flake's self.rev / self.dirtyRev).
import os
from pathlib import Path


def short_rev(rev):
    if not rev or rev == 'unknown':
        return 'unknown'
    dirty = rev.endswith('-dirty')
    h = rev[:-6] if dirty else rev
    return h[:12] + ('-dirty' if dirty else '')


rev = short_rev(os.environ.get('NIXOS_PBS_REV'))

p = Path('www/panel/NodeInfo.js')
s = p.read_text()

old = """        {
            xtype: 'pmxNodeInfoRepoStatus',
            itemId: 'repositoryStatus',
            product: 'Proxmox Backup Server',
            repoLink: '#pbsServerAdministration:aptrepositories',
        },
"""
new = """        {
            itemId: 'nixosPbsRevision',
            colspan: 2,
            printBar: false,
            title: gettext('Using NixOS-PBS Revision'),
            text: '%s',
        },
""" % rev

assert old in s, 'repository status row not found in NodeInfo.js'
s = s.replace(old, new)
p.write_text(s)
