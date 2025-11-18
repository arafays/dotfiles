import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    spacing: 2

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            width: 24
            height: parent.height
            color: modelData.active ? Qt.rgba(colors.yellow.r, colors.yellow.g, colors.yellow.b, 0.1) : "transparent"
            radius: 2

            // Caelestia-style animations
            Behavior on color {
                ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }

            scale: mouseArea.pressed ? 0.95 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }

            property var icons: ({
                "1": "", // Terminal
                "2": "", // Browser
                "3": "", // Mail
                "4": "", // Code
                "5": "", // Code
                "urgent": "", // Urgent
                "active": "", // Active
                "default": "" // Default
            })

            Text {
                text: parent.icons[modelData.id.toString()] || parent.icons["default"]
                color: modelData.active ? colors.yellow : colors.overlay0
                font.family: fonts.primary
                font.pointSize: fonts.size
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter

                Behavior on color {
                    ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: modelData.active = true
            }
        }
    }
}