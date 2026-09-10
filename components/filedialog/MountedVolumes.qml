pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string mediaRoot: `/run/media/${Quickshell.env("USER") || "root"}`
    property list<var> mounts: []

    function parse(data: string): void {
        const pseudo = ["tmpfs", "devtmpfs", "proc", "sysfs", "cgroup", "cgroup2",
            "overlay", "squashfs", "devpts", "mqueue", "ramfs", "rpc_pipefs",
            "autofs", "configfs", "debugfs", "tracefs", "securityfs", "pstore",
            "bpf", "binfmt_misc", "hugetlbfs", "fusectl", "efivarfs", "selinuxfs"];
        const unescape = s => s.replace(/\\040/g, " ").replace(/\\011/g, "\t")
            .replace(/\\012/g, "\n").replace(/\\134/g, "\\");

        const out = [];
        for (const line of data.split("\n")) {
            const fields = line.trim().split(/\s+/);
            if (fields.length < 3)
                continue;
            const fstype = fields[2];
            if (pseudo.includes(fstype) || fstype.startsWith("fuse."))
                continue;
            const path = unescape(fields[1]);
            if (path === "/" || path === "/mnt")
                continue;
            if (!path.startsWith("/mnt/") && !path.startsWith("/run/media/"))
                continue;
            const name = path.slice(path.lastIndexOf("/") + 1);
            if (!name)
                continue;
            out.push({ path: path, name: name });
        }
        out.sort((a, b) => a.path.localeCompare(b.path));
        root.mounts = out;
    }

    // procfs doesn't emit inotify events, so watchChanges is best-effort and the
    // timer is the reliable update mechanism for plug/unplug.
    FileView {
        id: mountsView

        path: "/proc/mounts"
        watchChanges: true
        printErrors: false
        onLoaded: root.parse(text())
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: mountsView.reload()
    }
}
