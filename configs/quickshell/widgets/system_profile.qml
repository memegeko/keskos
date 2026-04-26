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
            text: "SYSTEM PROFILE"
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
            label: "HOST"
            value: root.dataObject.host || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "USER"
            value: root.dataObject.user || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "MACHINE"
            value: root.dataObject.machine || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "SESSION"
            value: root.dataObject.session || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "UPTIME"
            value: root.dataObject.uptime || "--"
        }
    }
}
