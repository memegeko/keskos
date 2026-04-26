import QtQuick

Rectangle {
    id: root
    color: "#000000"

    property int stage

    onStageChanged: {
        if (stage === 2) {
            fadeIn.running = true;
        } else if (stage === 5) {
            fadeOut.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Item {
            anchors.centerIn: parent
            width: Math.min(root.width * 0.48, 920)
            height: Math.min(root.height * 0.34, 380)

            Image {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -22
                source: "assets/logo.png"
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                sourceSize.width: width
                sourceSize.height: height
                width: parent.width
                height: parent.height * 0.7
            }

            Image {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: logo.bottom
                anchors.topMargin: 18
                source: "assets/spinner.png"
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                sourceSize.width: width
                sourceSize.height: height
                width: Math.min(parent.width * 0.12, 84)
                height: width

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1800
                    loops: Animation.Infinite
                    running: true
                }
            }
        }
    }

    OpacityAnimator {
        id: fadeIn
        target: content
        from: 0
        to: 1
        duration: 450
    }

    OpacityAnimator {
        id: fadeOut
        target: content
        from: content.opacity
        to: 0
        duration: 350
    }
}
