#include "iutils.hpp"

#include "cachingimageprovider.hpp"

namespace caelestia::images {

IUtils* IUtils::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(jsEngine);

    engine->addImageProvider(QStringLiteral("ccache"), new CachingImageProvider(CachingImageProvider::FillMode::Crop));
    engine->addImageProvider(QStringLiteral("fcache"), new CachingImageProvider(CachingImageProvider::FillMode::Fit));
    engine->addImageProvider(
        QStringLiteral("scache"), new CachingImageProvider(CachingImageProvider::FillMode::Stretch));

    return new IUtils(engine);
}

QUrl IUtils::urlForPath(const QString& path, int fillMode) {
    if (path.isEmpty())
        return QUrl();

    QString prefix;
    switch (fillMode) {
    case 1: // Image.PreserveAspectFit
        prefix = QStringLiteral("fcache");
        break;
    case 2: // Image.PreserveAspectCrop
        prefix = QStringLiteral("ccache");
        break;
    case 3: // Image.Tile
    case 4: // Image.TileVertically
    case 5: // Image.TileHorizontally
    case 6: // Image.Pad
        return QUrl::fromLocalFile(path);
    default: // Image.Stretch or any other ones
        prefix = QStringLiteral("scache");
        break;
    }

    QUrl url;
    url.setScheme(QStringLiteral("image"));
    url.setHost(prefix);
    url.setPath(path.startsWith(QLatin1Char('/')) ? path : QLatin1Char('/') + path);
    return url;
}

} // namespace caelestia::images
