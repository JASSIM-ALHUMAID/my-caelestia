import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    readonly property real uiScale: Math.max(0.78, Math.min(1.45, height / 900))
    readonly property string command: "caelestia screensaver --status"
    readonly property list<string> statusLines: [
        `USER       ${SysInfo.user || "unknown"}@${SysInfo.hostname || "localhost"}`,
        `SYSTEM     ${SysInfo.osPrettyName || SysInfo.osName || "Linux"}`,
        `KERNEL     ${SysInfo.kernel || "loading..."}`,
        `UPTIME     ${SysInfo.uptime || "loading..."}`,
        `SESSION    ${SysInfo.wm || "Wayland"}`,
        "POWER      IDLE DISPLAY // SYSTEM NOMINAL"
    ]

    Rectangle {
        anchors.fill: parent

        color: "#020b05"

        gradient: Gradient {
            GradientStop { position: 0; color: "#05150a" }
            GradientStop { position: 0.55; color: "#020b05" }
            GradientStop { position: 1; color: "#010402" }
        }
    }

    Canvas {
        id: scanlines

        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "rgba(0,0,0,0.16)";
            const pitch = Math.max(3, Math.round(4 * root.uiScale));
            for (let y = 0; y < height; y += pitch)
                ctx.fillRect(0, y, width, 1);
        }
    }

    Rectangle {
        id: terminalFrame

        anchors.centerIn: parent
        width: Math.min(root.width * 0.82, 900 * root.uiScale)
        height: Math.min(root.height * 0.76, 610 * root.uiScale)

        color: "#051108"
        border.width: Math.max(1, Math.round(root.uiScale))
        border.color: "#2af47f"
        radius: 8 * root.uiScale
        opacity: 0.94

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 38 * root.uiScale

            color: "#0a2a15"
            radius: terminalFrame.radius

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius

                color: parent.color
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.uiScale
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7 * root.uiScale

                Repeater {
                    model: ["#ff6b6b", "#ffd166", "#43f28b"]

                    Rectangle {
                        required property string modelData

                        width: 9 * root.uiScale
                        height: width
                        radius: width / 2
                        color: modelData
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent

                text: "CAELESTIA // IDLE TERMINAL"
                color: "#8dffb9"
                font: Tokens.font.mono.builders.medium.scale(root.uiScale).weight(Font.DemiBold).build()
            }
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 34 * root.uiScale
            anchors.rightMargin: 34 * root.uiScale
            anchors.topMargin: 62 * root.uiScale
            anchors.bottomMargin: 28 * root.uiScale
            spacing: 10 * root.uiScale

            StyledText {
                Layout.fillWidth: true

                text: Time.format("HH:mm:ss")
                color: "#baffd1"
                font: Tokens.font.mono.builders.large.scale(root.uiScale * 2.25).weight(Font.Light).build()
            }

            StyledText {
                Layout.fillWidth: true

                text: Time.format("dddd, yyyy-MM-dd")
                color: "#4fe98a"
                font: Tokens.font.mono.builders.medium.scale(root.uiScale).build()
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 14 * root.uiScale
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: `> ${root.command}`
                    color: "#8dffb9"
                    font: Tokens.font.mono.builders.medium.scale(root.uiScale).build()
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter

                    width: 8 * root.uiScale
                    height: 18 * root.uiScale
                    color: "#9affbf"

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite

                        NumberAnimation { to: 0; duration: 480 }
                        NumberAnimation { to: 1; duration: 480 }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4 * root.uiScale
            }

            Repeater {
                model: root.statusLines

                StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    text: `[OK]  ${modelData}`
                    color: "#54d982"
                    font: Tokens.font.mono.builders.small.scale(root.uiScale).build()
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            StyledText {
                Layout.fillWidth: true

                text: "Listening for input -- move pointer or press any key to resume"
                color: "#2f9b59"
                font: Tokens.font.mono.builders.small.scale(root.uiScale * 0.9).build()
            }
        }

        Rectangle {
            x: 1
            width: parent.width - 2
            height: Math.max(1, 2 * root.uiScale)
            color: "#55ff9a"
            opacity: 0.12

            NumberAnimation on y {
                from: terminalFrame.height * 0.06
                to: terminalFrame.height * 0.96
                duration: 5200
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
            }
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        PauseAnimation { duration: 3600 }
        NumberAnimation { target: terminalFrame; property: "opacity"; to: 0.88; duration: 45 }
        NumberAnimation { target: terminalFrame; property: "opacity"; to: 0.94; duration: 85 }
    }
}
