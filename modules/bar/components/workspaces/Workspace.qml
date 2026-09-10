pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property var barConfig
    required property bool vertical
    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    // Max window icons to draw; <= 0 means unlimited. Set by Workspaces from the bar's
    // overflow budget, already clamped against workspaces.maxWindowIcons.
    required property int iconLimit

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int size: implicitHeight + (hasWindows ? Tokens.padding.small : 0)
    readonly property int sizeHorizontal: implicitWidth + (hasWindows ? Tokens.padding.small : 0)
    readonly property real mainPos: vertical ? y : x
    readonly property real mainSize: vertical ? size : sizeHorizontal

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && root.barConfig.workspaces.showWindows && (root.barConfig.workspaces.showWindowsOnActive !== false || activeWsId !== ws)

    // Single column (number over windows) when vertical, single row (number then windows)
    // when horizontal, so a cell never overflows the bar's cross axis.
    flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    columns: root.vertical ? 1 : -1
    rows: root.vertical ? -1 : 1
    rowSpacing: 0
    columnSpacing: 0

    Layout.alignment: Qt.AlignCenter
    Layout.preferredHeight: root.vertical ? size : implicitHeight
    Layout.preferredWidth: root.vertical ? implicitWidth : sizeHorizontal

    Loader {
        id: indicatorLoader

        Layout.alignment: root.vertical ? (Qt.AlignHCenter | Qt.AlignTop) : (Qt.AlignVCenter | Qt.AlignLeft)
        Layout.preferredHeight: root.vertical ? Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 : -1
        Layout.preferredWidth: root.vertical ? -1 : Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

        active: true
        sourceComponent: root.barConfig.workspaces.useIcon ? iconComponent : textComponent

        Component {
            id: textComponent

            StyledText {
                animate: true
                text: {
                    const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                    const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
                    let displayName = wsName.toString();
                    if (root.barConfig.workspaces.capitalisation.toLowerCase() === "upper") {
                        displayName = displayName.toUpperCase();
                    } else if (root.barConfig.workspaces.capitalisation.toLowerCase() === "lower") {
                        displayName = displayName.toLowerCase();
                    }
                    if (root.barConfig.workspaces.numbered)
                        return displayName;
                    const label = root.barConfig.workspaces.label || displayName;
                    const occupiedLabel = root.barConfig.workspaces.occupiedLabel || label;
                    const activeLabel = root.barConfig.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
                    return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
                }
                color: root.barConfig.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                font.family: "Rubik"
            }
        }

        Component {
            id: iconComponent

            Item {
                id: iconRoot

                readonly property bool active: root.activeWsId === root.ws
                property int randShape: MaterialShape.Slanted
                property bool wasActive: false

                width: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
                height: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

                readonly property list<int> shapePool: [
                    MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Oval, MaterialShape.Pill,
                    MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon,
                    MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided,
                    MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided,
                    MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.Clover8Leaf,
                    MaterialShape.SoftBurst, MaterialShape.Ghostish
                ]

                onActiveChanged: {
                    if (active && !wasActive) {
                        wasActive = true;
                        const shapes = shapePool;
                        randShape = shapes[Math.floor(Math.random() * shapes.length)];
                    } else if (!active) {
                        wasActive = false;
                    }
                }

                Component.onCompleted: {
                    if (active) {
                        wasActive = true;
                        const shapes = shapePool;
                        randShape = shapes[Math.floor(Math.random() * shapes.length)];
                    }
                }

                MaterialShape {
                    id: wsShape

                    anchors.centerIn: parent
                    implicitSize: parent.width

                    scale: iconRoot.active ? 2 / 3 : 1 / 3

                    shape: {
                        if (!root.isOccupied)
                            return MaterialShape.Circle;
                        if (iconRoot.active)
                            return iconRoot.randShape;
                        return MaterialShape.Square;
                    }

                    color: root.barConfig.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)

                    Behavior on shape {
                        Anim {}
                    }

                    Behavior on scale {
                        Anim {}
                    }
                }
            }
        }
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: root.vertical
        Layout.fillWidth: !root.vertical
        // Overlap slightly toward the number along the main axis.
        Layout.topMargin: root.vertical ? -Tokens.sizes.bar.innerWidth / 10 : 0
        Layout.leftMargin: root.vertical ? 0 : -Tokens.sizes.bar.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: Grid {
            // Stack the window icons along the bar's main axis.
            flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
            columns: root.vertical ? 1 : -1
            rows: root.vertical ? -1 : 1
            spacing: root.barConfig.workspaces.windowIconSpacing

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
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
                        const maxIcons = root.iconLimit;
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
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }
}
