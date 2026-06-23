Ext.define('PBS.StorageAndDiskPanel', {
    extend: 'Ext.tab.Panel',
    alias: 'widget.pbsStorageAndDiskPanel',
    mixins: ['Proxmox.Mixin.CBind'],

    title: gettext('Storage / Disks'),

    tools: [PBS.Utils.get_help_tool('storage-disk-management')],

    border: false,
    defaults: {
        border: false,
    },

    items: [
        {
            xtype: 'pbsDirectoryList',
            title: Proxmox.Utils.directoryText,
            itemId: 'directorystorage',
            iconCls: 'fa fa-folder',
        },
    ],
});
