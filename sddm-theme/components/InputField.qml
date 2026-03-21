import QtQuick 2.15

FocusScope {
    id: fieldRoot

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""

    // Theme properties (set from parent)
    property color bgColor: "#1a1a1a"
    property color borderColor: "#2a2a2a"
    property color focusBorderColor: "#888888"
    property color textColor: "#ffffff"
    property color placeholderColor: "#333333"
    property color selectionColor: "#444444"
    property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    property int fontSize: 12
    property bool fieldEnabled: true

    signal accepted()
    signal tabPressed()

    height: 40
    opacity: fieldEnabled ? 1.0 : 0.5

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: fieldRoot.bgColor
        border.color: input.activeFocus ? fieldRoot.focusBorderColor : fieldRoot.borderColor
        border.width: 1

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            font.family: fieldRoot.fontFamily
            font.pixelSize: fieldRoot.fontSize
            color: fieldRoot.textColor
            selectionColor: fieldRoot.selectionColor
            selectedTextColor: fieldRoot.textColor
            enabled: fieldRoot.fieldEnabled
            focus: true

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: fieldRoot.placeholder
                font.family: fieldRoot.fontFamily
                font.pixelSize: fieldRoot.fontSize
                font.letterSpacing: 2
                color: fieldRoot.placeholderColor
                visible: input.text.length === 0
            }

            Keys.onTabPressed: fieldRoot.tabPressed()
            Keys.onReturnPressed: fieldRoot.accepted()
        }
    }
}
