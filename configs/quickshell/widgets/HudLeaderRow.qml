import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string label: ""
    property string status: "OK"
    property string leader: ".........."
    property real scaleFactor: 1.0
    property int rowWidth: 380
    property int labelWidth: Math.round(170 * root.scaleFactor)
    property int statusWidth: Math.round(58 * root.scaleFactor)

    width: rowWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Math.round(10 * root.scaleFactor)

        GlowText {
            Layout.preferredWidth: root.labelWidth
            text: root.label
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(0.3 * root.scaleFactor)
        }

        GlowText {
            Layout.fillWidth: true
            text: root.leader
            dim: true
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(0.2 * root.scaleFactor)
        }

        GlowText {
            Layout.preferredWidth: root.statusWidth
            text: root.status
            fontSize: Math.round(12 * root.scaleFactor)
            horizontalAlignment: Text.AlignRight
            letterSpacing: Math.round(0.3 * root.scaleFactor)
        }
    }
}
