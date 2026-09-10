#pragma once

#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qmap.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia::config {

inline QVariantMap vmap(std::initializer_list<std::pair<QString, QVariant>> entries) {
    QVariantMap map;
    for (const auto& [key, value] : entries)
        map.insert(std::move(key), std::move(value));
    return map;
}

} // namespace caelestia::config

// Declares a serialized config property with getter, setter (change-detected), signal, and member.
#define CONFIG_PROPERTY(Type, name, ...)                                                                               \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val)) {                                            \
            markPropertyLoaded(QStringLiteral(#name));                                                                 \
            Q_EMIT name##Changed();                                                                                    \
            notifyPropertyChanged(QStringLiteral(#name), QVariant::fromValue(m_##name));                               \
        }                                                                                                              \
    }                                                                                                                  \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name __VA_OPT__(= __VA_ARGS__);

// Declares a CONSTANT sub-object property. Initialize the member in the constructor.
#define CONFIG_SUBOBJECT(Type, name)                                                                                   \
    Q_PROPERTY(caelestia::config::Type* name READ name CONSTANT)                                                       \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = nullptr;

// Like CONFIG_PROPERTY but warns on read/write when accessed on a per-monitor overlay.
#define CONFIG_GLOBAL_PROPERTY(Type, name, ...)                                                                        \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        if (isOverlay())                                                                                               \
            qCWarning(caelestia::config::lcConfig, "Reading global-only option '%s' on per-monitor overlay",           \
                qUtf8Printable(propertyPath(QStringLiteral(#name))));                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (isOverlay())                                                                                               \
            qCWarning(caelestia::config::lcConfig, "Writing global-only option '%s' on per-monitor overlay",           \
                qUtf8Printable(propertyPath(QStringLiteral(#name))));                                                  \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val)) {                                            \
            markPropertyLoaded(QStringLiteral(#name));                                                                 \
            Q_EMIT name##Changed();                                                                                    \
            notifyPropertyChanged(QStringLiteral(#name), QVariant::fromValue(m_##name));                               \
        }                                                                                                              \
    }                                                                                                                  \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name __VA_OPT__(= __VA_ARGS__);                                                                           \
    const bool m_##name##_go = [this] {                                                                                \
        markGlobalOnly(QStringLiteral(#name));                                                                         \
        return true;                                                                                                   \
    }();

namespace caelestia::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

class ConfigObject : public QObject {
    Q_OBJECT

public:
    explicit ConfigObject(QObject* parent = nullptr);

    void loadFromJson(const QJsonObject& obj);
    [[nodiscard]] QJsonObject toJsonObject() const;

    // Per-monitor overlay support (Qt Resolve Mask pattern).
    void syncFromGlobal(ConfigObject* global);
    void resyncFromGlobal();
    void clearLoadedKeys();

    [[nodiscard]] bool isPropertyLoaded(const QString& name) const;
    [[nodiscard]] QString propertyPath(const QString& name) const;

    // A property holding a list of config objects (e.g. session.items). Such a list is a
    // fixed roster built in C++; JSON only overrides fields on entries that already exist,
    // matched by their `id`. asConfigObjectList returns an empty list for anything else, so
    // check isConfigObjectList first when empty and "not a roster" must be told apart.
    [[nodiscard]] static bool isConfigObjectList(const QVariant& value);
    [[nodiscard]] static QList<ConfigObject*> asConfigObjectList(const QVariant& value);

    // First property index past QObject's own (objectName). ConfigObject declares no
    // properties, so this is where every subclass's config properties begin — including
    // ones inherited from an intermediate config class (e.g. IconFontStyleConfig). Use
    // this instead of metaObject()->propertyOffset(), which excludes inherited properties.
    [[nodiscard]] static int basePropertyOffset();
    [[nodiscard]] bool isOverlay() const;
    // Returns true only on overlays — global singleton always returns false.
    [[nodiscard]] bool isGlobalOnly(const QString& name) const;

    // Snapshots every property's value as its default. Must run after construction (so
    // constructor-initialised defaults like AnimCurves are included) and before any config
    // file is applied — RootConfig::setupFileBackend calls it at exactly that point.
    void captureDefaults();

    // The captured default, or an invalid QVariant if this property has none.
    Q_INVOKABLE QVariant defaultOf(const QString& name) const;
    // True when the property currently differs from its captured default.
    Q_INVOKABLE bool isModified(const QString& name) const;

    // Writes an option looked up by name. QML's bracket assignment (obj[key] = value) does not
    // reliably reach the C++ setter on these sub-objects, so anything driving the config from a
    // schema -- where the key is data, not source -- has to go through this instead.
    Q_INVOKABLE bool setOption(const QString& name, const QVariant& value);

    Q_INVOKABLE void resetOption(const QString& name);
    // Restores every property on this object (and its sub-objects) to its captured default.
    Q_INVOKABLE void resetAllOptions();
    Q_INVOKABLE void resetToDefaults(const QVariantMap& defaults);

    template <typename T> static bool updateMember(T& member, const T& value) {
        if constexpr (std::is_floating_point_v<T>) {
            if (qFuzzyCompare(member + 1.0, value + 1.0))
                return false;
        } else {
            if (member == value)
                return false;
        }
        member = value;
        return true;
    }

signals:
    void propertiesChanged(const QMap<QString, QVariant>& changed);

protected:
    void markPropertyLoaded(const QString& name);
    void markGlobalOnly(const QString& name);
    void notifyPropertyChanged(const QString& name, const QVariant& value);

private:
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed);
    void emitBatchedChanges();

    // Built-in defaults, captured before the config file is applied
    QMap<QString, QVariant> m_defaults;

    // Per-monitor overlay state
    ConfigObject* m_global = nullptr;
    QSet<QString> m_loadedKeys;
    QSet<QString> m_globalOnlyKeys;
    QMap<QString, QVariant> m_pendingChanges;
    QTimer* m_batchTimer = nullptr;
};

} // namespace caelestia::config
