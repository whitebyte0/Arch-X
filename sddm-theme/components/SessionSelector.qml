import QtQuick 2.15

Item {
    id: selectorRoot

    property var model
    property int currentIndex: 0
    property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    property color textColor: "#333333"
    property color hoverColor: "#aaaaaa"
    property color popupBg: "#111111"
    property color popupBorder: "#222222"
    property color popupItemHover: "#1a1a1a"

    signal sessionChanged(int index)

    implicitWidth: currentLabel.implicitWidth
    implicitHeight: currentLabel.implicitHeight

    Text {
        id: currentLabel
        text: {
            if (!selectorRoot.model) return ""
            var idx = selectorRoot.model.index(selectorRoot.currentIndex, 0)
            // Try multiple role access methods
            var name = selectorRoot.model.data(idx, Qt.DisplayRole)
            if (!name) name = selectorRoot.model.data(idx, Qt.UserRole + 1)
            return name ? name.toUpperCase() : "SESSION"
        }
        font.family: selectorRoot.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 2
        color: selectorArea.containsMouse ? selectorRoot.hoverColor : selectorRoot.textColor

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: selectorArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible = !popup.visible
        }
    }

    Rectangle {
        id: popup
        visible: false
        width: 200
        height: Math.min(popupList.contentHeight + 16, 200)
        anchors.bottom: currentLabel.top
        anchors.bottomMargin: 8
        anchors.left: currentLabel.left
        radius: 4
        color: selectorRoot.popupBg
        border.color: selectorRoot.popupBorder
        border.width: 1

        ListView {
            id: popupList
            anchors.fill: parent
            anchors.margins: 8
            model: selectorRoot.model
            clip: true
            spacing: 2

            delegate: Rectangle {
                width: popupList.width
                height: 28
                radius: 2
                color: delegateArea.containsMouse ? selectorRoot.popupItemHover : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    text: model.name ? model.name.toUpperCase() : ""
                    font.family: selectorRoot.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    color: index === selectorRoot.currentIndex
                           ? selectorRoot.hoverColor
                           : selectorRoot.textColor
                    font.weight: index === selectorRoot.currentIndex ? Font.Bold : Font.Normal
                }

                MouseArea {
                    id: delegateArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        selectorRoot.currentIndex = index
                        selectorRoot.sessionChanged(index)
                        popup.visible = false
                    }
                }
            }
        }
    }
}
