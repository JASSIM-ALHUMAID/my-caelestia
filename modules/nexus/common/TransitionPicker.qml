pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ConnectedRect {
    id: root

    readonly property var tiles: [
        { label: qsTr("Fade"), value: "fade" },
        { label: qsTr("Wipe"), value: "wipe" },
        { label: qsTr("Grow"), value: "grow" },
        { label: qsTr("Outer"), value: "outer" },
        { label: qsTr("Wave"), value: "wave" },
        { label: qsTr("Diagonal"), value: "diagonal" },
        { label: qsTr("Stripes"), value: "stripes" },
        { label: qsTr("Zoom"), value: "zoom" },
        { label: qsTr("Honeycomb"), value: "honeycomb" },
        { label: qsTr("Iris"), value: "iris" },
        { label: qsTr("Pixelate"), value: "pixelate" }
    ]

    // Direction suffixes per directional tile; a bare value means random
    readonly property var directionalTiles: ({
            "wipe": ["left", "right", "top", "bottom"],
            "grow": ["left", "right", "top", "bottom"],
            "outer": ["left", "right", "top", "bottom"],
            "wave": ["left", "right", "top", "bottom", "tl", "tr", "bl", "br"],
            "stripes": ["left", "right", "top", "bottom"],
            "diagonal": ["tl", "tr", "bl", "br"]
        })

    readonly property list<string> selectedParts: {
        const t = Config.background.transitionType;
        if (t === "none" || t === "")
            return [];
        return t.split(",");
    }

    readonly property string summary: {
        if (selectedParts.length === 0)
            return qsTr("Animation when switching wallpapers");
        if (selectedParts.length === 1)
            return qsTr("Plays %1").arg(labelFor(selectedParts[0]));
        return qsTr("Plays one at random on each switch");
    }

    function baseOf(type: string): string {
        const i = type.indexOf("-");
        if (i < 0)
            return type;
        const b = type.slice(0, i);
        return (directionalTiles[b] ?? null) !== null ? b : type;
    }

    function variantsOf(value: string): var {
        return (directionalTiles[value] ?? []).map(s => value + "-" + s);
    }

    function labelFor(value: string): string {
        const base = baseOf(value);
        const tile = tiles.find(t => t.value === base);
        if (!tile)
            return value;
        if (value === base)
            return tile.label;
        const names = {
            "left": qsTr("left"),
            "right": qsTr("right"),
            "top": qsTr("top"),
            "bottom": qsTr("bottom"),
            "tl": qsTr("top-left"),
            "tr": qsTr("top-right"),
            "bl": qsTr("bottom-left"),
            "br": qsTr("bottom-right")
        };
        return "%1 %2".arg(tile.label).arg(names[value.slice(base.length + 1)] ?? "");
    }

    function isSelected(value: string): bool {
        return selectedParts.includes(value) || variantsOf(value).some(v => selectedParts.includes(v));
    }

    function previewTypeFor(value: string): string {
        if (selectedParts.includes(value))
            return value;
        return variantsOf(value).find(v => selectedParts.includes(v)) ?? value;
    }

    function apply(parts: var): void {
        GlobalConfig.background.transitionType = parts.length > 0 ? parts.join(",") : "none";
    }

    function toggle(value: string): void {
        let parts = [...selectedParts];
        if (isSelected(value)) {
            const all = [value, ...variantsOf(value)];
            parts = parts.filter(p => !all.includes(p));
        } else {
            parts.push(value);
        }
        apply(parts);
    }

    function toggleVariant(value: string, suffix: string): void {
        const v = value + "-" + suffix;
        let parts = [...selectedParts].filter(p => p !== value);
        if (parts.includes(v))
            parts = parts.filter(p => p !== v);
        else
            parts.push(v);
        apply(parts);
    }

    function toggleShuffle(value: string): void {
        let parts = [...selectedParts];
        if (parts.includes(value)) {
            parts = parts.filter(p => p !== value);
        } else {
            parts = parts.filter(p => !variantsOf(value).includes(p));
            parts.push(value);
        }
        apply(parts);
    }

    function selectAll(): void {
        apply(tiles.map(t => t.value));
    }

    function adjustWaveCount(delta: int): void {
        GlobalConfig.background.transitionWaveCount = Math.max(0, Math.min(8, Config.background.transitionWaveCount + delta));
    }

    function adjustStripeCount(delta: int): void {
        let v = Config.background.transitionStripeCount + delta;
        if (v === 1)
            v = delta > 0 ? 2 : 0;
        GlobalConfig.background.transitionStripeCount = Math.max(0, Math.min(24, v));
    }

    function adjustHoneycombSize(delta: int): void {
        GlobalConfig.background.transitionHoneycombSize = Math.max(0, Math.min(3, Config.background.transitionHoneycombSize + delta));
    }

    implicitHeight: column.implicitHeight + Tokens.padding.largeIncreased * 2

    // Tile previews play on the current wallpaper when a thumbnail is available
    Image {
        id: wallSource

        width: 320
        height: 200
        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(320, 200)

        source: {
            Wallpapers.videoFrames;
            return Wallpapers.thumbnailFor(Wallpapers.current);
        }
    }

    Column {
        id: column

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        Item {
            width: parent.width
            implicitHeight: headerBtns.implicitHeight

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Effects")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            Row {
                id: headerBtns

                anchors.right: parent.right
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    text: qsTr("All")
                    type: TextButton.Text
                    onClicked: root.selectAll()
                }

                TextButton {
                    text: qsTr("Clear")
                    type: TextButton.Text
                    onClicked: root.apply([])
                }
            }
        }

        Grid {
            id: grid

            readonly property real cellWidth: (width - spacing * (columns - 1)) / columns

            width: parent.width
            columns: 2
            spacing: Tokens.spacing.small

            Repeater {
                model: root.tiles

                Column {
                    id: tile

                    required property var modelData
                    readonly property bool selected: root.isSelected(modelData.value)
                    readonly property bool directional: (root.directionalTiles[modelData.value] ?? null) !== null

                    width: grid.cellWidth
                    spacing: Tokens.spacing.extraSmall

                    StyledClippingRect {
                        id: previewRect

                        width: parent.width
                        height: Math.round(width * 0.6)
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainerHigh

                        TransitionPreview {
                            anchors.fill: parent
                            type: root.previewTypeFor(tile.modelData.value)
                            playing: hover.hovered

                            Binding on fromItem {
                                when: wallSource.status === Image.Ready
                                value: wallSource
                            }
                        }

                        StateLayer {
                            radius: previewRect.radius
                            onClicked: root.toggle(tile.modelData.value)
                        }

                        Loader {
                            anchors.fill: parent
                            active: tile.selected && (tile.directional || ["stripes", "honeycomb"].includes(tile.modelData.value))

                            sourceComponent: Item {
                                id: overlay

                                readonly property bool corners: tile.modelData.value === "diagonal"
                                readonly property bool wave: tile.modelData.value === "wave"
                                readonly property bool stripes: tile.modelData.value === "stripes"
                                readonly property bool honeycomb: tile.modelData.value === "honeycomb"

                                DirArrow {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Tokens.padding.extraSmall
                                    anchors.verticalCenter: overlay.corners ? undefined : parent.verticalCenter
                                    anchors.top: overlay.corners ? parent.top : undefined
                                    anchors.topMargin: overlay.corners ? Tokens.padding.extraSmall : 0
                                    visible: tile.directional
                                    tileValue: tile.modelData.value
                                    suffix: overlay.corners ? "tl" : "left"
                                    arrowIcon: overlay.corners ? "north_west" : "arrow_back"
                                }

                                DirArrow {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Tokens.padding.extraSmall
                                    anchors.verticalCenter: overlay.corners ? undefined : parent.verticalCenter
                                    anchors.top: overlay.corners ? parent.top : undefined
                                    anchors.topMargin: overlay.corners ? Tokens.padding.extraSmall : 0
                                    visible: tile.directional
                                    tileValue: tile.modelData.value
                                    suffix: overlay.corners ? "tr" : "right"
                                    arrowIcon: overlay.corners ? "north_east" : "arrow_forward"
                                }

                                DirArrow {
                                    anchors.top: overlay.corners ? undefined : parent.top
                                    anchors.topMargin: overlay.corners ? 0 : Tokens.padding.extraSmall
                                    anchors.horizontalCenter: overlay.corners ? undefined : parent.horizontalCenter
                                    anchors.left: overlay.corners ? parent.left : undefined
                                    anchors.leftMargin: overlay.corners ? Tokens.padding.extraSmall : 0
                                    anchors.bottom: overlay.corners ? parent.bottom : undefined
                                    anchors.bottomMargin: overlay.corners ? Tokens.padding.extraSmall : 0
                                    visible: tile.directional
                                    tileValue: tile.modelData.value
                                    suffix: overlay.corners ? "bl" : "top"
                                    arrowIcon: overlay.corners ? "south_west" : "arrow_upward"
                                }

                                DirArrow {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Tokens.padding.extraSmall
                                    anchors.horizontalCenter: overlay.corners ? undefined : parent.horizontalCenter
                                    anchors.right: overlay.corners ? parent.right : undefined
                                    anchors.rightMargin: overlay.corners ? Tokens.padding.extraSmall : 0
                                    visible: tile.directional
                                    tileValue: tile.modelData.value
                                    suffix: overlay.corners ? "br" : "bottom"
                                    arrowIcon: overlay.corners ? "south_east" : "arrow_downward"
                                }

                                DirArrow {
                                    anchors.centerIn: parent
                                    visible: tile.directional
                                    tileValue: tile.modelData.value
                                    suffix: ""
                                    arrowIcon: "shuffle"
                                }

                                CountButton {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: Tokens.padding.extraSmall
                                    visible: overlay.wave || overlay.stripes || overlay.honeycomb
                                    target: overlay.wave ? "wave" : overlay.stripes ? "stripes" : "honeycomb"
                                    btnIcon: "remove"
                                    delta: -1
                                }

                                CountButton {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: Tokens.padding.extraSmall
                                    visible: overlay.wave || overlay.stripes || overlay.honeycomb
                                    target: overlay.wave ? "wave" : overlay.stripes ? "stripes" : "honeycomb"
                                    btnIcon: "add"
                                    delta: 1
                                }

                                StyledRect {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.margins: Tokens.padding.extraSmall
                                    visible: overlay.wave || overlay.stripes || overlay.honeycomb
                                    implicitWidth: Math.max(26, countLabel.implicitWidth + Tokens.padding.small * 2)
                                    implicitHeight: 22
                                    radius: Tokens.rounding.full
                                    color: Colours.tPalette.m3surfaceContainer

                                    StyledText {
                                        id: countLabel

                                        anchors.centerIn: parent
                                        visible: overlay.honeycomb || (overlay.wave ? Config.background.transitionWaveCount > 0 : Config.background.transitionStripeCount > 0)
                                        text: {
                                            if (overlay.honeycomb)
                                                return ["XS", "S", "M", "L"][Config.background.transitionHoneycombSize];
                                            return overlay.wave ? Config.background.transitionWaveCount : Config.background.transitionStripeCount;
                                        }
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.medium
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: !overlay.honeycomb && !countLabel.visible
                                        text: "shuffle"
                                        color: Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.builders.small.scale(0.8).build()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: previewRect.radius
                            border.width: tile.selected ? 2 : 0
                            border.color: Colours.palette.m3primary
                        }

                        HoverHandler {
                            id: hover
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tile.selected
                            text: "check"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.builders.small.scale(0.75).build()
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tile.modelData.label
                            color: tile.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                        }
                    }
                }
            }
        }
    }

    component DirArrow: StyledRect {
        id: arrow

        required property string tileValue
        required property string suffix
        required property string arrowIcon
        readonly property bool active: root.selectedParts.includes(suffix === "" ? tileValue : tileValue + "-" + suffix)

        implicitWidth: 22
        implicitHeight: 22
        radius: Tokens.rounding.full
        color: active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

        MaterialIcon {
            anchors.centerIn: parent
            text: arrow.arrowIcon
            color: arrow.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.small.scale(0.8).build()
        }

        StateLayer {
            radius: parent.radius
            color: arrow.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: arrow.suffix === "" ? root.toggleShuffle(arrow.tileValue) : root.toggleVariant(arrow.tileValue, arrow.suffix)
        }
    }

    component CountButton: StyledRect {
        id: countBtn

        required property string btnIcon
        required property int delta
        required property string target

        implicitWidth: 22
        implicitHeight: 22
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer

        MaterialIcon {
            anchors.centerIn: parent
            text: countBtn.btnIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.small.scale(0.8).build()
        }

        StateLayer {
            radius: parent.radius
            onClicked: {
                if (countBtn.target === "wave")
                    root.adjustWaveCount(countBtn.delta);
                else if (countBtn.target === "stripes")
                    root.adjustStripeCount(countBtn.delta);
                else
                    root.adjustHoneycombSize(countBtn.delta);
            }
        }
    }
}
