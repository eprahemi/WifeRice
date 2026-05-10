import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"
import "../WindowRegistry.js" as Registry

PanelWindow {
    id: popupWindow

    property var popupModel
    property real uiScale: 1.0

    property var layoutConfig: Registry.getPopupLayout(Screen.width, popupWindow.uiScale)

    WlrLayershell.namespace: "qs-popups"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: popupWindow.layoutConfig.marginTop
        right: popupWindow.layoutConfig.marginRight
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    width: popupWindow.layoutConfig.w
    height: Math.min(popupList.contentHeight, Screen.height * 0.8)

    Behavior on height {
        NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
    }

    property bool dndEnabled: false

    Process {
        id: dndPoller
        command: ["bash", "-c", "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: popupWindow.dndEnabled = (this.text.trim() === "1")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: dndPoller.running = true
    }

    Item {
        id: contentWrapper
        anchors.fill: parent

        opacity: popupWindow.dndEnabled ? 0.0 : 1.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MatugenColors { id: _theme }

        property var accentPalette: [_theme.mauve, _theme.blue, _theme.peach, _theme.green, _theme.pink, _theme.sapphire, _theme.teal, _theme.yellow, _theme.red, _theme.maroon]

        property real globalOrbitAngle: 0
        NumberAnimation on globalOrbitAngle {
            from: 0; to: Math.PI * 2; duration: 25000; loops: Animation.Infinite; running: true
        }

        ListView {
            id: popupList
            anchors.fill: parent
            model: popupWindow.popupModel
            spacing: popupWindow.layoutConfig.spacing
            interactive: false
            clip: false

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "x"; from: popupWindow.width * 0.4; to: 0; duration: 500; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "x"; to: popupWindow.width * 0.4; duration: 250; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "scale"; to: 0.85; duration: 250; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "height"; to: 0; duration: 350; easing.type: Easing.OutQuint }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint }
            }

            delegate: Item {
                id: delegateRoot
                width: ListView.view.width
                height: contentCol.height + (popupWindow.layoutConfig.padding * 2)

                property string fullSummary: model.summary || ""
                property string fullBody: model.body || ""
                property int typeLenSum: 0
                property int typeLenBody: 0
                property bool cardHovered: false

                function appIcon(appName, summary, body) {
                    var text = (summary + " " + body).toLowerCase()
                    var map = {
                        "Google Chrome": "",
                        "Firefox": "",
                        "Chromium": "",
                        "Brave": "",
                        "Discord": "󰙯",
                        "Telegram": "",
                        "Slack": "󰒱",
                        "WhatsApp": "",
                        "Messenger": "󰭻",
                        "Spotify": "",
                        "Code": "󰨞",
                        "Visual Studio Code": "󰨞",
                        "GitHub": "",
                        "GitHub Desktop": "",
                        "Thunar": "󰉋",
                        "Nautilus": "󰉋",
                        "Kitty": "󰄛",
                        "Terminal": "󰆍",
                        "Alacritty": "󰆍",
                        "Screenshot": "󰹑",
                        "Screen Recorder": "",
                        "Calendar": "",
                        "Weather": "󰖐",
                        "Battery": "󰁹",
                        "Network": "󰤨",
                        "Bluetooth": "",
                        "Volume": "󰕾",
                        "Update": "󰑖",
                        "Updater": "󰑖",
                        "Music": "󰎆",
                        "Player": "󰎆",
                        "Steam": "",
                        "Printer": "󰐪",
                        "Camera": "󰄀",
                        "Microphone": "󰍬",
                        "Keyboard": "󰌌",
                        "Power": "󰐥",
                        "FocusTime": "󰄉",
                        "SSH": "󰢬",
                        "Firewall": "󰒃",
                        "USB": "󰊾",
                        "Backup": "󰁯",
                        "Calendar": "",
                        "Meeting": "󰥔",
                        "VMware": "󰅩",
                        "VirtualBox": "󰅩",
                        "Docker": "󰡨",
                        "Podman": "󰡨",
                        "Figma": "󰙨",
                        "GIMP": "󰌸",
                        "Blender": "󰂫",
                        "OBS": "󰑄",
                        "PDF": "󰈙",
                        "FileZilla": "󰋄",
                        "VLC": "󰕼",
                        "MPV": "󰕼",
                    }
                    if (map[appName]) return map[appName]
                    if (text.indexOf("update") !== -1 || text.indexOf("upgrade") !== -1 || text.indexOf("available") !== -1) return "󰑖"
                    if (text.indexOf("battery") !== -1 || text.indexOf("charging") !== -1 || text.indexOf("power") !== -1) return "󰁹"
                    if (text.indexOf("backup") !== -1 || text.indexOf("restore") !== -1) return "󰁯"
                    if (text.indexOf("firewall") !== -1 || text.indexOf("blocked") !== -1 || text.indexOf("security") !== -1) return "󰒃"
                    if (text.indexOf("ssh") !== -1 || text.indexOf("server") !== -1 || text.indexOf("connection") !== -1) return "󰢬"
                    if (text.indexOf("bluetooth") !== -1 || text.indexOf("headset") !== -1 || text.indexOf("earbud") !== -1) return ""
                    if (text.indexOf("wifi") !== -1 || text.indexOf("network") !== -1 || text.indexOf("connected") !== -1 || text.indexOf("signal") !== -1) return "󰤨"
                    if (text.indexOf("printer") !== -1 || text.indexOf("print") !== -1) return "󰐪"
                    if (text.indexOf("usb") !== -1 || text.indexOf("mount") !== -1 || text.indexOf("drive") !== -1) return "󰊾"
                    if (text.indexOf("calendar") !== -1 || text.indexOf("meeting") !== -1 || text.indexOf("schedule") !== -1) return ""
                    if (text.indexOf("thermal") !== -1 || text.indexOf("temperature") !== -1 || text.indexOf("cpu") !== -1 || text.indexOf("cool") !== -1) return "󰈸"
                    if (text.indexOf("recording") !== -1 || text.indexOf("record") !== -1 || text.indexOf("screenshot") !== -1) return "󰹑"
                    if (text.indexOf("weather") !== -1 || text.indexOf("rain") !== -1 || text.indexOf("forecast") !== -1) return "󰖐"
                    if (text.indexOf("focus") !== -1 || text.indexOf("pomodoro") !== -1 || text.indexOf("session") !== -1) return "󰄉"
                    if (text.indexOf("night") !== -1 || text.indexOf("dark") !== -1 || text.indexOf("blue light") !== -1) return "󰛨"
                    if (text.indexOf("download") !== -1 || text.indexOf("finished") !== -1 || text.indexOf("complete") !== -1) return "󰉍"
                    if (text.indexOf("error") !== -1 || text.indexOf("fail") !== -1 || text.indexOf("critical") !== -1 || text.indexOf("warning") !== -1) return "󰀨"
                    if (text.indexOf("call") !== -1 || text.indexOf("ring") !== -1 || text.indexOf("incoming") !== -1) return ""
                    if (appName === "System") return ""
                    return ""
                }

                property color accentColor: contentWrapper.accentPalette[index % contentWrapper.accentPalette.length]

                property real glowIntensity: 0.0
                SequentialAnimation on glowIntensity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { from: 0.0; to: 1.0; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.0; duration: 3000; easing.type: Easing.InOutSine }
                }

                ParallelAnimation {
                    running: true
                    NumberAnimation {
                        target: delegateRoot; property: "typeLenSum";
                        from: 0; to: fullSummary.length;
                        duration: Math.min(fullSummary.length * 20, 600);
                        easing.type: Easing.OutCubic
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: 150 }
                        NumberAnimation {
                            target: delegateRoot; property: "typeLenBody";
                            from: 0; to: fullBody.length;
                            duration: Math.min(fullBody.length * 15, 1200);
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: popupCard
                    anchors.fill: parent
                    radius: popupWindow.layoutConfig.radius
                    color: cardHovered ? Qt.lighter(_theme.base, 1.03) : _theme.base
                    border.color: cardHovered ? Qt.lighter(delegateRoot.accentColor, 1.4) : _theme.surface1
                    border.width: cardHovered ? 1.5 : 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }
                    Behavior on border.width { NumberAnimation { duration: 200 } }

                    property color blob1Color: delegateRoot.accentColor
                    property color blob2Color: contentWrapper.accentPalette[(index + 3) % contentWrapper.accentPalette.length]

                    Rectangle {
                        width: parent.width * 0.6; height: width; radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.cos(contentWrapper.globalOrbitAngle * 2 + index) * 50
                        y: (parent.height / 2 - height / 2) + Math.sin(contentWrapper.globalOrbitAngle * 2 + index) * 25
                        color: popupCard.blob1Color
                        opacity: 0.08 + (delegateRoot.glowIntensity * 0.04)
                    }

                    Rectangle {
                        width: parent.width * 0.4; height: width; radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.sin(contentWrapper.globalOrbitAngle * 1.5 - index) * -45
                        y: (parent.height / 2 - height / 2) + Math.cos(contentWrapper.globalOrbitAngle * 1.5 - index) * -35
                        color: popupCard.blob2Color
                        opacity: 0.06 + (delegateRoot.glowIntensity * 0.03)
                    }

                    Rectangle {
                        width: 3
                        height: parent.height * 0.6
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        radius: 1.5
                        color: delegateRoot.accentColor
                        opacity: 0.5 + (delegateRoot.glowIntensity * 0.3)

                        Behavior on opacity { NumberAnimation { duration: 800 } }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: 1
                        color: delegateRoot.accentColor
                        opacity: 0.15
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * (1.0 - ((delegateRoot.typeLenSum > 0 || delegateRoot.typeLenBody > 0) ? 0 : 0))
                        height: 2
                        radius: 1
                        color: delegateRoot.accentColor
                        opacity: 0.3

                        property real totalDuration: 5000
                        property real elapsed: 0

                        Timer {
                            interval: 50
                            running: true
                            repeat: true
                            onTriggered: {
                                parent.elapsed += 50
                                if (parent.elapsed >= parent.totalDuration) {
                                    parent.elapsed = parent.totalDuration
                                }
                            }
                        }

                        onElapsedChanged: {
                            var progress = 1.0 - (elapsed / totalDuration)
                            width = parent.parent.width * Math.max(0, progress)
                        }
                    }

                    Timer {
                        interval: model.appName === "Eprahemi Dots" ? 10000 : 5000
                        running: true
                        onTriggered: masterWindow.removePopup(model.uid)
                    }

                    Timer {
                        id: dismissCountdown
                        interval: model.appName === "Eprahemi Dots" ? 10000 : 5000
                        running: true
                        onTriggered: {
                            if (model.notif && typeof model.notif.close === "function") {
                                model.notif.close()
                            }
                            masterWindow.removePopup(model.uid)
                        }
                    }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: delegateRoot.cardHovered = true
                        onExited: delegateRoot.cardHovered = false

                        onClicked: {
                            if (model.appName === "Eprahemi Dots") {
                                let url = "https://raw.githubusercontent.com/eprahemi/WifeRice/master/install.sh";
                                let cmd = "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c \"$(curl -fsSL " + url + ")\"; else bash -c \"$(curl -fsSL " + url + ")\"; fi";
                                Quickshell.execDetached(["bash", "-c", cmd])
                            } else if ((model.appName === "Screenshot" || model.appName === "Screen Recorder") && model.iconPath !== "") {
                                let folderPath = model.iconPath.substring(0, model.iconPath.lastIndexOf('/'))
                                Quickshell.execDetached(["xdg-open", folderPath])
                            } else {
                                if (model.notif && typeof model.notif.invokeAction === "function") {
                                    model.notif.invokeAction("default")
                                }
                            }

                            if (model.notif && typeof model.notif.close === "function") {
                                model.notif.close()
                            }
                            masterWindow.removePopup(model.uid)
                        }
                    }

                    Item {
                        id: dismissBtn
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        anchors.rightMargin: 4
                        width: 22
                        height: 22
                        opacity: delegateRoot.cardHovered ? 1.0 : 0.0
                        scale: delegateRoot.cardHovered ? 1.0 : 0.5

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 11
                            color: dismissMa.containsMouse ? Qt.alpha(_theme.red, 0.2) : Qt.alpha(_theme.surface0, 0.6)
                            border.color: dismissMa.containsMouse ? _theme.red : _theme.surface2
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 10
                            color: dismissMa.containsMouse ? _theme.red : _theme.overlay0
                        }

                        MouseArea {
                            id: dismissMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.notif && typeof model.notif.close === "function") {
                                    model.notif.close()
                                }
                                masterWindow.removePopup(model.uid)
                            }
                        }
                    }

                    RowLayout {
                        id: contentRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: popupWindow.layoutConfig.padding + 6
                        anchors.rightMargin: popupWindow.layoutConfig.padding + 4
                        anchors.topMargin: popupWindow.layoutConfig.padding
                        spacing: 10

                        Item {
                            id: iconContainer
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignTop

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: Qt.alpha(delegateRoot.accentColor, 0.12)
                                border.color: Qt.alpha(delegateRoot.accentColor, 0.2)
                                border.width: 1
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: model.iconPath && model.iconPath !== "" ? "file://" + model.iconPath.replace("file://", "") : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: model.iconPath && model.iconPath !== ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: Qt.alpha(delegateRoot.accentColor, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: delegateRoot.appIcon(model.appName, model.summary, model.body)
                                    font.family: "Iosevka Nerd Font"
                                    font.weight: Font.Normal
                                    font.pixelSize: 20
                                    color: delegateRoot.accentColor
                                }
                            }
                        }

                        ColumnLayout {
                            id: contentCol
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: model.appName || "System"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                font.pixelSize: 11
                                color: Qt.alpha(delegateRoot.accentColor, 0.8)
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: hiddenSummary.implicitHeight

                                Text {
                                    id: hiddenSummary
                                    text: delegateRoot.fullSummary
                                    width: parent.width
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 14
                                    wrapMode: Text.Wrap
                                    visible: false
                                }

                                Text {
                                    anchors.fill: parent
                                    text: delegateRoot.fullSummary.substring(0, delegateRoot.typeLenSum)
                                    font: hiddenSummary.font
                                    color: delegateRoot.cardHovered ? _theme.text : Qt.lighter(_theme.text, 1.05)
                                    wrapMode: Text.Wrap

                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: hiddenBody.implicitHeight
                                visible: delegateRoot.fullBody !== ""

                                Text {
                                    id: hiddenBody
                                    text: delegateRoot.fullBody
                                    width: parent.width
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                    visible: false
                                }

                                Text {
                                    anchors.fill: parent
                                    text: delegateRoot.fullBody.substring(0, delegateRoot.typeLenBody)
                                    font: hiddenBody.font
                                    color: delegateRoot.cardHovered ? _theme.subtext0 : Qt.lighter(_theme.subtext0, 1.05)
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText

                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Qt.alpha(_theme.surface1, 0.3)
                        }
                    }
                }
            }
        }
    }
}
