pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../components"

PanelWindow {
    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: fonts.barHeight

    color: "transparent"

    // Use the wlroots specific layer property to ensure it displays over
    // fullscreen windows.
    WlrLayershell.layer: WlrLayer.Top

    RowLayout {
        anchors.fill: parent
        spacing: 5

        // Left section - workspaces and window title (matching Waybar layout)
        RowLayout {
            Layout.fillHeight: true
            Layout.leftMargin: 10
            spacing: 5

            WorkspaceIndicator {
                Layout.fillHeight: true
            }

            // Gap
            Item { Layout.preferredWidth: 10 }

            WindowTitle {
                Layout.fillHeight: true
                Layout.maximumWidth: 300
            }
        }

        // Center section - clock
        Item {
            Layout.fillWidth: true

            Clock {
                anchors.centerIn: parent
            }
        }

        // Right section - system modules (matching Waybar layout)
        RowLayout {
            Layout.fillHeight: true
            Layout.rightMargin: 10
            spacing: 5

            SpotifyIndicator {
                Layout.fillHeight: true
            }

            // Gap
            Item { Layout.preferredWidth: 10 }

            NetworkIndicator {
                Layout.fillHeight: true
            }

            NotificationIndicator {
                Layout.fillHeight: true
            }

            // Gap
            Item { Layout.preferredWidth: 10 }

            VolumeIndicator {
                Layout.fillHeight: true
            }

            // Gap
            Item { Layout.preferredWidth: 10 }

            TrayIndicator {
                Layout.fillHeight: true
            }
        }
    }
}