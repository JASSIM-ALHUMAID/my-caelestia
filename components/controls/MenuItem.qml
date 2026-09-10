import QtQuick

QtObject {
    required property string text
    property string icon
    property string trailingIcon
    property string activeIcon: icon
    property string activeText: text

    // Optional image path (e.g. from Quickshell.iconPath). When set it replaces the leading
    // Material glyph, so items can show a real app icon instead of a symbol.
    property string iconSource
    property string activeIconSource: iconSource

    // Optional grouping label. Menu draws a header above the first item of each run of items
    // sharing a group, so a long list can be sectioned without changing how items are selected.
    // Empty on every existing caller, which renders exactly as before.
    property string group

    signal clicked
}
