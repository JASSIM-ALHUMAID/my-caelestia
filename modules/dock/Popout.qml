pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts
import qs.modules.launcher.services

// Hover preview / right-click menu for the floating dock. Lives as a sibling panel of the
// dock in Panels.qml rather than inside it: the dock's Loader is destroyed whenever the
// dock hides, which would take a nested popup down with it mid-interaction.
Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item dockWrapper

    // "preview" | "menu" | "" (closed)
    property string mode: ""
    property var targetData: null
    property bool editMode: false

    readonly property bool shouldBeActive: mode.length > 0
    readonly property bool menuOpen: mode === "menu" && visible

    // Latch the last non-null target and mode so the content stays stable through the close
    // animation rather than snapping to empty mid-fade.
    property var lastTarget: null
    property string lastMode: "preview"

    property real offsetScale: shouldBeActive ? 0 : 1

    // Whichever axis the card travels along as it follows the hovered icon. The other axis is
    // the one it slides in and out on, and offsetScale already animates that; a Behavior there
    // would fight it and drag the first appearance in from wherever the card was last left.
    readonly property bool followsX: !dockWrapper.isVertical

    // Falls back to the latched mode once closed, so a card sliding out keeps both its content
    // and its size the whole way rather than blanking after 200ms of a 500ms slide. The bar
    // gets this for free: PopoutState clears hasCurrent on close but leaves currentName set.
    readonly property string effectiveMode: root.mode.length > 0 ? root.mode : root.lastMode
    readonly property Item activeLoader: root.effectiveMode === "menu" ? menuLoader : previewLoader

    // The unanimated size target, read straight off the active loader so the size Behaviors
    // below always interpolate toward the truth — the same indirection popouts/Wrapper.qml
    // uses. It is what keeps the frame and the background from drifting apart mid-animation.
    readonly property real nonAnimWidth: activeLoader.implicitWidth + pad * 2
    readonly property real nonAnimHeight: activeLoader.implicitHeight + pad * 2

    // Prefer the app's focused window, matching the bar dock's DockApp. Always taking
    // toplevels[0] previewed the wrong window for a multi-window app, and DockItem.activate
    // cycles through them, so the icon you just clicked twice would keep previewing the first.
    readonly property var previewToplevel: {
        const tops = root.lastTarget?.toplevels ?? [];
        const active = Hypr.activeToplevel?.address;
        return tops.find(t => t.address === active) ?? tops[0] ?? null;
    }

    // Frame padding around the loaded content, matching the bar popout's
    // Tokens.padding.extraLargeIncreased/large split (Content.qml + its content margins).
    readonly property int pad: Tokens.padding.large

    // The bookmark reads as pinned state, not just as the action it performs: a pinned app
    // gets the solid glyph in the accent colour, an unpinned one the hollow outline in the
    // muted one, so the dock's two kinds of icon are told apart at a glance rather than by
    // reading which of add/remove the label says.
    readonly property bool targetPinned: root.lastTarget?.isPinned ?? false
    readonly property string bookmarkIcon: targetPinned ? "bookmark_remove" : "bookmark_add"
    readonly property real bookmarkFill: targetPinned ? 1 : 0
    readonly property color bookmarkColour: targetPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

    signal editModeRequested(bool active)
    signal addAppRequested
    signal closeRequested

    function pinnedPatternIndex(): int {
        return Strings.findRegexList(GlobalConfig.launcher.favouriteApps, root.targetData?.id ?? "");
    }

    function togglePinned(): void {
        const apps = [...GlobalConfig.launcher.favouriteApps];
        if (root.targetData?.isPinned) {
            const idx = root.pinnedPatternIndex();
            if (idx >= 0)
                apps.splice(idx, 1);
        } else if (root.targetData?.entry) {
            apps.push(Strings.exactPattern(root.targetData.id));
        } else {
            root.closeRequested();
            return;
        }
        GlobalConfig.launcher.favouriteApps = apps;
        root.closeRequested();
    }

    visible: offsetScale < 1
    opacity: 1 - offsetScale
    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight
    focus: menuOpen

    onTargetDataChanged: {
        if (targetData !== null)
            lastTarget = targetData;
    }

    onModeChanged: {
        if (mode.length > 0)
            lastMode = mode;
    }

    Keys.onEscapePressed: root.closeRequested()

    Behavior on offsetScale {
        Anim {}
    }

    // Gated on offsetScale so the size snaps while the card is hidden and only morphs once it
    // is on screen: a first open then places itself at the new app's size rather than growing
    // out of whatever the last one happened to be. dockMenuBg (ContentWindow.qml) reads this
    // same animated geometry, so the blob morphs with the frame instead of behind it.
    Behavior on implicitWidth {
        enabled: root.offsetScale < 1

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.offsetScale < 1

        Anim {}
    }

    // Only follow along the dock once open — otherwise the first appearance slides in from
    // wherever the card was last left, instead of just being placed.
    Behavior on x {
        enabled: root.followsX && root.offsetScale < 1

        Anim {}
    }

    Behavior on y {
        enabled: !root.followsX && root.offsetScale < 1

        Anim {}
    }

    // In hugged mode dockMenuBg's blob (ContentWindow.qml) provides the surface, merged
    // with the dock's own; painting an opaque rect here on top of it would hide the seamless
    // join the blob group exists to create.
    StyledRect {
        anchors.fill: parent
        visible: Config.dock.popoutMode !== "hugged"
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }
    }

    // A HoverHandler tracks hover over the whole subtree, unlike a MouseArea, which loses
    // onExited the moment the cursor lands on a topmost hover-accepting child (a MenuRow's
    // StateLayer, the ActiveWindow preview's internals) and starts the close timer early.
    // The menu no longer hover-dismisses at all; only the preview keeps its grace timer.
    HoverHandler {
        onHoveredChanged: hovered ? root.dockWrapper.cancelClose() : (root.mode === "preview" ? root.dockWrapper.closeDeferred() : null)
    }

    // One loader per mode rather than a single one swapping sourceComponent: swapping tore the
    // card down and rebuilt it on every preview→menu switch, and destroying it on close meant
    // every first hover constructed an ActiveWindow and started a ScreencopyView on the same
    // frame the fade began — the hitch that made the first preview feel worse than the bar's.
    // These crossfade in place instead, and stay resident once shown.
    ModeLoader {
        id: previewLoader

        mode: "preview"
        sourceComponent: previewComponent
    }

    ModeLoader {
        id: menuLoader

        mode: "menu"
        sourceComponent: menuComponent
    }

    // PropertyAction ordering, as in the bar's popouts/Content.qml: the loader is populated
    // before the fade in starts, so its size is known on the first frame and the frame's size
    // Behavior has somewhere truthful to animate to. Asymmetric durations (300ms in, 200ms
    // out) let the incoming card dominate the crossfade.
    component ModeLoader: Loader {
        id: modeLoader

        required property string mode
        readonly property bool shouldBeActive: root.effectiveMode === modeLoader.mode
        // Latched so a card that has been shown once is never rebuilt, only faded.
        property bool everActive: false

        anchors.centerIn: parent
        opacity: 0
        active: everActive

        onLoaded: everActive = true

        states: State {
            name: "active"
            when: modeLoader.shouldBeActive

            PropertyChanges {
                modeLoader.active: true
                modeLoader.opacity: 1
            }
        }

        // Both gated on the card being on screen. A mode change while hidden is a swap, not a
        // transition — animating it would leave the outgoing card fading out on top of the
        // incoming one for the first 200ms of the slide in, on every open that follows a
        // different mode.
        transitions: [
            Transition {
                from: "active"
                to: ""
                enabled: root.offsetScale < 1

                Anim {
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
            },
            Transition {
                from: ""
                to: "active"
                enabled: root.offsetScale < 1

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        property: "opacity"
                        type: Anim.SlowEffects
                    }
                }
            }
        ]
    }

    Component {
        id: previewComponent

        Column {
            spacing: Tokens.spacing.small

            BarPopouts.ActiveWindow {
                toplevel: root.previewToplevel

                trailingAction: Item {
                    width: 24 + Tokens.padding.small
                    height: 24

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.bookmarkIcon
                        color: root.bookmarkColour
                        fill: root.bookmarkFill
                        fontStyle: Tokens.font.icon.small

                        Behavior on fill {
                            Anim {}
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePinned()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: menuComponent

        // A ColumnLayout rather than a Column: rows have to span the widest row, and a Column
        // sizes itself from its children's actual width, so `width: parent.width` on each row
        // feeds the column its own width back and settles narrow — the menu rows then overflow
        // the card while the separators stop short. A layout reads implicitWidth instead and
        // stretches the rows afterwards, which is the same thing without the cycle.
        ColumnLayout {
            id: menu

            // Caps the card however long a window title is; the title elides into what's left.
            readonly property int maxWidth: 320

            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: root.lastTarget?.entry?.name ?? root.lastTarget?.appClass ?? ""
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
                padding: Tokens.padding.small
                bottomPadding: Tokens.padding.medium
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.maximumWidth: menu.maxWidth
            }

            Separator {
                visible: (root.lastTarget?.toplevels?.length ?? 0) > 0
            }

            Repeater {
                model: root.lastTarget?.toplevels ?? []

                RowLayout {
                    id: windowRow

                    required property var modelData

                    // Room the close icon needs (its box plus both margins), so the title's
                    // preferred width can be capped against maxWidth without squeezing it out.
                    readonly property int closeIconSpan: 24 + Tokens.padding.small * 2

                    spacing: Tokens.spacing.small
                    Layout.fillWidth: true
                    Layout.maximumWidth: menu.maxWidth

                    StyledText {
                        text: windowRow.modelData.lastIpcObject?.title ?? qsTr("Unknown")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        Layout.preferredWidth: Math.min(implicitWidth, menu.maxWidth - windowRow.closeIconSpan)
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                    }

                    MaterialIcon {
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                        Layout.rightMargin: Tokens.padding.small

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hypr.closeWindow(windowRow.modelData.address)
                        }
                    }
                }
            }

            MenuRow {
                visible: (root.lastTarget?.toplevels?.length ?? 0) > 1
                icon: "close"
                label: qsTr("Close All (%1)").arg(root.lastTarget?.toplevels?.length ?? 0)
                destructive: true
                onTriggered: {
                    for (const w of (root.lastTarget?.toplevels ?? []))
                        Hypr.closeWindow(w.address);
                    root.closeRequested();
                }
            }

            Separator {}

            MenuRow {
                visible: root.lastTarget?.entry != null
                icon: "add"
                label: qsTr("New Instance")
                onTriggered: {
                    if (root.lastTarget?.entry)
                        Apps.launch(root.lastTarget.entry);
                    root.closeRequested();
                }
            }

            MenuRow {
                icon: root.bookmarkIcon
                iconFill: root.bookmarkFill
                iconColour: root.bookmarkColour
                label: root.targetPinned ? qsTr("Unpin from Dock") : qsTr("Pin to Dock")
                onTriggered: root.togglePinned()
            }

            Separator {}

            MenuRow {
                icon: "apps"
                label: qsTr("Add App…")
                onTriggered: {
                    root.addAppRequested();
                    root.closeRequested();
                }
            }

            MenuRow {
                icon: "edit"
                label: root.editMode ? qsTr("Done Editing") : qsTr("Edit Dock")
                onTriggered: {
                    root.editModeRequested(!root.editMode);
                    root.closeRequested();
                }
            }
        }
    }

    // An Item wrapping the line rather than the StyledRect itself: the positioner places the
    // item directly, so anchor margins on it are inert — the breathing room either side of the
    // line has to be baked into implicitHeight instead.
    component Separator: Item {
        // Contributes no width of its own — it spans whatever the widest row settles on.
        implicitWidth: 0
        implicitHeight: 2 + Tokens.padding.extraSmall * 2
        Layout.fillWidth: true

        StyledRect {
            anchors.centerIn: parent
            width: parent.width
            height: 2
            color: Colours.palette.m3outlineVariant
        }
    }

    component MenuRow: StyledRect {
        id: menuRow

        required property string icon
        required property string label
        property bool destructive: false
        // Opt-in overrides for rows whose icon carries state of its own; the defaults keep
        // every other row on the plain muted glyph.
        property real iconFill: 0
        property color iconColour: destructive ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant

        readonly property color fg: destructive ? Colours.palette.m3error : Colours.palette.m3onSurface

        signal triggered

        implicitWidth: rowContent.implicitWidth + Tokens.padding.small * 2 + Tokens.padding.large
        implicitHeight: visible ? rowContent.implicitHeight + Tokens.padding.medium * 2 : 0
        radius: Tokens.rounding.small
        Layout.fillWidth: true

        Row {
            id: rowContent

            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.small
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: menuRow.icon
                color: menuRow.iconColour
                fill: menuRow.iconFill
                fontStyle: Tokens.font.icon.medium
                anchors.verticalCenter: parent.verticalCenter

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                text: menuRow.label
                font: Tokens.font.body.medium
                color: menuRow.fg
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StateLayer {
            anchors.fill: parent
            radius: Tokens.rounding.small
            color: menuRow.destructive ? Colours.palette.m3error : Colours.palette.m3onSurface
            onClicked: menuRow.triggered()
        }
    }
}
