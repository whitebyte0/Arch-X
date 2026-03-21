import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0
import "./components"

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: colorBackground

    // ── Color Palette ──────────────────────────────────────────
    readonly property color colorBackground:    "#0a0a0a"
    readonly property color colorCard:          "#111111"
    readonly property color colorCardBorder:    "#222222"
    readonly property color colorInput:         "#1a1a1a"
    readonly property color colorInputBorder:   "#2a2a2a"
    readonly property color colorInputFocus:    "#888888"
    readonly property color colorDivider:       "#1e1e1e"
    readonly property color colorTextPrimary:   "#ffffff"
    readonly property color colorTextSecondary: "#cccccc"
    readonly property color colorTextMuted:     "#555555"
    readonly property color colorTextDim:       "#333333"
    readonly property color colorSelection:     "#444444"
    readonly property color colorHoverBg:       "#2a2a2a"
    readonly property color colorHoverBorder:   "#666666"
    readonly property color colorHoverText:     "#aaaaaa"
    readonly property color colorError:         "#aa4444"

    // ── Font & Layout ──────────────────────────────────────────
    readonly property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property int marginOuter: 24
    readonly property int marginCard:  32

    // ── State ──────────────────────────────────────────────────
    property bool loginInProgress: false
    property bool capsLockOn: false
    property int currentSessionIndex: sessionModel.lastIndex
    property string errorMessage: ""

    // ── Login Logic ────────────────────────────────────────────
    function doLogin() {
        errorMessage = ""

        if (usernameField.text.trim() === "") {
            errorMessage = "Enter a username"
            usernameField.forceActiveFocus()
            return
        }
        if (passwordField.text === "") {
            errorMessage = "Enter a password"
            passwordField.forceActiveFocus()
            return
        }

        loginInProgress = true
        sddm.login(usernameField.text.trim(), passwordField.text, currentSessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            loginInProgress = false
            errorMessage = "Login failed"
            passwordField.text = ""
            passwordField.forceActiveFocus()
            shakeAnimation.start()
        }
        function onLoginSucceeded() {
            fadeOut.start()
        }
    }

    // ── Caps Lock Detection ────────────────────────────────────
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_CapsLock)
            capsLockOn = !capsLockOn
    }

    // ── Login Fade Out ─────────────────────────────────────────
    PropertyAnimation {
        id: fadeOut
        target: root
        property: "opacity"
        from: 1.0; to: 0.0
        duration: 400
        easing.type: Easing.InQuad
    }

    // ── Background Image ───────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        visible: source !== ""
        smooth: true
    }

    // ── Grid Overlay ───────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: "assets/grid-tile.png"
        fillMode: Image.Tile
        opacity: 0.03
    }

    // ── Center Card ────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 400
        height: cardLayout.implicitHeight + marginCard * 2
        radius: 4
        color: colorCard
        border.color: colorCardBorder
        border.width: 1

        // Shake animation on login failure
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12;  duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -8;  duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 8;   duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0;   duration: 50; easing.type: Easing.InOutQuad }
        }

        ColumnLayout {
            id: cardLayout
            anchors.centerIn: parent
            width: parent.width - marginCard * 2
            spacing: 12

            // ── Clock + Date ───────────────────────────────────
            ClockDisplay {
                Layout.fillWidth: true
                fontFamily: root.fontFamily
                timeColor: colorTextPrimary
                dateColor: colorTextMuted
                clockRunning: !loginInProgress
            }

            // ── Divider ────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                height: 9
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: colorDivider
                }
            }

            // ── Username ───────────────────────────────────────
            InputField {
                id: usernameField
                Layout.fillWidth: true
                placeholder: "USERNAME"
                text: userModel.data(userModel.index(0, 0), Qt.UserRole + 1)
                fontFamily: root.fontFamily
                bgColor: colorInput
                borderColor: colorInputBorder
                focusBorderColor: colorInputFocus
                textColor: colorTextPrimary
                placeholderColor: colorTextDim
                selectionColor: colorSelection
                fieldEnabled: !loginInProgress
                onTabPressed: passwordField.forceActiveFocus()
                onAccepted: passwordField.forceActiveFocus()
            }

            // ── Password ───────────────────────────────────────
            InputField {
                id: passwordField
                Layout.fillWidth: true
                placeholder: "PASSWORD"
                echoMode: TextInput.Password
                fontFamily: root.fontFamily
                bgColor: colorInput
                borderColor: colorInputBorder
                focusBorderColor: colorInputFocus
                textColor: colorTextPrimary
                placeholderColor: colorTextDim
                selectionColor: colorSelection
                fieldEnabled: !loginInProgress
                onTabPressed: usernameField.forceActiveFocus()
                onAccepted: root.doLogin()
            }

            // ── Caps Lock Warning ──────────────────────────────
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "CAPS LOCK"
                font.family: root.fontFamily
                font.pixelSize: 10
                font.letterSpacing: 2
                color: colorError
                visible: capsLockOn
            }

            // ── Login Button ───────────────────────────────────
            ActionButton {
                Layout.fillWidth: true
                label: loginInProgress ? "..." : "LOGIN"
                fontFamily: root.fontFamily
                normalColor: colorInput
                hoverColor: colorHoverBg
                normalBorderColor: colorInputBorder
                hoverBorderColor: colorHoverBorder
                textColor: colorTextSecondary
                btnEnabled: !loginInProgress
                onClicked: root.doLogin()
            }

            // ── Error Message ──────────────────────────────────
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: colorError
                font.family: root.fontFamily
                font.pixelSize: 11
                text: errorMessage || sddm.lastError
                visible: text !== ""
            }
        }
    }

    // ── Bottom Bar ─────────────────────────────────────────────
    // Hostname
    Text {
        id: hostnameText
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: marginOuter
        color: colorTextDim
        font.family: root.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 2
        text: sddm.hostName.toUpperCase()
    }

    // Session selector (next to hostname)
    SessionSelector {
        anchors.bottom: parent.bottom
        anchors.left: hostnameText.right
        anchors.leftMargin: 16
        anchors.bottomMargin: marginOuter
        model: sessionModel
        currentIndex: root.currentSessionIndex
        fontFamily: root.fontFamily
        textColor: colorTextDim
        hoverColor: colorHoverText
        popupBg: colorCard
        popupBorder: colorCardBorder
        popupItemHover: colorInput
        onSessionChanged: function(index) {
            root.currentSessionIndex = index
        }
    }

    // Power + Reboot
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: marginOuter
        spacing: 20

        ActionButton {
            isRect: false
            label: "↺"
            fontSize: 16
            letterSpacing: 0
            fontFamily: root.fontFamily
            textColor: colorTextDim
            textHoverColor: colorHoverText
            onClicked: sddm.reboot()
        }

        ActionButton {
            isRect: false
            label: "⏻"
            fontSize: 16
            letterSpacing: 0
            fontFamily: root.fontFamily
            textColor: colorTextDim
            textHoverColor: colorHoverText
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: usernameField.forceActiveFocus()
}
