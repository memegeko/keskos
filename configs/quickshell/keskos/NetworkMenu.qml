import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property var menuData

    signal networkActionSelected(string action, var networkItem)
    signal quickActionSelected(string action)
    signal dismissRequested()

    readonly property var connectedItems: menuData && menuData.connected ? menuData.connected : []
    readonly property var availableItems: menuData && menuData.available ? menuData.available : []
    readonly property bool wifiEnabled: menuData && menuData.wifi_enabled
    readonly property bool networkingEnabled: menuData && menuData.networking_enabled
    readonly property string currentConnection: menuData && menuData.primary_connection ? menuData.primary_connection : "No active network link"

    width: 322
    implicitWidth: width
    implicitHeight: Math.min(404, contentColumn.implicitHeight + 24)
    color: "#080706"
    border.width: 1
    border.color: root.theme.accent
    clip: true
    focus: true
    Keys.onEscapePressed: root.dismissRequested()

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Repeater {
            model: 18

            Rectangle {
                x: 0
                y: 18 + index * 17
                width: root.width
                height: 1
                color: "#12ce6a35"
            }
        }

        Repeater {
            model: 10

            Rectangle {
                x: 22 + index * 30
                y: 0
                width: 1
                height: root.height
                color: "#10ce6a35"
            }
        }
    }

    ScanlinesOverlay {
        anchors.fill: parent
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Rectangle {
            width: parent.width
            height: 58
            color: "#0d0b09"
            border.width: 1
            border.color: "#26ce6a35"

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    text: root.menuData && root.menuData.status === "CONNECTED" ? "NETWORK ONLINE" : "NETWORK OFFLINE"
                    color: root.theme.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.letterSpacing: 1.0
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    text: root.currentConnection
                    color: root.theme.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 6
            rowSpacing: 6

            PopupActionButton {
                Layout.fillWidth: true
                label: root.wifiEnabled ? "WIFI OFF" : "WIFI ON"
                theme: root.theme
                onPressed: root.quickActionSelected(root.wifiEnabled ? "wifi-off" : "wifi-on")
            }

            PopupActionButton {
                Layout.fillWidth: true
                label: root.networkingEnabled ? "NET OFF" : "NET ON"
                theme: root.theme
                onPressed: root.quickActionSelected(root.networkingEnabled ? "network-off" : "network-on")
            }

            PopupActionButton {
                Layout.fillWidth: true
                label: "RESCAN"
                theme: root.theme
                onPressed: root.quickActionSelected("rescan")
            }

            PopupActionButton {
                Layout.fillWidth: true
                label: "SETTINGS"
                theme: root.theme
                onPressed: root.quickActionSelected("open-settings")
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#34ce6a35"
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 8
            rowSpacing: 4

            Text {
                text: "WIFI"
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.letterSpacing: 0.7
                renderType: Text.NativeRendering
            }

            Text {
                text: root.wifiEnabled ? "ENABLED" : "DISABLED"
                color: root.wifiEnabled ? root.theme.accent : root.theme.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
                renderType: Text.NativeRendering
            }

            Text {
                text: "NETWORK"
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.letterSpacing: 0.7
                renderType: Text.NativeRendering
            }

            Text {
                text: root.networkingEnabled ? "ENABLED" : "DISABLED"
                color: root.networkingEnabled ? root.theme.accent : root.theme.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#26ce6a35"
        }

        Column {
            width: parent.width
            spacing: 6

            Text {
                text: "ACTIVE"
                color: root.theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 0.8
                renderType: Text.NativeRendering
            }

            Text {
                visible: root.connectedItems.length === 0
                text: "No active network session"
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }

            Repeater {
                model: root.connectedItems

                delegate: Rectangle {
                    required property var modelData

                    width: parent.width
                    height: 56
                    color: "transparent"
                    border.width: 1
                    border.color: "#22ce6a35"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            width: 44
                            height: parent.height
                            color: "transparent"
                            border.width: 1
                            border.color: "#22ce6a35"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.kind === "wired" ? "LAN" : "WIFI"
                                color: root.theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                renderType: Text.NativeRendering
                            }
                        }

                        Column {
                            width: 148
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                width: parent.width
                                text: modelData.label
                                color: root.theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                width: parent.width
                                text: modelData.subtitle
                                color: root.theme.accentSoft
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }
                        }

                        PopupActionButton {
                            width: 94
                            anchors.verticalCenter: parent.verticalCenter
                            label: "DISCONNECT"
                            theme: root.theme
                            onPressed: root.networkActionSelected(modelData.action, modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#26ce6a35"
        }

        Column {
            width: parent.width
            spacing: 6

            Text {
                text: "AVAILABLE"
                color: root.theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 0.8
                renderType: Text.NativeRendering
            }

            Text {
                visible: root.availableItems.length === 0
                text: "No saved wireless networks found"
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }

            Repeater {
                model: root.availableItems

                delegate: Rectangle {
                    required property var modelData

                    width: parent.width
                    height: 56
                    color: "transparent"
                    border.width: 1
                    border.color: "#22ce6a35"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            width: 44
                            height: parent.height
                            color: "transparent"
                            border.width: 1
                            border.color: "#22ce6a35"

                            Text {
                                anchors.centerIn: parent
                                text: "WIFI"
                                color: root.theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                renderType: Text.NativeRendering
                            }
                        }

                        Column {
                            width: 148
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                width: parent.width
                                text: modelData.label
                                color: root.theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                width: parent.width
                                text: modelData.subtitle
                                color: root.theme.accentSoft
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }
                        }

                        PopupActionButton {
                            width: 94
                            anchors.verticalCenter: parent.verticalCenter
                            label: "CONNECT"
                            theme: root.theme
                            onPressed: root.networkActionSelected(modelData.action, modelData)
                        }
                    }
                }
            }
        }
    }
}
