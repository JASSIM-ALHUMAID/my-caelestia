pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Edge Gestures")
    isSubPage: true

    // Every panel that can claim an edge gesture. The OSD, session menu and launcher can sit
    // on any of the four edges (a floating launcher owns none); the dashboard and dock are
    // top/bottom only.
    readonly property list<MenuItem> allItems: [
        MenuItem { text: qsTr("None"); property string value: "none" },
        MenuItem { text: qsTr("Launcher"); property string value: "launcher" },
        MenuItem { text: qsTr("Dashboard"); property string value: "dashboard" },
        MenuItem { text: qsTr("Dock"); property string value: "dock" },
        MenuItem { text: qsTr("OSD"); property string value: "osd" },
        MenuItem { text: qsTr("Session"); property string value: "session" },
    ]

    function itemFor(items: var, value: string): MenuItem {
        for (const item of items)
            if (item.value === value)
                return item;
        return items[0];
    }

    // A gesture pointing at a panel that has since moved off this edge is dead: itemFor falls
    // back to "None", so the row would read None while the config still held the old name and
    // silently resurrected the gesture if the panel ever came back. Clear it for real instead.
    function pruneStaleGestures(edge: string): void {
        const occupants = root.occupantsOf(edge);
        const cfg = GlobalConfig.edges[edge];
        if (cfg.hover !== "none" && !occupants.includes(cfg.hover))
            cfg.hover = "none";
        if (cfg.drag !== "none" && !occupants.includes(cfg.drag))
            cfg.drag = "none";
    }

    // Panels currently living on each edge. Assigning a gesture to a panel that isn't on the
    // edge does nothing, so the choices are filtered down to the actual occupants.
    function occupantsOf(edge: string): var {
        const names = [];
        // A floating launcher owns no edge — see Interactions.qml's launcherEdge — so it must
        // never appear as an occupant, or pruneStaleGestures would treat a stale gesture
        // pointing at it as still live. Docked + "center" is coerced to bottom the same way
        // Wrapper.qml coerces it, so the listed occupant matches where the panel renders.
        const launcherEdge = Config.launcher.position === "center" ? "bottom" : Config.launcher.position;
        if (Config.launcher.mode !== "floating" && launcherEdge === edge)
            names.push("launcher");
        if (Config.dashboard.position === edge)
            names.push("dashboard");
        if (Config.dock.position === edge)
            names.push("dock");
        if (Config.osd.position === edge)
            names.push("osd");
        if (Config.session.position === edge)
            names.push("session");
        return names;
    }

    function itemsFor(edge: string): var {
        const occupants = root.occupantsOf(edge);
        return root.allItems.filter(item => item.value === "none" || occupants.includes(item.value));
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.medium
            Layout.rightMargin: Tokens.padding.medium
            Layout.bottomMargin: Tokens.padding.small
            text: qsTr("Several panels can share a screen edge. Each edge decides which one a hover opens and which one an inward drag opens, so two panels never fight over the same gesture.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
            wrapMode: Text.WordWrap
        }

        EdgeSection {
            edge: "top"
            title: qsTr("Top edge")
        }

        EdgeSection {
            edge: "bottom"
            title: qsTr("Bottom edge")
        }

        EdgeSection {
            edge: "left"
            title: qsTr("Left edge")
        }

        EdgeSection {
            edge: "right"
            title: qsTr("Right edge")
        }
    }

    component EdgeSection: ColumnLayout {
        id: section

        required property string edge
        required property string title
        property string subtitle: ""

        readonly property var items: root.itemsFor(section.edge)
        readonly property var occupants: root.occupantsOf(section.edge)

        onOccupantsChanged: root.pruneStaleGestures(section.edge)
        Component.onCompleted: root.pruneStaleGestures(section.edge)

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            text: section.title
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.medium
            Layout.rightMargin: Tokens.padding.medium
            visible: text.length > 0
            text: section.subtitle ? section.subtitle : (section.occupants.length > 0 ? qsTr("Panels on this edge: %1").arg(section.occupants.join(", ")) : qsTr("No panels on this edge"))
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        SelectRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Hover opens")
            menuItems: section.items
            active: root.itemFor(section.items, Config.edges[section.edge].hover)
            onSelected: item => GlobalConfig.edges[section.edge].hover = item.value
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag opens")
            menuItems: section.items
            active: root.itemFor(section.items, Config.edges[section.edge].drag)
            onSelected: item => GlobalConfig.edges[section.edge].drag = item.value
        }
    }
}
