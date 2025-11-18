import QtQuick
import Quickshell.Hyprland

Text {
    text: Hyprland.focusedWindow?.title || "Desktop"
    color: colors.text
    font.family: fonts.primary
    font.pointSize: fonts.size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}