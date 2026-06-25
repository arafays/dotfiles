# Noctalia + Quickshell Development Context

## Core framework

- **Quickshell** (noctalia-qs): Qt6/QML Wayland shell framework
- **Noctalia Shell** (noctalia-shell): Desktop shell built on Quickshell

## QML import paths (for qmlls)

- Native Quickshell modules: /usr/lib/qt6/qml/Quickshell/
- Noctalia QML modules (qs.\*): /etc/xdg/quickshell/noctalia-shell/

## Common QML imports

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell              // CoreQuickshell types (Process, ShellScreen, etc.)
import Quickshell.Io           // Process, IpcHandler, StdioCollector
import qs.Commons              // Color, Style, Logger, Settings, ShellState, Time, Icons
import qs.Widgets              // NButton, NText, NIcon, NIconButton, NComboBox, NScrollView, NCollapsible, etc.
import qs.Services.UI          // ToastService, BarService, TooltipService
```

## Key Quickshell types used in plugins

| Type                        | Purpose                                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------------- |
| `Process`                   | Executes external commands. Properties: `exec()`, `running`, `stdout`, `stderr`             |
| `IpcHandler`                | IPC communication with Quickshell core. `target: "plugin:name"`, defines callable functions |
| `StdioCollector`            | Captures stdout/stderr from a Process                                                       |
| `Timer`                     | QML timer with `interval` (ms), `running`, `repeat`, `onTriggered`                          |
| `Quickshell.execDetached()` | Run command detached from shell                                                             |
| `ShellScreen`               | Screen info (name, geometry)                                                                |

## Noctalia plugin architecture

Each plugin in `~/.config/noctalia/plugins/<name>/` has:

| File            | Purpose                                                                                    |
| --------------- | ------------------------------------------------------------------------------------------ |
| `Main.qml`      | Plugin entry point. `pluginApi` property injected by host. Handles lifecycle, IPC          |
| `Settings.qml`  | Plugin settings UI panel. `pluginApi`, `contentPreferredWidth/Height`                      |
| `BarWidget.qml` | Small widget shown in the bar. `screen`, `widgetId`, `section`, `sectionWidgetIndex/Count` |
| `Panel.qml`     | Full-size panel UI. `pluginApi`, `geometryPlaceholder`, `contentPreferredWidth/Height`     |

### Plugin API

`pluginApi` provides:

- `.pluginDir` — path to plugin directory
- `.pluginSettings` — persisted settings object
- `.saveSettings()` — persist plugin settings
- `.manifest.metadata.defaultSettings` — defaults from plugin manifest
- `.mainInstance` — reference to Main.qml's root Item
- `.tr(key, args)` — i18n translation lookup
- `.closePanel(screen)` — close the plugin panel

### IPC pattern

Plugins communicate with external backends via `IpcHandler`:

- Backend sets status via `IpcHandler.setStatus(jsonStr)` with `{state, message, text}`
- Plugin calls backend via `Quickshell.execDetached(pythonCmd(["start"]))`

## Noctalia component conventions

- Widget prefix `N` (NButton, NText, NIcon, etc.)
- `Color.m*` for Material You colors (mSurface, mOnSurface, mPrimary, etc.)
- `Style.*` for spacing (marginXS/S/M/L), radius, font sizes, capsule dimensions
- `Style.pixelAlignCenter(container, item)` for pixel-perfect centering
- `Style.uiScaleRatio` for display scaling
- `Style.getCapsuleHeightForScreen(screenName)` / `Style.getBarFontSizeForScreen(screenName)`

## Python backend conventions

- Venv at `<pluginDir>/.venv/`
- `backendScript` is `dictation_backend.py`
- Python entry via `venvPython` (path to venv python)
- UV is used for package management (not pip)

## Naming conventions

- QML: camelCase (vars, funcs, properties), PascalCase (types)
- Files: kebab-case
- Python: snake_case

your information is outdated, and check for the latest updates in the Noctalia documentation and codebase when developing plugins. The conventions outlined here are based on the current state of the Noctalia project as of June 2024, but may evolve over time. Always refer to the official Noctalia resources and existing plugins for the most up-to-date practices and examples. use context7

use <https://github.com/noctalia-dev/noctalia-plugins/tree/main> to check for examples of existing plugins and how they implement the above conventions in practice.
