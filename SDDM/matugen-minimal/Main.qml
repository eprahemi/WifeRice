import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: Colors.crust

    // Core States
    property int currentUserIndex: 0
    property int nextUserIndexTarget: 0
    property string currentUserName: userModel.count > 0 ? userModel.data(userModel.index(currentUserIndex, 0), 257) : "User"

    property bool inputActive: false
    property bool loginFailed: false
    property real introState: 0.0

    // Clock state - prevent "00:00" flash
    property string _hours: "00"
    property string _minutes: "00"

    // Subtle clock wiggle
    property real wiggleT: 0.0
    NumberAnimation on wiggleT {
        from: 0; to: 1000; duration: 5000000; loops: Animation.Infinite; running: true
    }
    property real wiggleX: 0
    property real wiggleY: 0
    property real wiggleAngle: 0
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            let t = wiggleT
            wiggleX = Math.sin(t * Math.PI * 2.3) * 0.8
            wiggleY = Math.cos(t * Math.PI * 1.8 + 0.5) * 0.5
            wiggleAngle = Math.sin(t * Math.PI * 1.2 + 0.3) * 0.15
        }
    }

    Component.onCompleted: {
        var idx = 0
        if (userModel.lastUser !== "") {
            for (var i = 0; i < userModel.count; ++i) {
                if (userModel.data(userModel.index(i, 0), 257) === userModel.lastUser) { idx = i; break }
            }
        }
        currentUserIndex = idx
        _hours = Qt.formatTime(new Date(), "hh")
        _minutes = Qt.formatTime(new Date(), "mm")
        introAnim.start()
    }

    // Intro animation
    SequentialAnimation {
        id: introAnim
        NumberAnimation { target: root; property: "introState"; from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutCubic }
    }

    function nextUser() {
        if (userModel.count <= 1 || switchUserAnim.running) return
        nextUserIndexTarget = (currentUserIndex + 1) % userModel.count
        switchUserAnim.restart()
    }

    function prevUser() {
        if (userModel.count <= 1 || switchUserAnim.running) return
        nextUserIndexTarget = (currentUserIndex - 1 + userModel.count) % userModel.count
        switchUserAnim.restart()
    }

    onInputActiveChanged: {
        if (inputActive) {
            passwordField.forceActiveFocus()
        } else {
            root.forceActiveFocus()
            passwordField.text = ""
            loginFailed = false
            errorMessage.opacity = 0.0
        }
    }

    // Smooth transition animation for switching users
    SequentialAnimation {
        id: switchUserAnim
        ParallelAnimation {
            NumberAnimation { target: innerAuthLayout; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InSine }
            NumberAnimation { target: innerAuthLayout; property: "scale"; to: 0.95; duration: 150; easing.type: Easing.InSine }
        }
        ScriptAction {
            script: {
                root.currentUserIndex = root.nextUserIndexTarget
                passwordField.text = ""
                root.loginFailed = false
                errorMessage.opacity = 0.0
            }
        }
        ParallelAnimation {
            NumberAnimation { target: innerAuthLayout; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutOutExpo }
            NumberAnimation { target: innerAuthLayout; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
    }

    // Capture global key presses to activate input mode
    Item {
        anchors.fill: parent
        focus: !root.inputActive
        Keys.onPressed: (event) => {
            if (!root.inputActive) {
                root.inputActive = true
                event.accepted = true
            }
        }
    }

    // Click anywhere to activate input mode
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (!root.inputActive) {
                root.inputActive = true
            } else {
                passwordField.forceActiveFocus()
            }
        }
    }

    // SDDM Connections for error handling
    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            root.loginFailed = true
            errorMessage.opacity = 1.0
            shakeAnim.restart()
            errorHideTimer.restart()
        }
    }

    Timer { id: errorHideTimer; interval: 3000; onTriggered: errorMessage.opacity = 0.0 }

    // 1. BACKGROUND & BLUR
    Item {
        anchors.fill: parent

        Image {
            id: bgWallpaper
            anchors.fill: parent
            source: config.background
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        FastBlur {
            anchors.fill: bgWallpaper
            source: bgWallpaper
            radius: 64
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.08) }
                GradientStop { position: 0.65; color: Qt.rgba(0, 0, 0, 0.08) }
                GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.55) }
            }
        }
    }

    // 2. MAIN CONTENT LAYER (Cross-fading Clock & Auth)
    Item {
        anchors.fill: parent
        opacity: introState

        // --- CLOCK MODULE (Idle State) ---
        ColumnLayout {
            id: clockModule
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.inputActive ? -120 : -40
            spacing: -10

            opacity: root.inputActive ? 0.0 : 1.0
            scale: root.inputActive ? 0.9 : 1.0
            visible: opacity > 0.01

            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            Text {
                id: timeText
                text: root._hours + ":" + root._minutes
                font.family: "JetBrains Mono"
                font.pixelSize: 140
                font.weight: Font.Bold
                color: Colors.text
                Layout.alignment: Qt.AlignHCenter
                transform: [
                    Translate { x: wiggleX; y: wiggleY },
                    Rotation { angle: wiggleAngle; origin.x: width/2; origin.y: height/2 }
                ]
            }

            Text {
                id: dateText
                text: Qt.formatDate(new Date(), "dddd, MMMM dd")
                font.family: "JetBrains Mono"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: Colors.text
                Layout.alignment: Qt.AlignHCenter
            }

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    root._hours = Qt.formatTime(new Date(), "hh")
                    root._minutes = Qt.formatTime(new Date(), "mm")
                    dateText.text = Qt.formatDate(new Date(), "dddd, MMMM dd")
                }
            }
        }

        // --- AUTHENTICATION MODULE (Input State) ---
        RowLayout {
            id: authModule
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.inputActive ? -40 : 40
            spacing: 24

            opacity: root.inputActive ? 1.0 : 0.0
            scale: root.inputActive ? 1.0 : 0.9
            visible: opacity > 0.01

            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            // Left Arrow
            Rectangle {
                width: 48; height: 48; radius: 24
                Layout.alignment: Qt.AlignVCenter
                color: leftArrowMa.containsMouse ? Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1) : "transparent"
                visible: userModel.count > 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 24
                    color: Colors.text
                }

                MouseArea {
                    id: leftArrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.prevUser()
                }
            }

            // Wrapper to isolate the user swap animation from the arrows
            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: innerAuthLayout.implicitWidth
                Layout.preferredHeight: innerAuthLayout.implicitHeight

                RowLayout {
                    id: innerAuthLayout
                    anchors.centerIn: parent
                    spacing: 32

                    // Avatar
                    Item {
                        implicitWidth: 150
                        implicitHeight: 150
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignTop

                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            source: "/usr/share/sddm/faces/" + root.currentUserName + ".face.icon"
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            onStatusChanged: {
                                if (status == Image.Error) source = ""
                            }
                        }

                        Rectangle {
                            id: avatarMask
                            anchors.fill: parent
                            radius: 75
                            color: "white"
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: avatarImage
                            maskSource: avatarMask
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 75
                            color: "transparent"
                            border.color: root.loginFailed ? Colors.red : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.5)
                            border.width: root.loginFailed ? 4 : 3

                            Behavior on border.color { ColorAnimation { duration: 300 } }
                            Behavior on border.width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        }
                    }

                    // Details & Input
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 12

                        Text {
                            text: root.currentUserName
                            font.family: "JetBrains Mono"
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            color: Colors.text
                            Layout.alignment: Qt.AlignLeft
                        }

                        // Typing activity indicator — subtle wave dots above pill
                        Row {
                            id: typingWave
                            spacing: 5
                            Layout.alignment: Qt.AlignLeft
                            opacity: passwordField.text.length > 0 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Repeater {
                                model: 5
                                Rectangle {
                                    width: 6; height: width; radius: width / 2
                                    color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.7)

                                    SequentialAnimation {
                                        running: passwordField.text.length > 0
                                        loops: Animation.Infinite
                                        NumberAnimation { target: parent; property: "opacity"; to: 0.3; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                    }
                                    SequentialAnimation {
                                        running: passwordField.text.length > 0
                                        loops: Animation.Infinite
                                        NumberAnimation { target: parent; property: "scale"; to: 0.6; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: parent; property: "scale"; to: 1.2; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: pinPill
                            Layout.preferredWidth: 280
                            Layout.preferredHeight: 60
                            radius: height / 2
                            clip: true

                            // Liquid continuous squish
                            property real pillSquishX: 1.0
                            property real pillSquishY: 1.0
                            property real pillLiquidPhase: 0.0
                            NumberAnimation on pillLiquidPhase {
                                from: 0; to: 1000; duration: 4000000; loops: Animation.Infinite; running: true
                            }
                            Timer {
                                interval: 16; running: true; repeat: true
                                onTriggered: {
                                    let t = pinPill.pillLiquidPhase
                                    let intensity = root.inputActive ? 0.025 : 0.012
                                    pinPill.pillSquishX = 1.0 + Math.sin(t * Math.PI * 1.5) * intensity
                                    pinPill.pillSquishY = 1.0 - Math.sin(t * Math.PI * 1.5) * intensity
                                }
                            }

                            color: root.loginFailed ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.1) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                            border.width: 2 + Math.sin(pinPill.pillLiquidPhase * Math.PI * 2.0) * 0.5
                            border.color: {
                                if (root.loginFailed) return Colors.red
                                if (passwordField.text.length > 0) return Colors.text
                                return Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.08)
                            }

                            Behavior on color        { ColorAnimation { duration: 350; easing.type: Easing.OutExpo } }
                            Behavior on border.color { ColorAnimation { duration: 350; easing.type: Easing.OutExpo } }

                            property real pillStateScale: root.loginFailed ? 1.03 : 1.0
                            Behavior on pillStateScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                            transform: [
                                Translate { id: shakeTranslate; x: 0 },
                                Scale { xScale: pinPill.pillSquishX * pinPill.pillStateScale; yScale: pinPill.pillSquishY * pinPill.pillStateScale; origin.x: pinPill.width/2; origin.y: pinPill.height/2 }
                            ]

                            // Liquid wave fill — animated wave inside pill
                            Canvas {
                                anchors.fill: parent
                                anchors.margins: 2
                                opacity: passwordField.text.length > 0 ? 0.20 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                property real wavePhase: 0.0
                                NumberAnimation on wavePhase {
                                    from: 0; to: 360; duration: 3000; loops: Animation.Infinite; running: passwordField.text.length > 0
                                }
                                onWavePhaseChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var waveY = height * 0.7
                                    ctx.beginPath()
                                    ctx.moveTo(0, height)
                                    for (var x = 0; x <= width; x += 2) {
                                        var y = waveY + Math.sin((x + wavePhase * 2) * 0.05) * 3
                                                    + Math.sin((x + wavePhase * 1.3) * 0.08) * 2
                                        ctx.lineTo(x, y)
                                    }
                                    ctx.lineTo(width, height)
                                    ctx.closePath()
                                    var wc = Colors.text
                                    ctx.fillStyle = "rgba(" + Math.floor(wc.r*255) + "," + Math.floor(wc.g*255) + "," + Math.floor(wc.b*255) + ",0.6)"
                                    ctx.fill()
                                }
                            }

                            // Elegant Shake Animation on Error
                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: shakeTranslate; property: "x"; from: 0; to: -8; duration: 120; easing.type: Easing.InOutSine }
                                NumberAnimation { target: shakeTranslate; property: "x"; from: -8; to: 8; duration: 120; easing.type: Easing.InOutSine }
                                NumberAnimation { target: shakeTranslate; property: "x"; from: 8; to: 0; duration: 120; easing.type: Easing.InOutSine }
                            }

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                echoMode: TextInput.Password
                                font.family: "JetBrains Mono"
                                font.pixelSize: 24
                                color: root.loginFailed ? Colors.red : Colors.text

                                Text {
                                    text: "Password..."
                                    color: Qt.rgba(Colors.subtext0.r, Colors.subtext0.g, Colors.subtext0.b, 0.5)
                                    font: passwordField.font
                                    visible: !passwordField.text && !passwordField.inputMethodComposing
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Keys.onEscapePressed: {
                                    root.inputActive = false
                                }

                                // Tab navigation
                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Tab) {
                                        root.nextUser()
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Backtab) {
                                        root.prevUser()
                                        event.accepted = true
                                    }
                                }

                                onAccepted: {
                                    if (text !== "") {
                                        errorMessage.opacity = 0.0
                                        sddm.login(root.currentUserName, text, sessionMenu.currentIndex)
                                    }
                                }

                                onTextChanged: {
                                    if (root.loginFailed) {
                                        root.loginFailed = false
                                        errorMessage.opacity = 0.0
                                    }
                                }
                            }
                        }

                        // Error Message Label
                        Text {
                            id: errorMessage
                            Layout.alignment: Qt.AlignHCenter
                            text: "Login failed. Please try again."
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Colors.red
                            opacity: 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }
            }

            // Right Arrow
            Rectangle {
                width: 48; height: 48; radius: 24
                Layout.alignment: Qt.AlignVCenter
                color: rightArrowMa.containsMouse ? Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1) : "transparent"
                visible: userModel.count > 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 24
                    color: Colors.text
                }

                MouseArea {
                    id: rightArrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.nextUser()
                }
            }
        }
    }

    // 3. BOTTOM CONTROLS (Session & Power)
    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40
        spacing: 16
        opacity: introState

        // Styled Session Switcher
        ComboBox {
            id: sessionMenu
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 192
            Layout.preferredHeight: 48
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            font.family: "JetBrains Mono"
            font.pixelSize: 14

            background: Rectangle {
                color: sessionMenu.hovered || sessionMenu.popup.visible ? Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.7) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                radius: 24
                border.width: 1
                border.color: sessionMenu.hovered || sessionMenu.popup.visible ? Colors.text : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            contentItem: Text {
                leftPadding: 16
                rightPadding: sessionMenu.indicator.width + 12
                text: "󰧨  " + sessionMenu.currentText
                color: sessionMenu.hovered || sessionMenu.popup.visible ? Colors.text : Colors.subtext0
                font: sessionMenu.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            indicator: Text {
                x: sessionMenu.width - width - 16
                y: sessionMenu.topPadding + (sessionMenu.availableHeight - height) / 2
                text: sessionMenu.popup.visible ? "" : ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 14
                color: sessionMenu.hovered || sessionMenu.popup.visible ? Colors.text : Colors.subtext0
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            popup: Popup {
                y: -(sessionMenu.popup.height + 8)
                width: sessionMenu.width
                padding: 8

                background: Rectangle {
                    color: Qt.rgba(Colors.crust.r, Colors.crust.g, Colors.crust.b, 0.95)
                    radius: 16
                    border.width: 1
                    border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.15)
                }

                contentItem: ListView {
                    clip: true
                    implicitHeight: Math.min(contentHeight, 200)
                    model: sessionMenu.popup.visible ? sessionMenu.delegateModel : null
                    ScrollIndicator.vertical: ScrollIndicator { }
                }
            }

            delegate: ItemDelegate {
                width: sessionMenu.popup.width - 16
                padding: 12

                contentItem: Text {
                    text: model.name
                    color: hovered ? Colors.crust : Colors.text
                    font: sessionMenu.font
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8
                    color: hovered ? Colors.text : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Power Buttons Row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            // Suspend
            Rectangle {
                width: 48; height: 48; radius: 24
                color: suspendMa.containsMouse ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                border.color: suspendMa.containsMouse ? Colors.mauve : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)

                scale: suspendMa.pressed ? 0.9 : (suspendMa.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒲"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: suspendMa.containsMouse ? Colors.mauve : Colors.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: suspendMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.suspend()
                }
            }

            // Reboot
            Rectangle {
                width: 48; height: 48; radius: 24
                color: rebootMa.containsMouse ? Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                border.color: rebootMa.containsMouse ? Colors.blue : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)

                scale: rebootMa.pressed ? 0.9 : (rebootMa.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰜉"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: rebootMa.containsMouse ? Colors.blue : Colors.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: rebootMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.reboot()
                }
            }

            // Power Off
            Rectangle {
                width: 48; height: 48; radius: 24
                color: powerMa.containsMouse ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                border.color: powerMa.containsMouse ? Colors.red : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)

                scale: powerMa.pressed ? 0.9 : (powerMa.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: powerMa.containsMouse ? Colors.red : Colors.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.powerOff()
                }
            }
        }
    }
}
