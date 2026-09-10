import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        Item {
            id: timeBlock

            Layout.alignment: Qt.AlignHCenter

            implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
            implicitHeight: hourMetrics.tightBoundingRect.height

            StyledText {
                id: hours

                y: -root.calcTopOff(hourMetrics)
                text: Time.hourStr
                color: Colours.palette.m3primary
                font: Tokens.font.headline.builders.large.scale(7).width(30).build()

                TextMetrics {
                    id: hourMetrics

                    text: hours.text
                    font: hours.font
                }
            }

            StyledText {
                id: minutes

                anchors.right: parent.right
                y: -root.calcTopOff(minuteMetrics)

                text: Time.minuteStr
                color: Colours.palette.m3secondary
                font: Tokens.font.headline.builders.large.scale(GlobalConfig.services.useTwelveHourClock ? 3.8 : 7).width(30).build()

                TextMetrics {
                    id: minuteMetrics

                    text: minutes.text
                    font: minutes.font
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter

            text: Qt.formatDate(Time.date, "dddd, MMMM d")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.title.large
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: content
            property: "opacity"
            from: 1.0
            to: 0.9
            duration: 2000
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: content
            property: "opacity"
            from: 0.9
            to: 1.0
            duration: 2000
            easing.type: Easing.InOutSine
        }
    }
}
