import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: clockRoot

    property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    property color timeColor: "#ffffff"
    property color dateColor: "#555555"
    property bool clockRunning: true

    spacing: 4

    property date currentDateTime: new Date()

    Timer {
        interval: 1000
        running: clockRoot.clockRunning
        repeat: true
        onTriggered: clockRoot.currentDateTime = new Date()
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        color: clockRoot.timeColor
        font.family: clockRoot.fontFamily
        font.pixelSize: 56
        font.weight: Font.Bold
        font.letterSpacing: 2
        text: Qt.formatTime(clockRoot.currentDateTime, "hh:mm")
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        color: clockRoot.dateColor
        font.family: clockRoot.fontFamily
        font.pixelSize: 12
        font.letterSpacing: 3
        text: Qt.formatDate(clockRoot.currentDateTime, "dddd, MMMM d").toUpperCase()
    }
}
