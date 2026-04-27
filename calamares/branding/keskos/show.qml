import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Component {
        id: slideFrame

        Item {
            anchors.fill: parent

            Image {
                anchors.fill: parent
                source: "wallpaper.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.28
            }

            Rectangle {
                anchors.fill: parent
                color: "#050403"
                opacity: 0.82
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 58
                anchors.right: parent.right
                anchors.rightMargin: 58
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18

                Image {
                    source: "logo.png"
                    fillMode: Image.PreserveAspectFit
                    width: 360
                    height: 120
                    smooth: true
                }

                Text {
                    width: parent.width
                    text: slideTitle
                    color: "#ce6a35"
                    font.family: "VT323"
                    font.pixelSize: 34
                }

                Text {
                    width: parent.width
                    text: slideBody
                    wrapMode: Text.WordWrap
                    color: "#e7c9b3"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    lineHeight: 1.28
                }
            }
        }
    }

    property string slideTitle: ""
    property string slideBody: ""

    Slide {
        onActivated: {
            presentation.slideTitle = "Calamares-guided Arch install"
            presentation.slideBody = "KeskOS boots to a live KDE Plasma desktop, then hands off installation to Calamares with a clean Arch-focused flow."
        }
        Loader { anchors.fill: parent; sourceComponent: slideFrame }
    }

    Slide {
        onActivated: {
            presentation.slideTitle = "Themed for the full KeskOS desktop"
            presentation.slideBody = "The installed system keeps the current orange-on-black terminal look, the centered launcher, the Konsole profile, and the HUD stack."
        }
        Loader { anchors.fill: parent; sourceComponent: slideFrame }
    }

    Slide {
        onActivated: {
            presentation.slideTitle = "Built for testing and iteration"
            presentation.slideBody = "Tweak the package list, swap the wallpaper, change Calamares branding, or jump back to the preserved legacy branch whenever you need the original script installer."
        }
        Loader { anchors.fill: parent; sourceComponent: slideFrame }
    }

    function onActivate() {
        presentation.currentSlide = 0
    }
}
