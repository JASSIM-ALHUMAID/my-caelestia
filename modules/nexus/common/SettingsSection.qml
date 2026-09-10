import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls

// A CollapsibleSection with the nexus page conventions baked in: tinted
// background, spacing between consecutive sections, and an inner column whose
// spacing matches the pages' so ConnectedRect rows still read as one card.
CollapsibleSection {
    id: root

    property bool first // First section on the page — no top margin

    default property alias rows: rowColumn.data

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.spacing.small
    showBackground: true

    content: ColumnLayout {
        id: rowColumn

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2
    }
}
