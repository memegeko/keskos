import QtQuick

Rectangle {
    id: root

    required property string label
    required property var theme

    implicitWidth: chipText.width + 14
    implicitHeight: 22
    color: mouse.containsMouse ? theme.hoverFill : "transparent"
    border.width: mouse.containsMouse ? 1 : 0
    border.color: theme.separator

    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.theme.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
    }
}
