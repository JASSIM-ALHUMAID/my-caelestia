pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities
    // Computed once, in ContentList, from the same search prefixes that decide list-vs-grid —
    // one source of truth instead of two places parsing the same text independently.
    required property string listState

    model: ScriptModel {
        id: model

        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    // The delegate decides its own height now — app rows grow with iconScale, action and calc
    // rows don't — so measure the real one instead of assuming the token.
    readonly property int rowHeight: currentItem?.implicitHeight ?? Tokens.sizes.launcher.itemHeight

    implicitHeight: state === "emoji" ? 400 : (rowHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    // AppList has no "wallpapers" state — WallpaperList handles that one — but it stays loaded
    // through the cross-fade into it, and an unknown state name would revert every
    // PropertyChanges above and blank the list mid-animation. "actions" is what the old
    // in-AppList state machine resolved the wallpaper prefix to, so the fade looks unchanged.
    state: listState === "wallpapers" ? "actions" : listState

    function incrementCurrentIndex(): void {
        if (state === "emoji" && currentItem) {
            currentItem.incrementCurrentIndex();
        } else {
            currentIndex = (currentIndex + 1) % count;
        }
    }

    function decrementCurrentIndex(): void {
        if (state === "emoji" && currentItem) {
            currentItem.decrementCurrentIndex();
        } else {
            currentIndex = (currentIndex - 1 + count) % count;
        }
    }

    function incrementCurrentIndexHorizontal(): void {
        if (state === "emoji" && currentItem)
            currentItem.incrementCurrentIndexHorizontal();
    }

    function decrementCurrentIndexHorizontal(): void {
        if (state === "emoji" && currentItem)
            currentItem.decrementCurrentIndexHorizontal();
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
        else if (state === "emoji")
            Emojis.load();
        else if (state === "clipboard")
            Clipboard.load();
    }

    states: [
        State {
            name: "apps"

            PropertyChanges {
                model.values: Apps.search(search.text)
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                model.values: Actions.query(search.text)
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                model.values: [0]
                root.delegate: calcItem
            }
        },
        State {
            name: "timer"

            PropertyChanges {
                model.values: [0]
                root.delegate: timerItem
            }
        },
        State {
            name: "run"

            PropertyChanges {
                model.values: [0]
                root.delegate: runItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                model.values: Schemes.query(search.text)
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                model.values: M3Variants.query(search.text)
                root.delegate: variantItem
            }
        },
        State {
            name: "emoji"

            PropertyChanges {
                model.values: [0]
                root.delegate: emojiItem
            }
        },
        State {
            name: "clipboard"

            PropertyChanges {
                model.values: Clipboard.query(search.text)
                root.delegate: clipboardItem
            }
        },
        State {
            name: "pin"

            PropertyChanges {
                model.values: Apps.search(search.text.slice(GlobalConfig.launcher.actionPrefix.length + 4))
                root.delegate: pinItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                targets: [model, root]
                properties: "values,delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
            pinMode: false
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: timerItem

        TimerItem {
            list: root
        }
    }

    Component {
        id: runItem

        RunItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Component {
        id: emojiItem

        EmojiItem {
            list: root
        }
    }

    Component {
        id: clipboardItem

        ClipboardItem {
            list: root
        }
    }

    Component {
        id: pinItem

        PinItem {
            list: root
        }
    }
}
