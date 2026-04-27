import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 768
    property int panelHeight: 288

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(18 * root.scaleFactor)

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "OS:"
            value: root.dataObject.os || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "KERNEL:"
            value: root.dataObject.kernel || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "UPTIME:"
            value: root.dataObject.uptime || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "SHELL:"
            value: root.dataObject.shell || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(158 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "SESSION:"
            value: root.dataObject.session || "--"
        }
    }
}
