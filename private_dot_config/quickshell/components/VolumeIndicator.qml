import QtQuick
import Quickshell.Io

Text {
    id: volumeText
    text: "--% "
    color: colors.green
    font.family: fonts.primary
    font.pointSize: fonts.size

    Process {
        id: volumeProcess
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/(\d+)%/);
                if (match) {
                    const volume = parseInt(match[1]);
                    let icon = ""; // Low
                    if (volume > 66) icon = ""; // High
                    else if (volume > 33) icon = ""; // Medium

                    volumeText.text = volume + "% " + icon;
                }
            }
        }
    }

    Process {
        id: muteProcess
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.includes("yes")) {
                    volumeText.text = "󰖁 Muted";
                    volumeText.color = colors.overlay0;
                } else {
                    volumeProcess.running = true; // Refresh volume
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            volumeProcess.running = true;
            muteProcess.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => {
            // Open pavucontrol
            pavucontrolProcess.running = true;
        }
    }

    Process {
        id: pavucontrolProcess
        command: ["pavucontrol"]
    }
}