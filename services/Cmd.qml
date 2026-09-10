pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

// Runs a command and surfaces its failure instead of dropping it.
//
// `Quickshell.execDetached` is the right tool when nothing depends on the outcome -- launching
// an app, opening a URL. It is the wrong one everywhere the shell has already changed its own
// state on the assumption the command worked, because it has no failure path by construction:
// the process is disowned before it runs, so a missing binary and a successful run look the
// same. That shape is behind most of this codebase's silent-failure bugs, where the UI keeps
// reporting a state the system was never put into.
//
// Use `run` for those. Keep execDetached for genuine fire-and-forget.
Singleton {
    id: root

    // Jobs are parented to this singleton rather than to the caller, so a popout that closes
    // mid-run doesn't take its own command down with it.
    property list<var> running: []

    // opts (all optional):
    //   title   -- toast title on failure. Omit to fail into the log only.
    //   detail  -- toast body. Defaults to the command's stderr, which is usually the better
    //              message; pass this when stderr is noise or empty.
    //   icon    -- toast icon name.
    //   onExit  -- (exitCode, stdout, stderr) => {}. Called on success *and* failure, so a
    //              caller can reconcile its optimistic state either way.
    function run(argv: list<string>, opts: var): void {
        const o = opts ?? {};
        const job = jobComp.createObject(root, {
            argv: argv,
            failTitle: o.title ?? "",
            failDetail: o.detail ?? "",
            failIcon: o.icon ?? "error",
            onExitCb: o.onExit ?? null
        });
        root.running.push(job);
        job.start();
    }

    Component {
        id: jobComp

        // An Item rather than a bare Process: Process derives from QObject and declares no
        // default property, so it cannot hold the backstop timer as a child.
        Item {
            id: job

            property var argv: []
            property string failTitle
            property string failDetail
            property string failIcon
            property var onExitCb

            readonly property string program: argv.length > 0 ? argv[0] : "?"

            // Quickshell does not document whether `exited` fires before or after the
            // collectors' `streamFinished`, and with waitForEnd (the default) a collector's
            // text stays empty until its stream ends. Reading output in onExited would
            // therefore be a coin flip, so settle() waits for both -- and the backstop makes
            // sure a stream that never reports still produces a result, rather than a command
            // that silently never finishes.
            property int code: 0
            property bool exitSeen: false
            property bool outSeen: false
            property bool errSeen: false
            property bool done: false

            function start(): void {
                proc.command = job.argv;
                proc.running = true;
            }

            function settle(): void {
                if (!job.exitSeen || job.done)
                    return;
                if (job.outSeen && job.errSeen)
                    job.finish(errCollector.text.trim());
                else
                    backstop.restart();
            }

            function finish(message: string): void {
                if (job.done)
                    return;
                job.done = true;
                backstop.stop();

                if (job.code !== 0) {
                    console.warn(`Cmd: ${job.program} failed (${job.code})${message ? `: ${message}` : ""}`);
                    if (job.failTitle)
                        Toaster.toast(job.failTitle, job.failDetail || message || qsTr("%1 exited with code %2").arg(job.program).arg(job.code), job.failIcon);
                }

                if (job.onExitCb)
                    job.onExitCb(job.code, outCollector.text.trim(), message);

                const i = root.running.indexOf(job);
                if (i >= 0)
                    root.running.splice(i, 1);
                job.destroy();
            }

            Process {
                id: proc

                stdout: StdioCollector {
                    id: outCollector

                    onStreamFinished: {
                        job.outSeen = true;
                        job.settle();
                    }
                }

                stderr: StdioCollector {
                    id: errCollector

                    onStreamFinished: {
                        job.errSeen = true;
                        job.settle();
                    }
                }

                onExited: (exitCode, exitStatus) => {
                    job.code = exitCode;
                    job.exitSeen = true;
                    job.settle();
                }

                // A command that never launched -- almost always a missing binary -- produces
                // no exit code and no streams, so without this it would hang as an unfinished
                // job and never report: exactly the silent failure this file exists to
                // prevent, and the likeliest way these commands fail on a user's machine.
                //
                // Process.error can't be used for it. Its parameter is QProcess::ProcessError,
                // which isn't registered with QML, so Qt does not expose the signal and
                // `onError` is rejected outright. Dropping back to `running` going false is
                // the documented surface that covers the same case; the backstop sorts out
                // whether an exit was on its way, since their ordering isn't specified either.
                onRunningChanged: {
                    if (!running && !job.exitSeen && !job.done)
                        backstop.restart();
                }
            }

            Timer {
                id: backstop

                interval: 100
                onTriggered: {
                    if (job.exitSeen) {
                        job.finish(errCollector.text.trim());
                    } else {
                        job.code = -1;
                        job.exitSeen = true;
                        job.finish(qsTr("Could not run %1 — is it installed?").arg(job.program));
                    }
                }
            }
        }
    }
}
