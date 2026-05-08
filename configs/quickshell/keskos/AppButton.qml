import QtQuick

Rectangle {
    id: root

    required property string iconSource
    required property bool active
    required property var theme

    signal pressed()

    width: 46
    height: 40
    color: active ? theme.activeFill : "#050505"
    border.width: 1
    border.color: mouse.containsMouse ? theme.accent : theme.separator

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: root.active ? root.theme.accent : "transparent"
    }

    Image {
        anchors.centerIn: parent
        width: 22
        height: 22
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.pressed()
    }
}
