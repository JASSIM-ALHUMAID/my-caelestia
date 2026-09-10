import QtQuick
import Quickshell
import qs.services

AnimatedImage {
    id: root

    required property string path
    readonly property bool ready: status === Image.Ready

    source: path
    asynchronous: true
    fillMode: Wallpapers.imageFillMode
    sourceSize: {
        if (fillMode === Image.Pad || fillMode === Image.Tile)
            return undefined;
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
    paused: !Wallpapers.animationsActiveOn((QsWindow.window as QsWindow)?.screen ?? null)
}
