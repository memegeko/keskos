import QtQuick
import QtQuick.Window

Window {
    id: root

    width: 480
    height: 440
    visible: true
    color: "#050505"
    title: "ABOUT KESKOS"

    Rectangle {
        anchors.fill: parent
        color: "#050505"
        border.width: 1
        border.color: "#ce6a35"
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: Math.ceil(root.height / 4)

            Rectangle {
                x: 0
                y: index * 4
                width: root.width
                height: 1
                color: index % 2 === 0 ? "#090807" : "#070606"
                opacity: 0.28
            }
        }
    }

    Rectangle {
        x: 18
        y: 26
        width: root.width - 36
        height: 1
        color: "#ce6a35"
        opacity: 0.75
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 72
        text: "K E S K   O S"
        color: "#ce6a35"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 34
        font.letterSpacing: 3
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 136
        text: "S.P.L.I.T. EDITION"
        color: "#b8afa6"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 17
        font.letterSpacing: 2
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 170
        text: "BUILT DIFFERENT."
        color: "#8f8a84"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        font.letterSpacing: 2
        renderType: Text.NativeRendering
    }

    Rectangle {
        x: 42
        y: 218
        width: root.width - 84
        height: 1
        color: "#ce6a35"
        opacity: 0.8
    }

    Column {
        x: 52
        y: 244
        spacing: 12

        Repeater {
            model: [
                "VERSION: 1.0-SPLIT",
                "CODENAME: STATIC",
                "ARCHITECTURE: x86_64",
                "KERNEL: 6.6.12-kesk"
            ]

            Text {
                required property string modelData
                text: modelData
                color: "#b8afa6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                font.letterSpacing: 1.2
                renderType: Text.NativeRendering
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 52
        text: "\u00a9 2024 KESK INDUSTRIES"
        color: "#8f8a84"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.letterSpacing: 1.6
        renderType: Text.NativeRendering
    }
}
