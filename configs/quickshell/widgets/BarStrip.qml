import QtQuick

Item {
    id: root

    property var values: []
    property real scaleFactor: 1.0
    property int stripWidth: 320
    property int stripHeight: 22
    property int barCount: 16
    property color activeColor: "#e77a34"
    property color inactiveColor: "#3f2413"

    width: stripWidth
    height: stripHeight

    Row {
        anchors.fill: parent
        spacing: Math.round(5 * root.scaleFactor)

        Repeater {
            model: root.barCount

            Rectangle {
                readonly property real ratio: {
                    if (!Array.isArray(root.values) || index >= root.values.length) {
                        return 0
                    }
                    const numeric = Number(root.values[index])
                    if (isNaN(numeric)) {
                        return 0
                    }
                    return Math.max(0, Math.min(1, numeric / 100))
                }

                width: Math.round(9 * root.scaleFactor)
                height: root.stripHeight
                color: "transparent"

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(Math.round(3 * root.scaleFactor), Math.round(parent.height * ratio))
                    color: ratio > 0 ? root.activeColor : root.inactiveColor
                    opacity: ratio > 0 ? 0.92 : 0.6
                }
            }
        }
    }
}
