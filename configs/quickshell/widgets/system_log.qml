import QtQuick

Item {
    id: root

    property var dataObject: ({})
    property real scaleFactor: 1.0
    property int panelWidth: 1088
    property int panelHeight: 406

    width: panelWidth
    height: panelHeight
    clip: true

    property var lines: (root.dataObject && root.dataObject.lines) ? root.dataObject.lines : []

    Column {
        anchors.fill: parent
        spacing: Math.round(12 * root.scaleFactor)

        Repeater {
            model: root.lines

            GlowText {
                width: root.panelWidth
                text: modelData
                fontSize: Math.round(15 * root.scaleFactor)
                letterSpacing: Math.round(0.1 * root.scaleFactor)
            }
        }
    }
}
