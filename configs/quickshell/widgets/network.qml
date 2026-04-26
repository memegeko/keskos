import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 385
    property int panelHeight: 172

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(4 * root.scaleFactor)

        GlowText {
            text: "NETWORK"
            fontSize: Math.round(17 * root.scaleFactor)
            fontWeight: Font.DemiBold
            letterSpacing: Math.round(3 * root.scaleFactor)
        }

        HudRule {
            width: parent.width
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "IP"
            value: root.dataObject.local_ip || "n/a"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "GATEWAY"
            value: root.dataObject.gateway || "n/a"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "STATUS"
            value: root.dataObject.status || "offline"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "DOWN"
            value: root.dataObject.down || "0 B/s"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "UP"
            value: root.dataObject.up || "0 B/s"
        }
    }
}
