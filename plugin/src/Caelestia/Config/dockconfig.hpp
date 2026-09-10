#pragma once

#include "configobject.hpp"
#include <QQmlEngine>

#include <qstring.h>
#include <qstringlist.h>

namespace caelestia::config {

class DockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    // "bottom" | "top" | "left" | "right" - which screen edge the dock sits on
    CONFIG_PROPERTY(QString, position, u"bottom"_s)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(bool, hideOnHoverOut, true)
    CONFIG_PROPERTY(int, iconSize, 48)
    CONFIG_PROPERTY(int, minIconSize, 32)
    CONFIG_PROPERTY(int, maxIconSize, 80)
    CONFIG_PROPERTY(bool, showAddButton, true)
    CONFIG_PROPERTY(bool, showEditButton, true)
    CONFIG_PROPERTY(bool, showHoverPopout, true)
    CONFIG_PROPERTY(bool, wiggleInEditMode, true)
    CONFIG_PROPERTY(bool, dragAndDrop, true)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    CONFIG_PROPERTY(bool, hideOnActivate, true)
    // Keeps the dock revealed and makes it reserve an exclusive zone, so windows tile
    // around it rather than under it. Written at runtime by the pin button.
    CONFIG_PROPERTY(bool, pinned, false)
    // Hover-only mode. Deliberately overrides pinned, so a dock can be parked out of the
    // way without losing its pinned state.
    CONFIG_PROPERTY(bool, keepHidden, false)
    CONFIG_PROPERTY(bool, availableOnFullscreen, false)
    // Reveal the dock when the active workspace has no windows, so an empty desktop
    // always offers a way to launch something.
    CONFIG_PROPERTY(bool, revealOnEmptyWorkspace, true)
    CONFIG_PROPERTY(bool, showRunningIndicators, true)
    // Include windows on special workspaces when deriving running dock apps.
    CONFIG_PROPERTY(bool, showSpecialWorkspaceApps, true)
    CONFIG_PROPERTY(bool, showPinButton, true)
    // Divider drawn between pinned apps and running-but-unpinned ones.
    CONFIG_PROPERTY(bool, showSeparator, true)
    // Clicking a running app cycles through its windows instead of always focusing the first.
    CONFIG_PROPERTY(bool, cycleWindowsOnClick, true)
    CONFIG_PROPERTY(bool, middleClickNewInstance, true)
    // Running indicators drawn per app before they collapse to squares.
    CONFIG_PROPERTY(int, maxIndicatorDots, 3)
    CONFIG_PROPERTY(int, spacing, 4)
    // Gap in px between the dock and its screen edge.
    CONFIG_PROPERTY(int, margin, 8)
    // Window classes matching these are never shown in the dock. Tested against the
    // lowercased class via Strings.testRegexList, which only treats a "^...$" anchored
    // entry as a regex and compares anything else literally.
    CONFIG_PROPERTY(QStringList, ignoredAppRegexes, { u"^quickshell.*$"_s, u"^xdg-desktop-portal.*$"_s })
    // Screen names the dock (and its exclusive zone) are suppressed on.
    CONFIG_PROPERTY(QStringList, excludedScreens)
    // "hugged" | "floating" - how the popout appears relative to the dock
    CONFIG_PROPERTY(QString, popoutMode, u"hugged"_s)
    // Distance in px between a floating popout and the dock. Ignored in hugged mode.
    CONFIG_PROPERTY(int, popoutGap, 12)
    // How long in ms the popout lingers after the cursor leaves, so it can be moved onto.
    CONFIG_PROPERTY(int, hoverGrace, 200)

public:
    explicit DockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

}
