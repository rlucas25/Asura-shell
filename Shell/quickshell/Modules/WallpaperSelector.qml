import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Animations
import qs.Asura
import qs.Services

Item {
    id: root

    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    property bool showOnlyFavorites: false
    property string appliedWallpaperUrl: ""
    property real scrollAccumulator: 0

    function isFavorite(pathOrName) {
        if (!pathOrName || !Config.cfg || !Config.cfg.favoriteWallpapers)
            return false;

        var clean = pathOrName.toString().replace(/^file:\/\//, "").trim();
        var name = clean.substring(clean.lastIndexOf("/") + 1);
        var favs = Config.cfg.favoriteWallpapers;
        for (var i = 0; i < favs.length; i++) {
            var f = favs[i].toString().replace(/^file:\/\//, "").trim();
            var fName = f.substring(f.lastIndexOf("/") + 1);
            if (f === clean || fName === name)
                return true;

        }
        return false;
    }

    function toggleFavorite(pathOrName) {
        if (!pathOrName || !Config.cfg)
            return ;

        var clean = pathOrName.toString().replace(/^file:\/\//, "").trim();
        var name = clean.substring(clean.lastIndexOf("/") + 1);
        var favs = (Config.cfg.favoriteWallpapers && Array.isArray(Config.cfg.favoriteWallpapers)) ? Config.cfg.favoriteWallpapers.slice() : [];
        var foundIdx = -1;
        for (var i = 0; i < favs.length; i++) {
            var f = favs[i].toString().replace(/^file:\/\//, "").trim();
            var fName = f.substring(f.lastIndexOf("/") + 1);
            if (f === clean || fName === name) {
                foundIdx = i;
                break;
            }
        }
        if (foundIdx !== -1)
            favs.splice(foundIdx, 1);
        else
            favs.push(name);
        Config.cfg.favoriteWallpapers = favs;
        Config.save();
    }

    function favoriteCurrentItem() {
        if (carousel && carousel.currentItem && carousel.currentItem.imageUrl)
            toggleFavorite(carousel.currentItem.imageUrl);

    }

    function toggleFavoritesFilter() {
        showOnlyFavorites = !showOnlyFavorites;
        Qt.callLater(root.scrollToCurrentWallpaper);
    }

    function findCurrentWallpaperIndex() {
        if (!imageFolderModel || imageFolderModel.count === 0 || !Config.cfg || !Config.cfg.wallpaper)
            return -1;

        var target = Config.cfg.wallpaper.toString().replace(/^file:\/\//, "").trim();
        var targetFile = target.substring(target.lastIndexOf("/") + 1);
        for (var i = 0; i < imageFolderModel.count; i++) {
            var fPath = imageFolderModel.get(i, "filePath");
            if (fPath && fPath.toString().replace(/^file:\/\//, "").trim() === target)
                return i;

            var fUrl = imageFolderModel.get(i, "fileUrl");
            if (fUrl && fUrl.toString().replace(/^file:\/\//, "").trim() === target)
                return i;

            var fName = imageFolderModel.get(i, "fileName");
            if (fName && targetFile && fName === targetFile)
                return i;

        }
        return -1;
    }

    function scrollToCurrentWallpaper() {
        var idx = findCurrentWallpaperIndex();
        if (idx >= 0 && carousel.count > 0) {
            if (typeof carousel.positionViewAtIndex === "function")
                carousel.positionViewAtIndex(idx, PathView.Center);

            carousel.currentIndex = idx;
        }
    }

    implicitWidth: 1050
    implicitHeight: 395
    Component.onCompleted: {
        Qt.callLater(function() {
            if (root && searchInput)
                searchInput.forceActiveFocus();
            if (root && typeof root.scrollToCurrentWallpaper === "function")
                root.scrollToCurrentWallpaper();
        });
    }
    onVisibleChanged: {
        if (visible) {
            if (searchInput)
                searchInput.text = "";
            Qt.callLater(function() {
                if (root && searchInput)
                    searchInput.forceActiveFocus();
                if (root && typeof root.scrollToCurrentWallpaper === "function")
                    root.scrollToCurrentWallpaper();
            });
        }
    }

    MenuEntrance {
        id: wpEntrance

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
        anchors.margins: {
            bottom:
            10;
        }
        width: 700
        height: 45
        radius: 20
        color: Qt.alpha(surfaceContainer, 0.4)
        opacity: wpEntrance.opacity

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
                carousel.applyWallpaper(carousel.currentItem.imageUrl);
                event.accepted = true;
            }
            Keys.onEnterPressed: (event) => {
                carousel.applyWallpaper(carousel.currentItem.imageUrl);
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
                    return ;
                }
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.toggleFavoritesFilter();
                    event.accepted = true;
                    return ;
                }
            }

            Text {
                text: qsTr("Search wallpapers...")
                color: root.primary
                opacity: 0.3
                font.pixelSize: 16
                visible: searchInput.text === ""
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        transform: Translate {
            y: wpEntrance.offsetY
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
                text: qsTr("Wallpaper Applied")
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

    FolderListModel {
        id: imageFolderModel

        folder: "file://" + String(Quickshell.env("HOME")) + Config.cfg.wallpaperFolder
        showDirs: false
        nameFilters: {
            if (root.showOnlyFavorites) {
                var favs = (Config.cfg && Config.cfg.favoriteWallpapers) ? Config.cfg.favoriteWallpapers : [];
                if (favs.length === 0)
                    return ["__no_favs_found__"];

                var q = searchInput.text.trim().toLowerCase();
                var result = [];
                for (var i = 0; i < favs.length; i++) {
                    var fName = favs[i].toString().replace(/^file:\/\//, "").trim();
                    var base = fName.substring(fName.lastIndexOf("/") + 1);
                    if (q === "" || base.toLowerCase().indexOf(q) !== -1)
                        result.push(base);

                }
                return result.length > 0 ? result : ["__no_favs_found__"];
            }
            var searchQuery = "*" + searchInput.text.trim() + "*";
            return [searchQuery + ".png", searchQuery + ".jpg", searchQuery + ".jpeg", searchQuery + ".webp", searchQuery + ".svg"];
        }
        onStatusChanged: {
            if (status === FolderListModel.Ready && root.visible && searchInput.text === "")
                Qt.callLater(root.scrollToCurrentWallpaper);

        }
        onCountChanged: {
            if (root.visible && searchInput.text === "" && count > 0)
                Qt.callLater(root.scrollToCurrentWallpaper);

        }
    }

    PathView {
        id: carousel

        function applyWallpaper(url) {
            if (!url)
                return ;

            var cleanPath = url.toString().replace("file://", "");
            console.log("New wallpaper: " + cleanPath);
            root.appliedWallpaperUrl = url.toString();
            appliedToastAnim.restart();
            try {
                Config.cfg.wallpaper = cleanPath;
                Config.save();
                if (Config.cfg.colorsAutoGenerate)
                    Colors.generateDynamicColors(cleanPath, Config.cfg.isDarkMode, Config.cfg.scheme);
                else
                    Colors.applyThemeFromWallpaper(cleanPath, Config.cfg.isDarkMode);
            } catch (e) {
                console.log(e);
            }
        }

        anchors.top: searchContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: shortcutsBar.top
        anchors.bottomMargin: 6
        anchors.margins: 20
        opacity: wpEntrance.opacity
        onCountChanged: {
            if (root.visible && searchInput.text === "" && count > 0)
                Qt.callLater(root.scrollToCurrentWallpaper);

        }
        scale: wpEntrance.scale
        model: imageFolderModel
        pathItemCount: 5
        highlightMoveDuration: 300
        maximumFlickVelocity: 1000
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        Keys.onLeftPressed: carousel.decrementCurrentIndex()
        Keys.onRightPressed: carousel.incrementCurrentIndex()
        Keys.onUpPressed: carousel.decrementCurrentIndex()
        Keys.onDownPressed: carousel.incrementCurrentIndex()
        Keys.onReturnPressed: applyWallpaper(carousel.currentItem.imageUrl)
        Keys.onEnterPressed: applyWallpaper(carousel.currentItem.imageUrl)
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
            visible: root.showOnlyFavorites && imageFolderModel.count === 0
            text: qsTr("No favorite wallpapers yet\nPress 'Ctrl' to favorite a wallpaper")
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
            y: (1 - wpEntrance.progress) * 16
        }

        delegate: Item {
            id: delegateRoot

            property string imageUrl: fileUrl

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

                Image {
                    id: originalImage

                    anchors.fill: parent
                    source: fileUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 200)
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: imageMask

                    anchors.fill: parent
                    radius: 25
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: originalImage
                    maskSource: imageMask
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

                    readonly property bool isFav: root.isFavorite(fileUrl) || root.isFavorite(fileName)

                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
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
                            root.toggleFavorite(fileUrl);
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
                    function onAppliedWallpaperUrlChanged() {
                        if (root.appliedWallpaperUrl !== "" && (root.appliedWallpaperUrl === delegateRoot.imageUrl || root.appliedWallpaperUrl.indexOf(fileName) !== -1))
                            cardApplyAnim.restart();

                    }

                    target: root
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 25
                    border.color: "light gray"
                    border.width: delegateRoot.PathView.isCurrentItem ? 4 : 0

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

            }

            Text {
                anchors.top: imageWrapper.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: fileName
                font.pixelSize: 14
                font.bold: true
                color: delegateRoot.PathView.isCurrentItem ? "white" : "#a6adc8"

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            TapHandler {
                onTapped: {
                    carousel.focus = true;
                    carousel.applyWallpaper(fileUrl);
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
