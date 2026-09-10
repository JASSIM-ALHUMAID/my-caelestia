import QtQuick
import qs.services

Item {
    id: root

    readonly property url wallpaperSource: Wallpapers.currentAnalysable || Wallpapers.fallback
    readonly property real blockSize: Math.max(14, Math.min(42, Math.min(width, height) * 0.035))

    property real elapsed: 0

    onWidthChanged: Qt.callLater(() => sourceTexture.scheduleUpdate())
    onHeightChanged: Qt.callLater(() => sourceTexture.scheduleUpdate())

    Rectangle {
        anchors.fill: parent

        color: "#04060a"
    }

    Image {
        id: wallpaper

        anchors.fill: parent

        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
    }

    ShaderEffectSource {
        id: sourceTexture

        sourceItem: wallpaper
        textureSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        hideSource: true
        live: false
        visible: false
    }

    ShaderEffect {
        readonly property variant sourceTex: sourceTexture
        readonly property real time: root.elapsed
        readonly property real pixelSize: root.blockSize
        readonly property real aspectRatio: height > 0 ? width / height : 1
        readonly property vector4d tintColor: Qt.vector4d(0.74, 0.94, 1.0, 1.0)

        anchors.fill: parent
        blending: false
        fragmentShader: Qt.resolvedUrl("shaders/mosaic.frag.qsb")
    }

    Connections {
        function onStatusChanged(): void {
            if (wallpaper.status === Image.Ready)
                sourceTexture.scheduleUpdate();
        }

        target: wallpaper
    }

    Timer {
        interval: 33
        repeat: true
        running: true

        onTriggered: root.elapsed += 0.033
    }
}
