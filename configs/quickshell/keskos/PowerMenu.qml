import QtQuick

Rectangle {
    id: root

    required property var theme

    signal actionSelected(string action)
    signal dismissRequested()

    readonly property var powerItems: [
        { "label": "LOCK SESSION", "action": "lock", "danger": false },
        { "label": "LOG OUT", "action": "logout", "danger": false },
        { "label": "SUSPEND", "action": "suspend", "danger": false },
        { "label": "RESTART", "action": "reboot", "danger": true },
        { "label": "SHUT DOWN", "action": "poweroff", "danger": true }
    ]

    width: 196
    implicitWidth: width
    implicitHeight: headerBox.height + itemColumn.implicitHeight + 18
    color: "#080706"
    border.width: 1
    border.color: root.theme.accent
    focus: true
    Keys.onEscapePressed: root.dismissRequested()

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#45ce6a35"
    }

    ScanlinesOverlay {
        anchors.fill: parent
    }

    Rectangle {
        id: headerBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        color: "#0d0b09"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: "POWER CONTROL"
            color: root.theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.letterSpacing: 1.2
            renderType: Text.NativeRendering
        }
    }

    Column {
        id: itemColumn
        anchors.top: headerBox.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 2

        Repeater {
            model: root.powerItems

            delegate: Rectangle {
                required property var modelData

                width: itemColumn.width
                height: 31
                color: itemMouse.containsMouse ? root.theme.hoverFill : "transparent"
                border.width: 1
                border.color: itemMouse.containsMouse ? root.theme.accent : "#18ce6a35"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: modelData.label
                    color: itemMouse.containsMouse
                        ? root.theme.accent
                        : (modelData.danger ? "#d29a79" : root.theme.text)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.letterSpacing: 1.0
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actionSelected(modelData.action)
                }
            }
        }
    }
}
