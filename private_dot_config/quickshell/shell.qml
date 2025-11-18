import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "modules"

ShellRoot {
    // Caelestia-inspired color scheme
    QtObject {
        id: colors
        // Catppuccin Mocha colors (matching Caelestia)
        readonly property color foreground: "#dde1e6"
        readonly property color foregroundInactive: "#262626"
        readonly property color background: "#393E41"
        readonly property color magenta: "#ff7eb6"
        readonly property color green: "#42be65"
        readonly property color yellow: "#ffe97b"
        readonly property color blue: "#33b1ff"
        readonly property color red: "#ee5396"
        readonly property color cyan: "#3ddbd9"
        readonly property color text: "#dde1e6"
        readonly property color overlay0: "#6c7086"
        readonly property color surface0: "#313244"
        readonly property color base: "#1e1e2e"
        readonly property color mantle: "#181825"
    }

    QtObject {
        id: fonts
        readonly property string primary: "CaskaydiaCove Nerd Font Mono"
        readonly property int size: 14
        readonly property int barHeight: 30
    }

	Variants {
		// Create the panel once on each monitor.
		model: Quickshell.screens

		Bar {}
	}
}