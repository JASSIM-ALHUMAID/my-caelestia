#pragma once

#include "diskinfo.hpp"
#include "tickingservice.hpp"

#include <qbytearrayview.h>
#include <qfuturewatcher.h>
#include <qhash.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qvariant.h>

namespace caelestia::services {

// Per-physical-disk totals accumulated by a scan. Lives in the header so it can cross the
// worker/main thread boundary as a QFutureWatcher result type.
struct DiskAccum {
    quint64 usedBytes = 0;
    quint64 totalBytes = 0;
    bool hasRoot = false;
};

class Storage : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::services::DiskInfo> disks READ disksProp NOTIFY disksChanged)
    Q_PROPERTY(caelestia::services::DiskInfo* manualPrimaryDisk READ manualPrimaryDisk WRITE setManualPrimaryDisk NOTIFY
            manualPrimaryDiskChanged)
    Q_PROPERTY(caelestia::services::DiskInfo* primaryDisk READ primaryDisk NOTIFY primaryDiskChanged)

public:
    explicit Storage(QObject* parent = nullptr);

    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] QQmlListProperty<DiskInfo> disksProp();
    [[nodiscard]] DiskInfo* manualPrimaryDisk() const;
    void setManualPrimaryDisk(DiskInfo* disk);
    [[nodiscard]] DiskInfo* primaryDisk() const;

signals:
    void disksChanged();
    void percentageChanged();
    void manualPrimaryDiskChanged();
    void primaryDiskChanged();

protected:
    void tick() override;

private:
    [[nodiscard]] static QStringList resolveToPhysicalDisks(const QString& devicePath);
    [[nodiscard]] static bool isPseudoFs(QByteArrayView fsType);
    [[nodiscard]] static bool sameOrder(const QList<DiskInfo*>& a, const QList<DiskInfo*>& b);

    // Runs on a worker thread: stats every eligible mount and folds the results into
    // per-physical-disk totals. Must not touch any QObject state.
    [[nodiscard]] static QHash<QString, DiskAccum> scanDisks();
    // Runs on the main thread with the finished scan's results.
    void applyDisks(const QHash<QString, DiskAccum>& byDisk);

    static qsizetype disksCount(QQmlListProperty<DiskInfo>* prop);
    static DiskInfo* disksAt(QQmlListProperty<DiskInfo>* prop, qsizetype i);

    QList<DiskInfo*> m_disks;
    QPointer<DiskInfo> m_manualPrimaryDisk;

    QFutureWatcher<QHash<QString, DiskAccum>>* const m_watcher;
    // A scan can block indefinitely on an unresponsive mount, so only ever have one in
    // flight - otherwise a stuck scan would leak a thread pool thread every tick.
    bool m_scanInFlight = false;
};

} // namespace caelestia::services
