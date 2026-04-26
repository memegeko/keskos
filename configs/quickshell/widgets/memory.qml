import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 385
    property int panelHeight: 152

    width: panelWidth
    height: panelHeight
    clip: true

    Column {
        anchors.fill: parent
        spacing: Math.round(4 * root.scaleFactor)

        GlowText {
            text: "MEMORY"
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
            label: "TOTAL"
            value: root.dataObject.total || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "USED"
            value: root.dataObject.used || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "USAGE"
            value: root.dataObject.percent || "--"
        }

        GlowText {
            text: root.dataObject.bar || "[....................]"
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(root.scaleFactor)
        }
    }
}
