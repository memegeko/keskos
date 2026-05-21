import QtQuick
import org.kde.kwin.decoration

Decoration {
    id: root

    property int sideBorder: 6
    property int bottomBorder: 6
    property int topInset: 4
    property int titleHeight: 36

    property color activeAccent: "#ce6a35"
    property color inactiveAccent: "#6e4128"
    property color activeBg: "#050505"
    property color inactiveBg: "#040404"
    property color activeTitleBg: "#070707"
    property color inactiveTitleBg: "#050505"
    property color activeText: "#ce6a35"
    property color inactiveText: "#8f8a84"

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
        height: 1
        color: root.accent
        opacity: 0.7
    }

    Rectangle {
        x: root.frameSide
        y: root.titleHeight + root.topInset - 1
        width: root.width - (root.frameSide * 2)
        height: 1
        color: root.accent
        opacity: 0.45
    }

    Rectangle {
        x: root.frameSide + 10
        y: 7
        width: 12
        height: 1
        color: root.accent
        opacity: 0.55
    }

    Rectangle {
        x: root.width - root.frameSide - 22
        y: 7
        width: 12
        height: 1
        color: root.accent
        opacity: 0.55
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
        x: 5
        y: 5
        width: 1
        height: 12
        color: root.accent
        opacity: 0.6
    }

    Rectangle {
        x: 5
        y: 5
        width: 12
        height: 1
        color: root.accent
        opacity: 0.6
    }

    Rectangle {
        x: root.width - 17
        y: root.height - 6
        width: 12
        height: 1
        color: root.accent
        opacity: 0.6
    }

    Rectangle {
        x: root.width - 6
        y: root.height - 17
        width: 1
        height: 12
        color: root.accent
        opacity: 0.6
    }

    Image {
        id: logoMark
        x: root.frameSide + 7
        y: Math.round(((root.titleHeight + root.topInset) - height) / 2)
        width: 18
        height: 18
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        source: "../assets/kesk_os_logo-removebg.png"
    }

    Item {
        id: buttonRow
        anchors {
            right: parent.right
            rightMargin: root.frameSide + 7
            top: parent.top
            topMargin: 8
        }
        width: childrenRect.width
        height: 24

        Row {
            spacing: 5

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
        x: logoMark.x + logoMark.width + 8
        y: 0
        width: buttonRow.x - x - 12
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
            font.pixelSize: 16
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
