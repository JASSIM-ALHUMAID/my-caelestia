pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.audio
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.desktop
import qs.modules.nexus.pages.panels
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.pages.lockscreen
import qs.modules.nexus.pages.panels.taskbar
import qs.modules.nexus.pages.panels.utilities
import qs.modules.nexus.pages.keybinds
import qs.modules.nexus.pages.battery
import qs.modules.nexus.pages.animation
import qs.modules.nexus.pages.hyprland

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            // Wallpaper & style
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
                Component {
                    WallpaperSelect {}
                }
                Component {
                    ColourSelect {}
                }
            }
        },

        Component {
            // Desktop
            StackPage {
                Component {
                    DesktopPage {}
                }
                Component {
                    DesktopClockPage {}
                }
                Component {
                    VisualiserPage {}
                }
                Component {
                    DesktopBatteryPage {}
                }
            }
        },

        Component {
            // Animation
            StackPage {
                Component {
                    AnimationPage {}
                }
                Component {
                    BezierCurveEditor {}
                }
            }
        },

        Component {
            // Screensaver
            StackPage {
                Component {
                    ScreensaverPage {}
                }
            }
        },

        // Connectivity
        Component {
            // Network
            StackPage {
                Component {
                    NetworkPage {}
                }
            }
        },
        Component {
            // Bluetooth
            StackPage {
                Component {
                    BluetoothPage {}
                }
                Component {
                    BtDeviceInfo {}
                }
                Component {
                    BluetoothPairing {}
                }
            }
        },
        Component {
            // Audio
            StackPage {
                Component {
                    AudioPage {}
                }
                Component {
                    AppVolumes {}
                }
            }
        },

        // System
        Component {
            PlaceholderComp {}
        },
        Component {
            PlaceholderComp {}
        },
        Component {
            // Power & screen
            StackPage {
                Component {
                    PowerAndScreen {}
                }
            }
        },
        Component {
            // Battery
            StackPage {
                Component {
                    BatteryPage {}
                }
            }
        },
        Component {
            // Keybindings. The index comments match `keybindsSubPages` below.
            StackPage {
                Component {
                    // 0
                    KeybindingsPage {}
                }
                Component {
                    // 1
                    BindingEditor {}
                }
            }
        },

        // Shell
        Component {
            // Panels. The index comments below are what `panelsSubPages` maps to — keep them
            // in sync when adding a page, and prefer appending over inserting.
            StackPage {
                Component {
                    // 0
                    PanelsPage {}
                }
                Component {
                    // 1
                    DashboardPanel {}
                }
                Component {
                    // 2
                    TaskbarPanel {}
                }
                Component {
                    // 3
                    LauncherPanel {}
                }
                Component {
                    // 4
                    SidebarPanel {}
                }
                Component {
                    // 5
                    DockPanel {}
                }
                Component {
                    // 6
                    OsdPanel {}
                }
                Component {
                    // 7
                    SessionPanel {}
                }
                Component {
                    // 8
                    NotificationsPage {}
                }
                Component {
                    // 9
                    EdgeConflictPage {}
                }

                // Taskbar component sub-pages
                Component {
                    // 10
                    BarWorkspaces {}
                }
                Component {
                    // 11
                    BarActiveWindow {}
                }
                Component {
                    // 12
                    BarTray {}
                }
                Component {
                    // 13
                    BarStatusIcons {}
                }
                Component {
                    // 14
                    BarClock {}
                }
                Component {
                    // 15
                    BarDock {}
                }
                Component {
                    // 16
                    BarVisualiser {}
                }
                Component {
                    // 17
                    BarEntriesEditor {}
                }

                Component {
                    // 18
                    UtilitiesPanel {}
                }
                Component {
                    // 19
                    QuickTogglesEditor {}
                }
                Component {
                    // 20
                    SoundsEditor {}
                }
            }
        },
        Component {
            // Lock screen
            StackPage {
                Component {
                    LockScreenPage {}
                }
                Component {
                    // Left column
                    LockScreenColumnEditor {
                        column: "left"
                    }
                }
                Component {
                    // Center column
                    LockScreenColumnEditor {
                        column: "center"
                    }
                }
                Component {
                    // Right column
                    LockScreenColumnEditor {
                        column: "right"
                    }
                }
            }
        },
        Component {
            // Services
            StackPage {
                Component {
                    ServicesPage {}
                }
            }
        },
        Component {
            // Hyprland. The index comments match `hyprlandSubPages` below.
            StackPage {
                Component {
                    // 0
                    HyprlandPage {}
                }
                Component {
                    // 1
                    HyprlandVarsPage {}
                }
                Component {
                    // 2
                    HyprlandConfigPage {}
                }
                Component {
                    // 3
                    HyprlandBindsPage {}
                }
            }
        },
        Component {
            // Language & region
            StackPage {
                Component {
                    LanguageAndRegion {}
                }
            }
        },

        // About
        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
            }
        }
    ]

    // Indices into pageComps above. Positional, like panelsSubPages below — inserting a
    // Component renumbers everything after it. DesktopBattery.qml used to keep its own copy
    // of this map and it silently drifted two entries out of date.
    readonly property var topLevelPages: ({
        appearance: 0,
        desktop: 1,
        animation: 2,
        network: 4,
        devices: 5,
        audio: 6,
        updates: 7,
        plugins: 8,
        power: 9,
        battery: 10,
        keybindings: 11,
        panels: 12,
        lockscreen: 13,
        services: 14,
        hyprland: 15,
        language: 16,
        about: 17,
        screensaver: 3
    })

    // Sub-page indices into the Panels StackPage above. These are positional — inserting a
    // Component renumbers everything after it — so callers go through this map rather than
    // hardcoding integers. Two insertions have already silently broken navigation this way.
    readonly property var panelsSubPages: ({
        dashboard: 1,
        taskbar: 2,
        launcher: 3,
        sidebar: 4,
        dock: 5,
        osd: 6,
        session: 7,
        notifications: 8,
        edgeConflict: 9,
        barWorkspaces: 10,
        barActiveWindow: 11,
        barTray: 12,
        barStatusIcons: 13,
        barClock: 14,
        barDock: 15,
        barVisualiser: 16,
        barEntries: 17,
        utilities: 18,
        quickToggles: 19,
        sounds: 20
    })

    // Sub-page indices into the Keybindings StackPage above. Positional, like panelsSubPages.
    readonly property var keybindsSubPages: ({
        editor: 1
    })

    // Sub-page indices into the Hyprland StackPage above. Positional, like panelsSubPages.
    readonly property var hyprlandSubPages: ({
        vars: 1,
        config: 2,
        binds: 3
    })

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    component PlaceholderComp: Item {
        property NexusState nState // To avoid the warning from non-existent property

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Page under construction")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("This page will be available in a future update.")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }
        }
    }
}
