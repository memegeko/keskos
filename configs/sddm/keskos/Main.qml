import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1600
    height: 900
    color: "#050403"

    property string messageText: textConstants.prompt
    property color messageColor: config.textColor
    property bool optionsVisible: config.showSession === "true"

    function preferredUserName() {
        const remembered = (userModel.lastUser || "").toString().trim()
        if (remembered.length > 0) {
            return remembered
        }

        const configured = (config.defaultUser || "").toString().trim()
        if (configured.length > 0) {
            return configured
        }

        return ""
    }

    component RetroButton: QQC2.Button {
        id: retroButton
        implicitWidth: 118
        implicitHeight: 34
        font.family: "IBM Plex Mono"
        font.pixelSize: 15

        contentItem: Text {
            text: retroButton.text
            color: retroButton.down ? "#fbfdff" : config.textColor
            font: retroButton.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: retroButton.down ? "#6d2a16" : "#090909"
            border.color: retroButton.hovered ? config.primaryGlow : config.borderColor
            border.width: 1
        }
    }

    function submitLogin() {
        messageText = textConstants.login
        messageColor = config.textColor
        sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
    }

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginFailed() {
            passwordField.text = ""
            passwordField.forceActiveFocus()
            root.messageText = textConstants.loginFailed
            root.messageColor = config.errorColor
        }

        function onLoginSucceeded() {
            root.messageText = textConstants.loginSucceeded
            root.messageColor = config.primaryGlow
        }

        function onInformationMessage(message) {
            root.messageText = message
            root.messageColor = config.warningColor
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: 0.88
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#030303" }
            GradientStop { position: 0.45; color: "#050403" }
            GradientStop { position: 1.0; color: "#020202" }
        }
        opacity: 0.88
    }

    Rectangle {
        anchors.fill: parent
        color: config.ambientColor
        opacity: 0.08
    }

    Repeater {
        model: Math.ceil(root.height / 4)
        delegate: Rectangle {
            x: 0
            y: index * 4
            width: root.width
            height: 1
            color: config.primaryGlow
            opacity: 0.018
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.6; color: "#00000022" }
            GradientStop { position: 1.0; color: "#000000bb" }
        }
    }

    DropShadow {
        anchors.fill: loginWindow
        source: loginWindow
        horizontalOffset: 0
        verticalOffset: 0
        radius: 24
        samples: 33
        color: Qt.rgba(0.81, 0.42, 0.21, 0.18)
    }

    Rectangle {
        id: loginWindow
        width: 760
        height: optionsVisible ? 520 : 472
        anchors.centerIn: parent
        color: config.panelColor
        border.color: config.borderColor
        border.width: 2

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "transparent"
            border.color: Qt.rgba(0.81, 0.42, 0.21, 0.18)
            border.width: 1
        }

        Rectangle {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 42
            color: config.panelAltColor
            border.color: config.borderColor
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: config.title
                color: config.primaryGlow
                font.family: "IBM Plex Sans"
                font.pixelSize: 22
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: ["-", "[]", "X"]
                    delegate: Rectangle {
                        width: 28
                        height: 22
                        color: "#090909"
                        border.color: config.borderColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: config.textColor
                            font.family: "IBM Plex Mono"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            anchors.topMargin: 62
            anchors.bottomMargin: 22
            spacing: 10

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 168

                Image {
                    id: logo
                    source: config.logo
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 70, 540)
                    height: 240
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "User name:"
                color: config.textColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 18
            }

            QQC2.TextField {
                id: usernameField
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                font.family: "IBM Plex Mono"
                font.pixelSize: 18
                color: config.primaryGlow
                selectByMouse: true
                padding: 8
                background: Rectangle {
                    color: config.fieldColor
                    border.color: usernameField.activeFocus ? config.primaryGlow : config.borderColor
                    border.width: 1
                }
                onAccepted: passwordField.forceActiveFocus()
            }

            Text {
                Layout.fillWidth: true
                text: "Password:"
                color: config.textColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 18
            }

            QQC2.TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                echoMode: TextInput.Password
                font.family: "IBM Plex Mono"
                font.pixelSize: 18
                color: config.primaryGlow
                selectByMouse: true
                padding: 8
                background: Rectangle {
                    color: config.fieldColor
                    border.color: passwordField.activeFocus ? config.primaryGlow : config.borderColor
                    border.width: 1
                }
                onAccepted: root.submitLogin()
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: optionsVisible ? 46 : 0
                visible: optionsVisible

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "Session:"
                        color: config.textColor
                        font.family: "IBM Plex Mono"
                        font.pixelSize: 14
                    }

                    QQC2.ComboBox {
                        id: sessionCombo
                        Layout.fillWidth: true
                        model: sessionModel
                        currentIndex: sessionModel.lastIndex
                        textRole: "name"
                        font.family: "IBM Plex Mono"
                        font.pixelSize: 14

                        contentItem: Text {
                            leftPadding: 10
                            rightPadding: 30
                            text: sessionCombo.displayText
                            font: sessionCombo.font
                            color: config.primaryGlow
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            color: config.fieldColor
                            border.color: config.borderColor
                            border.width: 1
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.messageText
                color: root.messageColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                RetroButton {
                    text: "OK"
                    onClicked: root.submitLogin()
                }

                RetroButton {
                    text: "Cancel"
                    onClicked: {
                        usernameField.text = root.preferredUserName()
                        passwordField.text = ""
                        root.messageText = textConstants.prompt
                        root.messageColor = config.textColor
                        passwordField.forceActiveFocus()
                    }
                }

                RetroButton {
                    text: "Shut Down"
                    enabled: sddm.canPowerOff
                    onClicked: sddm.powerOff()
                }

                RetroButton {
                    text: "Reboot"
                    enabled: sddm.canReboot
                    onClicked: sddm.reboot()
                }

                RetroButton {
                    text: optionsVisible ? "Options <<" : "Options >>"
                    visible: sessionModel.count > 1
                    onClicked: root.optionsVisible = !root.optionsVisible
                }
            }
        }
    }

    Component.onCompleted: {
        usernameField.text = root.preferredUserName()
        if (usernameField.text.length > 0) {
            passwordField.forceActiveFocus()
        } else {
            usernameField.forceActiveFocus()
        }
    }
}
