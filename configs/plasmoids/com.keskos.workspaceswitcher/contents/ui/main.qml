import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property color accent: "#ce6a35"
    readonly property color activeFill: "#29ce6a35"
    readonly property color hoverFill: "#38ce6a35"
    readonly property color inactiveFill: "#11100e"
    readonly property color inactiveText: "#8f8a84"
    readonly property int minimumDesktopCount: 4
    readonly property int buttonWidth: 48
    readonly property int desktopCount: Math.max(minimumDesktopCount, desktopInfo.numberOfDesktops > 0 ? desktopInfo.numberOfDesktops : minimumDesktopCount)
    readonly property string switchPrefix: "/usr/local/bin/keskos-workspace set "

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Workspace Switcher"

    Layout.minimumWidth: desktopCount * buttonWidth
    Layout.preferredWidth: desktopCount * buttonWidth
    Layout.minimumHeight: 46
    Layout.fillHeight: true

    implicitWidth: desktopCount * buttonWidth
    implicitHeight: 46

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    Plasma5Support.DataSource {
        id: commandRunner
        engine: "executable"
        connectedSources: []

        function exec(command) {
            connectSource(command)
        }

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
        }
    }

    function currentDesktopNumber() {
        const current = desktopInfo.currentDesktop

        if (typeof current === "number" && current > 0) {
            return current
        }

        const parsed = Number(current)
        if (!Number.isNaN(parsed) && parsed > 0) {
            return parsed
        }

        const currentText = `${current}`
        for (let i = 0; i < desktopInfo.desktopIds.length; ++i) {
            if (`${desktopInfo.desktopIds[i]}` === currentText) {
                return i + 1
            }
        }

        return 1
    }

    function labelFor(index) {
        return String(index + 1)
    }

    function activateDesktop(index) {
        commandRunner.exec(`${switchPrefix}${index + 1}`)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.desktopCount

            delegate: Rectangle {
                readonly property bool active: root.currentDesktopNumber() === index + 1

                Layout.minimumWidth: root.buttonWidth
                Layout.preferredWidth: root.buttonWidth
                Layout.fillHeight: true

                color: switchMouse.pressed ? "#45ce6a35" : (active ? root.activeFill : (switchMouse.containsMouse ? root.hoverFill : root.inactiveFill))
                border.width: 1
                border.color: active ? root.accent : "#3a34302b"

                Text {
                    anchors.centerIn: parent
                    text: root.labelFor(index)
                    color: active ? root.accent : root.inactiveText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.letterSpacing: 1.0
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: switchMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activateDesktop(index)
                }
            }
        }
    }
}
