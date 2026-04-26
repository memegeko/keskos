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
            text: "SYSTEM STATUS"
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
            label: "OS"
            value: root.dataObject.os || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "KERNEL"
            value: root.dataObject.kernel || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "UPTIME"
            value: root.dataObject.uptime || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "SHELL"
            value: root.dataObject.shell || "--"
        }

        HudFieldRow {
            rowWidth: root.panelWidth
            scaleFactor: root.scaleFactor
            label: "SESSION"
            value: root.dataObject.session || "--"
        }
    }
}
