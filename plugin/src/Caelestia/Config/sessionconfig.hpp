#pragma once

#include "configobject.hpp"

#include <qlist.h>
#include <qstring.h>
#include <qstringlist.h>

#include <utility>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class SessionItem : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, id, u""_s)
    CONFIG_PROPERTY(QString, icon, u""_s)
    CONFIG_PROPERTY(QStringList, command, {})
    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, order, 0)

public:
    explicit SessionItem(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, dragThreshold, 30)
    // Opt-in: the session menu is a destructive-action panel, so revealing it by hover is off
    // unless asked for. The edge must also name "session" as its hover gesture.
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(bool, vimKeybinds, false)
    CONFIG_PROPERTY(QString, position, u"left"_s)
    // "outlined" or "filled" -- the Material Symbols FILL axis. Note that only glyphs with
    // an enclosed area (lock, bedtime) actually change; stroke-only ones such as logout,
    // cached and power_settings_new render identically either way.
    CONFIG_PROPERTY(QString, iconStyle, u"outlined"_s)
    CONFIG_PROPERTY(QList<SessionItem*>, items, {})

public:
    explicit SessionConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {
        auto* lockItem = new SessionItem(this);
        lockItem->set_id("lock");
        lockItem->set_icon("lock");
        lockItem->set_command({ u"loginctl"_s, u"lock-session"_s });
        lockItem->set_enabled(true);
        lockItem->set_order(0);
        m_items.append(lockItem);

        auto* sleepItem = new SessionItem(this);
        sleepItem->set_id("sleep");
        sleepItem->set_icon("bedtime");
        sleepItem->set_command({ u"systemctl"_s, u"suspend"_s });
        sleepItem->set_enabled(true);
        sleepItem->set_order(1);
        m_items.append(sleepItem);

        auto* logoutItem = new SessionItem(this);
        logoutItem->set_id("logout");
        logoutItem->set_icon("logout");
        logoutItem->set_command({ u"loginctl"_s, u"terminate-user"_s, u""_s });
        logoutItem->set_enabled(true);
        logoutItem->set_order(2);
        m_items.append(logoutItem);

        auto* rebootItem = new SessionItem(this);
        rebootItem->set_id("reboot");
        rebootItem->set_icon("cached");
        rebootItem->set_command({ u"systemctl"_s, u"reboot"_s });
        rebootItem->set_enabled(true);
        rebootItem->set_order(3);
        m_items.append(rebootItem);

        auto* shutdownItem = new SessionItem(this);
        shutdownItem->set_id("shutdown");
        shutdownItem->set_icon("power_settings_new");
        shutdownItem->set_command({ u"systemctl"_s, u"poweroff"_s });
        shutdownItem->set_enabled(true);
        shutdownItem->set_order(4);
        m_items.append(shutdownItem);

        // Decoration rather than an action: it carries no command, and the menu renders it
        // as the session gif. It lives in the roster so it can be reordered and toggled
        // alongside the buttons; the icon is only used by the settings list.
        auto* gifItem = new SessionItem(this);
        gifItem->set_id("gif");
        gifItem->set_icon("image");
        gifItem->set_command({});
        gifItem->set_enabled(true);
        gifItem->set_order(5);
        m_items.append(gifItem);

        // The setters above mark every field as loaded, which would serialize the whole
        // default roster back into the config file. Config output is meant to be sparse, so
        // reset the roster to "nothing set by the user" now that it's populated.
        for (auto* const item : std::as_const(m_items))
            item->clearLoadedKeys();
    }
};

} // namespace caelestia::config
