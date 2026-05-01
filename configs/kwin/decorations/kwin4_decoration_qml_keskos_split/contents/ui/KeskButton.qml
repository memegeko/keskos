import QtQuick
import org.kde.kwin.decoration

DecorationButton {
    id: button

    property color accentActive: "#ce6a35"
    property color accentInactive: "#845236"
    property color fillIdle: "#0e0b08"
    property color fillHover: "#1a110c"
    property color fillPressed: "#27170e"
    property color textIdle: decoration.client.active ? accentActive : accentInactive

    readonly property string symbol: {
        if (button.buttonType === DecorationOptions.DecorationButtonMinimize) {
            return "–"
        }
        if (button.buttonType === DecorationOptions.DecorationButtonMaximizeRestore) {
            return decoration.client.maximized ? "❐" : "□"
        }
        if (button.buttonType === DecorationOptions.DecorationButtonClose) {
            return "×"
        }
        return "•"
    }

    width: 34
    height: 26

    Rectangle {
        anchors.fill: parent
        color: button.pressed ? button.fillPressed : (button.hovered ? button.fillHover : button.fillIdle)
        border.width: 1
        border.color: button.textIdle
    }

    Text {
        anchors.centerIn: parent
        text: button.symbol
        color: button.textIdle
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        renderType: Text.NativeRendering
    }
}
