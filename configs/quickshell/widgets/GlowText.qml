import QtQuick

Item {
    id: root

    property string text: ""
    property color color: "#ce6a35"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property real fontSize: 12
    property int fontWeight: Font.Normal
    property real letterSpacing: 0
    property bool dim: false
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignVCenter
    property color renderColor: dim ? "#9d582f" : color

    implicitWidth: front.implicitWidth
    implicitHeight: front.implicitHeight

    Text {
        id: glow

        anchors.fill: front
        text: front.text
        color: root.renderColor
        opacity: 0.24
        font.family: root.fontFamily
        font.pixelSize: root.fontSize + 1
        font.weight: root.fontWeight
        letterSpacing: root.letterSpacing
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        renderType: Text.NativeRendering
    }

    Text {
        id: front

        text: root.text
        color: root.renderColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
        letterSpacing: root.letterSpacing
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        renderType: Text.NativeRendering
    }
}
