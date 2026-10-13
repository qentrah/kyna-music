import QtQuick
import QtQuick.Controls
Item {
    id: card
    property var track: ({})
    implicitHeight: width + 61
    Rectangle { anchors.fill: parent; anchors.margins: -9; radius: 8; color: "#282828"; visible: hover.hovered }
    HoverHandler { id: hover }
    Image { id: cover; width: parent.width; height: width; source: card.track.art || ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(450,450) }
    Button {
        anchors.fill: cover; background: Item {}
        Accessible.name: "Play " + (card.track.title || "track")
        onClicked: music.send("play",card.track.id)
        Rectangle { anchors.fill: parent; visible: parent.activeFocus; color: "transparent"; border.color: "#ffffff"; border.width: 2 }
    }
    IconButton { anchors.right: cover.right; anchors.bottom: cover.bottom; anchors.margins: 10; width: 44; height: 44; prominent: true; iconName: "play"; label: "Play " + (card.track.title || "track"); visible: hover.hovered || activeFocus; onClicked: music.send("play",card.track.id) }
    Text { anchors.top: cover.bottom; anchors.topMargin: 12; width: parent.width; text: card.track.title || ""; color: "#f2f5f2"; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
    Text { anchors.top: cover.bottom; anchors.topMargin: 34; width: parent.width; text: card.track.artist || ""; color: "#b3b3b3"; font.pixelSize: 12; elide: Text.ElideRight }
}
