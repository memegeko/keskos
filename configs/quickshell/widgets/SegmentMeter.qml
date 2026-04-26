import QtQuick

Item {
    id: root

    property int totalSegments: 28
    property int filledSegments: 0
    property real scaleFactor: 1.0
    property int meterWidth: 520
    property int meterHeight: 38
    property color activeColor: "#e77a34"
    property color inactiveColor: "#3b2112"

    width: meterWidth
    height: meterHeight

    Row {
        anchors.fill: parent
        spacing: Math.round(5 * root.scaleFactor)

        Repeater {
            model: root.totalSegments

            Rectangle {
                width: Math.round(13 * root.scaleFactor)
                height: root.meterHeight
                color: index < root.filledSegments ? root.activeColor : root.inactiveColor
                opacity: index < root.filledSegments ? 0.92 : 0.68
            }
        }
    }
}
