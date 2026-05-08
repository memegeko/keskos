import QtQuick

Rectangle {
    id: root

    required property string label
    required property var theme
    property bool accentText: true
    property bool danger: false

    signal pressed()

    implicitHeight: 30
    color: mouse.containsMouse ? root.theme.hoverFill : "#120f0d"
    border.width: 1
    border.color: mouse.containsMouse ? root.theme.accent : "#24ce6a35"

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.danger
            ? "#d29a79"
            : (root.accentText ? root.theme.accent : root.theme.text)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.letterSpacing: 0.8
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
