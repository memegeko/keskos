import QtQuick
import org.kde.kwin.decoration

Decoration {
    id: root

    property int sideBorder: 7
    property int bottomBorder: 7
    property int topInset: 6
    property int titleHeight: 34

    property color activeAccent: "#ce6a35"
    property color inactiveAccent: "#845236"
    property color activeBg: "#050403"
    property color inactiveBg: "#040302"
    property color activeTitleBg: "#0a0806"
    property color inactiveTitleBg: "#070504"
    property color activeText: "#e7c9b3"
    property color inactiveText: "#b6937c"

    readonly property color accent: decoration.client.active ? activeAccent : inactiveAccent
    readonly property color chromeBg: decoration.client.active ? activeTitleBg : inactiveTitleBg
    readonly property color bodyBg: decoration.client.active ? activeBg : inactiveBg
    readonly property color captionColor: decoration.client.active ? activeText : inactiveText
    readonly property bool maximizedLike: decoration.client.maximized
    readonly property int frameSide: maximizedLike ? 1 : sideBorder
    readonly property int frameBottom: maximizedLike ? 1 : bottomBorder

    function updateBorders() {
        borders.setBorders(frameSide)
        borders.setTitle(titleHeight + topInset)
        maximizedBorders.setTitle(titleHeight + topInset)
    }

    alpha: false

    Rectangle {
        anchors.fill: parent
        color: root.bodyBg
        border.width: 1
        border.color: root.accent
    }

    Rectangle {
        x: root.frameSide
        y: 0
        width: root.width - (root.frameSide * 2)
        height: root.titleHeight + root.topInset
        color: root.chromeBg
    }

    Rectangle {
        x: root.frameSide
        y: 1
        width: root.width - (root.frameSide * 2)
        height: 2
        color: root.accent
    }

    Rectangle {
        x: root.frameSide
        y: root.titleHeight + root.topInset - 1
        width: root.width - (root.frameSide * 2)
        height: 2
        color: root.accent
    }

    Rectangle {
        x: root.frameSide + 8
        y: 8
        width: 18
        height: 1
        color: root.accent
    }

    Rectangle {
        x: root.width - root.frameSide - 26
        y: 8
        width: 18
        height: 1
        color: root.accent
    }

    Rectangle {
        x: 1
        y: root.titleHeight + root.topInset
        width: root.frameSide
        height: root.height - root.titleHeight - root.topInset - root.frameBottom - 1
        color: root.bodyBg
    }

    Rectangle {
        x: root.width - root.frameSide - 1
        y: root.titleHeight + root.topInset
        width: root.frameSide
        height: root.height - root.titleHeight - root.topInset - root.frameBottom - 1
        color: root.bodyBg
    }

    Rectangle {
        x: root.frameSide
        y: root.height - root.frameBottom - 1
        width: root.width - (root.frameSide * 2)
        height: root.frameBottom
        color: root.bodyBg
    }

    Rectangle {
        x: 6
        y: 6
        width: 1
        height: 14
        color: root.accent
    }

    Rectangle {
        x: 6
        y: 6
        width: 14
        height: 1
        color: root.accent
    }

    Rectangle {
        x: root.width - 20
        y: root.height - 7
        width: 14
        height: 1
        color: root.accent
    }

    Rectangle {
        x: root.width - 7
        y: root.height - 20
        width: 1
        height: 14
        color: root.accent
    }

    Image {
        id: logoMark
        x: root.frameSide + 6
        y: Math.round(((root.titleHeight + root.topInset) - height) / 2)
        width: 20
        height: 20
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        source: "../assets/kesk_os_logo-removebg.png"
    }

    Item {
        id: buttonRow
        anchors {
            right: parent.right
            rightMargin: root.frameSide + 8
            top: parent.top
            topMargin: 7
        }
        width: childrenRect.width
        height: 26

        Row {
            spacing: 6

            KeskButton {
                buttonType: DecorationOptions.DecorationButtonMinimize
            }

            KeskButton {
                buttonType: DecorationOptions.DecorationButtonMaximizeRestore
            }

            KeskButton {
                buttonType: DecorationOptions.DecorationButtonClose
            }
        }
    }

    Item {
        id: titleArea
        x: logoMark.x + logoMark.width + 6
        y: 0
        width: buttonRow.x - x - 10
        height: root.titleHeight + root.topInset

        Component.onCompleted: {
            decoration.installTitleItem(titleArea)
        }

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            text: decoration.client.caption
            color: root.captionColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            elide: Text.ElideRight
            width: parent.width
            renderType: Text.NativeRendering
        }
    }

    Component.onCompleted: {
        root.updateBorders()
    }

    Connections {
        target: decoration.client

        function onMaximizedChanged() {
            root.updateBorders()
        }
    }
}
