import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 770
    property int panelHeight: 420

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(14 * root.scaleFactor)

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "LOCAL IP:"
            value: root.dataObject.local_ip || "n/a"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "GATEWAY:"
            value: root.dataObject.gateway || "n/a"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "CONNECTION:"
            value: root.dataObject.connection || "Disconnected"
        }

        HudRule {
            width: Math.round(690 * root.scaleFactor)
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "DOWNLOAD:"
            value: root.dataObject.down || "0 B/s"
        }

        Item {
            width: root.panelWidth
            height: Math.round(32 * root.scaleFactor)

            BarStrip {
                x: Math.round(182 * root.scaleFactor)
                stripWidth: Math.round(454 * root.scaleFactor)
                stripHeight: Math.round(32 * root.scaleFactor)
                scaleFactor: root.scaleFactor
                values: root.dataObject.download_history || []
            }
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "UPLOAD:"
            value: root.dataObject.up || "0 B/s"
        }

        Item {
            width: root.panelWidth
            height: Math.round(24 * root.scaleFactor)

            BarStrip {
                x: Math.round(182 * root.scaleFactor)
                stripWidth: Math.round(454 * root.scaleFactor)
                stripHeight: Math.round(24 * root.scaleFactor)
                scaleFactor: root.scaleFactor
                values: root.dataObject.upload_history || []
            }
        }

        HudRule {
            width: Math.round(690 * root.scaleFactor)
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(182 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "STATUS:"
            value: root.dataObject.status || "OFFLINE"
        }
    }
}
