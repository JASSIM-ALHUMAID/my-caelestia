#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qpainterpath.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>
#include <qstring.h>
#include <qvector.h>

namespace caelestia::internal {

class VisualiserBars : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector<double> values READ values WRITE setValues NOTIFY valuesChanged)
    Q_PROPERTY(QColor primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)
    Q_PROPERTY(QColor secondaryColor READ secondaryColor WRITE setSecondaryColor NOTIFY secondaryColorChanged)
    Q_PROPERTY(QString style READ style WRITE setStyle NOTIFY styleChanged)
    Q_PROPERTY(int thickness READ thickness WRITE setThickness NOTIFY thicknessChanged)
    Q_PROPERTY(qreal centerGap READ centerGap WRITE setCenterGap NOTIFY centerGapChanged)
    Q_PROPERTY(qreal rounding READ rounding WRITE setRounding NOTIFY roundingChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    // "bottom" | "top" | "left" | "right" - which edge the bars grow from
    Q_PROPERTY(QString position READ position WRITE setPosition NOTIFY positionChanged)
    // Fraction of the growth extent (item height for top/bottom, width for left/right) a bar
    // at full amplitude may occupy
    Q_PROPERTY(qreal reach READ reach WRITE setReach NOTIFY reachChanged)
    Q_PROPERTY(int animationDuration READ animationDuration WRITE setAnimationDuration NOTIFY animationDurationChanged)
    Q_PROPERTY(bool settled READ settled NOTIFY settledChanged)

public:
    explicit VisualiserBars(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    Q_INVOKABLE void advance(qreal dt);

    [[nodiscard]] QVector<double> values() const;
    void setValues(const QVector<double>& values);

    [[nodiscard]] QColor primaryColor() const;
    void setPrimaryColor(const QColor& color);

    [[nodiscard]] QColor secondaryColor() const;
    void setSecondaryColor(const QColor& color);

    [[nodiscard]] QString style() const;
    void setStyle(const QString& style);

    [[nodiscard]] int thickness() const;
    void setThickness(int thickness);

    [[nodiscard]] qreal centerGap() const;
    void setCenterGap(qreal centerGap);

    [[nodiscard]] qreal rounding() const;
    void setRounding(qreal rounding);

    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] QString position() const;
    void setPosition(const QString& position);

    [[nodiscard]] qreal reach() const;
    void setReach(qreal reach);

    [[nodiscard]] int animationDuration() const;
    void setAnimationDuration(int duration);

    [[nodiscard]] bool settled() const;

signals:
    void valuesChanged();
    void primaryColorChanged();
    void secondaryColorChanged();
    void styleChanged();
    void thicknessChanged();
    void centerGapChanged();
    void roundingChanged();
    void spacingChanged();
    void positionChanged();
    void reachChanged();
    void animationDurationChanged();
    void settledChanged();

private:
    void drawSide(QPainter* painter, bool rightSide, qreal lw, qreal lh);
    void drawWaveformSide(QPainter* painter, bool rightSide, qreal lw, qreal lh, bool fill);
    void drawSineSide(QPainter* painter, bool rightSide, qreal lw, qreal lh);
    [[nodiscard]] QPainterPath envelopePath(bool rightSide, qreal lw, qreal lh) const;
    [[nodiscard]] qreal sideEnergy(bool rightSide) const;
    [[nodiscard]] bool sineIsVisible() const;

    QVector<double> m_targetValues;
    QVector<double> m_displayValues;
    QColor m_primaryColor;
    QColor m_secondaryColor;
    QString m_style = QStringLiteral("bars");
    int m_thickness = 6;
    qreal m_centerGap = 0.2;
    qreal m_rounding = 0.0;
    qreal m_spacing = 0.0;
    QString m_position = QStringLiteral("bottom");
    qreal m_reach = 0.4;
    int m_animationDuration = 200;
    qreal m_phase = 0.0;
    bool m_sourceWasEmpty = false;
    bool m_settled = true;
};

} // namespace caelestia::internal
