import QtQuick
import Quickshell.Wayland

// System tray placeholder - Quickshell may not have direct tray support
// This would need to be implemented based on available APIs
Text {
    text: "Tray"
    color: colors.overlay0
    font.family: fonts.primary
    font.pointSize: fonts.size
    visible: false // Hide for now until proper implementation
}