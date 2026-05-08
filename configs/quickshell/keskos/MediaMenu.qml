import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var menuData

    signal actionSelected(string action)
    signal dismissRequested()

    width: 336
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
            width: parent.width
            height: 28
            color: "#0d0b09"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: "MEDIA LINK"
                color: root.theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 1.0
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: mediaRow.implicitHeight + 16
            color: "#0b0908"
            border.width: 1
            border.color: "#18ce6a35"

            Row {
                id: mediaRow
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Rectangle {
                    id: mediaCoverFrame
                    width: 92
                    height: 92
                    color: "#100d0b"
                    border.width: 1
                    border.color: "#30ce6a35"

                    readonly property bool hasSource: coverImage.source.toString().length > 0
                    readonly property bool showFallback: !hasSource || coverImage.status === Image.Error

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.menuData.art_url || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: mediaCoverFrame.hasSource
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "NO\nART"
                        horizontalAlignment: Text.AlignHCenter
                        color: root.theme.accentSoft
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.letterSpacing: 0.8
                        renderType: Text.NativeRendering
                        visible: mediaCoverFrame.showFallback
                    }
                }

                Column {
                    width: 172
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.menuData.title || "No active player"
                        color: root.theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.letterSpacing: 0.6
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: root.menuData.artist || "Start playback in a media app"
                        color: root.theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: (root.menuData.player || "PLAYER") + " // " + (root.menuData.status || "IDLE")
                        color: root.theme.accentSoft
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Row {
                        spacing: 6

                        Repeater {
                            model: [
                                { "label": "<<", "action": "previous" },
                                { "label": (root.menuData.status === "PLAYING" ? "PAUSE" : "PLAY"), "action": "toggle" },
                                { "label": ">>", "action": "next" }
                            ]

                            delegate: Rectangle {
                                required property var modelData

                                width: modelData.label === "PAUSE" || modelData.label === "PLAY" ? 64 : 34
                                height: 24
                                color: mediaButtonMouse.containsMouse ? root.theme.hoverFill : "#120f0d"
                                border.width: 1
                                border.color: mediaButtonMouse.containsMouse ? root.theme.accent : "#24ce6a35"
                                opacity: root.menuData.active ? 1.0 : 0.55

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.theme.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.7
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: mediaButtonMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.menuData.active
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.actionSelected(modelData.action)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 22
                        color: "#0f0c0a"
                        border.width: 1
                        border.color: "#18ce6a35"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, Math.round(parent.width * ((root.menuData.progress_percent || 0) / 100))))
                            color: "#30ce6a35"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            height: 2
                            width: Math.max(0, Math.min(parent.width, Math.round(parent.width * ((root.menuData.progress_percent || 0) / 100))))
                            color: "#63ce6a35"
                        }
                    }

                    Item {
                        width: parent.width
                        height: 14

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.menuData.position || "0:00"
                            color: root.theme.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.menuData.length || "0:00"
                            color: root.theme.accentSoft
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    width: 22
                    height: 92
                    color: "#0f0c0a"
                    border.width: 1
                    border.color: "#24ce6a35"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: 10

                            Rectangle {
                                width: 8
                                height: 6
                                color: (9 - index) < Math.ceil((root.menuData.volume_percent || 0) / 10)
                                    ? root.theme.accent
                                    : "#15110e"
                                border.width: 1
                                border.color: (9 - index) < Math.ceil((root.menuData.volume_percent || 0) / 10)
                                    ? "#60ce6a35"
                                    : "#1a34302b"
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 32
            color: "#0b0908"
            border.width: 1
            border.color: "#18ce6a35"

            Text {
                anchors.fill: parent
                anchors.margins: 10
                verticalAlignment: Text.AlignVCenter
                text: root.menuData.active
                    ? ((root.menuData.album || "Now Playing") + " // VOL " + (root.menuData.volume_percent || 0) + "%")
                    : "No active MPRIS player detected. Start audio in Firefox, Spotify, VLC, or another media app."
                color: root.theme.accentSoft
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }
    }
}
