pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services

StyledRect {
    id: root

    required property var dialog

    // Containers first so /mnt and the user's media root are always reachable,
    // then one row per mounted volume.
    readonly property var mountedEntries: {
        const out = [];
        out.push({ path: "/mnt", label: "/mnt", icon: "hard_drive" });
        out.push({ path: mounts.mediaRoot, label: "Media", icon: "folder_special" });
        for (const m of mounts.mounts)
            out.push({ path: m.path, label: m.name, icon: "usb" });
        return out;
    }

    function cwdFor(path: string): list<string> {
        const parts = path.split("/").filter(p => p.length > 0);
        parts[0] = "/" + parts[0];
        return parts;
    }

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Files")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: ["Home", "Downloads", "Desktop", "Documents", "Music", "Pictures", "Videos"]

            PlaceEntry {
                required property string modelData

                placeText: modelData
                icon: {
                    if (modelData === "Home")
                        return "home";
                    if (modelData === "Downloads")
                        return "file_download";
                    if (modelData === "Desktop")
                        return "desktop_windows";
                    if (modelData === "Documents")
                        return "description";
                    if (modelData === "Music")
                        return "music_note";
                    if (modelData === "Pictures")
                        return "image";
                    if (modelData === "Videos")
                        return "video_library";
                    return "folder";
                }
                selected: modelData === root.dialog.cwd[root.dialog.cwd.length - 1]
                onClicked: {
                    if (modelData === "Home")
                        root.dialog.cwd = ["Home"];
                    else
                        root.dialog.cwd = ["Home", modelData];
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.extraSmall / 2
            text: qsTr("Mounted")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        Repeater {
            model: root.mountedEntries

            PlaceEntry {
                required property var modelData

                placeText: modelData.label
                icon: modelData.icon
                selected: root.dialog.cwd.join("/") === modelData.path
                onClicked: root.dialog.cwd = root.cwdFor(modelData.path)
            }
        }
    }

    MountedVolumes {
        id: mounts
    }

    component PlaceEntry: StyledRect {
        id: place

        required property string placeText
        required property string icon
        required property bool selected

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

        StateLayer {
            color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            onClicked: place.clicked()
        }

        RowLayout {
            id: placeInner

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large

            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: place.icon
                color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.medium
                fill: place.selected ? 1 : 0

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: place.placeText
                color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }
}
