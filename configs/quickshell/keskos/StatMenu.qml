import QtQuick

Rectangle {
    id: root

    required property var theme
    required property string title
    required property var rows
    property string footerText: ""
    property string actionLabel: ""
    property string meterLabel: ""
    property int meterValue: -1

    signal actionRequested()
    signal dismissRequested()

    width: 288
    implicitWidth: width
    implicitHeight: outerColumn.implicitHeight + 20
    color: "#080706"
    border.width: 1
    border.color: root.theme.accent
    focus: true
    Keys.onEscapePressed: root.dismissRequested()

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#45ce6a35"
    }

    ScanlinesOverlay {
        anchors.fill: parent
    }

    Column {
        id: outerColumn
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            id: headerBox
            width: parent.width
            height: 28
            color: "#0d0b09"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: root.title
                color: root.theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 1.0
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            visible: root.meterValue >= 0
            width: parent.width
            height: visible ? 58 : 0
            color: "#0b0908"
            border.width: 1
            border.color: "#18ce6a35"

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.meterLabel
                        color: root.theme.accentSoft
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.letterSpacing: 0.7
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.meterValue >= 0 ? root.meterValue + "%" : ""
                        color: root.theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.letterSpacing: 0.7
                        renderType: Text.NativeRendering
                    }
                }

                Row {
                    spacing: 3

                    Repeater {
                        model: 28

                        Rectangle {
                            width: 6
                            height: 14
                            color: index < Math.ceil((Math.max(0, root.meterValue) * 28) / 100)
                                ? root.theme.accent
                                : "#15110e"
                            border.width: 1
                            border.color: index < Math.ceil((Math.max(0, root.meterValue) * 28) / 100)
                                ? "#60ce6a35"
                                : "#1a34302b"
                        }
                    }
                }
            }
        }

        Column {
            id: rowColumn
            width: parent.width
            spacing: 2

            Repeater {
                model: root.rows

                delegate: Rectangle {
                    required property var modelData

                    width: rowColumn.width
                    height: 28
                    color: "transparent"
                    border.width: 1
                    border.color: "#18ce6a35"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: modelData.label
                        color: root.theme.accentSoft
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.letterSpacing: 0.7
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        text: modelData.value
                        color: modelData.highlight ? root.theme.accent : root.theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        PopupActionButton {
            visible: root.actionLabel.length > 0
            width: parent.width
            label: root.actionLabel
            theme: root.theme
            onPressed: root.actionRequested()
        }

        Rectangle {
            id: footerBox
            visible: root.footerText.length > 0
            width: parent.width
            height: visible ? 46 : 0
            color: "#0b0908"
            border.width: 1
            border.color: "#18ce6a35"

            Text {
                anchors.fill: parent
                anchors.margins: 10
                verticalAlignment: Text.AlignVCenter
                text: root.footerText
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
            }
        }
    }
}
