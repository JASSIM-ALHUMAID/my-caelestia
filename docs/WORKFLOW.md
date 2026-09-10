# Caelestia shell — working guide

Single source of truth for working in this repo: layout, the edit→run loop, how to add features,
and the traps that fail **silently**. If you are an agent picking up work here, read §0–§2 before
touching anything.

---

## 0. Fast path

```sh
# QML-only change
./scripts/sync-live.sh                 # rsync QML into the runtime copy + restart shell

# C++ / plugin change (no root)
devfiles/install-user.fish             # configure, build, install to ~/.local, restart shell

# check QML syntax before running
qmlformat path/to/File.qml >/dev/null || echo "PARSE FAIL"

# inspect the restarted shell's log, including from a detached/TTY environment
qs -c caelestia log --any-display | grep -iE "error"
```

Neither script commits or pushes. Do that yourself.

---

## 1. Layout — which copy actually runs

| Copy | Path | Role |
|---|---|---|
| Repo | this tree | Source of truth. Editing it alone changes nothing at runtime. |
| Live config | `caelestia-configs/` | `~/.config/caelestia` symlinks here. The installer points that link at whichever tree it was run from, so config edits in that tree are live immediately. |
| Runtime QML | `~/.config/quickshell/caelestia` | What `qs -c caelestia` loads. Must be synced/installed after QML edits. |
| C++ plugin (user) | `~/.local/lib/qt6/qml/Caelestia` | Installed by `devfiles/install-user.fish` or `cmake --install build`. |
| C++ plugin (system) | `/usr/lib/qt6/qml/Caelestia` | Root-owned, from `devfiles/install-system.fish` or `scripts/install.sh`. **See §1.2.** |

### 1.1 Hot reload

- The **repo** `shell.qml` has `settings.watchFiles: true`, so a dev shell (`qs -p .`) watches
  files. It is **not reliable** — reloads are sometimes missed. Confirm with
  `grep -c Reloading <log>` and restart if the count didn't move. A bare `touch` never works
  (content is watched, not mtime).
- The **installed** copy is rewritten to `watchFiles: false` by both `sync-live.sh` and the cmake
  install. It never hot-reloads; it must be re-synced and restarted.

### 1.2 Trap: `/usr` can shadow your freshly built plugin

`qs` may resolve `Caelestia.Config` from `/usr/lib/qt6/qml/...` **even when** every other
Caelestia module loads from `~/.local` and `QML2_IMPORT_PATH` points elsewhere. A stale `/usr`
copy then silently supplies the types, so a config property you just added reads back
`undefined` with no error anywhere. (`sync-live.sh` carries a comment about this same hazard for
missing types.)

Check what is actually loaded:

```sh
grep -i caelestia /proc/$(pgrep -x qs)/maps | awk '{print $6}' | sort -u
```

Updating `/usr` needs sudo. To test a rebuilt plugin **without root**, bind-mount over it:

```sh
cmake --install build          # installs to ~/.local
bwrap --dev-bind / / \
  --bind ~/.local/lib/qt6/qml/Caelestia/Config /usr/lib/qt6/qml/Caelestia/Config \
  --bind ~/.local/lib/qt6/qml/Caelestia/lib    /usr/lib/qt6/qml/Caelestia/lib \
  qs -p .
```

---

## 2. Making a change

### QML / assets / configs only

```sh
./scripts/sync-live.sh
```

Takes **no arguments**. It rsyncs `assets/ components/ modules/ services/ utils/` and `shell.qml`
into `~/.config/quickshell/caelestia`, then kills and restarts the shell with
`QML2_IMPORT_PATH` pointed at `~/.local/lib/qt6/qml`. It warns if `plugin/` or `CMakeLists.txt`
have pending changes, because it does **not** build them. It does **not** git-add, commit, or push.

### C++ / plugin / `CMakeLists.txt`

```sh
devfiles/install-user.fish     # user-only, no root: builds + installs to ~/.local + restarts
```

Or manually: `cd build && ninja && cmake --install build`. `scripts/install.sh --skip-sddm`
is the older system-wide path and needs `sudo`.

`install-user.fish` also appends the session env (`QML2_IMPORT_PATH`, `CAELESTIA_LIB_DIR`) to
Hyprland/uwsm config so `qs -c caelestia` finds the user plugin, and it restarts the shell at the
end — treat running it exactly like a shell kill (§9.4).

---

## 3. Adding a config option

`plugin/src/Caelestia/Config/`. A new config section needs **four** registrations. Miss any one
and there is no build error — the QML property is just `undefined` or `null` forever.

1. **`CMakeLists.txt`** — add `<name>config.hpp` to `SOURCES`. Header-only config classes are
   still listed there; without it AUTOMOC never generates the metaobject. Symptom: link error
   `undefined symbol: ...FooConfig::staticMetaObject`, and only once something references it.
2. **`config.hpp`** — forward declare `class FooConfig;`, add `Q_MOC_INCLUDE("fooconfig.hpp")`,
   and `CONFIG_SUBOBJECT(FooConfig, foo)`.
3. **`config.cpp`** — `#include "fooconfig.hpp"` and add `, m_foo(new FooConfig(this))` to
   **both** `GlobalConfig` constructors. `CONFIG_SUBOBJECT` only declares `m_foo = nullptr`;
   the macro comment says "Initialize the member in the constructor" and it means it.
4. **`configattached.hpp` + `.cpp`** — `Q_MOC_INCLUDE`, `Q_PROPERTY`, the declaration, and
   `CONFIG_ATTACHED_GETTER(FooConfig, foo)`.

> **Step 4 is the one people skip.** In QML, `Config.foo` is the *per-screen attached* type
> (`configattached`), **not** `GlobalConfig`. Registering only in `config.hpp` gives a working
> `GlobalConfig.foo` and an `undefined` `Config.foo`.

Nested per-edge/per-variant sub-objects: copy `BarConfig` / `BarEdgeConfig` in `barconfig.hpp`
(it takes ctor args for per-instance defaults). `edgesconfig.hpp` is a small worked example.

### Reading vs writing from QML

```qml
Config.foo.bar              // READ  — per-screen attached config
GlobalConfig.foo.bar = x    // WRITE — the singleton; persists to shell.json
```

Do **not** paper over an `undefined` with `Config.foo?.bar`. Optional chaining here hides a
missing registration and turns a hard failure into a feature that silently never works.

### Trap: an old plugin eats unknown keys

The shell re-serializes `shell.json`. If a shell with an **older** plugin is running while you add
a new key, it rewrites the file and silently drops the key it doesn't know. Install and restart
first, then add sample config values. Config file-watch reload is also flaky — when a config
toggle "doesn't work", restart the shell before debugging the binding.

---

## 4. Adding a panel / drawer

Follow the Launcher (`modules/launcher/`) or Dashboard pattern: a `Wrapper.qml` (positioning +
slide animation) around a `Content.qml`.

| # | File | What |
|---|---|---|
| 1 | `modules/<name>/Wrapper.qml` | `shouldBeActive`, `offsetScale`, `Loader` for content |
| 2 | `modules/<name>/Content.qml` | The actual UI |
| 3 | `components/DrawerVisibilities.qml` | `property bool <name>` |
| 4 | `modules/drawers/Panels.qml` | Instantiate wrapper + `readonly property alias` |
| 5 | `modules/drawers/Regions.qml` | `R { panel: root.panels.<name> }` — input mask |
| 6 | `modules/Shortcuts.qml` | `CustomShortcut` to toggle |
| 7 | `modules/drawers/ContentWindow.qml` | **`PanelBg`** — without it the panel has no blob background/shadow |
| 8 | `modules/drawers/ContentWindow.qml` | **`<name>.transform: Matrix4x4 { matrix: <name>Bg.deformMatrix }`** |
| 9 | `modules/drawers/ContentWindow.qml` | **`HyprlandFocusGrab`** `active:` + `onCleared:` — else click-outside won't dismiss |
| 10 | `modules/drawers/ContentWindow.qml` | **`dragMaskPadding`** panel list — else drag-to-reveal can never start |
| 11 | `caelestia-configs/keybinds.json` | A bind, or the panel is unreachable (§4.3) |

Items 7–10 are the ones that get forgotten; all four live in the same file.

### 4.1 The panel draws no background of its own

`PanelBg` (a metaball blob in `ContentWindow`) supplies it. A full-bleed `StyledRect`
(`anchors.fill: parent`) inside `Content.qml` gives a hard-edged rectangle sitting on top of the
blob. Compare `modules/launcher/Content.qml`: its root is a plain `Item` sized from its children,
and the `StyledRect`s inside are individual controls (the search field), never a backdrop.

### 4.2 Positioning on a configurable edge

Don't toggle anchors to `undefined` at runtime (the item floats). Two established patterns,
depending on how many edges the panel supports:

- **Two edges** (e.g. the dashboard, top/bottom only): the `AnchorChanges` state pattern in
  `Panels.qml` (see the dock, which uses it for all four edges), with **both**
  `anchors.topMargin` and `anchors.bottomMargin` set on the wrapper — only the one matching the
  active anchor takes effect.
- **Four edges, optionally floating off any of them** (the OSD, session menu and launcher):
  self-positioning via `x`/`y` instead of anchors at all — see `modules/launcher/Wrapper.qml`
  and the `osdWrapper`/`sessionWrapper` items in `Panels.qml`. `AnchorChanges` still works for a
  fixed set of docked edges, but it has no way to express "detached from every edge by a
  configurable gap", which floating mode needs.

### 4.3 Making it reachable

`enabled: true` in config only *permits* a panel. It appears only when `visibilities.<name>`
becomes true, via a keybind (`caelestia shell drawers toggle <name>`), `showOnHover` + the edge
gesture table (§5), or IPC:

```sh
qs -c caelestia ipc call drawers toggle <name>
qs -c caelestia ipc call drawers list
```

The IPC `toggle`/`list` handler is **generic** — it enumerates boolean keys on
`DrawerVisibilities`, so a new panel works over IPC with no handler changes.

`DrawerVisibilities` is `PersistentProperties`: visibility survives restarts. When testing
toggles, an odd number of calls leaves it inverted — check state before concluding it's broken.

---

## 5. Edge gestures (hover / drag arbitration)

Several panels can occupy one screen edge — dashboard and dock sit on top or bottom; the OSD,
session menu and launcher can each be on any of the four. A **floating** launcher
(`Config.launcher.mode === "floating"`) is the one exception: it owns no edge at all, so it
never claims a gesture and never shows up as an occupant in the Edge Gestures page (see
`Interactions.qml`'s `launcherEdge` and `EdgeConflictPage.qml`'s `occupantsOf`). For everything
else, the **edge**, not the panel, owns which one a gesture opens. Defined in `edgesconfig.hpp`,
consumed in `modules/drawers/Interactions.qml`:

```json
"edges": {
  "top":    { "hover": "launcher", "drag": "launcher" },
  "bottom": { "hover": "dock",     "drag": "dock"     },
  "left":   { "hover": "osd",      "drag": "session"  }
}
```

Valid names: `launcher`, `dashboard`, `dock`, `osd`, `session`, `none`.

- Hover and drag are independent, so one edge can hover one panel and drag another.
- Helpers: `hoverOwns(panel, edge)`, `dragOwns(panel, edge)`, `closeOthersOnEdge(edge, keep)`.
- A panel's own `showOnHover` is an opt-out: hover fires only if the edge names the panel **and**
  its `showOnHover` is true.
- When hover does *not* govern a panel, never write `visibilities.x = false` on every mouse move
  — that instantly closes anything opened by drag or shortcut. Guard it (see
  `dashboardHoverEnabled`).
- OSD hover code exists in **three** places in `Interactions.qml`: sidebar-hidden branch,
  sidebar-visible branch, and an early-returning `if (fullscreen)` branch. Change all three.

Nexus UI: `modules/nexus/pages/panels/EdgeConflictPage.qml`.

---

## 6. QML conventions and traps

Nearly every file uses `pragma ComponentBehavior: Bound`. Consequences:

- **Delegates must declare what they use.** Inside a `Repeater`/`ListView` delegate, `index` and
  `modelData` are *not* in scope unless declared:
  ```qml
  required property int index
  required property var modelData
  ```
  Symptom: `ReferenceError: index is not defined`. See
  `modules/bar/components/workspaces/Workspace.qml`.

- **A `required property` must be set at creation.** Declaring `required property var modelData`
  on a component you instantiate bare and populate later throws
  `Required property ... was not initialized`, and the *whole enclosing file* fails to load — so
  the feature vanishes with one log line. If it's assigned after construction, it's a plain
  `property`, not `required`.

- **Assigning to a bound property destroys the binding — permanently.**
  ```qml
  property var model: buildModel()   // re-evaluates when dependencies change
  root.model = newModel;             // binding gone; never updates again
  ```
  Persist to config instead and let the binding re-evaluate. Related: if display order must be
  user-editable, the model builder has to *read* the persisted order (iterate the config list),
  or reordering appears to do nothing.

- **Qualify `modelData` in nested scopes.** A delegate's own `required property var modelData`
  shadows an outer one; use `root.modelData` for the outer object.

- Widgets need `import qs.services` for `Colours`, else they render unstyled/transparent with
  only a `ReferenceError` in the log.
- Nexus rows (`ToggleRow`, `StepperRow`, …) need explicit `Layout.fillWidth: true` or they
  collapse to indicator width.
- `XMLHttpRequest` file reads are blocked — use `FileView` from `Quickshell.Io`.

---

## 7. Nexus settings pages

1. Create the page under `modules/nexus/pages/…`.
2. Register the `Component` in `modules/nexus/PageCompRegistry.qml`.
3. Add a `NavRow` with `onClicked: root.nState.openSubPage(N)`.

**Sub-page indices are positional and 1-based.** `StackPage` pushes `pages[0]` (the main page)
itself, so the first sub-page `Component` is index 1. Inserting a Component mid-list
**renumbers everything after it** — update every `openSubPage(N)` that refers to them
(`modules/nexus/pages/panels/TaskbarPanel.qml` is the usual casualty).

---

## 8. Keybinds

Stored in `caelestia-configs/keybinds.json` (live via the `~/.config/caelestia` symlink), watched
by `services/KeybindsConfig.qml`, which saves changes back to disk. `services/KeybindApplier.qml`
applies each bind at runtime via Hyprland IPC `keyword bind` — so **binds only exist while the
shell is running**. Available actions: `services/KeybindActions.js`. Edits are normally made
through Nexus (Super+I → Keybindings) with press-to-record capture and conflict warnings.

The one static bind the JSON system can't express — the tap-Super "bindi" toggle — lives in
`caelestia-configs/hypr-user.conf`.

When editing the JSON directly, verify semantically (parse both sides and diff the binding set)
rather than trusting `git diff`; the shell reformats the file, so a textual diff is noisy.

---

## 9. Verifying your change

### 9.1 Syntax check

`qmllint` cannot resolve this project's `qs.*` imports and exits silently — it is not a useful
gate. Use `qmlformat` as a **syntax** check (exit 1 on parse error, 0 otherwise):

```sh
for f in modules/**/*.qml; do qmlformat "$f" >/dev/null 2>&1 || echo "PARSE FAIL: $f"; done
```

It catches only syntax, not the scope/binding traps in §6 — the log is the real check.

### 9.2 Reading the log

Ignore the startup burst of `TypeError: Cannot read property '…' of undefined` from
`Background.qml` / `BarWrapper.qml` / `ContentWindow.qml` — the attached config resolves per
screen slightly later. **A message that repeats on every interaction is real; one at startup
usually is not.**

### 9.3 Driving the UI without a mouse

There is no pointer injection (no ydotool/wtype), but Hyprland can move the cursor, which is
enough to exercise hover paths:

```sh
hyprctl dispatch 'hl.dsp.cursor.move{x=960,y=1197}'   # Lua dispatch API on this version
hyprctl cursorpos
grim -o eDP-1 shot.png                                 # display is 1920x1200
```

Press/drag gestures can't be simulated — verify those by hand.

For state-driven UI, a temporary `console.warn` probe beats reasoning about it. Put it inside the
exact branch you think should run; if nothing prints, the branch isn't being reached and the bug
is upstream (input mask, config, early return) — not in the logic you were about to "fix".

Other no-pointer tricks: open a Nexus sub-page by temporarily defaulting `currentPageIdx` in
`NexusState.qml`; trigger functions with a temporary `Timer` **inside** an `Item` (a top-level
`Timer` breaks `PageBase`, whose default property takes a single Item).

### 9.4 Before killing the shell

`pkill -x qs` / `qs -c caelestia kill` while the session is **locked** takes out the lockscreen
and drops Hyprland to its "lockscreen app died" fallback. `hyprctl activewindow` answers normally
while locked — it is **not** a lock check. The only valid check is `grim` immediately before, and
actually looking at the image. Recovery:

```sh
hyprctl keyword misc:allow_session_lock_restore 1
qs ipc -i <instance> call lock lock
```

Also: `qs -c <config> kill/list/ipc` is display-scoped — it silently no-ops without
`WAYLAND_DISPLAY` set.

### 9.5 Restart by hand

```sh
# Normal graphical terminal (WAYLAND_DISPLAY is set):
QT_QPA_PLATFORM=wayland qs -c caelestia -n -d

# Detached agent / TTY: use sync-live.sh, which discovers Hyprland and launches
# through it so the shell inherits the complete Wayland session environment.
./scripts/sync-live.sh
```

Do not launch bare `qs -c caelestia -d` when `WAYLAND_DISPLAY` is unset. Qt falls back to XCB,
then fails with `could not connect to display`. Also keep `-n`: without it, a second invocation can
start a duplicate shell.

---

## 10. Known pre-existing issues

Verified; don't burn time rediscovering them:

- **Left-edge OSD hover never fires.** With `sidebar.edge: "left"`, pointer events never reach
  the drawers window at `x < ~12`; `onPositionChanged` is not called there at all. The cause is
  the input mask in `Regions.qml`, not the OSD logic (proved by removing all gating — behaviour
  unchanged). `Regions.qml` carries a comment about exactly this class of bug.
- **A hover-reveal bar occupies its whole edge.** With `bar.bottom.persistent: false`, the bar is
  a separate layer surface that consumes pointer events along the bottom, so a panel on that same
  edge (e.g. the dock) never receives the hover. Use a keybind on such edges.
