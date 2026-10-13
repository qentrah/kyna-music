import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id: row
    property var track: ({})
    property int number: 1
    property bool current: music.state.current && music.state.current.id === track.id
    color: current ? "#282828" : hover.hovered ? "#282828" : "transparent"
    radius: 5; implicitHeight: 62
    HoverHandler { id: hover }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 14
        Text { text: row.current && music.playing ? "▥" : row.number; color: row.current ? "#1ed760" : "#b3b3b3"; font.pixelSize: 13; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignHCenter }
        Image { source: row.track.art || ""; Layout.preferredWidth: 40; Layout.preferredHeight: 40; sourceSize: Qt.size(80,80) }
        ColumnLayout {
            spacing: 4; Layout.fillWidth: true
            Text { text: row.track.title || ""; color: row.current ? "#1ed760" : "#edf2ee"; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: row.track.artist || ""; color: "#b3b3b3"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Text { visible: row.width > 630; text: row.track.album || ""; color: "#b3b3b3"; font.pixelSize: 12; Layout.preferredWidth: 150; elide: Text.ElideRight }
        Text { text: row.track.duration || ""; color: "#b3b3b3"; font.pixelSize: 12; Layout.preferredWidth: 55; horizontalAlignment: Text.AlignRight }
        Item { Layout.preferredWidth: 76; Layout.preferredHeight: 36 }
    }
    Button {
        anchors.fill: parent; anchors.rightMargin: 95; background: Item {}
        Accessible.name: "Play " + (row.track.title || "track") + " by " + (row.track.artist || "")
        onClicked: music.send("play",row.track.id)
        Rectangle { anchors.fill: parent; visible: parent.activeFocus; color: "transparent"; border.width: 2; border.color: "#ffffff"; radius: 4 }
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 2
        IconButton { iconName: row.track.liked ? "heart-filled" : "heart"; label: row.track.liked ? "Unlike " + row.track.title : "Like " + row.track.title; onClicked: music.send("like",row.track.id) }
        IconButton { id: more; iconName: "more"; label: "Options for " + (row.track.title || "track"); onClicked: menu.popup() }
    }
    Menu {
        id: menu
        MenuItem { text: "Add to queue"; onTriggered: music.send("enqueue",row.track.id) }
        Menu { title: "Add to playlist"; Repeater { model: music.state.playlists || []; MenuItem { required property var modelData; text: modelData.name; onTriggered: music.send("playlist-add",JSON.stringify([modelData.id,row.track.id])) } } }
        MenuItem { visible: music.state.view === "playlist"; height: visible ? implicitHeight : 0; text: "Remove from this playlist"; onTriggered: music.send("playlist-remove",row.track.id) }
    }
}
