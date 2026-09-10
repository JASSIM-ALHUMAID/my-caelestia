pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property string quoteText: ""
    property string quoteAuthor: ""

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    FileView {
        path: Quickshell.shellPath("assets/quotes.json")
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const index = Math.floor(Math.random() * data.length);
                root.quoteText = data[index].text;
                root.quoteAuthor = data[index].author ?? "";
            } catch (e) {
                console.warn("Quote: failed to load quotes.json:", e);
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "format_quote"
            color: Colours.palette.m3outlineVariant
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            Layout.fillWidth: true
            text: root.quoteText
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.large
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.quoteAuthor.length > 0
            text: "~ " + root.quoteAuthor
            color: Colours.palette.m3primary
            font: Tokens.font.title.small
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
