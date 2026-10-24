import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Services

Item {
    id: root

    focus: true

    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property bool showOnlyFavorites: false
    property string appliedPresetId: ""
    property string appliedPresetName: ""
    property real scrollAccumulator: 0

    implicitWidth: 1050
    implicitHeight: 395

    Keys.onEscapePressed: (event) => {
        MenuService.closeAll();
        event.accepted = true;
    }

    function focusSearchInput() {
        if (searchInput)
            searchInput.forceActiveFocus();
    }

    readonly property var allPresets: PresetService.presets || []

    readonly property var filteredPresets: {
        var list = root.allPresets;
        var q = searchInput.text.trim().toLowerCase();

        if (root.showOnlyFavorites) {
            list = list.filter(function(item) {
                return item && root.isFavorite(item.id);
            });
        }

        if (q === "")
            return list;

        return list.filter(function(item) {
            if (!item)
                return false;
            var nameMatch = item.name && item.name.toLowerCase().indexOf(q) !== -1;
            var themeMatch = item.theme && item.theme.toLowerCase().indexOf(q) !== -1;
            var schemeMatch = item.scheme && item.scheme.toLowerCase().indexOf(q) !== -1;
            return nameMatch || themeMatch || schemeMatch;
        });
    }

    function isFavorite(presetId) {
        if (!presetId || !Config.cfg || !Config.cfg.favoritePresets)
            return false;

        var favs = Config.cfg.favoritePresets;
        for (var i = 0; i < favs.length; i++) {
            if (favs[i] === presetId)
                return true;
        }
        return false;
    }

    function toggleFavorite(presetId) {
        if (!presetId || !Config.cfg)
            return;

        var favs = (Config.cfg.favoritePresets && Array.isArray(Config.cfg.favoritePresets)) ? Config.cfg.favoritePresets.slice() : [];
        var idx = favs.indexOf(presetId);
        if (idx !== -1)
            favs.splice(idx, 1);
        else
            favs.push(presetId);

        Config.cfg.favoritePresets = favs;
        Config.save();
    }

    function favoriteCurrentItem() {
        if (carousel && carousel.currentIndex >= 0 && carousel.currentIndex < filteredPresets.length) {
            var item = filteredPresets[carousel.currentIndex];
            if (item && item.id)
                toggleFavorite(item.id);
        }
    }

    function toggleFavoritesFilter() {
        showOnlyFavorites = !showOnlyFavorites;
        Qt.callLater(root.scrollToActivePreset);
    }

    function findActivePresetIndex() {
        if (!filteredPresets || filteredPresets.length === 0)
            return -1;

        var activeId = PresetService.activePresetId;
        for (var i = 0; i < filteredPresets.length; i++) {
            if (filteredPresets[i] && filteredPresets[i].id === activeId)
                return i;
        }
        return 0;
    }

    function scrollToActivePreset() {
        if (!carousel || carousel.count <= 0)
            return;

        var idx = findActivePresetIndex();
        if (idx >= 0 && carousel.count > 0) {
            if (typeof carousel.positionViewAtIndex === "function")
                carousel.positionViewAtIndex(idx, PathView.Center);

            carousel.currentIndex = idx;
        }
    }

    function applyPreset(item) {
        if (!item || !item.id)
            return;

        root.appliedPresetId = item.id;
        root.appliedPresetName = item.name || item.id;
        appliedToastAnim.restart();
        PresetService.applyPreset(item.id);
    }

    function applyCurrentItem() {
        if (carousel && carousel.currentIndex >= 0 && carousel.currentIndex < filteredPresets.length) {
            applyPreset(filteredPresets[carousel.currentIndex]);
        }
    }

    Component.onCompleted: {
        PresetService.loadPresets();
        Qt.callLater(function() {
            if (root && searchInput) {
                searchInput.forceActiveFocus();
                root.scrollToActivePreset();
            }
        });
    }

    onVisibleChanged: {
        if (visible) {
            PresetService.loadPresets();
            if (searchInput)
                searchInput.text = "";

            Qt.callLater(function() {
                if (root && searchInput) {
                    searchInput.forceActiveFocus();
                    root.scrollToActivePreset();
                }
            });
        }
    }

    Connections {
        target: PresetService
        function onPresetApplied(presetId, name) {
            root.appliedPresetId = presetId;
            root.appliedPresetName = name;
        }
        function onPresetsLoaded() {
            if (root && root.visible && searchInput && searchInput.text === "") {
                Qt.callLater(function() {
                    if (root && typeof root.scrollToActivePreset === "function")
                        root.scrollToActivePreset();
                });
            }
        }
    }

    MenuEntrance {
        id: psEntrance

        active: root.visible
        duration: 320
        startOffsetY: 12
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12
    }

    Rectangle {
        id: searchContainer

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 700
        height: 45
        radius: 20
        color: Qt.alpha(surfaceContainer, 0.4)
        opacity: psEntrance.opacity

        MouseArea {
            anchors.fill: parent
            onClicked: searchInput.forceActiveFocus()
        }

        TextInput {
            id: searchInput

            focus: true
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            verticalAlignment: TextInput.AlignVCenter
            color: "white"
            font.pixelSize: 16
            clip: true

            Keys.onEscapePressed: (event) => {
                MenuService.closeAll();
                event.accepted = true;
            }
            Keys.onLeftPressed: (event) => {
                carousel.decrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onRightPressed: (event) => {
                carousel.incrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onUpPressed: (event) => {
                carousel.decrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onDownPressed: (event) => {
                carousel.incrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onReturnPressed: (event) => {
                root.applyCurrentItem();
                event.accepted = true;
            }
            Keys.onEnterPressed: (event) => {
                root.applyCurrentItem();
                event.accepted = true;
            }
            Keys.onTabPressed: (event) => {
                root.toggleFavoritesFilter();
                event.accepted = true;
            }
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Control) {
                    root.favoriteCurrentItem();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.toggleFavoritesFilter();
                    event.accepted = true;
                    return;
                }
            }

            Text {
                text: qsTr("Search presets...")
                color: root.primary
                opacity: 0.3
                font.pixelSize: 16
                visible: searchInput.text === ""
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        transform: Translate {
            y: psEntrance.offsetY
        }
    }

    Rectangle {
        id: appliedToast

        anchors.top: searchContainer.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: toastRow.implicitWidth + 24
        height: 28
        radius: 14
        color: Qt.alpha(Colors.cfg.background, 0.95)
        border.color: root.primary
        border.width: 1.5
        z: 200
        opacity: 0
        scale: 0.8
        visible: opacity > 0.001

        RowLayout {
            id: toastRow

            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "󰄬"
                font.family: "GeistMono Nerd Font Propo"
                font.pixelSize: 14
                color: root.primary
            }

            Text {
                text: root.appliedPresetName ? qsTr("Preset '%1' Applied").arg(root.appliedPresetName) : qsTr("Preset Applied")
                font.pixelSize: 12
                font.bold: true
                color: Colors.cfg.textBright || "white"
            }
        }

        SequentialAnimation {
            id: appliedToastAnim

            ParallelAnimation {
                NumberAnimation {
                    target: appliedToast
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: appliedToast
                    property: "scale"
                    from: 0.8
                    to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            PauseAnimation {
                duration: 900
            }

            ParallelAnimation {
                NumberAnimation {
                    target: appliedToast
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 250
                    easing.type: Easing.InQuad
                }

                NumberAnimation {
                    target: appliedToast
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: 250
                }
            }
        }
    }

    PathView {
        id: carousel

        anchors.top: searchContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: shortcutsBar.top
        anchors.bottomMargin: 6
        anchors.margins: 20
        opacity: psEntrance.opacity
        scale: psEntrance.scale
        model: root.filteredPresets
        pathItemCount: Math.max(1, Math.min(5, root.filteredPresets.length))
        highlightMoveDuration: 300
        maximumFlickVelocity: 1000
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        Keys.onEscapePressed: (event) => {
            MenuService.closeAll();
            event.accepted = true;
        }
        Keys.onLeftPressed: carousel.decrementCurrentIndex()
        Keys.onRightPressed: carousel.incrementCurrentIndex()
        Keys.onUpPressed: carousel.decrementCurrentIndex()
        Keys.onDownPressed: carousel.incrementCurrentIndex()
        Keys.onReturnPressed: root.applyCurrentItem()
        Keys.onEnterPressed: root.applyCurrentItem()
        Keys.onTabPressed: (event) => {
            root.toggleFavoritesFilter();
            event.accepted = true;
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Control) {
                root.favoriteCurrentItem();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.toggleFavoritesFilter();
                event.accepted = true;
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.filteredPresets.length === 0
            text: (root.allPresets.length > 0)
                ? (root.showOnlyFavorites
                    ? qsTr("No favorite presets yet\nPress 'Ctrl' to favorite a preset")
                    : qsTr("No presets found matching '%1'").arg(searchInput.text.trim()))
                : qsTr("No appearance presets saved yet\nSave presets in Settings > Presets")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 15
            color: root.primary
            opacity: 0.7
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                scrollAccumulator += wheel.angleDelta.y ? wheel.angleDelta.y : wheel.angleDelta.x;
                var sensitivity = 120;
                if (scrollAccumulator <= -sensitivity) {
                    carousel.incrementCurrentIndex();
                    scrollAccumulator = 0;
                } else if (scrollAccumulator >= sensitivity) {
                    carousel.decrementCurrentIndex();
                    scrollAccumulator = 0;
                }
            }
        }

        transform: Translate {
            y: (1 - psEntrance.progress) * 16
        }

        delegate: Item {
            id: delegateRoot

            required property var modelData
            required property int index

            readonly property string presetId: modelData ? (modelData.id || "") : ""
            readonly property string presetName: modelData ? (modelData.name || "") : ""
            readonly property string wpPath: modelData ? (modelData.wallpaperCopyPath || modelData.originalWallpaper || "") : ""
            readonly property bool isActiveRice: PresetService.activePresetId === presetId
            readonly property string presetBarPosition: (modelData && modelData.barPosition) ? modelData.barPosition : (Config.barPosition || "top")
            readonly property int presetBarMode: (modelData && modelData.barMode !== undefined) ? modelData.barMode : ((Config.cfg && Config.cfg.barMode !== undefined) ? Config.cfg.barMode : 1)
            readonly property var presetActiveCapsules: (modelData && modelData.activeCapsules) ? modelData.activeCapsules : ({ "left": true, "center": true, "right": true })

            width: 320
            height: 240
            scale: PathView.iconScale ?? 1
            opacity: PathView.iconOpacity ?? 1
            z: PathView.iconZ ?? 0

            Item {
                id: imageWrapper

                width: 320
                height: 200
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    id: wallpaperSurface

                    anchors.fill: parent
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        color: modelData && modelData.backgroundColor ? modelData.backgroundColor : Colors.cfg.surfaceContainer
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: modelData && modelData.backgroundColor ? modelData.backgroundColor : Colors.cfg.surface }
                            GradientStop { position: 1.0; color: modelData && modelData.surfaceColor ? modelData.surfaceColor : Colors.cfg.surfaceContainer }
                        }
                    }

                    Image {
                        id: presetWallpaperImage

                        anchors.fill: parent
                        source: delegateRoot.wpPath ? ("file://" + delegateRoot.wpPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(320, 200)
                        asynchronous: true
                        visible: delegateRoot.wpPath !== ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                            GradientStop { position: 0.35; color: "transparent" }
                            GradientStop { position: 0.65; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                        }
                    }

                    PresetBarPreview {
                        id: miniBarPreview
                        barPosition: delegateRoot.presetBarPosition
                        barMode: delegateRoot.presetBarMode
                        activeCapsules: delegateRoot.presetActiveCapsules
                        barBackground: delegateRoot.modelData && delegateRoot.modelData.surfaceColor ? delegateRoot.modelData.surfaceColor : Colors.cfg.surfaceContainer
                        primaryColor: delegateRoot.modelData && delegateRoot.modelData.primaryColor ? delegateRoot.modelData.primaryColor : Colors.cfg.primary
                        secondaryColor: delegateRoot.modelData && delegateRoot.modelData.secondaryColor ? delegateRoot.modelData.secondaryColor : Colors.cfg.secondary
                        textColor: delegateRoot.modelData && delegateRoot.modelData.textColor ? delegateRoot.modelData.textColor : Colors.cfg.text
                        isHighlighted: delegateRoot.PathView.isCurrentItem
                    }
                }

                Rectangle {
                    id: imageMask

                    anchors.fill: parent
                    radius: 25
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: wallpaperSurface
                    maskSource: imageMask
                }

                Rectangle {
                    id: palettePill
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: (delegateRoot.presetBarPosition === "bottom") ? 24 : 10
                    anchors.leftMargin: (delegateRoot.presetBarPosition === "left") ? 24 : 10
                    height: 22
                    radius: 11
                    color: Qt.alpha(Colors.cfg.background, 0.8)
                    border.color: Qt.alpha(Colors.cfg.border, 0.4)
                    border.width: 1
                    implicitWidth: colorRow.implicitWidth + 12
                    z: 8

                    Row {
                        id: colorRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: delegateRoot.modelData && delegateRoot.modelData.primaryColor ? delegateRoot.modelData.primaryColor : Colors.cfg.primary
                            border.color: Qt.alpha("white", 0.3)
                            border.width: 1
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: delegateRoot.modelData && delegateRoot.modelData.secondaryColor ? delegateRoot.modelData.secondaryColor : Colors.cfg.secondary
                            border.color: Qt.alpha("white", 0.3)
                            border.width: 1
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: delegateRoot.modelData && delegateRoot.modelData.surfaceColor ? delegateRoot.modelData.surfaceColor : Colors.cfg.surface
                            border.color: Qt.alpha("white", 0.3)
                            border.width: 1
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: delegateRoot.modelData && delegateRoot.modelData.backgroundColor ? delegateRoot.modelData.backgroundColor : Colors.cfg.background
                            border.color: Qt.alpha("white", 0.3)
                            border.width: 1
                        }
                    }
                }

                Rectangle {
                    id: activeBadge
                    visible: delegateRoot.isActiveRice
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: (delegateRoot.presetBarPosition === "top") ? 24 : 10
                    anchors.leftMargin: (delegateRoot.presetBarPosition === "left") ? 24 : 10
                    height: 22
                    radius: 11
                    color: Colors.cfg.primary
                    implicitWidth: activeRow.implicitWidth + 14
                    z: 9

                    RowLayout {
                        id: activeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄬"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 11
                            color: Colors.cfg.on_primary
                        }

                        Text {
                            text: qsTr("ACTIVE")
                            font.pixelSize: 9
                            font.bold: true
                            color: Colors.cfg.on_primary
                        }
                    }
                }

                Rectangle {
                    id: barInfoBadge
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: (delegateRoot.presetBarPosition === "bottom") ? 24 : 10
                    anchors.rightMargin: (delegateRoot.presetBarPosition === "right") ? 24 : 10
                    height: 22
                    radius: 11
                    color: Qt.alpha(Colors.cfg.background, 0.82)
                    border.color: delegateRoot.PathView.isCurrentItem ? Qt.alpha(root.primary, 0.5) : Qt.alpha(Colors.cfg.border, 0.35)
                    border.width: 1
                    implicitWidth: barInfoRow.implicitWidth + 14
                    z: 8

                    RowLayout {
                        id: barInfoRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: {
                                if (delegateRoot.presetBarMode === 2) return "󰏚";
                                if (delegateRoot.presetBarMode === 0) return "󰍹";
                                return "󰖲";
                            }
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 11
                            color: delegateRoot.modelData && delegateRoot.modelData.primaryColor ? delegateRoot.modelData.primaryColor : root.primary
                        }

                        Text {
                            text: {
                                var pos = delegateRoot.presetBarPosition;
                                var capPos = pos.charAt(0).toUpperCase() + pos.slice(1);
                                if (delegateRoot.presetBarMode === 2) {
                                    var count = (delegateRoot.presetActiveCapsules.left !== false ? 1 : 0) +
                                                (delegateRoot.presetActiveCapsules.center !== false ? 1 : 0) +
                                                (delegateRoot.presetActiveCapsules.right !== false ? 1 : 0);
                                    return capPos + " • " + qsTr("Capsules (%1)").arg(count);
                                } else if (delegateRoot.presetBarMode === 0) {
                                    return capPos + " • " + qsTr("Island");
                                } else {
                                    return capPos + " • " + qsTr("Full");
                                }
                            }
                            font.pixelSize: 9
                            font.bold: true
                            color: Colors.cfg.textBright || "white"
                        }
                    }
                }

                Rectangle {
                    id: flashOverlay

                    anchors.fill: parent
                    radius: 25
                    color: root.primary
                    opacity: 0
                    z: 5
                }

                Rectangle {
                    id: checkmarkBadge

                    anchors.centerIn: parent
                    width: 52
                    height: 52
                    radius: 26
                    color: Qt.alpha(Colors.cfg.background, 0.9)
                    border.color: root.primary
                    border.width: 2
                    opacity: 0
                    scale: 0.5
                    z: 6

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: 26
                        color: root.primary
                    }
                }

                Rectangle {
                    id: starBadge

                    readonly property bool isFav: root.isFavorite(delegateRoot.presetId)

                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: (delegateRoot.presetBarPosition === "top") ? 24 : 10
                    anchors.rightMargin: (delegateRoot.presetBarPosition === "right") ? 24 : 10
                    width: 32
                    height: 32
                    radius: 16
                    color: isFav ? Qt.alpha(Colors.cfg.background, 0.85) : (starMa.containsMouse ? Qt.alpha(Colors.cfg.background, 0.75) : "transparent")
                    border.color: isFav ? (Colors.cfg.warning || "#F5A97F") : Qt.alpha(Colors.cfg.text, 0.25)
                    border.width: isFav ? 1.5 : (starMa.containsMouse ? 1 : 0)
                    z: 10
                    scale: isFav ? 1 : (starMa.containsMouse ? 1.15 : 0.85)
                    opacity: (isFav || starMa.containsMouse || delegateRoot.PathView.isCurrentItem) ? 1 : 0

                    Text {
                        anchors.centerIn: parent
                        text: starBadge.isFav ? "󰓎" : "󰓍"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: starBadge.isFav ? (Colors.cfg.warning || "#F5A97F") : Colors.cfg.text
                    }

                    MouseArea {
                        id: starMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.toggleFavorite(delegateRoot.presetId);
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                SequentialAnimation {
                    id: cardApplyAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: flashOverlay
                            property: "opacity"
                            from: 0.6
                            to: 0
                            duration: 400
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: checkmarkBadge
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 600
                            easing.type: Easing.InQuad
                        }

                        NumberAnimation {
                            target: checkmarkBadge
                            property: "scale"
                            from: 0.5
                            to: 1.2
                            duration: 250
                            easing.type: Easing.OutBack
                        }

                        SequentialAnimation {
                            NumberAnimation {
                                target: imageWrapper
                                property: "scale"
                                to: 0.94
                                duration: 100
                                easing.type: Easing.OutQuad
                            }

                            NumberAnimation {
                                target: imageWrapper
                                property: "scale"
                                to: 1.06
                                duration: 180
                                easing.type: Easing.OutBack
                            }

                            NumberAnimation {
                                target: imageWrapper
                                property: "scale"
                                to: 1
                                duration: 150
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }

                Connections {
                    target: root
                    function onAppliedPresetIdChanged() {
                        if (root.appliedPresetId !== "" && root.appliedPresetId === delegateRoot.presetId)
                            cardApplyAnim.restart();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 25
                    border.color: delegateRoot.isActiveRice ? Colors.cfg.primary : (Colors.cfg.border || "light gray")
                    border.width: delegateRoot.PathView.isCurrentItem ? 4 : (delegateRoot.isActiveRice ? 2 : 0)

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            Column {
                anchors.top: imageWrapper.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: delegateRoot.presetName
                    font.pixelSize: 14
                    font.bold: true
                    color: delegateRoot.PathView.isCurrentItem ? (Colors.cfg.textBright || "white") : Colors.cfg.textSecondary
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        text: delegateRoot.modelData && delegateRoot.modelData.theme ? String(delegateRoot.modelData.theme).toUpperCase() : ""
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: delegateRoot.PathView.isCurrentItem ? root.primary : Colors.cfg.textSecondary
                        opacity: 0.8
                    }

                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Colors.cfg.textSecondary
                        opacity: 0.5
                    }

                    Text {
                        text: {
                            var pos = delegateRoot.presetBarPosition;
                            var capPos = pos.charAt(0).toUpperCase() + pos.slice(1);
                            if (delegateRoot.presetBarMode === 2) {
                                var count = (delegateRoot.presetActiveCapsules.left !== false ? 1 : 0) +
                                            (delegateRoot.presetActiveCapsules.center !== false ? 1 : 0) +
                                            (delegateRoot.presetActiveCapsules.right !== false ? 1 : 0);
                                return capPos + " " + qsTr("Capsules (%1)").arg(count);
                            } else if (delegateRoot.presetBarMode === 0) {
                                return capPos + " " + qsTr("Island");
                            } else {
                                return capPos + " " + qsTr("Full Bar");
                            }
                        }
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: delegateRoot.PathView.isCurrentItem ? (Colors.cfg.textBright || "white") : Colors.cfg.textSecondary
                        opacity: 0.85
                    }
                }
            }

            TapHandler {
                onTapped: {
                    carousel.focus = true;
                    root.applyPreset(delegateRoot.modelData);
                }
            }
        }

        path: Path {
            startX: (carousel.width / 2) - 550
            startY: carousel.height / 2

            PathPercent {
                value: 0
            }

            PathAttribute {
                name: "iconScale"
                value: 0.4
            }

            PathAttribute {
                name: "iconOpacity"
                value: 0.4
            }

            PathAttribute {
                name: "iconZ"
                value: 0
            }

            PathLine {
                x: (carousel.width / 2) - 320
                y: carousel.height / 2
            }

            PathPercent {
                value: 0.25
            }

            PathAttribute {
                name: "iconScale"
                value: 0.7
            }

            PathAttribute {
                name: "iconOpacity"
                value: 0.6
            }

            PathAttribute {
                name: "iconZ"
                value: 50
            }

            PathLine {
                x: carousel.width / 2
                y: carousel.height / 2
            }

            PathPercent {
                value: 0.5
            }

            PathAttribute {
                name: "iconScale"
                value: 1
            }

            PathAttribute {
                name: "iconOpacity"
                value: 1
            }

            PathAttribute {
                name: "iconZ"
                value: 100
            }

            PathLine {
                x: (carousel.width / 2) + 320
                y: carousel.height / 2
            }

            PathPercent {
                value: 0.75
            }

            PathAttribute {
                name: "iconScale"
                value: 0.7
            }

            PathAttribute {
                name: "iconOpacity"
                value: 0.6
            }

            PathAttribute {
                name: "iconZ"
                value: 50
            }

            PathLine {
                x: (carousel.width / 2) + 550
                y: carousel.height / 2
            }

            PathPercent {
                value: 1
            }

            PathAttribute {
                name: "iconScale"
                value: 0.4
            }

            PathAttribute {
                name: "iconOpacity"
                value: 0.4
            }

            PathAttribute {
                name: "iconZ"
                value: 0
            }
        }
    }

    Rectangle {
        id: shortcutsBar

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        height: 30
        radius: 15
        color: Qt.alpha(Colors.cfg.surfaceContainer, 0.65)
        border.color: Qt.alpha(root.primary, 0.15)
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            RowLayout {
                spacing: 6

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 20
                    radius: 6
                    color: Qt.alpha(root.primary, 0.15)
                    border.color: Qt.alpha(root.primary, 0.3)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "󰁍"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 11
                            color: root.primary
                        }

                        Text {
                            text: "󰁔"
                            font.family: "GeistMono Nerd Font Propo"
                            font.pixelSize: 11
                            color: root.primary
                        }
                    }
                }

                Text {
                    text: qsTr("Navigate")
                    font.pixelSize: 11
                    color: Colors.cfg.textSecondary
                }
            }

            RowLayout {
                spacing: 6

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 20
                    radius: 6
                    color: Qt.alpha(root.primary, 0.15)
                    border.color: Qt.alpha(root.primary, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰌑"
                        font.family: "GeistMono Nerd Font Propo"
                        font.pixelSize: 12
                        color: root.primary
                    }
                }

                Text {
                    text: qsTr("Apply")
                    font.pixelSize: 11
                    color: Colors.cfg.textSecondary
                }
            }

            RowLayout {
                spacing: 6

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 20
                    radius: 6
                    color: Qt.alpha(root.primary, 0.15)
                    border.color: Qt.alpha(root.primary, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Ctrl"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.primary
                    }
                }

                RowLayout {
                    spacing: 4

                    Text {
                        text: "󰓎"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: Colors.cfg.warning || "#F5A97F"
                    }

                    Text {
                        text: qsTr("Favorite")
                        font.pixelSize: 11
                        color: Colors.cfg.textSecondary
                    }
                }
            }

            Item {
                implicitWidth: tabRow.implicitWidth
                implicitHeight: 20

                RowLayout {
                    id: tabRow

                    anchors.fill: parent
                    spacing: 6

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 20
                        radius: 6
                        color: root.showOnlyFavorites ? root.primary : Qt.alpha(root.primary, 0.15)
                        border.color: root.showOnlyFavorites ? root.primary : Qt.alpha(root.primary, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Tab"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.showOnlyFavorites ? Colors.cfg.on_primary : root.primary
                        }
                    }

                    RowLayout {
                        spacing: 4

                        Text {
                            text: "󰓎"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: root.showOnlyFavorites ? root.primary : Colors.cfg.textSecondary
                        }

                        Text {
                            text: root.showOnlyFavorites ? qsTr("Favorites (Active)") : qsTr("Filter Favorites")
                            font.pixelSize: 11
                            font.bold: root.showOnlyFavorites
                            color: root.showOnlyFavorites ? root.primary : Colors.cfg.textSecondary
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleFavoritesFilter()
                }
            }

            RowLayout {
                spacing: 6

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 20
                    radius: 6
                    color: Qt.alpha(root.primary, 0.15)
                    border.color: Qt.alpha(root.primary, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Esc"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.primary
                    }
                }

                Text {
                    text: qsTr("Close")
                    font.pixelSize: 11
                    color: Colors.cfg.textSecondary
                }
            }
        }
    }
}
