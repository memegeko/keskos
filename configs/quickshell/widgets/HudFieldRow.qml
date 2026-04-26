import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string label: ""
    property string value: ""
    property real scaleFactor: 1.0
    property int rowWidth: 380

    width: rowWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Math.round(10 * root.scaleFactor)

        GlowText {
            Layout.preferredWidth: Math.round(118 * root.scaleFactor)
            text: root.label
            dim: true
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(root.scaleFactor)
        }

        GlowText {
            Layout.fillWidth: true
            text: root.value
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(0.5 * root.scaleFactor)
        }
    }
}
