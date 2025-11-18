import QtQuick
import Quickshell.Io

Text {
    id: notificationText
    text: " --"
    color: colors.yellow
    font.family: fonts.primary
    font.pointSize: fonts.size

    // Caelestia-style animations
    scale: mouseArea.pressed ? 0.95 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Process {
        id: notificationProcess
        command: ["dunstctl", "count"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                if (output && output !== "0") {
                    notificationText.text = " " + output;
                    notificationText.color = colors.yellow;
                } else {
                    notificationText.text = " --";
                    notificationText.color = colors.overlay0;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: notificationProcess.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Toggle pause
                togglePauseProcess.running = true;
            } else if (mouse.button === Qt.RightButton) {
                // Close all
                closeAllProcess.running = true;
            } else if (mouse.button === Qt.MiddleButton) {
                // History pop
                historyPopProcess.running = true;
            }
        }
    }

    Process {
        id: togglePauseProcess
        command: ["dunstctl", "set-paused", "toggle"]
    }

    Process {
        id: closeAllProcess
        command: ["dunstctl", "close-all"]
    }

    Process {
        id: historyPopProcess
        command: ["dunstctl", "history-pop"]
    }
}