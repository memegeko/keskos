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

    property var lines: (root.dataObject && root.dataObject.lines) ? root.dataObject.lines : []

    Column {
        anchors.fill: parent
        spacing: Math.round(4 * root.scaleFactor)

        GlowText {
            text: "SYSTEM LOG"
            fontSize: Math.round(17 * root.scaleFactor)
            fontWeight: Font.DemiBold
            letterSpacing: Math.round(3 * root.scaleFactor)
        }

        HudRule {
            width: parent.width
        }

        Repeater {
            model: root.lines

            GlowText {
                width: root.panelWidth
                text: modelData
                fontSize: Math.round(11 * root.scaleFactor)
                letterSpacing: Math.round(0.5 * root.scaleFactor)
            }
        }
    }
}
