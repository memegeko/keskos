import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 984
    property int panelHeight: 380

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(13 * root.scaleFactor)

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "HOST:"
            value: root.dataObject.host || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "USER:"
            value: root.dataObject.user || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "MACHINE:"
            value: root.dataObject.machine || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "SESSION:"
            value: root.dataObject.session || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "UPTIME:"
            value: root.dataObject.uptime || "--"
        }

        HudRule {
            width: Math.round(920 * root.scaleFactor)
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "NODE:"
            value: root.dataObject.node || "KESK-01"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "ACCESS:"
            value: root.dataObject.access || "GRANTED"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "CLEARANCE:"
            value: root.dataObject.clearance || "USER"
        }
    }
}
