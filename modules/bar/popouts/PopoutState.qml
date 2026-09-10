import QtQuick

QtObject {
    id: root

    property string currentName
    property bool hasCurrent

    // Toplevel shown by the bar's active-window entry.
    property var activeWindowToplevel

    // Toplevel shown by the "dock" popout (the hovered dock app's window)
    property var dockToplevel

    // Entries the bar couldn't fit, shown by the "baroverflow" popout, with the config and
    // orientation of the bar they came from
    property var overflowEntries: []
    property var overflowBarConfig
    property bool overflowVertical: true
    property string overflowEdge
    property var overflowVisibilities

    // How long a popout lingers after the cursor leaves it, so the cursor can cross the gap
    // between the triggering bar entry and the popout itself. Set per-edge from ClipWrapper.
    property int closeGrace: 200

    signal detachRequested(mode: string)
    // Emitted once a deferred close actually lands, for cleanup that must not run during the grace.
    signal closed

    // Sites that still clear hasCurrent directly (tray menu activation, another drawer opening)
    // do their own cleanup, so drop any pending close rather than letting it fire later.
    onHasCurrentChanged: {
        if (!hasCurrent)
            closeTimer.stop();
    }

    readonly property Timer closeTimer: Timer {
        interval: root.closeGrace
        onTriggered: {
            root.hasCurrent = false;
            root.closed();
        }
    }

    // Open (or keep open), cancelling any pending close.
    function open(): void {
        closeTimer.stop();
        hasCurrent = true;
    }

    // Hover-out: close after the grace period unless something re-opens first. Guarded on
    // hasCurrent so idle movement over an empty bar doesn't keep re-arming the timer.
    function closeDeferred(): void {
        if (hasCurrent)
            closeTimer.restart();
    }

    // Explicit dismissal (escape, click, another drawer opening) - no grace.
    function closeNow(): void {
        closeTimer.stop();
        hasCurrent = false;
    }
}
