import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property real scaleFactor: Number(Quickshell.env("KESKOS_QS_SCALE") || 1.0)
    property string helperPath: (Quickshell.env("HOME") || "") + "/.local/bin/keskos-quickshell-data"

    readonly property int sideMargin: Math.round(76 * scaleFactor)
    readonly property int topOffset: Math.round(79 * scaleFactor)
    readonly property int gapTopMiddle: Math.round(120 * scaleFactor)
    readonly property int gapMiddleBottom: Math.round(141 * scaleFactor)
    readonly property int panelWidth: Math.round(385 * scaleFactor)
    readonly property int topLeftHeight: Math.round(152 * scaleFactor)
    readonly property int topRightHeight: Math.round(172 * scaleFactor)
    readonly property int middleLeftHeight: Math.round(152 * scaleFactor)
    readonly property int middleRightHeight: Math.round(152 * scaleFactor)
    readonly property int bottomLeftHeight: Math.round(172 * scaleFactor)
    readonly property int bottomRightHeight: Math.round(152 * scaleFactor)

    readonly property var systemStatusFallback: ({
        "os": "Arch Linux",
        "kernel": "--",
        "uptime": "--",
        "shell": "--",
        "session": "KDE Plasma / wayland"
    })

    readonly property var networkFallback: ({
        "interface": "lo",
        "status": "offline",
        "local_ip": "n/a",
        "gateway": "n/a",
        "down": "0 B/s",
        "up": "0 B/s"
    })

    readonly property var systemLogFallback: ({
        "lines": [
            "BOOTSTRAP CHANNEL READY",
            "HUD OVERLAY STANDBY",
            "WAYLAND LINK ACTIVE",
            "COMMAND LAYER IDLE",
            "MEMORY TELEMETRY OK",
            "NETWORK WATCH ACTIVE"
        ]
    })

    readonly property var systemProfileFallback: ({
        "host": "kesk-node",
        "user": "user",
        "machine": "x86_64",
        "session": "KDE Plasma / wayland",
        "uptime": "n/a"
    })

    readonly property var memoryFallback: ({
        "total": "0 GiB",
        "used": "0 GiB",
        "percent": "0%",
        "bar": "[....................]"
    })

    property var systemStatusData: systemStatusFallback
    property var networkData: networkFallback
    property var systemLogData: systemLogFallback
    property var systemProfileData: systemProfileFallback
    property var memoryData: memoryFallback

    function parseObjectJson(text, fallback) {
        try {
            let parsed = JSON.parse(text.trim())
            return parsed && typeof parsed === "object" ? parsed : fallback
        } catch (error) {
            return fallback
        }
    }

    function parseArrayJson(text, fallback) {
        try {
            let parsed = JSON.parse(text.trim())
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
                    x: root.sideMargin
                    y: root.topOffset
                    source: Quickshell.shellRoot + "/widgets/system_status.qml"
                    widgetData: root.systemStatusData
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.topLeftHeight
                }

                HudWidgetLoader {
                    x: root.sideMargin
                    y: root.topOffset + root.topLeftHeight + root.gapTopMiddle
                    source: Quickshell.shellRoot + "/widgets/core_modules.qml"
                    widgetData: ({})
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.middleLeftHeight
                }

                HudWidgetLoader {
                    x: root.sideMargin
                    y: root.topOffset + root.topLeftHeight + root.gapTopMiddle + root.middleLeftHeight + root.gapMiddleBottom
                    source: Quickshell.shellRoot + "/widgets/network.qml"
                    widgetData: root.networkData
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.bottomLeftHeight
                }

                HudWidgetLoader {
                    x: parent.width - root.sideMargin - root.panelWidth
                    y: root.topOffset
                    source: Quickshell.shellRoot + "/widgets/system_log.qml"
                    widgetData: root.systemLogData
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.topRightHeight
                }

                HudWidgetLoader {
                    x: parent.width - root.sideMargin - root.panelWidth
                    y: root.topOffset + root.topRightHeight + root.gapTopMiddle
                    source: Quickshell.shellRoot + "/widgets/system_profile.qml"
                    widgetData: root.systemProfileData
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.middleRightHeight
                }

                HudWidgetLoader {
                    x: parent.width - root.sideMargin - root.panelWidth
                    y: root.topOffset + root.topRightHeight + root.gapTopMiddle + root.middleRightHeight + root.gapMiddleBottom
                    source: Quickshell.shellRoot + "/widgets/memory.qml"
                    widgetData: root.memoryData
                    uiScale: root.scaleFactor
                    widgetWidth: root.panelWidth
                    widgetHeight: root.bottomRightHeight
                }
            }
        }
    }
}
