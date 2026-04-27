import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string label: ""
    property string value: ""
    property real scaleFactor: 1.0
    property int rowWidth: 380
    property int labelWidth: Math.round(152 * root.scaleFactor)
    property bool valueRightAligned: false

    width: rowWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Math.round(10 * root.scaleFactor)

        GlowText {
            Layout.preferredWidth: root.labelWidth
            text: root.label
            dim: true
            fontSize: Math.round(12 * root.scaleFactor)
            letterSpacing: Math.round(0.6 * root.scaleFactor)
        }

        GlowText {
            Layout.fillWidth: true
            text: root.value
            fontSize: Math.round(12 * root.scaleFactor)
            horizontalAlignment: root.valueRightAligned ? Text.AlignRight : Text.AlignLeft
            letterSpacing: Math.round(0.3 * root.scaleFactor)
        }
    }
}
