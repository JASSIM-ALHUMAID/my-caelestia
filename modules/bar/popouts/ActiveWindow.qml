import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    // Optional: the dock reuses this card outside the bar's popout system, where there is
    // no PopoutState and nothing to detach into.
    property PopoutState popouts: null
    // Window to display; defaults to the active one so existing usage is unchanged.
    property var toplevel: Hypr.activeToplevel
    // Optional trailing action rendered at the end of the details row (e.g. pin/unpin button
    // for dock hover preview). Only used when popouts === null (dock reuse mode).
    property Component trailingAction: null

    implicitWidth: root.toplevel ? child.implicitWidth : -Tokens.padding.extraLargeIncreased
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.medium

            IconImage {
                id: icon

                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(root.toplevel?.lastIpcObject.class ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: root.toplevel?.title ?? ""
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.toplevel?.lastIpcObject.class ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                visible: root.popouts !== null
                implicitWidth: visible ? expandIcon.implicitHeight + Tokens.padding.small : 0
                implicitHeight: expandIcon.implicitHeight + Tokens.padding.small

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Tokens.rounding.large
                    onClicked: root.popouts?.detachRequested("winfo")
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    fontStyle: Tokens.font.icon.large
                }
            }

            Loader {
                active: root.popouts === null && root.trailingAction !== null
                sourceComponent: root.trailingAction

                Layout.alignment: Qt.AlignVCenter
            }
        }

        ClippingWrapperRectangle {
            color: "transparent"
            radius: Tokens.rounding.medium

            ScreencopyView {
                id: preview

                captureSource: root.toplevel?.wayland ?? null // qmllint disable unresolved-type
                live: visible

                constraintSize.width: Tokens.sizes.bar.windowPreviewSize
                constraintSize.height: Tokens.sizes.bar.windowPreviewSize
            }
        }
    }
}
