import QtQuick

Item {
    id: root

    clip: true

    Repeater {
        model: Math.ceil(root.height / 3)

        Rectangle {
            x: 0
            y: index * 3
            width: root.width
            height: 1
            color: index % 2 === 0 ? "#090807" : "#060505"
            opacity: 0.22
        }
    }
}
