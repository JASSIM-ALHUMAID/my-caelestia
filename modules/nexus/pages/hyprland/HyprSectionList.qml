pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "../../../../services/KeybindActions.js" as KBActions

// Renders a HyprSchema section list. One CollapsibleSection per section, one row per var,
// with the row type chosen by the var's `type`. Adding a setting is a schema edit only.
ColumnLayout {
    id: root

    required property var sections

    // Optional, keyed by schema key -> warning string. Conflict detection needs to see every
    // row at once, which is the owning page's job, so the renderer only displays what it's given.
    property var conflicts: ({})

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    // isModified is a method, which a binding can't depend on. Reading the property first
    // registers it with the enclosing binding, so the reset affordance re-evaluates whenever
    // the value changes -- including when resetOption writes the default back.
    function isModified(key: string): bool {
        GlobalConfig.services[key];
        return GlobalConfig.services.isModified(key);
    }

    function resetOption(key: string): void {
        GlobalConfig.services.resetOption(key);
    }

    // QML bracket notation (obj[key] = value) does not trigger C++ property setters on
    // QObject sub-objects, and a schema-driven page has no key to assign directly, so writes
    // go through ConfigObject::setOption instead.
    function setValue(key: string, value: var): void {
        GlobalConfig.services.setOption(key, value);
    }

    Repeater {
        model: root.sections

        CollapsibleSection {
            id: section

            required property var modelData

            Layout.fillWidth: true
            title: qsTr(modelData.title)
            showBackground: false

            Repeater {
                model: section.modelData.vars

                VarRow {
                    required property var modelData
                    required property int index

                    v: modelData
                    first: index === 0
                    last: index === section.modelData.vars.length - 1
                }
            }
        }
    }

    // One schema entry -> one row. The Loader keeps a single row alive per var; the row
    // components below all read `v` off the enclosing VarRow.
    component VarRow: Item {
        id: varRow

        required property var v
        required property bool first
        required property bool last

        // The stored value scaled for display -- audioIncrement is a 0..1 fraction shown as a
        // percentage. Absent `scale` means the stored value is displayed as-is.
        readonly property real scale: v.scale ?? 1
        readonly property var raw: GlobalConfig.services[v.key]

        Layout.fillWidth: true
        implicitHeight: loader.implicitHeight

        Loader {
            id: loader

            anchors.left: parent.left
            anchors.right: parent.right
            sourceComponent: {
                const t = varRow.v.type;
                if (t === "bool")
                    return boolComp;
                if (t === "string")
                    return stringComp;
                if (t === "enum")
                    return enumComp;
                if (t === "keybind")
                    return bindComp;
                return numberComp;
            }
        }

        Component {
            id: numberComp

            StepperRow {
                first: varRow.first
                last: varRow.last
                label: qsTr(varRow.v.label)
                subtext: qsTr(varRow.v.subtext ?? "")
                value: varRow.scale === 1 ? varRow.raw : Math.round(varRow.raw * varRow.scale)
                from: varRow.v.min * varRow.scale
                to: varRow.v.max * varRow.scale
                stepSize: varRow.v.step * varRow.scale
                resetIcon: root.isModified(varRow.v.key) ? "restart_alt" : ""
                onMoved: value => root.setValue(varRow.v.key, varRow.scale === 1 ? value : value / varRow.scale)
                onResetRequested: root.resetOption(varRow.v.key)
            }
        }

        Component {
            id: boolComp

            ToggleRow {
                first: varRow.first
                last: varRow.last
                text: qsTr(varRow.v.label)
                subtext: qsTr(varRow.v.subtext ?? "")
                checked: varRow.raw
                resetIcon: root.isModified(varRow.v.key) ? "restart_alt" : ""
                onToggled: root.setValue(varRow.v.key, checked)
                onResetRequested: root.resetOption(varRow.v.key)
            }
        }

        Component {
            id: stringComp

            HyprTextRow {
                first: varRow.first
                last: varRow.last
                label: qsTr(varRow.v.label)
                subtext: qsTr(varRow.v.subtext ?? "")
                value: varRow.raw
                placeholder: varRow.v.def ?? ""
                resetIcon: root.isModified(varRow.v.key) ? "restart_alt" : ""
                onEdited: value => root.setValue(varRow.v.key, value)
                onResetRequested: root.resetOption(varRow.v.key)
            }
        }

        Component {
            id: bindComp

            KeyCaptureField {
                readonly property var parsed: KBActions.parseKeyCombo(varRow.raw)

                first: varRow.first
                last: varRow.last
                label: qsTr(varRow.v.label)
                subtext: qsTr(varRow.v.subtext ?? "")
                conflictText: root.conflicts[varRow.v.key] ?? ""
                modifiers: parsed.mods
                key: parsed.key
                modsOnly: varRow.v.mode === "mods"
                allowTextEntry: true
                resetIcon: root.isModified(varRow.v.key) ? "restart_alt" : ""
                onCaptured: (mods, k) => root.setValue(varRow.v.key, KBActions.formatKeyCombo(mods, k))
                onTextCommitted: combo => root.setValue(varRow.v.key, combo)
                onResetRequested: root.resetOption(varRow.v.key)
            }
        }

        Component {
            id: enumComp

            SelectRow {
                id: enumRow

                first: varRow.first
                last: varRow.last
                label: qsTr(varRow.v.label)
                subtext: qsTr(varRow.v.subtext ?? "")
                menuOnTop: true
                menuItems: optionVariants.instances
                active: menuItems.find(i => i.value === varRow.raw) ?? null
                fallbackText: varRow.raw
                fallbackIcon: "tune"
                onSelected: item => root.setValue(varRow.v.key, item.value)

                Variants {
                    id: optionVariants

                    model: varRow.v.options

                    MenuItem {
                        required property var modelData

                        readonly property string value: modelData.value

                        text: qsTr(modelData.label)
                        icon: modelData.icon ?? "tune"
                        trailingIcon: modelData.value === varRow.raw ? "check" : ""
                    }
                }
            }
        }
    }
}
