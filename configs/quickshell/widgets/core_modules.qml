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
            text: "CORE MODULES"
            fontSize: Math.round(17 * root.scaleFactor)
            fontWeight: Font.DemiBold
            letterSpacing: Math.round(3 * root.scaleFactor)
        }

        HudRule {
            width: parent.width
        }

        GlowText { text: "SYS_MONITOR .... OK"; fontSize: Math.round(12 * root.scaleFactor) }
        GlowText { text: "NET_MANAGER .... OK"; fontSize: Math.round(12 * root.scaleFactor) }
        GlowText { text: "FILE_SYSTEM .... OK"; fontSize: Math.round(12 * root.scaleFactor) }
        GlowText { text: "PROCESSOR ...... OK"; fontSize: Math.round(12 * root.scaleFactor) }
        GlowText { text: "MEMORY ......... OK"; fontSize: Math.round(12 * root.scaleFactor) }
        GlowText { text: "DISPLAY_SERVER . OK"; fontSize: Math.round(12 * root.scaleFactor) }
    }
}
