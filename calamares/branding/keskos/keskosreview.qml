import io.calamares.core 1.0

import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent ? parent.width : 1180
    height: parent ? parent.height : 720

    readonly property color bg: "#050505"
    readonly property color panel: "#080706"
    readonly property color block: "#11100e"
    readonly property color accent: "#ce6a35"
    readonly property color textColor: "#b8afa6"
    readonly property color dimText: "#8f8a84"
    readonly property color borderColor: "#ce6a35"

    property var browserLabels: ({
        "librewolf": "LibreWolf",
        "zen": "Zen Browser",
        "brave": "Brave",
        "firefox": "Firefox"
    })

    property var bundleLabels: ({
        "gaming": "Gaming",
        "chat": "Chat",
        "development": "Development",
        "media": "Media",
        "office": "Office",
        "system_tools": "System Tools",
        "customization": "Customization",
        "drivers_gaming": "Drivers / Gaming Support"
    })

    property var featureLabels: ({
        "quickshell_topbar": "Quickshell top bar",
        "kde_bottom_taskbar": "KDE bottom taskbar",
        "plasma_theme": "Plasma theme",
        "window_borders": "Window borders",
        "sddm_theme": "SDDM theme",
        "plymouth": "Plymouth boot splash",
        "browser_startpage": "Browser startpage",
        "gaming_tools": "Gaming performance tools",
        "bluetooth": "Bluetooth tools",
        "printing": "Printing support",
        "docker": "Docker support",
        "nvidia": "NVIDIA support"
    })

    function splitSelection(key) {
        var raw = Global.value(key)
        if (!raw || String(raw).length === 0) {
            return []
        }
        return String(raw).split(",").map(function(item) { return item.trim() }).filter(function(item) { return item.length > 0 })
    }

    function browserLabel() {
        var selection = splitSelection("packagechooser_keskos_browser")
        var key = selection.length ? selection[0] : "librewolf"
        return browserLabels[key] || "LibreWolf"
    }

    function bundleText() {
        var bundles = splitSelection("packagechooser_keskos_bundles")
        if (!bundles.length) return "none"
        var labels = []
        for (var i = 0; i < bundles.length; ++i) {
            labels.push(bundleLabels[bundles[i]] || bundles[i])
        }
        return labels.join(", ")
    }

    function applyBrowserTheme() {
        var themeSelection = splitSelection("packagechooser_keskos_browser_theme")
        return !themeSelection.length || themeSelection[0] !== "browser_theme_off"
    }

    function desktopProfileLabel() {
        var profileSelection = splitSelection("packagechooser_keskos_desktop_profile")
        if (profileSelection.length && profileSelection[0] === "plasma_base") {
            return "KDE Plasma Base Profile"
        }
        return "KeskOS Split Shell Profile"
    }

    function addonText() {
        var addons = splitSelection("packagechooser_keskos_addons")
        if (!addons.length) return "none"
        var labels = []
        for (var i = 0; i < addons.length; ++i) {
            labels.push(featureLabels[addons[i]] || addons[i])
        }
        return labels.join(", ")
    }

    function hasInternet() {
        return !!Global.value("hasInternet")
    }

    Rectangle {
        anchors.fill: parent
        color: bg
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: borderColor
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 112
            color: panel
            border.color: borderColor
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                Text {
                    text: "DEPLOY REVIEW"
                    color: accent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 30
                    font.bold: true
                }

                Text {
                    text: "Review the KeskOS deployment profile below. Continue to start installation."
                    color: textColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: hasInternet() ? "[ OK ] NETWORK LINK: ONLINE" : "[ WARN ] NETWORK LINK: OFFLINE"
                    color: hasInternet() ? accent : "#ff8a57"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: panel
                border.color: borderColor
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: "[ INSTALL PROFILE ]"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "[ OK ] Browser: " + browserLabel()
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "[ OK ] Browser theme: " + (applyBrowserTheme() ? "enabled" : "disabled")
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "[ OK ] Bundles: " + bundleText()
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "[ OK ] Desktop profile: " + desktopProfileLabel()
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "[ OK ] System add-ons: " + addonText()
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                color: panel
                border.color: borderColor
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: "[ DEPLOY NOTES ]"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "Optional packages are validated during deployment. Missing optional packages are skipped with warnings instead of aborting the full install."
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "The installed system should reboot directly into a finished KeskOS desktop. The old forced first-run app is no longer part of the default install path."
                        color: textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: hasInternet()
                            ? "Repository validation is available in the live environment."
                            : "Offline installs continue with the base image. Optional software may not be added until the system has network access."
                        color: dimText
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
