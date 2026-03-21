import QtQuick 2.15

Item {
    id: btnRoot

    property string label: ""
    property color normalColor: "#1a1a1a"
    property color hoverColor: "#2a2a2a"
    property color normalBorderColor: "#2a2a2a"
    property color hoverBorderColor: "#666666"
    property color textColor: "#cccccc"
    property color textHoverColor: "#cccccc"
    property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    property int fontSize: 12
    property int letterSpacing: 3
    property bool isRect: true
    property bool btnEnabled: true

    signal clicked()

    implicitHeight: isRect ? 40 : labelText.implicitHeight
    implicitWidth: isRect ? 200 : labelText.implicitWidth
    opacity: btnEnabled ? 1.0 : 0.5

    // Rectangle background (only for rect-style buttons)
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: area.containsMouse ? btnRoot.hoverColor : btnRoot.normalColor
        border.color: area.containsMouse ? btnRoot.hoverBorderColor : btnRoot.normalBorderColor
        border.width: 1
        visible: btnRoot.isRect

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: btnRoot.label
        font.family: btnRoot.fontFamily
        font.pixelSize: btnRoot.fontSize
        font.letterSpacing: btnRoot.letterSpacing
        color: btnRoot.isRect
            ? btnRoot.textColor
            : (area.containsMouse ? btnRoot.textHoverColor : btnRoot.textColor)

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: btnRoot.btnEnabled
        onClicked: btnRoot.clicked()
    }
}
