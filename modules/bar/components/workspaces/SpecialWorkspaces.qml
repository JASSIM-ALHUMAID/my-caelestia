pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    required property var barConfig
    required property bool vertical
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: (GlobalConfig.bar.perMonitorWorkspaces ? monitor : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name ?? ""

    // Scroll position / total length along the list's main axis.
    readonly property real scrollPos: vertical ? view.contentY : view.contentX
    readonly property real scrollLen: vertical ? view.contentHeight : view.contentWidth
    readonly property real viewLen: vertical ? view.height : view.width

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        // Fade cover at the leading edge (top / left), hidden once scrolled past it.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: root.vertical ? parent.right : undefined
            anchors.bottom: root.vertical ? undefined : parent.bottom

            radius: Tokens.rounding.full
            implicitWidth: root.vertical ? 0 : parent.width / 2
            implicitHeight: root.vertical ? parent.height / 2 : 0
            opacity: root.scrollPos > 0 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        // Fade cover at the trailing edge (bottom / right).
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.left: root.vertical ? parent.left : undefined
            anchors.top: root.vertical ? undefined : parent.top

            radius: Tokens.rounding.full
            implicitWidth: root.vertical ? 0 : parent.width / 2
            implicitHeight: root.vertical ? parent.height / 2 : 0
            opacity: root.scrollPos < root.scrollLen - root.viewLen + Tokens.padding.small ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
        spacing: Tokens.spacing.medium
        interactive: false

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (!GlobalConfig.bar.perMonitorWorkspaces || w.monitor === root.monitor))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: root.vertical ? height : width
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            x: root.vertical ? 0 : (view.currentItem?.x ?? 0)
            y: root.vertical ? (view.currentItem?.y ?? 0) : 0
            implicitWidth: root.vertical ? 0 : ((view.currentItem as SpecialWsDelegate)?.size ?? 0)
            implicitHeight: root.vertical ? ((view.currentItem as SpecialWsDelegate)?.size ?? 0) : 0

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }
        }

        delegate: SpecialWsDelegate {}

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                type: Anim.StandardSmall
            }
            Anim {
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        asynchronous: true
        active: root.barConfig.workspaces.activeIndicator
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                // Fill the cross axis; track the active item on the main axis.
                x: root.vertical ? 0 : (view.currentItem?.x ?? 0) - view.contentX
                y: root.vertical ? (view.currentItem?.y ?? 0) - view.contentY : 0
                implicitWidth: root.vertical ? parent.width : ((view.currentItem as SpecialWsDelegate)?.size ?? 0)
                implicitHeight: root.vertical ? ((view.currentItem as SpecialWsDelegate)?.size ?? 0) : parent.height

                color: Colours.palette.m3tertiary
                radius: Tokens.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter

                    x: root.vertical ? 0 : -indicator.x
                    y: root.vertical ? -indicator.y : 0
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on x {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on y {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    // Draw real app icons on top of the active indicator so the Colouriser (which
    // flattens images to a solid colour) never blackens them. Mirrors the overlay
    // used for normal workspaces in Workspaces.qml.
    Loader {
        anchors.fill: view
        clip: true
        z: 100
        active: root.barConfig.workspaces.appIcons && root.barConfig.workspaces.showWindowsOnSpecialWorkspaces

        sourceComponent: Repeater {
            model: view.count

            delegate: Item {
                id: ovCell

                required property int index
                readonly property SpecialWsDelegate wsItem: view.itemAtIndex(index) as SpecialWsDelegate
                // Offset past the icon's slot along the main axis.
                readonly property real winOffset: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

                visible: ovCell.wsItem?.hasWindows ?? false
                x: root.vertical ? (ovCell.wsItem?.x ?? 0) : (ovCell.wsItem?.x ?? 0) - view.contentX
                y: root.vertical ? (ovCell.wsItem?.y ?? 0) - view.contentY : (ovCell.wsItem?.y ?? 0)
                width: ovCell.wsItem?.width ?? 0
                height: ovCell.wsItem?.height ?? 0

                Grid {
                    flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
                    columns: root.vertical ? 1 : -1
                    rows: root.vertical ? -1 : 1
                    spacing: 0

                    x: root.vertical ? (ovCell.width - width) / 2 : ovCell.winOffset
                    y: root.vertical ? ovCell.winOffset : (ovCell.height - height) / 2

                    Repeater {
                        model: ScriptModel {
                            values: {
                                const wsId = ovCell.wsItem?.wsId ?? -1;
                                const wins = Hypr.toplevels.values.filter(c => c.workspace?.id === wsId);
                                const maxIcons = root.barConfig.workspaces.maxWindowIcons;
                                return maxIcons > 0 ? wins.slice(0, maxIcons) : wins;
                            }
                        }

                        WindowIcon {
                            required property var modelData

                            toplevel: modelData
                            barConfig: root.barConfig
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        property real dragStart

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: root.vertical ? Drag.YAxis : Drag.XAxis
        drag.maximumY: 0
        drag.minimumY: root.vertical ? Math.min(0, view.height - view.contentHeight - Tokens.padding.small) : 0
        drag.maximumX: 0
        drag.minimumX: root.vertical ? 0 : Math.min(0, view.width - view.contentWidth - Tokens.padding.small)

        onPressed: event => dragStart = root.vertical ? event.y : event.x

        onClicked: event => {
            if (Math.abs((root.vertical ? event.y : event.x) - dragStart) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y) as SpecialWsDelegate;
            if (ws?.modelData)
                Hypr.toggleSpecialWorkspace(ws.modelData.name.slice(8));
            else
                Hypr.toggleSpecialWorkspace("special");
        }
    }

    component SpecialWsDelegate: GridLayout {
        id: ws

        required property HyprlandWorkspace modelData
        readonly property int size: root.vertical ? label.Layout.preferredHeight + (hasWindows ? windows.implicitHeight + Tokens.padding.small : 0) : label.Layout.preferredWidth + (hasWindows ? windows.implicitWidth + Tokens.padding.small : 0)
        property int wsId
        property string icon
        property bool hasWindows

        // Fill the cross axis of the list.
        anchors.left: root.vertical ? view.contentItem.left : undefined
        anchors.right: root.vertical ? view.contentItem.right : undefined
        anchors.top: root.vertical ? undefined : view.contentItem.top
        anchors.bottom: root.vertical ? undefined : view.contentItem.bottom

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: 0
        columnSpacing: 0

        Component.onCompleted: {
            wsId = modelData.id;
            icon = Icons.getSpecialWsIcon(modelData.name);
            hasWindows = root.barConfig.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
        }

        // Hacky thing cause modelData gets destroyed before the remove anim finishes
        Connections {
            function onIdChanged(): void {
                if (ws.modelData)
                    ws.wsId = ws.modelData.id;
            }

            function onNameChanged(): void {
                if (ws.modelData)
                    ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
            }

            function onLastIpcObjectChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.barConfig.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: ws.modelData
        }

        Connections {
            function onShowWindowsOnSpecialWorkspacesChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.barConfig.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: root.barConfig.workspaces
        }

        Loader {
            id: label

            asynchronous: true

            Layout.alignment: root.vertical ? (Qt.AlignHCenter | Qt.AlignTop) : (Qt.AlignVCenter | Qt.AlignLeft)
            Layout.preferredHeight: root.vertical ? Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 : -1
            Layout.preferredWidth: root.vertical ? -1 : Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

            sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

            Component {
                id: iconComp

                MaterialIcon {
                    fill: 1
                    text: ws.icon
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                }
            }

            Component {
                id: letterComp

                StyledText {
                    text: ws.icon
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: root.vertical
            Layout.fillWidth: !root.vertical
            Layout.preferredHeight: implicitHeight

            visible: active
            active: ws.hasWindows

            sourceComponent: Grid {
                flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
                columns: root.vertical ? 1 : -1
                rows: root.vertical ? -1 : 1
                spacing: 0

                add: Transition {
                    Anim {
                        properties: "scale"
                        from: 0
                        to: 1
                        easing: Tokens.anim.standardDecel
                    }
                }

                move: Transition {
                    Anim {
                        properties: "scale"
                        to: 1
                        easing: Tokens.anim.standardDecel
                    }
                    Anim {
                        properties: "x,y"
                    }
                }

                Repeater {
                    model: ScriptModel {
                        values: {
                            const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId);
                            const maxIcons = root.barConfig.workspaces.maxWindowIcons;
                            return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                        }
                    }

                    WindowIcon {
                        required property var modelData

                        toplevel: modelData
                        barConfig: root.barConfig
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }
}
