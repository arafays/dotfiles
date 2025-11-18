import QtQuick

Text {
    id: clock
    text: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
    color: colors.text
    font.family: fonts.primary
    font.pointSize: fonts.size
    horizontalAlignment: Text.AlignHCenter

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
    }
}