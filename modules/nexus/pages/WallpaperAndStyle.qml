pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.curves
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus.common
import "../../../components/curves/bezier.js" as Bezier

PageBase {
    id: root

    readonly property bool transitionsEnabled: Config.background.transitionType !== "none"
    readonly property bool currentVideoThumbnailFailed: Images.isValidVideoByName(Wallpapers.current) && Wallpapers.videoFrames[Wallpapers.current] === ""

    readonly property list<MenuItem> videoProgressPositionItems: [
        MenuItem { text: qsTr("Top"); property string value: "top" },
        MenuItem { text: qsTr("Bottom"); property string value: "bottom" },
        MenuItem { text: qsTr("Left"); property string value: "left" },
        MenuItem { text: qsTr("Right"); property string value: "right" }
    ]
    readonly property MenuItem activeVideoProgressPositionItem: {
        for (const item of root.videoProgressPositionItems)
            if (item.value === Config.background.videoProgress.position) return item;
        return root.videoProgressPositionItems[1];
    }
    readonly property list<MenuItem> videoProgressStyleItems: [
        MenuItem { text: qsTr("Straight"); property string value: "straight" },
        MenuItem { text: qsTr("Wavy"); property string value: "wavy" }
    ]
    readonly property MenuItem activeVideoProgressStyleItem: {
        for (const item of root.videoProgressStyleItems)
            if (item.value === Config.background.videoProgress.style) return item;
        return root.videoProgressStyleItems[0];
    }

    readonly property list<string> fillModeValues: ["cover", "fit", "stretch", "center", "tile"]
    readonly property list<MenuItem> fillModeItems: [
        MenuItem {
            text: qsTr("Fill (crop)")
        },
        MenuItem {
            text: qsTr("Fit")
        },
        MenuItem {
            text: qsTr("Stretch")
        },
        MenuItem {
            text: qsTr("Center")
        },
        MenuItem {
            text: qsTr("Tile")
        }
    ]

    readonly property list<string> advanceOrderValues: ["random", "next"]
    readonly property list<MenuItem> advanceOrderItems: [
        MenuItem {
            text: qsTr("Random")
        },
        MenuItem {
            text: qsTr("Next in folder")
        }
    ]

    readonly property list<string> transitionInterruptValues: ["freeze", "reverse"]
    readonly property list<MenuItem> transitionInterruptItems: [
        MenuItem {
            text: qsTr("Freeze & restart")
        },
        MenuItem {
            text: qsTr("Reverse first")
        }
    ]

    readonly property list<string> transitionInterruptReplayValues: ["same", "new"]
    readonly property list<MenuItem> transitionInterruptReplayItems: [
        MenuItem {
            text: qsTr("Same transition")
        },
        MenuItem {
            text: qsTr("New transition")
        }
    ]

    // Built-in easings, then any motion token that is safe here, then a hand-drawn curve.
    readonly property var easingPresets: [
        { value: "inOutCubic", label: qsTr("Smooth") },
        { value: "outCubic", label: qsTr("Snappy") },
        { value: "outExpo", label: qsTr("Punchy") },
        { value: "linear", label: qsTr("Linear") },
        { value: "inCubic", label: qsTr("Gentle start") }
    ]

    readonly property var curveTokenLabels: ({
            standard: qsTr("Standard (token)"),
            standardAccel: qsTr("Standard accel (token)"),
            standardDecel: qsTr("Standard decel (token)"),
            emphasized: qsTr("Emphasized (token)"),
            emphasizedAccel: qsTr("Emphasized accel (token)"),
            emphasizedDecel: qsTr("Emphasized decel (token)"),
            expressiveFastSpatial: qsTr("Expressive fast spatial (token)"),
            expressiveDefaultSpatial: qsTr("Expressive default spatial (token)"),
            expressiveSlowSpatial: qsTr("Expressive slow spatial (token)"),
            expressiveFastEffects: qsTr("Expressive fast effects (token)"),
            expressiveDefaultEffects: qsTr("Expressive default effects (token)"),
            expressiveSlowEffects: qsTr("Expressive slow effects (token)")
        })

    // Tokens are offered only while they stay inside 0..1. The expressive set overshoots by
    // design, which the fade and zoom shaders can't take -- and this is computed rather than
    // hardcoded, so a token edited into overshoot drops out on its own.
    readonly property var easingOptions: {
        const out = root.easingPresets.slice();
        for (const name of Object.keys(root.curveTokenLabels)) {
            const pts = TokenConfig.appearance.curves[name];
            if (pts !== undefined && pts.length >= 6 && !Bezier.overshoots(pts))
                out.push({ value: name, label: root.curveTokenLabels[name] });
        }
        out.push({ value: "custom", label: qsTr("Custom curve") });
        return out;
    }

    readonly property bool easingIsCustom: Config.background.transitionEasing === "custom"

    readonly property list<real> easingPoints: {
        const name = Config.background.transitionEasing;
        if (name === "custom")
            return Config.background.transitionCurve;
        const token = TokenConfig.appearance.curves[name];
        return token !== undefined && token.length >= 6 ? token : [];
    }

    readonly property list<string> advancePoolValues: ["all", "images", "videos"]
    readonly property list<MenuItem> advancePoolItems: [
        MenuItem {
            text: qsTr("All")
        },
        MenuItem {
            text: qsTr("Images only")
        },
        MenuItem {
            text: qsTr("Videos only")
        }
    ]

    function showCurrentWallpaperInFiles(): void {
        const path = Wallpapers.current;
        if (!path)
            return;
        const dir = path.substring(0, path.lastIndexOf("/"));
        if (!dir)
            return;
        // FileManager1 highlights the file itself; fall back to just opening the containing
        // directory when no file manager owns the bus name. encodeURI leaves '#' alone.
        const uri = `file://${encodeURI(path).replace(/#/g, "%23")}`;
        const fallback = ["app2unit", "--", ...AppCommands.explorer, dir];
        Quickshell.execDetached(["sh", "-c", 'gdbus call --session --dest org.freedesktop.FileManager1 --object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems "[\\"$1\\"]" "" >/dev/null 2>&1 || { shift; exec "$@"; }', "sh", uri, ...fallback]);
    }

    function copyCurrentWallpaperName(): void {
        const path = Wallpapers.current;
        if (path)
            Quickshell.clipboardText = path.substring(path.lastIndexOf("/") + 1);
    }

    function copyCurrentWallpaperPath(): void {
        if (Wallpapers.current)
            Quickshell.clipboardText = Wallpapers.current;
    }

    function playLivePreview(): void {
        const parts = transitionPicker.selectedParts;
        const others = Wallpapers.list.filter(w => w.path !== Wallpapers.current);
        if (parts.length === 0 || others.length === 0)
            return;
        livePreview.type = parts[Math.floor(Math.random() * parts.length)];
        const target = others[Math.floor(Math.random() * others.length)];
        livePreview.pendingPlay = true;
        liveTargetImg.source = Wallpapers.thumbnailFor(target.path);
        if (liveTargetImg.status === Image.Ready) {
            livePreview.pendingPlay = false;
            livePreview.playing = true;
        }
    }

    title: qsTr("Wallpaper & style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.large
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    property real requestedOpacity: 0

                    anchors.centerIn: parent

                    opacity: root.currentVideoThumbnailFailed ? 0 : requestedOpacity
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.requestedOpacity = 1;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.currentVideoThumbnailFailed
                    text: "movie"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: {
                        Wallpapers.videoFrames;
                        return Wallpapers.thumbnailFor(Wallpapers.current);
                    }
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects
                    fillMode: Wallpapers.imageFillMode

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.requestedOpacity = 0;
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    asynchronous: true
                    active: Config.background.wallpaperEnabled && Images.isValidVideoByName(Wallpapers.current)

                    sourceComponent: WallpaperVideoPreview {
                        path: Wallpapers.current
                        active: true
                    }
                }
            }

            Image {
                id: liveTargetImg

                anchors.fill: parent
                visible: false
                asynchronous: true
                fillMode: Wallpapers.imageFillMode
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }

                onStatusChanged: {
                    if (status === Image.Ready && livePreview.pendingPlay) {
                        livePreview.pendingPlay = false;
                        livePreview.playing = true;
                    }
                }
            }

            TransitionPreview {
                id: livePreview

                property bool pendingPlay: false

                anchors.fill: parent
                visible: playing
                loop: false
                restProgress: 0
                fromItem: wallImg
                toItem: liveTargetImg

                onFinished: liveHoldTimer.start()
            }

            Timer {
                id: liveHoldTimer

                interval: 450
                onTriggered: livePreview.playing = false
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                IconButton {
                    icon: "folder_open"
                    type: IconButton.Tonal
                    visible: !!Wallpapers.current
                    onClicked: root.showCurrentWallpaperInFiles()
                }

                IconButton {
                    icon: "play_arrow"
                    type: IconButton.Tonal
                    visible: root.transitionsEnabled && Config.background.wallpaperEnabled && Wallpapers.list.length > 1 && !livePreview.playing
                    onClicked: root.playLivePreview()
                }
            }

            IconButton {
                id: wallActionsButton

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium

                icon: "more_vert"
                type: IconButton.Tonal
                visible: !!Wallpapers.current
                onClicked: wallActionsMenu.expanded = !wallActionsMenu.expanded
            }

            Menu {
                id: wallActionsMenu

                attachTo: wallActionsButton
                attachSideX: Menu.Right
                thisSideX: Menu.Right
                attachSideY: Menu.Bottom
                thisSideY: Menu.Top
                marginY: Tokens.spacing.small

                items: [
                    MenuItem {
                        icon: "content_copy"
                        text: qsTr("Copy file name")
                        onClicked: root.copyCurrentWallpaperName()
                    },
                    MenuItem {
                        icon: "link"
                        text: qsTr("Copy full path")
                        onClicked: root.copyCurrentWallpaperPath()
                    }
                ]
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.large
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(2) // Colours page
            }
        }

        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Wallpaper")

            ToggleRow {
                Layout.fillWidth: true

                first: true
                text: qsTr("Display wallpaper")
                checked: Config.background.wallpaperEnabled
                onToggled: GlobalConfig.background.wallpaperEnabled = checked
            }

            SelectRow {
                last: true
                Layout.fillWidth: true

                label: qsTr("Wallpaper fill mode")
                subtext: qsTr("How the wallpaper is scaled to the screen")
                menuItems: root.fillModeItems
                active: root.fillModeItems[Math.max(0, root.fillModeValues.indexOf(Config.background.fillMode))]
                onSelected: item => GlobalConfig.background.fillMode = root.fillModeValues[root.fillModeItems.indexOf(item)]
            }
        }

        SettingsSection {
            title: qsTr("Wallpaper directories")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: Wallpapers.wallpaperDirEntries

                    delegate: RowLayout {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "folder"
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.icon.small
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: Paths.shortenHome(modelData.path)
                                font: Tokens.font.body.medium
                                elide: Text.ElideMiddle
                                opacity: modelData.enabled ? 1 : 0.5
                            }
                        }

                        StyledSwitch {
                            checked: modelData.enabled
                            onToggled: Wallpapers.toggleDir(index)
                        }

                        IconButton {
                            icon: "close"
                            type: IconButton.Text
                            onClicked: {
                                const dirs = Wallpapers.wallpaperDirEntries.filter((_, i) => i !== index);
                                Wallpapers.setWallpaperDirs(dirs);
                            }
                        }
                    }
                }

                IconTextButton {
                    icon: "add"
                    text: qsTr("Add directory")
                    type: IconTextButton.Tonal
                    onClicked: dirDialog.open()
                }
            }
        }

        SettingsSection {
            title: qsTr("Video wallpaper")

            ToggleRow {
                first: true
                Layout.fillWidth: true

                text: qsTr("Video wallpaper audio")
                subtext: qsTr("Play audio from the video wallpaper")
                checked: Config.background.videoAudio
                onToggled: GlobalConfig.background.videoAudio = checked
            }

            ToggleRow {
                Layout.fillWidth: true

                visible: Config.background.videoAudio
                text: qsTr("Pause when other audio plays")
                subtext: qsTr("Pause wallpaper audio while another app is playing sound")
                checked: Config.background.pauseAudioWhenOtherPlaying
                onToggled: GlobalConfig.background.pauseAudioWhenOtherPlaying = checked
            }

            ToggleRow {
                Layout.fillWidth: true

                text: qsTr("Video progress bar")
                subtext: qsTr("Show video wallpaper progress along a screen edge")
                checked: Config.background.videoProgress.enabled
                onToggled: GlobalConfig.background.videoProgress.enabled = checked
            }

            SelectRow {
                Layout.fillWidth: true

                visible: Config.background.videoProgress.enabled
                label: qsTr("Progress bar edge")
                subtext: qsTr("Which screen edge shows video wallpaper progress")
                menuItems: root.videoProgressPositionItems
                active: root.activeVideoProgressPositionItem
                onSelected: item => GlobalConfig.background.videoProgress.position = item.value
            }

            SelectRow {
                Layout.fillWidth: true

                visible: Config.background.videoProgress.enabled
                label: qsTr("Progress bar style")
                subtext: qsTr("Draw the completed progress as a straight or animated wavy line")
                menuItems: root.videoProgressStyleItems
                active: root.activeVideoProgressStyleItem
                onSelected: item => GlobalConfig.background.videoProgress.style = item.value
            }

            StepperRow {
                Layout.fillWidth: true

                visible: Config.background.videoProgress.enabled
                label: qsTr("Progress bar thickness")
                subtext: qsTr("Line width in pixels")
                value: Config.background.videoProgress.thickness
                from: 2
                to: 24
                stepSize: 1
                onMoved: v => GlobalConfig.background.videoProgress.thickness = Math.round(v)
            }

            ToggleRow {
                Layout.fillWidth: true

                visible: Config.background.advancePool === "videos" && !Config.background.rotationEnabled
                text: qsTr("Loop forever")
                subtext: qsTr("Keep replaying this video wallpaper instead of advancing")
                checked: Config.background.videoLoops === 0
                onToggled: GlobalConfig.background.videoLoops = checked ? 0 : 1
            }

            StepperRow {
                Layout.fillWidth: true

                visible: Config.background.advancePool === "videos" && !Config.background.rotationEnabled && Config.background.videoLoops > 0
                label: qsTr("Play count")
                subtext: qsTr("Number of plays before advancing")
                value: Config.background.videoLoops
                from: 1
                to: 99
                onMoved: v => GlobalConfig.background.videoLoops = Math.round(v)
            }

            StepperRow {
                last: true
                Layout.fillWidth: true

                label: qsTr("Video seek step (seconds)")
                subtext: qsTr("How far the seek shortcut moves a video wallpaper")
                value: Config.background.videoSeekStepSeconds
                from: 1
                to: 300
                onMoved: v => GlobalConfig.background.videoSeekStepSeconds = Math.round(v)
            }
        }

        SettingsSection {
            title: qsTr("Auto-change")

            ToggleRow {
                first: true
                Layout.fillWidth: true

                text: qsTr("Auto-change wallpaper")
                subtext: qsTr("Automatically advance the wallpaper on a timer")
                checked: Config.background.rotationEnabled
                onToggled: GlobalConfig.background.rotationEnabled = checked
            }

            ToggleRow {
                Layout.fillWidth: true

                visible: Config.background.rotationEnabled && Config.background.advancePool !== "images"
                text: qsTr("Finish video before changing")
                subtext: qsTr("Let a video wallpaper play to the end of its current loop before auto-advancing")
                checked: Config.background.videoPlayToEnd
                onToggled: GlobalConfig.background.videoPlayToEnd = checked
            }

            StepperRow {
                Layout.fillWidth: true

                visible: Config.background.rotationEnabled
                label: qsTr("Interval (minutes)")
                subtext: qsTr("1440 = daily")
                value: Config.background.rotationIntervalMinutes
                from: 1
                to: 1440
                onMoved: v => GlobalConfig.background.rotationIntervalMinutes = Math.round(v)
            }

            SelectRow {
                Layout.fillWidth: true

                label: qsTr("Order")
                subtext: qsTr("How the next wallpaper is picked")
                menuItems: root.advanceOrderItems
                active: root.advanceOrderItems[Math.max(0, root.advanceOrderValues.indexOf(Config.background.advanceOrder))]
                onSelected: item => GlobalConfig.background.advanceOrder = root.advanceOrderValues[root.advanceOrderItems.indexOf(item)]
            }

            SelectRow {
                last: true
                Layout.fillWidth: true

                label: qsTr("Pick from")
                subtext: qsTr("Which wallpapers are eligible")
                menuItems: root.advancePoolItems
                active: root.advancePoolItems[Math.max(0, root.advancePoolValues.indexOf(Config.background.advancePool))]
                onSelected: item => GlobalConfig.background.advancePool = root.advancePoolValues[root.advancePoolItems.indexOf(item)]
            }
        }

        SettingsSection {
            title: qsTr("Transitions")

            ToggleRow {
                first: true
                last: !root.transitionsEnabled
                Layout.fillWidth: true

                text: qsTr("Wallpaper transitions")
                subtext: transitionPicker.summary
                checked: root.transitionsEnabled
                onToggled: {
                    if (checked) {
                        if (Config.background.transitionType === "none" || Config.background.transitionType === "")
                            GlobalConfig.background.transitionType = "fade";
                    } else {
                        GlobalConfig.background.transitionType = "none";
                    }
                }
            }

            CollapsibleSection {
                nested: true
                visible: root.transitionsEnabled

                title: qsTr("Transition style")

                TransitionPicker {
                    id: transitionPicker

                    Layout.fillWidth: true
                }
            }

            SliderRow {
                first: true
                Layout.fillWidth: true
                visible: root.transitionsEnabled
                icon: "timer"
                label: qsTr("Transition duration")
                valueLabel: Config.background.transitionDuration + "ms"
                value: Config.background.transitionDuration
                to: 3000
                onMoved: v => GlobalConfig.background.transitionDuration = Math.max(100, Math.round(v))
            }

            SelectRow {
                last: true
                Layout.fillWidth: true
                visible: root.transitionsEnabled

                label: qsTr("Easing")
                subtext: qsTr("How the transition accelerates")
                menuItems: easingVariants.instances
                active: menuItems.find(i => i.value === Config.background.transitionEasing) ?? null
                fallbackText: Config.background.transitionEasing
                onSelected: item => GlobalConfig.background.transitionEasing = item.value
            }

            // The curve itself, editable when "Custom curve" is picked and shown read-only
            // otherwise so you can see what a preset or token actually does.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                visible: root.transitionsEnabled && root.easingPoints.length >= 6
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.largeIncreased

                    BezierCanvas {
                        canvasSize: 150
                        controlPoints: root.easingPoints
                        interactive: root.easingIsCustom
                        showHandles: root.easingIsCustom
                        onPointsEdited: points => GlobalConfig.background.transitionCurve = points
                    }

                    EasingPreview {
                        Layout.fillWidth: true
                        controlPoints: root.easingPoints
                        duration: Config.background.transitionDuration
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: Bezier.overshoots(root.easingPoints)
                    text: qsTr("This curve overshoots past the end value. Fade and zoom transitions may flash at the peak.")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3error
                    wrapMode: Text.WordWrap
                }
            }

            SelectRow {
                first: true
                Layout.fillWidth: true
                visible: root.transitionsEnabled

                label: qsTr("When interrupted")
                subtext: qsTr("What happens if the wallpaper changes mid-transition")
                menuItems: root.transitionInterruptItems
                active: root.transitionInterruptItems[Math.max(0, root.transitionInterruptValues.indexOf(Config.background.transitionInterrupt))]
                onSelected: item => GlobalConfig.background.transitionInterrupt = root.transitionInterruptValues[root.transitionInterruptItems.indexOf(item)]
            }

            SelectRow {
                last: true
                Layout.fillWidth: true
                visible: root.transitionsEnabled

                label: qsTr("Replay with")
                subtext: qsTr("Which transition plays after an interruption")
                menuItems: root.transitionInterruptReplayItems
                active: root.transitionInterruptReplayItems[Math.max(0, root.transitionInterruptReplayValues.indexOf(Config.background.transitionInterruptReplay))]
                onSelected: item => GlobalConfig.background.transitionInterruptReplay = root.transitionInterruptReplayValues[root.transitionInterruptReplayItems.indexOf(item)]
            }
        }

        SettingsSection {
            title: qsTr("Appearance")

            ToggleRow {
                first: true
                Layout.fillWidth: true

                text: qsTr("Transparency")
                subtext: qsTr("Adjust opacity for surfaces and layers")
                checked: Colours.transparency.enabled
                onToggled: GlobalConfig.appearance.transparency.enabled = checked
            }

            SliderRow {
                Layout.fillWidth: true
                visible: Colours.transparency.enabled

                icon: "opacity"
                label: qsTr("Base")
                valueLabel: Math.round(value * 100) + "%"
                value: Colours.transparency.base
                onMoved: v => GlobalConfig.appearance.transparency.base = v
            }

            SliderRow {
                Layout.fillWidth: true
                visible: Colours.transparency.enabled

                icon: "layers"
                label: qsTr("Layers")
                valueLabel: Math.round(value * 100) + "%"
                value: Colours.transparency.layers
                onMoved: v => GlobalConfig.appearance.transparency.layers = v
            }

            ToggleRow {
                Layout.fillWidth: true

                last: true
                text: qsTr("Dark theme")
                checked: !Colours.light
                onToggled: {
                    Colours.setMode(checked ? "dark" : "light");
                    GlobalConfig.services.modeOverride = checked ? "dark" : "light";
                }
            }
        }

        Variants {
            id: easingVariants

            model: root.easingOptions

            MenuItem {
                required property var modelData

                readonly property string value: modelData.value

                text: modelData.label
            }
        }

        Item {
            DirDialog {
                id: dirDialog

                title: qsTr("Select wallpaper directory")
                onAccepted: path => {
                    const dirs = [...Wallpapers.wallpaperDirs, path];
                    Wallpapers.setWallpaperDirs(dirs);
                }
            }

        }
    }
}
