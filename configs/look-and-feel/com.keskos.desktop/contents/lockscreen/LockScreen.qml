import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.private.sessions

Item {
    id: root
    property bool debug: false
    property string notification: ""
    signal clearPassword()
    signal notificationRepeated()

    // Magical properties and signals expected by kscreenlocker.
    property bool viewVisible: true
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false
    signal suspendToDisk()
    signal suspendToRam()

    implicitWidth: 800
    implicitHeight: 600

    property color accent: "#ce6a35"
    property color accentGlow: "#df9a69"
    property color panelColor: "#060504"
    property color panelAltColor: "#0b0806"
    property color fieldColor: "#090706"
    property color textColor: "#ce6a35"
    property color dimText: "#83533a"
    property color danger: "#ff4f2e"

    function setStatus(message, color) {
        statusText.text = message;
        statusText.color = color;
    }

    function submitUnlock() {
        if (!passwordField.text.length) {
            setStatus("ENTER PASSWORD TO CONTINUE", dimText);
            passwordField.forceActiveFocus();
            return;
        }

        setStatus("AUTH CHECK IN PROGRESS", dimText);
        authenticator.respond(passwordField.text);
    }

    SessionManagement {
        id: sessionManagement
    }

    Connections {
        target: authenticator

        function onFailed(kind) {
            if (kind !== 0) {
                return;
            }

            passwordField.text = "";
            root.setStatus("ACCESS DENIED", root.danger);
            passwordField.forceActiveFocus();
        }

        function onSucceeded() {
            root.setStatus("ACCESS GRANTED", root.accentGlow);
            Qt.quit();
        }

        function onInfoMessageChanged() {
            if (authenticator.infoMessage) {
                root.setStatus(authenticator.infoMessage, root.dimText);
            }
        }

        function onErrorMessageChanged() {
            if (authenticator.errorMessage) {
                root.setStatus(authenticator.errorMessage, root.danger);
            }
        }

        function onPromptChanged() {
            if (authenticator.prompt) {
                root.setStatus(authenticator.prompt, root.dimText);
            }
        }

        function onPromptForSecretChanged() {
            root.setStatus("ENTER PASSWORD TO CONTINUE", root.dimText);
            passwordField.forceActiveFocus();
        }
    }

    Connections {
        target: root

        function onClearPassword() {
            passwordField.text = "";
            passwordField.forceActiveFocus();
            root.setStatus("ENTER PASSWORD TO CONTINUE", root.dimText);
        }
    }

    Component.onCompleted: {
        if (Window.window) {
            Window.window.requestActivate();
        }

        passwordField.forceActiveFocus();
        authenticator.startAuthenticating();
        root.setStatus("ENTER PASSWORD TO CONTINUE", root.dimText);
    }

    Keys.onEscapePressed: {
        root.clearPassword();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submitUnlock();
            event.accepted = true;
            return;
        }

        if (!passwordField.activeFocus) {
            passwordField.forceActiveFocus();
        }

        event.accepted = false;
    }

    Image {
        anchors.fill: parent
        source: "assets/background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.58
    }

    Item {
        anchors.fill: parent
        opacity: 0.06

        Repeater {
            model: Math.ceil(root.height / 4)

            Rectangle {
                x: 0
                y: index * 4
                width: root.width
                height: 1
                color: "#ffffff"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: passwordField.forceActiveFocus()
    }

    Rectangle {
        id: shadowFrame
        width: Math.min(root.width - 120, 760)
        height: Math.min(root.height - 120, 500)
        anchors.centerIn: parent
        color: root.panelColor
        border.color: root.accent
        border.width: 2
        opacity: 0.16
        transform: Translate { y: 4 }
    }

    Rectangle {
        id: windowFrame
        width: Math.min(root.width - 120, 760)
        height: Math.min(root.height - 120, 500)
        anchors.centerIn: parent
        color: root.panelColor
        border.color: root.accent
        border.width: 2

        Rectangle {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 42
            color: root.panelAltColor
            border.color: root.accent
            border.width: 1

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 14
                color: root.accentGlow
                font.family: "IBM Plex Sans"
                font.pixelSize: 22
                font.bold: true
                text: "Log on to KeskOS"
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: ["-", "[]", "X"]

                    Rectangle {
                        width: 28
                        height: 22
                        color: "#090909"
                        border.color: root.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            color: root.textColor
                            font.family: "IBM Plex Mono"
                            font.pixelSize: 12
                            text: modelData
                        }
                    }
                }
            }
        }

        Rectangle {
            id: panel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 12
            color: "#040302"
            border.color: root.accent
            border.width: 2

            ColumnLayout {
                id: formColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168

                    Image {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 70, 540)
                        height: 240
                        fillMode: Image.PreserveAspectFit
                        source: "assets/logo.png"
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "User name:"
                    color: root.textColor
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 18
                }

                QQC2.TextField {
                    id: userField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    text: kscreenlocker_userName
                    readOnly: true
                    color: root.accentGlow
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 18
                    padding: 8
                    selectByMouse: false
                    background: Rectangle {
                        color: root.fieldColor
                        border.color: root.accent
                        border.width: 1
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Password:"
                    color: root.textColor
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 18
                }

                QQC2.TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: root.accentGlow
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 18
                    padding: 8
                    echoMode: TextInput.Password
                    selectByMouse: false
                    focus: true
                    background: Rectangle {
                        color: root.fieldColor
                        border.color: passwordField.activeFocus ? root.accentGlow : root.accent
                        border.width: 1
                    }
                    onAccepted: root.submitUnlock()
                }

                Text {
                    id: statusText
                    Layout.fillWidth: true
                    color: root.dimText
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    text: ""
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    component ActionButton : QQC2.Button {
                        id: actionButton
                        implicitWidth: 108
                        implicitHeight: 34
                        hoverEnabled: true

                        contentItem: Text {
                            text: actionButton.text
                            color: root.textColor
                            font.family: "IBM Plex Mono"
                            font.pixelSize: 15
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: actionButton.down ? "#6d2a16" : "#090909"
                            border.color: actionButton.hovered ? root.accentGlow : root.accent
                            border.width: 1
                        }
                    }

                    ActionButton {
                        text: "OK"
                        onClicked: root.submitUnlock()
                    }

                    ActionButton {
                        text: "Clear"
                        onClicked: root.clearPassword()
                    }

                    ActionButton {
                        text: "Sleep"
                        visible: root.suspendToRamSupported
                        onClicked: root.suspendToRam()
                    }

                    ActionButton {
                        text: "Hibernate"
                        visible: root.suspendToDiskSupported
                        onClicked: root.suspendToDisk()
                    }

                    ActionButton {
                        text: "Switch User"
                        visible: sessionManagement.canSwitchUser
                        onClicked: sessionManagement.switchUser()
                    }
                }
            }
        }
    }
}
