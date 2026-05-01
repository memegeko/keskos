import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    property string debugText: "Awaiting Calamares session output..."
    property string stageText: "> Installer console online.\n> Waiting for partition and copy jobs to begin."
    property string summaryText: "> Live desktop: active\n> Installer backend: armed\n> Target root pipeline: ready"
    property string profileText: "- Filesystem: Arch defaults from Calamares\n- Bootloader: GRUB (EFI)\n- Desktop: KDE Plasma (KeskOS edition)\n- Branding: KeskOS dark console stack\n- Login: prefilled username on first boot"
    property string notesText: "- Meta / Meta+K opens the Kesk launcher.\n- Browser and Dolphin are staged for live-session testing.\n- Detailed installer output is written to ~/.cache/keskos/calamares-installer.log"
    property var logSources: [
        "file:///home/liveuser/.cache/keskos/calamares-installer.log",
        "file:///home/liveuser/.cache/calamares/session.log",
        "file:///root/.cache/calamares/session.log"
    ]

    function readTextFile(url) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, false)
        xhr.send()
        if (xhr.status === 0 || xhr.status === 200) {
            return xhr.responseText
        }
        return ""
    }

    function readInstallerLog() {
        for (var i = 0; i < logSources.length; ++i) {
            var content = readTextFile(logSources[i])
            if (content && content.trim().length > 0) {
                return content
            }
        }
        return ""
    }

    function tailLines(text, count) {
        var lines = text.split(/\r?\n/)
        var filtered = []
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].trim().length > 0) {
                filtered.push(lines[i])
            }
        }
        if (filtered.length === 0) {
            return "Awaiting Calamares session output..."
        }
        var start = Math.max(0, filtered.length - count)
        return filtered.slice(start).join("\n")
    }

    function detectStage(text) {
        if (!text || text.trim().length === 0) {
            return "> Installer console online.\n> Waiting for partition and copy jobs to begin."
        }

        if (text.indexOf("ERROR:") >= 0 || text.indexOf("Installation failed") >= 0) {
            return "> Fault detected in install pipeline.\n> Review the live debug stream below for the failing command."
        }
        if (text.indexOf("Starting job \"bootloader\"") >= 0 || text.indexOf("grub-install") >= 0) {
            return "> Bootloader deployment in progress.\n> Finalizing boot path and firmware entry."
        }
        if (text.indexOf("Starting job \"Creating initramfs") >= 0 || text.indexOf("mkinitcpio") >= 0) {
            return "> Building initramfs and kernel boot image.\n> Verifying target /boot layout."
        }
        if (text.indexOf("Starting job \"Filling up filesystems") >= 0 || text.indexOf("unpackfs") >= 0) {
            return "> Expanding the live image into the target filesystem.\n> This is usually the longest stage."
        }
        if (text.indexOf("Starting job \"Configuring users") >= 0 || text.indexOf("Set password for user") >= 0) {
            return "> Applying user profile and hostname data.\n> Writing login defaults for the installed system."
        }
        if (text.indexOf("Starting job \"Mounting") >= 0 || text.indexOf("mount") >= 0) {
            return "> Target disks mounted.\n> Preparing root layout for deployment."
        }
        if (text.indexOf("partition") >= 0 || text.indexOf("Create new") >= 0) {
            return "> Disk partitioning and filesystem layout active.\n> Waiting for copy phase."
        }
        return "> Installer pipeline active.\n> Live debug stream is following Calamares in real time."
    }

    function detectSummary(text) {
        var lines = [
            "> Live desktop: active",
            "> Installer backend: armed",
            "> Target root pipeline: ready"
        ]

        if (text.indexOf("internet") >= 0 || text.indexOf("NetworkManager") >= 0) {
            lines.push("> Network path: available")
        }
        if (text.indexOf("Set keyboard") >= 0 || text.indexOf("SetKeyboardLayoutJob") >= 0) {
            lines.push("> Keyboard layout: staged")
        }
        if (text.indexOf("locale") >= 0 || text.indexOf("Set timezone") >= 0) {
            lines.push("> Locale + time: staged")
        }
        return lines.join("\n")
    }

    function refreshDebug() {
        var log = readInstallerLog()
        debugText = tailLines(log, 12)
        stageText = detectStage(log)
        summaryText = detectSummary(log)
    }

    Timer {
        interval: 1200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: presentation.refreshDebug()
    }

    Slide {
        id: slide
        width: parent ? parent.width : 1280
        height: parent ? parent.height : 720
        clip: true

        Rectangle {
            anchors.fill: parent
            color: "#050403"

            Image {
                anchors.fill: parent
                source: "wallpaper.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.10
                smooth: true
            }

            Rectangle {
                anchors.fill: parent
                color: "#050403"
                opacity: 0.92
            }

            Item {
                anchors.fill: parent
                anchors.margins: 22

                Column {
                    anchors.fill: parent
                    spacing: 18

                    Item {
                        width: parent.width
                        height: 44

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 160
                                height: 2
                                color: "#ce6a35"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "[ KESKOS INSTALLATION CONSOLE ]"
                                color: "#ce6a35"
                                font.family: "VT323"
                                font.pixelSize: 32
                            }

                            Rectangle {
                                width: Math.max(80, slide.width - 760)
                                height: 2
                                color: "#ce6a35"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 210
                        spacing: 18

                        Rectangle {
                            width: parent.width * 0.56
                            height: parent.height
                            color: "#040303"
                            border.color: "#ce6a35"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                Text {
                                    text: "[ DEPLOY STATUS ]"
                                    color: "#ce6a35"
                                    font.family: "VT323"
                                    font.pixelSize: 28
                                }

                                Text {
                                    width: parent.width
                                    text: presentation.stageText
                                    color: "#e7c9b3"
                                    wrapMode: Text.WordWrap
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 15
                                    lineHeight: 1.16
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#7a4e36"
                                }

                                Text {
                                    width: parent.width
                                    text: presentation.summaryText
                                    color: "#e7c9b3"
                                    wrapMode: Text.WordWrap
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    lineHeight: 1.14
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - (parent.width * 0.56) - 18
                            height: parent.height
                            color: "#040303"
                            border.color: "#ce6a35"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                Text {
                                    text: "[ INSTALL PROFILE ]"
                                    color: "#ce6a35"
                                    font.family: "VT323"
                                    font.pixelSize: 28
                                }

                                Text {
                                    width: parent.width
                                    text: presentation.profileText
                                    color: "#e7c9b3"
                                    wrapMode: Text.WordWrap
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    lineHeight: 1.14
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#7a4e36"
                                }

                                Text {
                                    text: "[ LIVE SYSTEM NOTES ]"
                                    color: "#ce6a35"
                                    font.family: "VT323"
                                    font.pixelSize: 24
                                }

                                Text {
                                    width: parent.width
                                    text: presentation.notesText
                                    color: "#e7c9b3"
                                    wrapMode: Text.WordWrap
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    lineHeight: 1.12
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 44 - 210 - 36
                        color: "#040303"
                        border.color: "#ce6a35"
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Row {
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: "[ LIVE DEBUG STREAM ]"
                                    color: "#ce6a35"
                                    font.family: "VT323"
                                    font.pixelSize: 30
                                }

                                Rectangle {
                                    width: parent.width - 410
                                    height: 1
                                    color: "#7a4e36"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                width: parent.width
                                text: "> Watching ~/.cache/keskos/calamares-installer.log in real time."
                                color: "#ce6a35"
                                wrapMode: Text.WordWrap
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#7a4e36"
                            }

                            Text {
                                width: parent.width
                                height: parent.height - 92
                                text: presentation.debugText
                                color: "#e7c9b3"
                                wrapMode: Text.WordWrap
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                lineHeight: 1.10
                                elide: Text.ElideNone
                                clip: true
                            }
                        }
                    }
                }
            }
        }
    }
}
