pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            barLeft: content.barLeft
            barRight: content.barRight
            barTop: content.barTop
            barBottom: content.barBottom
            dockReserves: content.dockReserves
            dockPosition: content.dockPosition
            dockThickness: content.dockThickness
        }

        ContentWindow {
            id: content

            screen: scope.modelData
        }
    }
}
