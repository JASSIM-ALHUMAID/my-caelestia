pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, fonts, colours"),
            category: "appearance"
        },
        {
            label: qsTr("Desktop"),
            icon: "desktop_windows",
            description: qsTr("Clock, visualiser"),
            category: "appearance"
        },
        {
            label: qsTr("Animation"),
            icon: "animation",
            description: qsTr("Durations, easing curves, motion"),
            category: "appearance"
        },
        {
            label: qsTr("Screensaver"),
            icon: "nightlight",
            description: qsTr("Idle animation, effects"),
            category: "appearance"
        },

        // Connectivity
        // TODO
        // {
        //     label: qsTr("Display"),
        //     icon: "monitor",
        //     description: qsTr("Output configuration"),
        //     category: "connectivity"
        // },
        {
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet"),
            category: "connectivity"
        },
        {
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            label: qsTr("Updates"),
            icon: "update",
            description: qsTr("System updates"),
            category: "system"
        },
        {
            label: qsTr("Plugins"),
            icon: "extension",
            description: qsTr("Manage plugins"),
            category: "system"
        },
        {
            label: qsTr("Power & screen"),
            icon: "power_settings_new",
            description: qsTr("Screen timeout, lock, suspend"),
            category: "system"
        },
        {
            label: qsTr("Battery"),
            icon: "battery_std",
            description: qsTr("Charge status, history, cycles"),
            category: "system"
        },
        {
            label: qsTr("Keybindings"),
            icon: "keyboard",
            description: qsTr("Keyboard shortcuts"),
            category: "system"
        },

        // Shell
        {
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            label: qsTr("Lock screen"),
            icon: "lock",
            description: qsTr("Lock screen widgets, authentication"),
            category: "shell"
        },
        {
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            label: qsTr("Hyprland"),
            icon: "terminal",
            description: qsTr("Variables, layout, input, keybinds"),
            category: "shell"
        },
        {
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information, credits"),
            category: "about"
        },
    ]
}
