import QtQuick
import Quickshell.Io

Text {
    id: spotifyText
    text: "♪ --"
    color: colors.green
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
        id: spotifyProcess
        command: ["playerctl", "metadata", "--format", "{{ artist }} - {{ title }}"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                if (output) {
                    spotifyText.text = "♪ " + output;
                } else {
                    spotifyText.text = "♪ --";
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: spotifyProcess.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Play/pause
                playPauseProcess.running = true;
            } else if (mouse.button === Qt.RightButton) {
                // Next track
                nextProcess.running = true;
            } else if (mouse.button === Qt.MiddleButton) {
                // Previous track
                prevProcess.running = true;
            }
        }
    }

    Process {
        id: playPauseProcess
        command: ["playerctl", "play-pause"]
    }

    Process {
        id: nextProcess
        command: ["playerctl", "next"]
    }

    Process {
        id: prevProcess
        command: ["playerctl", "previous"]
    }
}