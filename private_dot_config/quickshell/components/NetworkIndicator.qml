import QtQuick
import Quickshell.Io

Text {
    id: networkText
    text: "Net: --"
    color: colors.blue
    font.family: fonts.primary
    font.pointSize: fonts.size

    // Caelestia-style animations
    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Process {
        id: networkProcess
        command: ["bash", "-c", "nmcli -t -f STATE general | head -1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const state = this.text.trim();
                if (state === "connected") {
                    // Get interface info
                    interfaceProcess.running = true;
                } else {
                    networkText.text = "󰤮 Disconnected";
                    networkText.color = colors.red;
                }
            }
        }
    }

    Process {
        id: interfaceProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,DEVICE device | grep -E '^(wifi|ethernet)' | head -1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim();
                if (line.startsWith("wifi:")) {
                    const device = line.split(":")[1];
                    networkText.text = "󰖩 " + device;
                    networkText.color = colors.blue;
                } else if (line.startsWith("ethernet:")) {
                    const device = line.split(":")[1];
                    networkText.text = "󰈀 " + device;
                    networkText.color = colors.blue;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: networkProcess.running = true
    }
}