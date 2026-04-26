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
    property real glowOpacity: dim ? 0.12 : 0.18
    property color renderColor: dim ? "#9b532a" : color

    implicitWidth: front.implicitWidth
    implicitHeight: front.implicitHeight

    Text {
        id: glow

        anchors.fill: front
        text: front.text
        color: root.renderColor
        opacity: root.glowOpacity
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
