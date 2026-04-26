import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property real scaleFactor: Number(Quickshell.env("KESKOS_QS_SCALE") || 0.46875)
    property string helperPath: (Quickshell.env("HOME") || "") + "/.local/bin/keskos-quickshell-data"

    readonly property var zeroBars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property var systemStatusFallback: ({
        "os": "Arch Linux",
        "kernel": "--",
        "uptime": "--",
        "shell": "--",
        "session": "KDE Plasma (Wayland)"
    })

    readonly property var networkFallback: ({
        "interface": "lo",
        "connection": "Disconnected",
        "status": "OFFLINE",
        "local_ip": "n/a",
        "gateway": "n/a",
        "down": "0 B/s",
        "up": "0 B/s",
        "download_history": root.zeroBars,
        "upload_history": root.zeroBars
    })

    readonly property var systemLogFallback: ({
        "lines": [
            "[12:45:10] bootstrap: Signal channel ready",
            "[12:45:11] display: Wayland overlay linked",
            "[12:45:12] network: Watch process active",
            "[12:45:13] memory: Telemetry online",
            "[12:45:14] profile: Access control synced",
            "[12:45:15] keskos: Awaiting input..."
        ]
    })

    readonly property var systemProfileFallback: ({
        "host": "kesk-node-01",
        "user": "user",
        "machine": "x86_64",
        "session": "KDE Plasma (Wayland)",
        "uptime": "n/a",
        "node": "KESK-01",
        "access": "GRANTED",
        "clearance": "USER"
    })

    readonly property var memoryFallback: ({
        "total": "0 GiB",
        "used": "0 GiB",
        "free": "0 GiB",
        "percent": "0%",
        "percent_value": 0,
        "segments_filled": 0
    })

    property var systemStatusData: systemStatusFallback
    property var networkData: networkFallback
    property var systemLogData: systemLogFallback
    property var systemProfileData: systemProfileFallback
    property var memoryData: memoryFallback

    function s(value) {
        return Math.round(value * scaleFactor)
    }

    function parseObjectJson(text, fallback) {
        try {
            const parsed = JSON.parse(text.trim())
            return parsed && typeof parsed === "object" ? parsed : fallback
        } catch (error) {
            return fallback
        }
    }

    function parseArrayJson(text, fallback) {
        try {
            const parsed = JSON.parse(text.trim())
            return Array.isArray(parsed) ? { "lines": parsed } : fallback
        } catch (error) {
            return fallback
        }
    }

    component HudWidgetLoader: Loader {
        property var widgetData: ({})
        property real uiScale: 1.0
        property int widgetWidth: 0
        property int widgetHeight: 0

        onLoaded: {
            if (!item) {
                return
            }

            item.dataObject = Qt.binding(function() { return widgetData })
            item.scaleFactor = Qt.binding(function() { return uiScale })
            item.panelWidth = Qt.binding(function() { return widgetWidth })
            item.panelHeight = Qt.binding(function() { return widgetHeight })
        }
    }

    Process {
        id: systemStatusProc
        command: [root.helperPath, "system-status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.systemStatusData = root.parseObjectJson(this.text, root.systemStatusFallback)
        }
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        onTriggered: systemStatusProc.running = true
    }

    Process {
        id: networkProc
        command: [root.helperPath, "network"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.networkData = root.parseObjectJson(this.text, root.networkFallback)
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: networkProc.running = true
    }

    Process {
        id: systemLogProc
        command: [root.helperPath, "system-log"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.systemLogData = root.parseArrayJson(this.text, root.systemLogFallback)
        }
    }

    Timer {
        interval: 20000
        repeat: true
        running: true
        onTriggered: systemLogProc.running = true
    }

    Process {
        id: systemProfileProc
        command: [root.helperPath, "system-profile"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.systemProfileData = root.parseObjectJson(this.text, root.systemProfileFallback)
        }
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        onTriggered: systemProfileProc.running = true
    }

    Process {
        id: memoryProc
        command: [root.helperPath, "memory"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.memoryData = root.parseObjectJson(this.text, root.memoryFallback)
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: memoryProc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            color: "transparent"
            focusable: false
            aboveWindows: true
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                width: 0
                height: 0
            }

            Item {
                anchors.fill: parent

                HudWidgetLoader {
                    x: root.s(118)
                    y: root.s(266)
                    source: Quickshell.shellRoot + "/widgets/system_status.qml"
                    widgetData: root.systemStatusData
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(768)
                    widgetHeight: root.s(288)
                }

                HudWidgetLoader {
                    x: root.s(118)
                    y: root.s(882)
                    source: Quickshell.shellRoot + "/widgets/core_modules.qml"
                    widgetData: ({})
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(770)
                    widgetHeight: root.s(334)
                }

                HudWidgetLoader {
                    x: root.s(118)
                    y: root.s(1556)
                    source: Quickshell.shellRoot + "/widgets/network.qml"
                    widgetData: root.networkData
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(770)
                    widgetHeight: root.s(420)
                }

                HudWidgetLoader {
                    x: root.s(2878)
                    y: root.s(266)
                    source: Quickshell.shellRoot + "/widgets/system_log.qml"
                    widgetData: root.systemLogData
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(1088)
                    widgetHeight: root.s(406)
                }

                HudWidgetLoader {
                    x: root.s(2964)
                    y: root.s(980)
                    source: Quickshell.shellRoot + "/widgets/system_profile.qml"
                    widgetData: root.systemProfileData
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(984)
                    widgetHeight: root.s(380)
                }

                HudWidgetLoader {
                    x: root.s(2964)
                    y: root.s(1670)
                    source: Quickshell.shellRoot + "/widgets/memory.qml"
                    widgetData: root.memoryData
                    uiScale: root.scaleFactor
                    widgetWidth: root.s(984)
                    widgetHeight: root.s(310)
                }
            }
        }
    }
}
