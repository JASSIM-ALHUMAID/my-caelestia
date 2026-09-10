import QtQuick
import Quickshell
import qs.components.images
import qs.services

CachingImage {
    readonly property bool ready: status === Image.Ready

    fillMode: Wallpapers.imageFillMode
    sourceSize: {
        if (fillMode === Image.Pad || fillMode === Image.Tile)
            return undefined; // native decode size — screen-sized decode would defeat Pad/Tile
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
}
