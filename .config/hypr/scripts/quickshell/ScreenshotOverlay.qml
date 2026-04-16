import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    color: "transparent"

    WlrLayershell.namespace: "qs-screenshot-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    exclusionMode: ExclusionMode.Ignore 
    focusable: true
    screen: Quickshell.cursorScreen
    width: screen.width
    height: screen.height

    Scaler { id: scaler; currentWidth: width }
    function s(val) { return scaler.s(val); }
    
    MatugenColors { id: _theme }
    property color dimColor: Qt.alpha(_theme.crust, 0.50)
    property color selectionTint: Qt.alpha(_theme.mauve, 0.05)
    property color handleColor: _theme.text
    property color accentColor: _theme.mauve

    property bool isEditMode: Quickshell.env("QS_SCREENSHOT_EDIT") === "true"
    
    property string cachedMode: Quickshell.env("QS_CACHED_MODE") || "false"
    property bool isVideoMode: cachedMode === "true"

    onIsVideoModeChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + (root.isVideoMode ? "true" : "false") + "' > ~/.cache/qs_screenshot_mode"]);
    }
    
    // --- Audio State Persistence ---
    property real deskVol: Quickshell.env("QS_DESK_VOL") ? parseFloat(Quickshell.env("QS_DESK_VOL")) : 1.0
    property bool deskMute: Quickshell.env("QS_DESK_MUTE") === "true"
    property real micVol: Quickshell.env("QS_MIC_VOL") ? parseFloat(Quickshell.env("QS_MIC_VOL")) : 1.0
    property bool micMute: Quickshell.env("QS_MIC_MUTE") === "true"
    property string micDevice: Quickshell.env("QS_MIC_DEV") || ""

    function saveAudioPrefs() {
        let data = `${deskVol},${deskMute},${micVol},${micMute},${micDevice}`
        Quickshell.execDetached(["bash", "-c", `echo '${data}' > ~/.cache/qs_audio_prefs`])
    }

    // --- Dynamic Mic Loader ---
    ListModel { id: micModel }
    
    Component.onCompleted: {
        let micData = Quickshell.env("QS_MIC_LIST") || ""
        if (micData.trim() !== "") {
            let lines = micData.trim().split('\n')
            for (let line of lines) {
                let parts = line.split('|')
                if (parts.length >= 2) {
                    micModel.append({ devName: parts[0], devDesc: parts.slice(1).join('|') })
                }
            }
        }
        
        if (root.micDevice === "" && micModel.count > 0) {
            root.micDevice = micModel.get(0).devName
            saveAudioPrefs()
        }
    }

    // --- Geometry State ---
    property string cachedGeom: Quickshell.env("QS_CACHED_GEOM") || ""
    property var cachedParts: cachedGeom.trim() !== "" ? cachedGeom.trim().split(",") : []
    property bool hasValidCache: cachedParts.length === 4 && parseFloat(cachedParts[2]) > 10

    property real startX: hasValidCache ? parseFloat(cachedParts[0]) : 0
    property real startY: hasValidCache ? parseFloat(cachedParts[1]) : 0
    property real endX: hasValidCache ? (parseFloat(cachedParts[0]) + parseFloat(cachedParts[2])) : 0
    property real endY: hasValidCache ? (parseFloat(cachedParts[1]) + parseFloat(cachedParts[3])) : 0
    
    property bool hasSelection: hasValidCache
    property bool isSelecting: false
    property bool isMaximized: false
    property real preStartX: 0
    property real preStartY: 0
    property real preEndX: 0
    property real preEndY: 0

    property real selX: Math.min(startX, endX)
    property real selY: Math.min(startY, endY)
    property real selW: Math.abs(endX - startX)
    property real selH: Math.abs(endY - startY)
    
    property string geometryString: `${Math.round(selX)},${Math.round(selY)} ${Math.round(selW)}x${Math.round(selH)}`
    property int interactionMode: 0
    property real anchorX: 0; property real anchorY: 0
    property real initX: 0; property real initY: 0
    property real initW: 0; property real initH: 0

    // --- QR Scanner State ---
    property bool isScanningQr: false
    property string qrResultText: ""
    property bool showQrPopup: false
    property real qrTargetX: 0
    property real qrTargetY: 0
    property real qrTargetW: 0
    property real qrTargetH: 0
    property bool isQrSuccess: !qrResultText.startsWith("No QR") && !qrResultText.startsWith("ERROR") && !qrResultText.startsWith("Scan timed")

    function saveCache() {
        if (root.hasSelection) {
            let data = Math.round(root.selX) + "," + Math.round(root.selY) + "," + Math.round(root.selW) + "," + Math.round(root.selH);
            Quickshell.execDetached(["bash", "-c", "echo '" + data + "' > ~/.cache/qs_screenshot_geom"]);
        }
    }

    ParallelAnimation {
        id: maximizeAnim
        property real targetStartX; property real targetStartY
        property real targetEndX; property real targetEndY

        NumberAnimation { target: root; property: "startX"; to: maximizeAnim.targetStartX; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "startY"; to: maximizeAnim.targetStartY; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "endX"; to: maximizeAnim.targetEndX; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "endY"; to: maximizeAnim.targetEndY; duration: 250; easing.type: Easing.InOutQuad }
        onFinished: root.saveCache()
    }

    function toggleMaximize() {
        if (!isMaximized) {
            preStartX = root.startX; preStartY = root.startY;
            preEndX = root.endX; preEndY = root.endY;
            maximizeAnim.targetStartX = 0; maximizeAnim.targetStartY = 0;
            maximizeAnim.targetEndX = root.width; maximizeAnim.targetEndY = root.height;
            isMaximized = true;
        } else {
            maximizeAnim.targetStartX = preStartX; maximizeAnim.targetStartY = preStartY;
            maximizeAnim.targetEndX = preEndX; maximizeAnim.targetEndY = preEndY;
            isMaximized = false;
        }
        maximizeAnim.restart();
    }

    // --- Keyboard Shortcuts ---
    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    Shortcut { sequence: "Return"; onActivated: { if (root.hasSelection) root.executeCapture(root.isEditMode && !root.isVideoMode, root.isVideoMode) } }
    Shortcut { sequence: "Tab"; onActivated: root.isVideoMode = !root.isVideoMode }

    // --- Global Reusable Toolbar Button ---
    component ToolbarBtn: Rectangle {
        id: tBtn
        property string iconTxt: ""
        property string label: ""
        property bool isDanger: false
        signal clicked()

        Layout.preferredHeight: s(36)
        Layout.preferredWidth: label !== "" ? (txt.implicitWidth + s(36)) : s(36)
        radius: s(18)
        color: maBtn.containsMouse ? (isDanger ? Qt.alpha(_theme.red, 0.2) : _theme.surface0) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent; spacing: s(6)
            Text { font.family: "Iosevka Nerd Font"; text: tBtn.iconTxt; color: tBtn.isDanger ? _theme.red : _theme.text; font.pixelSize: s(18) }
            Text { id: txt; visible: tBtn.label !== ""; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; text: tBtn.label; color: tBtn.isDanger ? _theme.red : _theme.text; font.pixelSize: s(13) }
        }
        MouseArea { id: maBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tBtn.clicked() }
    }

    Item {
        anchors.fill: parent
        z: 1
        Rectangle {
            anchors.fill: parent
            color: root.dimColor
            opacity: (!root.isSelecting && !root.hasSelection) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: root.isVideoMode ? "Select region to record" : "Select region to capture"
                font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: s(24); color: _theme.text
            }
        }
        Item {
            anchors.fill: parent
            opacity: (root.isSelecting || root.hasSelection) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Rectangle { x: 0; y: 0; width: parent.width; height: root.selY; color: root.dimColor } 
            Rectangle { x: 0; y: root.selY + root.selH; width: parent.width; height: parent.height - (root.selY + root.selH); color: root.dimColor }
            Rectangle { x: 0; y: root.selY; width: root.selX; height: root.selH; color: root.dimColor } 
            Rectangle { x: root.selX + root.selW; y: root.selY; width: parent.width - (root.selX + root.selW); height: root.selH; color: root.dimColor } 
        }
    }

    // The Main Selection Border
    Rectangle {
        visible: root.isSelecting || root.hasSelection
        x: root.selX; y: root.selY; width: root.selW; height: root.selH
        color: (root.showQrPopup && root.isQrSuccess) ? Qt.alpha(_theme.green, 0.15) : (root.isVideoMode ? Qt.alpha(_theme.red, 0.15) : root.selectionTint)
        border.color: (root.showQrPopup && root.isQrSuccess) ? _theme.green : (root.isVideoMode ? _theme.red : root.accentColor)
        border.width: s(4)
        z: 5
    }

    // --- The Physical QR Code Highlighter Box ---
    Rectangle {
        visible: opacity > 0
        opacity: (root.showQrPopup && root.isQrSuccess && root.qrTargetW > 0) ? 1.0 : 0.0

        // Internal static base coordinates so it snaps instantly without flying across the screen
        property real baseTargetX: root.qrTargetX
        property real baseTargetY: root.qrTargetY
        property real baseTargetW: root.qrTargetW
        property real baseTargetH: root.qrTargetH

        // The padding that smoothly animates outwards from the QR core
        property real pad: (root.showQrPopup && root.isQrSuccess) ? s(5) : 0

        x: baseTargetW > 0 ? (baseTargetX - pad) : baseTargetX
        y: baseTargetH > 0 ? (baseTargetY - pad) : baseTargetY
        width: baseTargetW > 0 ? (baseTargetW + (pad * 2)) : 0
        height: baseTargetH > 0 ? (baseTargetH + (pad * 2)) : 0
        
        color: Qt.alpha(_theme.green, 0.25)
        border.color: _theme.green
        border.width: s(3)
        radius: s(8)
        z: 34

        // Only animate opacity and the padding to guarantee it draws purely from the inside
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on pad { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
    }

    component Handle: Rectangle {
        width: s(20); height: s(20); radius: s(10)
        color: root.handleColor; border.color: root.accentColor; border.width: s(4)
        visible: (root.hasSelection || root.isSelecting) && !root.isScanningQr && !root.showQrPopup; z: 10
    }
    Handle { x: root.selX - width / 2; y: root.selY - height / 2 } 
    Handle { x: root.selX + root.selW - width / 2; y: root.selY - height / 2 } 
    Handle { x: root.selX - width / 2; y: root.selY + root.selH - height / 2 } 
    Handle { x: root.selX + root.selW - width / 2; y: root.selY + root.selH - height / 2 } 

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 20 

        function getInteractionMode(mx, my, mods) {
            if (!root.hasSelection) return 1; 
            if (mods & Qt.ShiftModifier) return 2; 

            let margin = s(20) 
            let inBox = mx >= root.selX && mx <= root.selX + root.selW && my >= root.selY && my <= root.selY + root.selH
            let onLeft = Math.abs(mx - root.selX) <= margin; let onRight = Math.abs(mx - (root.selX + root.selW)) <= margin
            let onTop = Math.abs(my - root.selY) <= margin; let onBottom = Math.abs(my - (root.selY + root.selH)) <= margin

            if (onTop && onLeft) return 3; if (onTop && onRight) return 5;
            if (onBottom && onLeft) return 8; if (onBottom && onRight) return 10;
            if (onTop) return 4; if (onBottom) return 9;
            if (onLeft) return 6; if (onRight) return 7;
            
            return 1;
        }

        onPositionChanged: (mouse) => {
            let mode = root.isSelecting ? root.interactionMode : getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            switch(mode) {
                case 2: cursorShape = Qt.ClosedHandCursor; break;
                case 3: case 10: cursorShape = Qt.SizeFDiagCursor; break;
                case 5: case 8: cursorShape = Qt.SizeBDiagCursor; break;
                case 4: case 9: cursorShape = Qt.SizeVerCursor; break;
                case 6: case 7: cursorShape = Qt.SizeHorCursor; break;
                default: cursorShape = Qt.CrossCursor; break;
            }

            if (!root.isSelecting) return;
            let dx = mouse.x - root.anchorX; let dy = mouse.y - root.anchorY
            let clamp = (val, min, max) => Math.max(min, Math.min(max, val))

            if (root.interactionMode === 1) { 
                root.endX = clamp(mouse.x, 0, root.width); root.endY = clamp(mouse.y, 0, root.height)
            } else if (root.interactionMode === 2) { 
                let targetX = clamp(root.initX + dx, 0, root.width - root.initW); let targetY = clamp(root.initY + dy, 0, root.height - root.initH)
                root.startX = targetX; root.startY = targetY; root.endX = targetX + root.initW; root.endY = targetY + root.initH;
            } else { 
                let nx = root.initX, ny = root.initY, nw = root.initW, nh = root.initH
                if ([3, 6, 8].includes(root.interactionMode)) { nx = clamp(root.initX + dx, 0, root.initX + root.initW - 10); nw = root.initW + (root.initX - nx) }
                if ([5, 7, 10].includes(root.interactionMode)) { nw = clamp(root.initW + dx, 10, root.width - root.initX) }
                if ([3, 4, 5].includes(root.interactionMode)) { ny = clamp(root.initY + dy, 0, root.initY + root.initH - 10); nh = root.initH + (root.initY - ny) }
                if ([8, 9, 10].includes(root.interactionMode)) { nh = clamp(root.initH + dy, 10, root.height - root.initY) }
                root.startX = nx; root.startY = ny; root.endX = nx + nw; root.endY = ny + nh;
            }
        }

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) { Qt.quit(); return; }

            root.isScanningQr = false;
            root.showQrPopup = false;
            qrWaitTimer.stop();

            maximizeAnim.stop() 
            root.interactionMode = getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            root.isSelecting = true
            if (root.interactionMode !== 1) root.isMaximized = false;
            root.anchorX = mouse.x; root.anchorY = mouse.y
            root.initX = root.selX; root.initY = root.selY; root.initW = root.selW; root.initH = root.selH;

            if (root.interactionMode === 1) {
                let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
                let clampedX = clamp(mouse.x, 0, root.width); let clampedY = clamp(mouse.y, 0, root.height)
                root.startX = clampedX; root.startY = clampedY; root.endX = clampedX; root.endY = clampedY;
                root.hasSelection = false; root.isMaximized = false
            }
        }

        onReleased: {
            if (root.isSelecting) {
                root.isSelecting = false
                if (root.selW > 10 && root.selH > 10) {
                    root.hasSelection = true; root.saveCache()
                } else { root.hasSelection = false }
            }
        }
    }

    // --- Main Bottom Toolbar ---
    Rectangle {
        id: toolbar
        z: 30 
        
        property bool fitsOutsideBottom: (root.selY + root.selH + height + s(15)) <= root.height
        property bool fitsOutsideTop: (root.selY - height - s(15)) >= 0
        property bool fitsInside: root.selH >= (height + s(30)) && root.selW >= (width + s(20))

        visible: root.hasSelection && !root.isSelecting && (fitsOutsideBottom || fitsOutsideTop || fitsInside) && !root.isScanningQr && !root.showQrPopup
        x: Math.max(s(10), Math.min(parent.width - width - s(10), root.selX + (root.selW / 2) - (width / 2)))
        y: fitsOutsideBottom ? (root.selY + root.selH + s(15)) : (fitsOutsideTop ? (root.selY - height - s(15)) : (root.selY + root.selH - height - s(15)))

        width: toolbarLayout.width + s(16)
        height: s(52)
        radius: s(26)
        color: _theme.base
        border.color: _theme.surface1
        border.width: s(2)

        property bool popUpwards: (toolbar.y + s(200)) > root.height

        component AudioControl: RowLayout {
            property string iconOn: ""
            property string iconOff: ""
            property real volumeValue: 1.0
            property bool mutedValue: false
            property bool hasDropdown: false
            
            signal volumeUpdate(real newVol)
            signal muteUpdate(bool newMute)
            signal dropdownClicked()

            spacing: s(4)

            Rectangle {
                width: s(30); height: s(30); radius: s(15)
                color: maIcon.containsMouse ? _theme.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    text: parent.parent.mutedValue ? parent.parent.iconOff : parent.parent.iconOn
                    color: parent.parent.mutedValue ? _theme.red : _theme.text
                    font.pixelSize: s(16)
                }
                MouseArea {
                    id: maIcon; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.muteUpdate(!parent.parent.mutedValue)
                }
            }

            Slider {
                Layout.preferredWidth: s(60)
                from: 0.0; to: 1.0; value: parent.volumeValue
                onValueChanged: parent.volumeUpdate(value)

                background: Rectangle {
                    x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: s(60); implicitHeight: s(4)
                    width: parent.availableWidth; height: implicitHeight
                    radius: s(2)
                    color: _theme.surface2
                    Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve; radius: s(2) }
                }
                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: s(12); implicitHeight: s(12); radius: s(6)
                    color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve
                }
            }

            Rectangle {
                visible: parent.hasDropdown
                width: s(20); height: s(30); color: "transparent"
                Text {
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    text: toolbar.popUpwards ? "󰅃" : "󰅀"
                    color: _theme.text
                    font.pixelSize: s(16)
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.dropdownClicked() }
            }
        }

        Rectangle {
            id: micDropdown
            visible: false
            width: s(280)
            height: micModel.count === 0 ? s(40) : Math.min(s(180), micModel.count * s(36))
            x: micAudio.x - s(40)
            y: toolbar.popUpwards ? (-height - s(8)) : (toolbar.height + s(8))
            color: _theme.base
            border.color: _theme.surface1; border.width: s(2)
            radius: s(8)
            z: 50

            Text {
                visible: micModel.count === 0
                anchors.centerIn: parent
                text: "No Microphones (Install pulseaudio)"
                color: _theme.subtext0
                font.pixelSize: s(12)
            }

            ListView {
                visible: micModel.count > 0
                anchors.fill: parent; anchors.margins: s(4)
                model: micModel
                clip: true
                delegate: Rectangle {
                    width: ListView.view.width; height: s(32); radius: s(6)
                    color: maList.containsMouse ? _theme.surface0 : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: s(6)
                        Text { text: model.devDesc; color: root.micDevice === model.devName ? _theme.mauve : _theme.text; font.pixelSize: s(12); elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    MouseArea { 
                        id: maList; anchors.fill: parent; hoverEnabled: true; 
                        onClicked: { root.micDevice = model.devName; root.saveAudioPrefs(); micDropdown.visible = false } 
                    }
                }
            }
        }

        RowLayout {
            id: toolbarLayout
            anchors.centerIn: parent
            spacing: s(8)

            Rectangle {
                width: s(80); height: s(36); radius: s(18)
                color: _theme.surface0
                
                RowLayout {
                    anchors.fill: parent; anchors.margins: s(4); spacing: 0
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: s(14)
                        color: !root.isVideoMode ? _theme.surface2 : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰄄"; color: !root.isVideoMode ? _theme.text : _theme.subtext0; font.pixelSize: s(16) }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = false }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: s(14)
                        color: root.isVideoMode ? _theme.surface2 : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: ""; color: root.isVideoMode ? _theme.text : _theme.subtext0; font.pixelSize: s(16) }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = true }
                    }
                }
            }

            Rectangle { width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }

            AudioControl { 
                id: deskAudio; visible: root.isVideoMode; iconOn: "󰓃"; iconOff: "󰓄" 
                volumeValue: root.deskVol; mutedValue: root.deskMute
                onVolumeUpdate: (v) => { root.deskVol = v; root.saveAudioPrefs() }
                onMuteUpdate: (m) => { root.deskMute = m; root.saveAudioPrefs() }
            }
            
            AudioControl { 
                id: micAudio; visible: root.isVideoMode; iconOn: "󰍬"; iconOff: "󰍭"; hasDropdown: true
                volumeValue: root.micVol; mutedValue: root.micMute
                onVolumeUpdate: (v) => { root.micVol = v; root.saveAudioPrefs() }
                onMuteUpdate: (m) => { root.micMute = m; root.saveAudioPrefs() }
                onDropdownClicked: micDropdown.visible = !micDropdown.visible
            }

            Rectangle { visible: root.isVideoMode; width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }

            ToolbarBtn { visible: !root.isVideoMode; iconTxt: "󰄄"; label: "Capture"; onClicked: root.executeCapture(false, false) }
            ToolbarBtn { visible: root.isVideoMode; iconTxt: "󰑊"; label: "Record"; isDanger: true; onClicked: root.executeCapture(false, true) }

            ToolbarBtn { visible: !root.isVideoMode; iconTxt: "󰏫"; onClicked: root.executeCapture(true, false) }
            ToolbarBtn { visible: !root.isVideoMode; iconTxt: "⿻"; onClicked: root.performQrScan() }


            Rectangle { width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }
            
            ToolbarBtn { iconTxt: root.isMaximized ? "" : ""; onClicked: root.toggleMaximize() }
            ToolbarBtn { iconTxt: "󰅖"; isDanger: true; onClicked: Qt.quit() }
        }
    }

    // --- Dynamic QR Data Popup (Sleek Toolbar Formatted) ---
    Rectangle {
        id: qrPopup
        visible: opacity > 0
        opacity: (root.showQrPopup && !root.isSelecting) ? 1.0 : 0.0
        
        property bool fitsTop: (root.qrTargetY - height - s(15)) >= root.selY
        
        // Target positioning locked precisely to the physical bounding box
        property real targetX: Math.max(s(10), Math.min(root.width - width - s(10), root.qrTargetX + (root.qrTargetW / 2) - (width / 2)))
        property real targetY: fitsTop ? (root.qrTargetY - height - s(15)) : (root.qrTargetY + root.qrTargetH + s(15))
        
        // Employs a slide-out effect bound cleanly to the opacity fade to prevent "flying"
        x: targetX
        y: targetY + (fitsTop ? (1.0 - opacity) * s(15) : -(1.0 - opacity) * s(15))
        
        width: qrPopupLayout.implicitWidth + s(32)
        height: s(52)
        radius: s(26)
        color: _theme.base
        border.color: root.isQrSuccess ? _theme.green : _theme.red
        border.width: s(2)
        z: 35

        // X/Y native behaviors removed. Bound specifically to opacity interpolation
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        RowLayout {
            id: qrPopupLayout
            anchors.centerIn: parent
            spacing: s(8)

            Text {
                text: root.qrResultText
                color: root.isQrSuccess ? _theme.text : _theme.red
                font.family: "JetBrains Mono"
                font.pixelSize: s(13)
                font.weight: Font.DemiBold
                Layout.maximumWidth: s(400)
                Layout.leftMargin: s(8)
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Rectangle { 
                visible: root.isQrSuccess
                width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) 
            }

            ToolbarBtn {
                visible: root.isQrSuccess
                iconTxt: "󰆏"
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", `echo -n '${root.qrResultText.replace(/'/g, "'\\''")}' | wl-copy`]);
                    root.showQrPopup = false;
                }
            }

            ToolbarBtn {
                visible: root.isQrSuccess && (root.qrResultText.startsWith("http://") || root.qrResultText.startsWith("https://"))
                iconTxt: "󰌹"
                onClicked: {
                    Quickshell.execDetached(["xdg-open", root.qrResultText]);
                    Qt.quit();
                }
            }

            Rectangle { 
                width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) 
            }

            ToolbarBtn { 
                iconTxt: "󰅖"
                isDanger: true 
                onClicked: root.showQrPopup = false 
            }
        }
    }

    Process {
        id: qrReaderProcess
        property string accumulated: ""
        command: ["cat", "/tmp/qs_qr_result"]
    
        stdout: SplitParser {
            splitMarker: ""  // Read all at once
            onRead: data => qrReaderProcess.accumulated += data
        }
    
        onExited: (exitCode) => {
            let res = qrReaderProcess.accumulated.trim()
            qrReaderProcess.accumulated = ""
    
            root.isScanningQr = false
    
            if (exitCode !== 0 || res === "") {
                root.qrTargetX = root.selX + (root.selW / 2)
                root.qrTargetY = root.selY + (root.selH / 2)
                root.qrTargetW = 0
                root.qrTargetH = 0
                root.qrResultText = "Scan timed out or failed."
                root.showQrPopup = true
                return
            }
    
            let splitIdx = res.indexOf('\n')
            let coordStr = splitIdx !== -1 ? res.substring(0, splitIdx) : res
            let actualText = splitIdx !== -1 ? res.substring(splitIdx + 1).trim() : ""
    
            let coords = coordStr.split(',')
            if (coords.length === 4 && !isNaN(parseInt(coords[0]))) {
                root.qrTargetX = root.selX + parseInt(coords[0])
                root.qrTargetY = root.selY + parseInt(coords[1])
                root.qrTargetW = parseInt(coords[2])
                root.qrTargetH = parseInt(coords[3])
            } else {
                root.qrTargetX = root.selX + (root.selW / 2)
                root.qrTargetY = root.selY + (root.selH / 2)
                root.qrTargetW = 0
                root.qrTargetH = 0
                actualText = res
            }
    
            if (actualText === "NOT_FOUND" || actualText.startsWith("ERROR:")) {
                root.qrResultText = actualText === "NOT_FOUND" ? "No QR code found in selection." : actualText
            } else {
                root.qrResultText = actualText.replace(/^QR-Code:/, "")
            }
    
            root.showQrPopup = true
            Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
        }
    }
    
    Timer {
        id: qrWaitTimer
        interval: 1200   // slightly more generous than the ~0.63s the scan takes
        repeat: false
        onTriggered: {
            qrReaderProcess.running = true
        }
    }
    
    function performQrScan() {
        Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
        root.isScanningQr = true
        root.showQrPopup = false
        root.qrResultText = ""

        let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}" --scan-qr`
        Quickshell.execDetached(["bash", "-c", cmd])

        // Start timer AFTER launching the script, not before
        qrWaitTimer.start()
    }    
    
    function executeCapture(openEditor, isRecord) {
        let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}"`
        if (isRecord) {
            cmd += " --record"
            cmd += ` --desk-vol ${root.deskVol} --desk-mute ${root.deskMute}`
            cmd += ` --mic-vol ${root.micVol} --mic-mute ${root.micMute}`
            if (root.micDevice !== "") cmd += ` --mic-dev "${root.micDevice}"`
        }
        if (openEditor) cmd += " --edit"
        Quickshell.execDetached(["bash", "-c", cmd])
        Qt.quit() 
    }
}
