pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    property string source: ""
    property alias text: label.text

    property alias radius: imgWrapper.radius

    property alias imgHeight: imgWrapper.implicitHeight

    property bool fillLabel: true
    property bool highlighted
    readonly property bool video: Images.isValidVideoByName(source)
    readonly property bool videoThumbnailFailed: video && Wallpapers.videoFrames[source] === ""

    signal clicked

    onSourceChanged: {
        if (source && Images.isValidVideoByName(source))
            Wallpapers.ensureVideoFrame(source);
    }

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imgWrapper

            Layout.fillWidth: true
            implicitHeight: width
            radius: Tokens.rounding.largeIncreased
            color: Colours.tPalette.m3surfaceContainer

            Loader {
                anchors.centerIn: parent

                opacity: root.videoThumbnailFailed || img.status === Image.Ready ? 0 : 1
                active: opacity > 0

                sourceComponent: StyledRect {
                    implicitWidth: loadingIndicator.implicitSize + Tokens.padding.large * 2
                    implicitHeight: loadingIndicator.implicitSize + Tokens.padding.large * 2

                    color: Colours.palette.m3primaryContainer
                    radius: Tokens.rounding.full

                    LoadingIndicator {
                        id: loadingIndicator

                        anchors.centerIn: parent
                        containsIcon: true
                        implicitSize: Math.min(imgWrapper.width, imgWrapper.height) * 0.3
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.videoThumbnailFailed
                text: "movie"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
            }

            Image {
                id: img

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: {
                    if (!root.source)
                        return "";
                    if (Images.isValidVideoByName(root.source)) {
                        Wallpapers.videoFrames;
                        return Wallpapers.thumbnailFor(root.source);
                    }
                    return root.source;
                }
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            // Marks the applied wallpaper. An overlay rather than a border because
            // StyledClippingRect is a ClippingRectangle, which has no border of its own.
            Rectangle {
                anchors.fill: parent
                visible: root.highlighted
                color: "transparent"
                radius: imgWrapper.radius
                border.width: 3
                border.color: Colours.palette.m3primary
            }
        }

        StyledText {
            id: label

            Layout.bottomMargin: Tokens.padding.small
            Layout.fillWidth: true
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    StateLayer {
        anchors.bottomMargin: root.fillLabel ? 0 : layout.implicitHeight - imgWrapper.implicitHeight
        onClicked: root.clicked()
    }
}
