import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 984
    property int panelHeight: 310

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(14 * root.scaleFactor)

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(176 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "TOTAL RAM:"
            value: root.dataObject.total || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(176 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "USED RAM:"
            value: root.dataObject.used || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(176 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "FREE RAM:"
            value: root.dataObject.free || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            labelWidth: Math.round(176 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            label: "USAGE:"
            value: root.dataObject.percent || "--"
        }

        HudRule {
            width: Math.round(118 * root.scaleFactor)
        }

        SegmentMeter {
            meterWidth: Math.round(904 * root.scaleFactor)
            meterHeight: Math.round(54 * root.scaleFactor)
            scaleFactor: root.scaleFactor
            totalSegments: 28
            filledSegments: Number(root.dataObject.segments_filled || 0)
        }
    }
}
