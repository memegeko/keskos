import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 770
    property int panelHeight: 334

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(15 * root.scaleFactor)

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "SYS_MONITOR"
            leader: ".........."
            status: "OK"
        }

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "NET_MANAGER"
            leader: ".........."
            status: "OK"
        }

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "FILE_SYSTEM"
            leader: ".........."
            status: "OK"
        }

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "PROCESSOR"
            leader: ".........."
            status: "OK"
        }

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "MEMORY"
            leader: ".........."
            status: "OK"
        }

        HudLeaderRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "DISPLAY_SERVER"
            leader: ".........."
            status: "OK"
        }
    }
}
