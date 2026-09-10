pragma ComponentBehavior: Bound

import "../components" as BarEntries
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

// The entries the bar couldn't fit, in popout mode. Only self-contained entries end up here
// (see BarOverflowState.movableIds) — anything with a hover-routed popout of its own stays in
// the bar and gets capped instead, since a popout can't host another popout.
//
// The entries are re-instantiated rather than reparented: Bar.qml's hit-testing walks its own
// children, so moving live items out of it would break checkPopout for everything else.
GridLayout {
    id: root

    required property PopoutState popouts

    // Lay the entries out across the bar, not along it
    flow: root.popouts.overflowVertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columns: root.popouts.overflowVertical ? -1 : 1
    rows: root.popouts.overflowVertical ? 1 : -1
    rowSpacing: Tokens.spacing.large
    columnSpacing: Tokens.spacing.large

    Repeater {
        model: root.popouts.overflowEntries

        Loader {
            id: entry

            required property var modelData

            Layout.alignment: Qt.AlignCenter

            sourceComponent: {
                switch (modelData?.id) {
                case "logo":
                    return logoComp;
                case "clock":
                    return clockComp;
                case "power":
                    return powerComp;
                case "barPin":
                    return barPinComp;
                case "layoutSelector":
                    return layoutSelectorComp;
                case "timer":
                    return timerComp;
                case "wallpaperAdvance":
                    return wallpaperAdvanceComp;
                default:
                    return null;
                }
            }

            Component {
                id: logoComp

                BarEntries.OsIcon {
                    variant: entry.modelData?.variant ?? "auto"
                }
            }

            Component {
                id: clockComp

                BarEntries.Clock {
                    barConfig: root.popouts.overflowBarConfig
                    // Popouts run across the bar, so the clock reads the other way round
                    vertical: !root.popouts.overflowVertical
                }
            }

            Component {
                id: powerComp

                BarEntries.Power {
                    visibilities: root.popouts.overflowVisibilities as DrawerVisibilities
                }
            }

            Component {
                id: barPinComp

                BarEntries.BarPin {
                    barConfig: root.popouts.overflowBarConfig
                    edge: root.popouts.overflowEdge
                }
            }

            Component {
                id: layoutSelectorComp

                BarEntries.LayoutSelector {}
            }

            Component {
                id: timerComp

                BarEntries.TimerEntry {
                    // Popouts run across the bar, so the timer reads the other way round
                    vertical: !root.popouts.overflowVertical
                }
            }

            Component {
                id: wallpaperAdvanceComp

                BarEntries.WallpaperAdvance {}
            }
        }
    }
}
