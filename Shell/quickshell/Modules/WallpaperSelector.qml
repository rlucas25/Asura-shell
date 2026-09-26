import QtQuick
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import qs.Asura
import qs.Animations
import qs.Services
import Quickshell

Item {
    id: root

    MenuEntrance {
        id: wpEntrance
        active: root.visible
        duration: 320
        startOffsetY: 12
    }

    property color surfaceContainer: Colors.cfg.surfaceContainer
    property color primary: Colors.cfg.primary
    implicitWidth: 1050
    implicitHeight: 360

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            searchInput.forceActiveFocus();
        });
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            Qt.callLater(function () {
                searchInput.forceActiveFocus();
            });
        }
    }
    property real scrollAccumulator: 0
    // --- Search Bar ---
    Rectangle {
        id: searchContainer
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: {
            bottom: 10;
        }
        width: 700
        height: 45
        radius: 20
        color: Qt.alpha(surfaceContainer, 0.4)
        opacity: wpEntrance.opacity
        transform: Translate {
            y: wpEntrance.offsetY
        }

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

            Keys.onEscapePressed: event => {
                MenuService.closeAll();
                event.accepted = true;
            }

            Keys.onLeftPressed: event => {
                carrossel.decrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onRightPressed: event => {
                carrossel.incrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onUpPressed: event => {
                carrossel.decrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onDownPressed: event => {
                carrossel.incrementCurrentIndex();
                event.accepted = true;
            }

            Keys.onReturnPressed: event => {
                carrossel.aplicarWallpaper(carrossel.currentItem.imageUrl);
                event.accepted = true;
            }
            Keys.onEnterPressed: event => {
                carrossel.aplicarWallpaper(carrossel.currentItem.imageUrl);
                event.accepted = true;
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
    }

    FolderListModel {
        id: pastaDeImagens

        folder: "file://" + String(Quickshell.env("HOME")) + Config.cfg.wallpaperFolder
        showDirs: false

        nameFilters: {
            var busca = "*" + searchInput.text.trim() + "*";
            return [busca + ".png", busca + ".jpg", busca + ".jpeg", busca + ".webp", busca + ".svg"];
        }
    }

    PathView {
        id: carrossel
        anchors.top: searchContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        opacity: wpEntrance.opacity
        scale: wpEntrance.scale
        transform: Translate {
            y: (1.0 - wpEntrance.progress) * 16
        }
        model: pastaDeImagens
        pathItemCount: 5

        highlightMoveDuration: 300
        maximumFlickVelocity: 1000
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        focus: true
        onActiveFocusChanged: {
            if (activeFocus)
                searchInput.focus = false;
        }

        function aplicarWallpaper(url) {
            if (!url)
                return;

            var cleanPath = url.toString().replace("file://", "");
            console.log("New wallpaper: " + cleanPath);

            try {
                Config.cfg.wallpaper = cleanPath;
                if (Config.cfg.colorsAutoGenerate) {
                    Colors.generateMatugenColors(cleanPath, Config.cfg.isDarkMode, Config.cfg.scheme);
                }
            } catch (e) {
                console.log(e);
            }
        }

        // Navigation keys
        Keys.onLeftPressed: carrossel.decrementCurrentIndex()
        Keys.onRightPressed: carrossel.incrementCurrentIndex()
        Keys.onUpPressed: carrossel.decrementCurrentIndex()
        Keys.onDownPressed: carrossel.incrementCurrentIndex()

        Keys.onReturnPressed: aplicarWallpaper(carrossel.currentItem.imageUrl)
        Keys.onEnterPressed: aplicarWallpaper(carrossel.currentItem.imageUrl)

        delegate: Item {
            id: delegateRoot
            width: 320
            height: 240

            scale: PathView.iconScale ?? 1
            opacity: PathView.iconOpacity ?? 1
            z: PathView.iconZ ?? 0

            property string imageUrl: fileUrl

            // --- Wallpaper Image Preview ---
            Item {
                id: wrapperImagem
                width: 320
                height: 200
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                Image {
                    id: imgOriginal
                    anchors.fill: parent
                    source: fileUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 200)
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: molde
                    anchors.fill: parent
                    radius: 25
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: imgOriginal
                    maskSource: molde
                }

                // --- Selection Border ---
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

            // --- File Name ---
            Text {
                anchors.top: wrapperImagem.top
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

            // --- Tap / Selection Handler ---
            TapHandler {
                onTapped: {
                    carrossel.focus = true;
                    carrossel.aplicarWallpaper(fileUrl);
                }
            }
        }        
        path: Path {

            startX: (carrossel.width / 2) - 550
            startY: carrossel.height/2
            PathPercent {
                value: 0.0
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
                x: (carrossel.width / 2) - 320
                y: carrossel.height/2
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
                x: carrossel.width / 2
                y: carrossel.height/2
            }
            PathPercent {
                value: 0.50
            }
            PathAttribute {
                name: "iconScale"
                value: 1.0
            }
            PathAttribute {
                name: "iconOpacity"
                value: 1.0
            }
            PathAttribute {
                name: "iconZ"
                value: 100
            }

            PathLine {
                x: (carrossel.width / 2) + 320
                y: carrossel.height/2
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
                x: (carrossel.width / 2) + 550
                y: carrossel.height/2
            }
            PathPercent {
                value: 1.0
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

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton
            onWheel: function (wheel) {
                scrollAccumulator += wheel.angleDelta.y ? wheel.angleDelta.y : wheel.angleDelta.x;
                var sensibilidade = 120;

                if (scrollAccumulator <= -sensibilidade) {
                    carrossel.incrementCurrentIndex();
                    scrollAccumulator = 0;
                } else if (scrollAccumulator >= sensibilidade) {
                    carrossel.decrementCurrentIndex();
                    scrollAccumulator = 0;
                }
            }
        }
    }
}
