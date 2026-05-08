import QtQuick

Rectangle {
    id: root

    required property string label
    required property var theme
    property color textColor: root.theme.text
    property bool active: false

    signal pressed()

    implicitWidth: chipText.width + 16
    implicitHeight: 22
    color: root.active ? root.theme.activeFill : (mouse.containsMouse ? root.theme.hoverFill : "transparent")
    border.width: root.active || mouse.containsMouse ? 1 : 0
    border.color: root.active ? root.theme.accent : root.theme.separator

    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.active ? root.theme.accent : root.textColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pressed()
    }
}
