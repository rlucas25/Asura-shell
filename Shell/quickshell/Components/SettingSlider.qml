import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Asura

ColumnLayout {
    id: sliderRoot

    // Header & metadata properties
    property string title: ""
    property string description: ""
    property string hint: ""
    property string hintIcon: "help"
    property string unit: ""
    property string customValueText: ""
    property bool showValue: true
    property bool showReset: false
    property real resetValue: 0
    // Adaptability & mode flags
    property bool compact: false
    property bool vertical: false
    property bool fillHeight: false
    property bool showHeader: !compact && (title !== "" || description !== "" || showReset || (showValue && (title !== "" || description !== "")))
    property bool interactive: true
    property bool wheelEnabled: false
    property real wheelStep: (stepSize >= 1) ? Math.max(1, stepSize * 5) : 5
    // Value & range
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property bool animated: true
    // Visual customizations (compact MD3 dimensions)
    property color activeColor: Colors.cfg.primary
    property color trackColor: Qt.alpha(Colors.cfg.base03, 0.4)
    property color trackBorderColor: Qt.alpha(Colors.cfg.base04, 0.22)
    property real trackBorderWidth: 1
    property bool showTrackBorder: false
    property real trackHeight: 12
    property real trackWidth: 12
    property real radius: -1
    // Thumb customizations
    property bool showThumb: true
    property bool hideThumbAtMax: false
    readonly property bool effectiveShowThumb: showThumb && (!hideThumbAtMax || fraction < 0.999)
    property color thumbColor: activeColor
    property color thumbBorderColor: "transparent"
    property real thumbBorderWidth: 0
    property real thumbWidth: 4
    property real thumbHeight: -1
    property real thumbGap: 6
    // Tooltip customization
    property bool showFloatingTooltip: !compact && showHeader
    // State exposure
    readonly property bool pressed: sliderMa.pressed
    readonly property bool hovered: sliderMa.containsMouse
    readonly property alias fraction: trackContainer.fraction

    // Signals
    signal valueModified(real val)
    signal valueCommitted(real val)
    signal moved(real val)
    signal interactionStarted()
    signal interactionEnded()
    signal rightClicked()

    Layout.fillWidth: true
    Layout.fillHeight: vertical || fillHeight
    spacing: showHeader ? 6 : 0

    RowLayout {
        id: headerRow

        Layout.fillWidth: true
        visible: sliderRoot.showHeader
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: sliderRoot.description !== "" ? 2 : 0

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    visible: sliderRoot.title !== ""
                    text: sliderRoot.title
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, sans-serif"
                    color: Colors.cfg.textBright
                }

                Rectangle {
                    visible: sliderRoot.hint !== ""
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: hintMa.containsMouse ? Qt.alpha(sliderRoot.activeColor, 0.2) : Qt.alpha(Colors.cfg.base03, 0.3)
                    border.color: hintMa.containsMouse ? Qt.alpha(sliderRoot.activeColor, 0.45) : "transparent"
                    border.width: 1
                    ToolTip.visible: hintMa.containsMouse
                    ToolTip.text: sliderRoot.hint
                    ToolTip.delay: 200

                    Text {
                        anchors.centerIn: parent
                        text: sliderRoot.hintIcon
                        font.pixelSize: 13
                        font.family: "Material Symbols Rounded"
                        color: hintMa.containsMouse ? sliderRoot.activeColor : Colors.cfg.textSecondary
                    }

                    MouseArea {
                        id: hintMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.WhatsThisCursor
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                }

            }

            Text {
                visible: sliderRoot.description !== ""
                text: sliderRoot.description
                font.pixelSize: 11
                font.family: "Google Sans, sans-serif"
                color: Colors.cfg.textSecondary
            }

        }

        Rectangle {
            visible: sliderRoot.showReset
            implicitWidth: 64
            implicitHeight: 22
            radius: 11
            color: resetHover.hovered ? Qt.alpha(sliderRoot.activeColor, 0.2) : Qt.alpha(Colors.cfg.base03, 0.25)
            border.color: resetHover.hovered ? Qt.alpha(sliderRoot.activeColor, 0.45) : Qt.alpha(Colors.cfg.base03, 0.35)
            border.width: 1
            scale: resetMa.pressed ? 0.92 : (resetHover.hovered ? 1.05 : 1)

            HoverHandler {
                id: resetHover
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    id: resetIcon

                    text: "restart_alt"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: sliderRoot.activeColor
                    transformOrigin: Item.Center

                    RotationAnimation on rotation {
                        id: resetRotateAnim

                        from: 0
                        to: -360
                        duration: 350
                        easing.type: Easing.OutCubic
                        running: false
                    }

                }

                Text {
                    text: qsTr("Reset")
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Google Sans"
                    color: Colors.cfg.textBright
                }

            }

            MouseArea {
                id: resetMa

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    resetRotateAnim.restart();
                    sliderRoot.valueModified(sliderRoot.resetValue);
                    sliderRoot.moved(sliderRoot.resetValue);
                    sliderRoot.valueCommitted(sliderRoot.resetValue);
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        Rectangle {
            visible: sliderRoot.showValue
            implicitHeight: 22
            implicitWidth: valueText.implicitWidth + 14
            radius: 11
            color: sliderMa.pressed ? Qt.alpha(sliderRoot.activeColor, 0.22) : (sliderMa.containsMouse ? Qt.alpha(sliderRoot.activeColor, 0.12) : Qt.alpha(sliderRoot.activeColor, 0.06))
            border.color: sliderMa.pressed ? sliderRoot.activeColor : (sliderMa.containsMouse ? Qt.alpha(sliderRoot.activeColor, 0.35) : Qt.alpha(sliderRoot.activeColor, 0.15))
            border.width: 1
            scale: sliderMa.pressed ? 1.08 : (sliderMa.containsMouse ? 1.03 : 1)

            Text {
                id: valueText

                anchors.centerIn: parent
                text: {
                    if (sliderRoot.customValueText !== "")
                        return sliderRoot.customValueText;

                    var valStr = (sliderRoot.stepSize < 1 && sliderRoot.stepSize > 0) ? sliderRoot.value.toFixed(2) : String(sliderRoot.value);
                    return valStr + sliderRoot.unit;
                }
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: "Google Sans Flex, Google Sans, sans-serif"
                color: sliderRoot.activeColor
            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Item {
        id: trackContainer

        readonly property real effectiveTrackHeight: {
            if (sliderRoot.vertical)
                return sliderRoot.trackHeight;

            var base = sliderRoot.trackHeight;
            if (sliderMa.pressed)
                return base + 3;

            if (sliderMa.containsMouse)
                return base + 2;

            return base;
        }
        readonly property real effectiveTrackWidth: {
            if (!sliderRoot.vertical)
                return sliderRoot.trackWidth;

            var base = sliderRoot.trackWidth;
            if (sliderMa.pressed)
                return base + 3;

            if (sliderMa.containsMouse)
                return base + 2;

            return base;
        }
        readonly property real fraction: (sliderRoot.to > sliderRoot.from) ? Math.max(0, Math.min(1, (sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from))) : 0
        readonly property real effectiveRadius: {
            if (sliderRoot.radius >= 0)
                return sliderRoot.radius;

            if (sliderRoot.vertical)
                return Math.min(width, height) / 2;

            return height / 2;
        }

        Layout.fillWidth: true
        Layout.fillHeight: sliderRoot.vertical || sliderRoot.fillHeight
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: sliderRoot.vertical ? 200 : effectiveTrackHeight
        implicitWidth: sliderRoot.vertical ? effectiveTrackWidth : 200

        Rectangle {
            id: inactiveTrack

            anchors.fill: parent
            radius: trackContainer.effectiveRadius
            color: sliderRoot.trackColor
            border.color: sliderMa.containsMouse ? Qt.alpha(sliderRoot.activeColor, 0.3) : (sliderRoot.showTrackBorder ? sliderRoot.trackBorderColor : "transparent")
            border.width: (sliderMa.containsMouse || sliderRoot.showTrackBorder) ? Math.max(1, sliderRoot.trackBorderWidth) : 0
            clip: false

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        Rectangle {
            id: activeTrack

            visible: !sliderRoot.vertical
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(parent.width, parent.width * trackContainer.fraction))
            radius: trackContainer.effectiveRadius
            color: sliderRoot.activeColor

            Behavior on width {
                enabled: !sliderMa.pressed && sliderRoot.animated

                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        Rectangle {
            id: activeTrackVertical

            visible: sliderRoot.vertical
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(0, Math.min(parent.height, parent.height * trackContainer.fraction))
            radius: trackContainer.effectiveRadius
            color: sliderRoot.activeColor

            Behavior on height {
                enabled: !sliderMa.pressed && sliderRoot.animated

                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

        }

        // Horizontal Thumb & Halo
        Item {
            id: thumbHorizontalWrapper

            visible: !sliderRoot.vertical && sliderRoot.effectiveShowThumb
            opacity: sliderRoot.effectiveShowThumb ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, (parent.width * trackContainer.fraction) - width / 2))
            width: thumbHorizontal.width
            height: thumbHorizontal.height

            // MD3 State Layer / Glowing Halo
            Rectangle {
                id: thumbHalo

                anchors.centerIn: parent
                width: Math.max(24, thumbHorizontal.width + 10)
                height: Math.max(24, thumbHorizontal.height + 4)
                radius: Math.min(width, height) / 2
                color: Qt.alpha(sliderRoot.activeColor, sliderMa.pressed ? 0.24 : 0.12)
                opacity: (sliderMa.containsMouse || sliderMa.pressed) ? 1 : 0
                scale: sliderMa.pressed ? 1.15 : (sliderMa.containsMouse ? 1 : 0.5)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

            }

            Rectangle {
                id: thumbHorizontal

                anchors.centerIn: parent
                width: sliderMa.pressed ? (sliderRoot.thumbWidth + 4) : (sliderMa.containsMouse ? (sliderRoot.thumbWidth + 2) : sliderRoot.thumbWidth)
                height: (sliderRoot.thumbHeight > 0) ? sliderRoot.thumbHeight : (sliderRoot.fillHeight ? trackContainer.height : (trackContainer.height + (sliderMa.pressed ? 6 : (sliderMa.containsMouse ? 4 : 2))))
                radius: Math.min(width, height) / 2
                color: sliderRoot.thumbColor
                border.color: sliderRoot.thumbBorderColor
                border.width: sliderRoot.thumbBorderWidth
                scale: sliderRoot.fillHeight ? 1.0 : (sliderMa.pressed ? 1.12 : (sliderMa.containsMouse ? 1.05 : 1))

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on x {
                enabled: !sliderMa.pressed && sliderRoot.animated

                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

        }

        // Vertical Thumb & Halo
        Item {
            id: thumbVerticalWrapper

            visible: sliderRoot.vertical && sliderRoot.effectiveShowThumb
            opacity: sliderRoot.effectiveShowThumb ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, Math.min(parent.height - height, (parent.height - (parent.height * trackContainer.fraction)) - height / 2))
            width: thumbVertical.width
            height: thumbVertical.height

            Rectangle {
                id: thumbHaloVert

                anchors.centerIn: parent
                width: Math.max(24, thumbVertical.width + 4)
                height: Math.max(24, thumbVertical.height + 10)
                radius: Math.min(width, height) / 2
                color: Qt.alpha(sliderRoot.activeColor, sliderMa.pressed ? 0.24 : 0.12)
                opacity: (sliderMa.containsMouse || sliderMa.pressed) ? 1 : 0
                scale: sliderMa.pressed ? 1.15 : (sliderMa.containsMouse ? 1 : 0.5)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

            }

            Rectangle {
                id: thumbVertical

                anchors.centerIn: parent
                height: sliderMa.pressed ? (sliderRoot.thumbWidth + 4) : (sliderMa.containsMouse ? (sliderRoot.thumbWidth + 2) : sliderRoot.thumbWidth)
                width: (sliderRoot.thumbHeight > 0) ? sliderRoot.thumbHeight : (sliderRoot.fillHeight ? trackContainer.width : (trackContainer.width + (sliderMa.pressed ? 6 : (sliderMa.containsMouse ? 4 : 2))))
                radius: Math.min(width, height) / 2
                color: sliderRoot.thumbColor
                border.color: sliderRoot.thumbBorderColor
                border.width: sliderRoot.thumbBorderWidth
                scale: sliderRoot.fillHeight ? 1.0 : (sliderMa.pressed ? 1.12 : (sliderMa.containsMouse ? 1.05 : 1))

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on y {
                enabled: !sliderMa.pressed && sliderRoot.animated

                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

        }

        // Floating MD3 Value Balloon
        Rectangle {
            id: floatingTooltip

            visible: sliderRoot.showFloatingTooltip
            anchors.bottom: trackContainer.top
            anchors.bottomMargin: 6
            x: Math.max(0, Math.min(trackContainer.width - width, thumbHorizontalWrapper.x + (thumbHorizontalWrapper.width - width) / 2))
            implicitWidth: floatingText.implicitWidth + 14
            implicitHeight: 22
            radius: 11
            color: sliderRoot.activeColor
            opacity: sliderMa.pressed ? 1 : 0
            scale: sliderMa.pressed ? 1 : 0.6
            transformOrigin: Item.Bottom
            z: 10

            Text {
                id: floatingText

                anchors.centerIn: parent
                text: valueText.text
                font.pixelSize: 11
                font.bold: true
                font.family: "Google Sans Flex, Google Sans, sans-serif"
                color: Colors.cfg.on_primary
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                }

            }

        }

        MouseArea {
            id: sliderMa

            function calculateValue(mx, my) {
                var frac;
                if (sliderRoot.vertical)
                    frac = Math.max(0, Math.min(1, (height - my) / height));
                else
                    frac = Math.max(0, Math.min(1, mx / width));
                var raw = sliderRoot.from + frac * (sliderRoot.to - sliderRoot.from);
                if (sliderRoot.stepSize > 0) {
                    var inv = 1 / sliderRoot.stepSize;
                    raw = Math.round(raw * inv) / inv;
                }
                return Math.max(sliderRoot.from, Math.min(sliderRoot.to, raw));
            }

            enabled: sliderRoot.interactive
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    sliderRoot.rightClicked();
                    return ;
                }
                sliderRoot.interactionStarted();
                var val = calculateValue(mouse.x, mouse.y);
                sliderRoot.valueModified(val);
                sliderRoot.moved(val);
            }
            onPositionChanged: (mouse) => {
                if (pressed && (pressedButtons & Qt.LeftButton)) {
                    var val = calculateValue(mouse.x, mouse.y);
                    sliderRoot.valueModified(val);
                    sliderRoot.moved(val);
                }
            }
            onReleased: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    var val = calculateValue(mouse.x, mouse.y);
                    sliderRoot.valueCommitted(val);
                }
                sliderRoot.interactionEnded();
            }
            onEntered: {
                sliderRoot.interactionStarted();
            }
            onExited: {
                if (!pressed)
                    sliderRoot.interactionEnded();

            }
            onWheel: (wheel) => {
                if (!sliderRoot.wheelEnabled) {
                    wheel.accepted = false;
                    return ;
                }
                var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                var step = (delta > 0 ? 1 : -1) * (sliderRoot.wheelStep > 0 ? sliderRoot.wheelStep : sliderRoot.stepSize);
                var newVal = Math.max(sliderRoot.from, Math.min(sliderRoot.to, sliderRoot.value + step));
                sliderRoot.valueModified(newVal);
                sliderRoot.moved(newVal);
                sliderRoot.valueCommitted(newVal);
            }
        }

        Behavior on implicitHeight {
            enabled: !sliderRoot.vertical

            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }

        }

        Behavior on implicitWidth {
            enabled: sliderRoot.vertical

            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }

        }

    }

}
