import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common
import "../../../../services/HyprSchema.js" as Schema

// Hyprland config -- the settings that live in hypr-user.lua rather than variables.lua:
// layout, input, animations, gesture tuning. They're stored as `cfg*` keys in hypr-vars.lua
// and read back by hypr-user.lua, which is sourced last and so wins over hyprland/*.lua.
PageBase {
    id: root

    title: qsTr("Config")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        HyprSectionList {
            sections: Schema.CFG_SECTIONS
        }
    }
}
