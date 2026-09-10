pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper barLeft
    required property Bar.BarWrapper barRight
    required property Bar.BarWrapper barTop
    required property Bar.BarWrapper barBottom

    required property bool dockReserves
    required property string dockPosition
    required property real dockThickness

    // Space a pinned dock claims on `edge`, stacked on top of whatever the bar or border
    // there already reserves — a dock sharing an edge with a bar sits beside it.
    function dockZone(edge: string): real {
        return root.dockReserves && root.dockPosition === edge ? root.dockThickness : 0;
    }

    // What the bar on `edge` claims before the dock is stacked on top. A floating bar normally
    // reserves nothing, but panels position off the bar's visual thickness (ContentWindow's
    // insetLeft/Top/...), so a pinned dock sharing the edge is still pushed inboard by it — and
    // reserving only the border there would tile windows underneath the dock.
    // `border` is passed in rather than read here: contentItem is a window property, in scope
    // inside the ExclusionZone items below but not on this Scope.
    function barZone(bar: Bar.BarWrapper, edge: string, border: real): real {
        if (!bar.present)
            return border;
        return dockZone(edge) > 0 ? bar.visualZone : bar.exclusiveZone;
    }

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.barZone(root.barLeft, "left", contentItem.Config.border.thickness) + root.dockZone("left")
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: root.barZone(root.barTop, "top", contentItem.Config.border.thickness) + root.dockZone("top")
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.barZone(root.barRight, "right", contentItem.Config.border.thickness) + root.dockZone("right")
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: root.barZone(root.barBottom, "bottom", contentItem.Config.border.thickness) + root.dockZone("bottom")
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
