#include "visualiserbars.hpp"

#include <algorithm>
#include <cmath>
#include <qbrush.h>
#include <qpainter.h>
#include <qpainterpath.h>
#include <qpen.h>
#include <qrect.h>
#include <qtransform.h>

namespace caelestia::internal {

// Time constant = duration / kEasingDivisor. At kEasingDivisor=3, animation reaches ~95% in duration ms.
static constexpr qreal kEasingDivisor = 3.0;
static constexpr qreal kSineCycleSeconds = 2.5;
static constexpr qreal kVisibleEnergy = 0.001;
// Bars are always laid out in a "logical" space whose baseline is the bottom edge (y == lh) and
// which grows upwards; a QTransform then maps that space onto the configured screen edge.
static QTransform edgeTransform(const QString& position, qreal lh) {
    if (position == QLatin1String("top"))
        return QTransform(1, 0, 0, -1, 0, lh); // vertical flip
    if (position == QLatin1String("left"))
        return QTransform(0, 1, -1, 0, lh, 0); // x = lh - ly, y = lx
    if (position == QLatin1String("right"))
        return QTransform(0, 1, 1, 0, 0, 0); // x = ly, y = lx
    return {}; // bottom
}

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void VisualiserBars::advance(qreal dt) {
    if (m_displayValues.isEmpty() || m_settled)
        return;

    // dt is in seconds (from FrameAnimation.frameTime). A pause or clock anomaly must not
    // produce a NaN or cause a multi-second jump in the travelling wave.
    const qreal safeDt = std::isfinite(dt) ? std::clamp(dt, 0.0, 0.25) : 0.0;
    const qreal dtMs = safeDt * 1000.0;
    const qreal tau = std::max<qreal>(1.0, m_animationDuration / kEasingDivisor);
    const qreal alpha = 1.0 - std::exp(-dtMs / tau);

    bool allSettled = true;
    bool visualChanged = false;

    for (qsizetype i = 0; i < m_displayValues.size(); ++i) {
        const double diff = m_targetValues[i] - m_displayValues[i];

        if (std::abs(diff) > 0.001) {
            const double nextValue = m_displayValues[i] + diff * alpha;
            visualChanged = visualChanged || alpha > 0.0;
            m_displayValues[i] = nextValue;
            allSettled = false;
        } else {
            visualChanged = visualChanged || std::abs(diff) > 0.0;
            m_displayValues[i] = m_targetValues[i];
        }
    }

    const bool animateSine = m_style == QLatin1String("sine") && sineIsVisible();
    if (animateSine && safeDt > 0) {
        m_phase = std::fmod(m_phase + safeDt * (2.0 * M_PI / kSineCycleSeconds), 2.0 * M_PI);
        visualChanged = true;
        allSettled = false;
    }

    if (allSettled && !m_settled) {
        if (m_sourceWasEmpty) {
            // The next paint clears the old texture. Keep the target/display arrays alive until
            // this final blank update is scheduled, then make values() accurately empty again.
            m_targetValues.clear();
            m_displayValues.clear();
        }
        if (visualChanged || m_sourceWasEmpty)
            update();
        m_settled = true;
        emit settledChanged();
    } else if (!allSettled && visualChanged) {
        update();
    }
}

void VisualiserBars::paint(QPainter* painter) {
    if (m_displayValues.isEmpty())
        return;

    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setPen(Qt::NoPen);

    // Logical space: lw spans along the edge, lh is the direction the bars grow in
    const bool vertical = m_position == QLatin1String("left") || m_position == QLatin1String("right");
    const qreal lw = vertical ? height() : width();
    const qreal lh = vertical ? width() : height();
    const qreal maxBarHeight = lh * m_reach;

    painter->setTransform(edgeTransform(m_position, lh), true);

    // Defined in logical coords, so the painter transform carries it onto the right edge
    QLinearGradient gradient(0, lh - maxBarHeight, 0, lh);
    gradient.setColorAt(0, m_primaryColor);
    gradient.setColorAt(1, m_secondaryColor);
    painter->setBrush(gradient);

    if (m_style == QLatin1String("waveform")) {
        drawWaveformSide(painter, false, lw, lh, false);
        drawWaveformSide(painter, true, lw, lh, false);
    } else if (m_style == QLatin1String("outline")) {
        drawWaveformSide(painter, false, lw, lh, true);
        drawWaveformSide(painter, true, lw, lh, true);
    } else if (m_style == QLatin1String("sine")) {
        drawSineSide(painter, false, lw, lh);
        drawSineSide(painter, true, lw, lh);
    } else {
        drawSide(painter, false, lw, lh);
        drawSide(painter, true, lw, lh);
    }
}

void VisualiserBars::drawSide(QPainter* painter, bool rightSide, qreal w, qreal h) {
    const auto count = m_displayValues.size();

    if (count == 0)
        return;

    const qreal sideWidth = w * (1.0 - m_centerGap) / 2.0;
    const qreal slotWidth = sideWidth / static_cast<qreal>(count);
    const qreal barWidth = slotWidth - m_spacing;

    if (barWidth <= 0)
        return;

    const qreal sideOffset = rightSide ? w - sideWidth : 0;
    const qreal maxBarHeight = h * m_reach;

    for (qsizetype i = 0; i < count; ++i) {
        const qsizetype valueIndex = rightSide ? i : (count - i - 1);
        const qreal value = std::clamp(m_displayValues[valueIndex], 0.0, 1.0);
        const qreal barHeight = value * maxBarHeight;

        if (barHeight <= 0)
            continue;

        const qreal x = static_cast<qreal>(i) * slotWidth + sideOffset;
        const qreal y = h - barHeight;
        const qreal r = std::min({ m_rounding, barWidth / 2.0, barHeight });

        QPainterPath path;
        path.moveTo(x, h);
        path.lineTo(x, y + r);

        if (r > 0) {
            path.arcTo(x, y, r * 2, r * 2, 180, -90);
            path.lineTo(x + barWidth - r, y);
            path.arcTo(x + barWidth - r * 2, y, r * 2, r * 2, 90, -90);
        } else {
            path.lineTo(x, y);
            path.lineTo(x + barWidth, y);
        }

        path.lineTo(x + barWidth, h);
        path.closeSubpath();

        painter->drawPath(path);
    }
}

QPainterPath VisualiserBars::envelopePath(bool rightSide, qreal w, qreal h) const {
    QPainterPath path;
    const qsizetype count = m_displayValues.size();
    const qreal sideWidth = w * (1.0 - m_centerGap) / 2.0;
    if (count == 0 || sideWidth <= 0)
        return path;

    const qreal sideOffset = rightSide ? w - sideWidth : 0;
    const qreal maxHeight = h * m_reach;
    const qreal sampleCount = static_cast<qreal>(count);
    QVector<QPointF> points;
    points.reserve(count + 2);
    for (qsizetype i = 0; i < count; ++i) {
        const qsizetype valueIndex = rightSide ? i : count - i - 1;
        const qreal value = std::clamp(m_displayValues[valueIndex], 0.0, 1.0);
        points.append(QPointF(sideOffset + (static_cast<qreal>(i) + 0.5) * sideWidth / sampleCount,
                              h - value * maxHeight));
    }
    points.prepend(QPointF(sideOffset, points.first().y()));
    points.append(QPointF(sideOffset + sideWidth, points.last().y()));

    path.moveTo(points.first());
    for (qsizetype i = 1; i < points.size() - 1; ++i) {
        const QPointF midpoint((points[i].x() + points[i + 1].x()) / 2.0,
                               (points[i].y() + points[i + 1].y()) / 2.0);
        path.quadTo(points[i], midpoint);
    }
    path.quadTo(points[points.size() - 2], points.last());
    return path;
}

void VisualiserBars::drawWaveformSide(QPainter* painter, bool rightSide, qreal w, qreal h, bool fill) {
    if (sideEnergy(rightSide) <= kVisibleEnergy)
        return;

    QPainterPath envelope = envelopePath(rightSide, w, h);
    if (envelope.isEmpty())
        return;

    const qreal sideWidth = w * (1.0 - m_centerGap) / 2.0;
    const qreal sideOffset = rightSide ? w - sideWidth : 0;
    const qreal lineWidth = std::max(1, m_thickness);

    // Clipping in logical edge coordinates protects the total centre gap from round caps and
    // joins, and also keeps outer-edge strokes inside the item after edgeTransform().
    painter->save();
    painter->setClipRect(QRectF(sideOffset, 0, sideWidth, h), Qt::IntersectClip);

    QPen pen(m_primaryColor, lineWidth, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
    if (fill) {
        const qreal maxHeight = h * m_reach;
        QLinearGradient gradient(0, h - maxHeight, 0, h);
        gradient.setColorAt(0, m_primaryColor);
        gradient.setColorAt(1, m_secondaryColor);
        painter->setBrush(gradient);

        QPainterPath area = envelope;
        area.lineTo(sideOffset + sideWidth, h);
        area.lineTo(sideOffset, h);
        area.closeSubpath();
        painter->setPen(Qt::NoPen);
        painter->drawPath(area);
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        painter->drawPath(envelope);
    } else {
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        painter->drawPath(envelope);
    }
    painter->restore();
}

qreal VisualiserBars::sideEnergy(bool rightSide) const {
    if (m_displayValues.isEmpty())
        return 0;

    qreal sumSquares = 0;
    for (qsizetype i = 0; i < m_displayValues.size(); ++i) {
        const qsizetype valueIndex = rightSide ? i : m_displayValues.size() - i - 1;
        const qreal value = std::clamp(m_displayValues[valueIndex], 0.0, 1.0);
        sumSquares += value * value;
    }
    return std::sqrt(sumSquares / static_cast<qreal>(m_displayValues.size()));
}

bool VisualiserBars::sineIsVisible() const {
    return sideEnergy(false) > kVisibleEnergy || sideEnergy(true) > kVisibleEnergy;
}

void VisualiserBars::drawSineSide(QPainter* painter, bool rightSide, qreal w, qreal h) {
    const qreal sideWidth = w * (1.0 - m_centerGap) / 2.0;
    if (sideWidth <= 0 || h <= 0)
        return;

    const qreal energy = sideEnergy(rightSide);
    if (energy <= kVisibleEnergy)
        return;
    const qreal extent = std::clamp(energy * h * m_reach, 0.0, h * m_reach);
    const qreal sideOffset = rightSide ? w - sideWidth : 0;
    const qreal frequency = std::max<qreal>(1.0, std::round(sideWidth / 120.0));
    const qreal step = std::max<qreal>(1.0, sideWidth / 256.0);
    const qreal lineWidth = std::max(1, m_thickness);

    painter->save();
    painter->setClipRect(QRectF(sideOffset, 0, sideWidth, h), Qt::IntersectClip);

    QPainterPath path;
    bool firstPoint = true;
    for (qreal distance = 0; distance < sideWidth; distance += step) {
        // Use distance from the inner edge on both sides so the two waves mirror coherently.
        const qreal x = rightSide ? sideOffset + distance : sideOffset + sideWidth - distance;
        const qreal phase = frequency * 2.0 * M_PI * distance / sideWidth + m_phase;
        const qreal y = h - extent * (std::sin(phase) + 1.0) / 2.0;
        if (firstPoint) {
            path.moveTo(x, y);
            firstPoint = false;
        } else {
            path.lineTo(x, y);
        }
    }
    const qreal outerX = rightSide ? sideOffset + sideWidth : sideOffset;
    const qreal outerPhase = frequency * 2.0 * M_PI + m_phase;
    path.lineTo(outerX, h - extent * (std::sin(outerPhase) + 1.0) / 2.0);

    painter->setBrush(Qt::NoBrush);
    painter->setPen(QPen(m_primaryColor, lineWidth, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    painter->drawPath(path);
    painter->restore();
}

QVector<double> VisualiserBars::values() const {
    return m_targetValues;
}

void VisualiserBars::setValues(const QVector<double>& values) {
    if (values.isEmpty()) {
        if (m_sourceWasEmpty)
            return;

        m_sourceWasEmpty = true;
        if (m_displayValues.isEmpty()) {
            m_targetValues.clear();
            emit valuesChanged();
            return;
        }

        m_targetValues.fill(0.0, m_displayValues.size());
        if (m_settled) {
            m_settled = false;
            emit settledChanged();
        }
        emit valuesChanged();
        return;
    }

    if (!m_sourceWasEmpty && m_targetValues == values)
        return;
    m_sourceWasEmpty = false;
    m_targetValues = values;

    if (m_displayValues.size() != values.size()) {
        m_displayValues.resize(values.size(), 0.0);
    }

    if (m_settled) {
        m_settled = false;
        emit settledChanged();
    }

    emit valuesChanged();
}

bool VisualiserBars::settled() const {
    return m_settled;
}

QColor VisualiserBars::primaryColor() const {
    return m_primaryColor;
}

void VisualiserBars::setPrimaryColor(const QColor& color) {
    if (m_primaryColor == color)
        return;
    m_primaryColor = color;
    emit primaryColorChanged();
    update();
}

QColor VisualiserBars::secondaryColor() const {
    return m_secondaryColor;
}

void VisualiserBars::setSecondaryColor(const QColor& color) {
    if (m_secondaryColor == color)
        return;
    m_secondaryColor = color;
    emit secondaryColorChanged();
    update();
}

QString VisualiserBars::style() const {
    return m_style;
}

void VisualiserBars::setStyle(const QString& style) {
    const QString normalized = style == QLatin1String("waveform") || style == QLatin1String("sine")
            || style == QLatin1String("outline") ? style : QStringLiteral("bars");
    if (m_style == normalized)
        return;
    m_style = normalized;
    if (m_style == QLatin1String("sine") && sineIsVisible() && m_settled) {
        m_settled = false;
        emit settledChanged();
    }
    emit styleChanged();
    update();
}

int VisualiserBars::thickness() const {
    return m_thickness;
}

void VisualiserBars::setThickness(int thickness) {
    if (m_thickness == thickness)
        return;
    m_thickness = thickness;
    emit thicknessChanged();
    update();
}

qreal VisualiserBars::centerGap() const {
    return m_centerGap;
}

void VisualiserBars::setCenterGap(qreal centerGap) {
    const qreal clamped = std::isfinite(centerGap) ? std::clamp(centerGap, 0.0, 0.8) : 0.2;
    if (std::abs(m_centerGap - clamped) < 0.001)
        return;
    m_centerGap = clamped;
    emit centerGapChanged();
    update();
}

qreal VisualiserBars::rounding() const {
    return m_rounding;
}

void VisualiserBars::setRounding(qreal rounding) {
    if (std::abs(m_rounding - rounding) < 0.001)
        return;
    m_rounding = rounding;
    emit roundingChanged();
    update();
}

qreal VisualiserBars::spacing() const {
    return m_spacing;
}

void VisualiserBars::setSpacing(qreal spacing) {
    if (std::abs(m_spacing - spacing) < 0.001)
        return;
    m_spacing = spacing;
    emit spacingChanged();
    update();
}

QString VisualiserBars::position() const {
    return m_position;
}

void VisualiserBars::setPosition(const QString& position) {
    if (m_position == position)
        return;
    m_position = position;
    emit positionChanged();
    update();
}

qreal VisualiserBars::reach() const {
    return m_reach;
}

void VisualiserBars::setReach(qreal reach) {
    const qreal clamped = std::clamp(reach, 0.01, 1.0);
    if (std::abs(m_reach - clamped) < 0.001)
        return;
    m_reach = clamped;
    emit reachChanged();
    update();
}

int VisualiserBars::animationDuration() const {
    return m_animationDuration;
}

void VisualiserBars::setAnimationDuration(int duration) {
    if (m_animationDuration == duration)
        return;
    m_animationDuration = duration;
    emit animationDurationChanged();
    update();
}

} // namespace caelestia::internal
