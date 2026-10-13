import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id: bar
    color: "#000000"; implicitHeight: 88
    property var track: music.state.current || ({})
    function time(ms) { var s=Math.floor(ms/1000); return Math.floor(s/60)+":"+String(s%60).padStart(2,"0") }
    Rectangle { height: 1; color: "#2b302c"; width: parent.width }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 24
        RowLayout {
            Layout.preferredWidth: bar.width<1100 ? 210 : 250; spacing: 12
            Rectangle { width: 56; height: 56; color: "#26332b"; Image { anchors.fill: parent; source: bar.track.art || "qrc:/music/ui/art/01.svg"; sourceSize: Qt.size(112,112) } }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                Text { text: bar.track.title || "Find your next favorite"; color: "#f2f5f2"; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: bar.track.artist || "Choose a track to begin"; color: "#b3b3b3"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            IconButton { enabled: !!bar.track.id; iconName: bar.track.liked ? "heart-filled" : "heart"; label: "Like current track"; onClicked: music.send("like",bar.track.id) }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.maximumWidth: 620; spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 12
                IconButton { iconName: "shuffle"; label: "Shuffle"; selected: !!music.state.shuffle; onClicked: music.send("shuffle") }
                IconButton { iconName: "previous"; label: "Previous track"; onClicked: music.send("previous") }
                IconButton { width: 40; height: 40; prominent: true; iconName: music.playing ? "pause" : "play"; label: music.playing ? "Pause" : "Play"; onClicked: music.send("toggle") }
                IconButton { iconName: "next"; label: "Next track"; onClicked: music.send("next") }
                IconButton { iconName: "repeat"; label: "Repeat current track"; selected: !!music.state.repeat; onClicked: music.send("repeat") }
            }
            RowLayout {
                spacing: 10; Layout.fillWidth: true
                Text { text: bar.time(music.position); color: "#b3b3b3"; font.pixelSize: 10; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                Slider {
                    id: progress; Layout.fillWidth: true; from: 0; to: Math.max(1,music.duration); value: music.position; enabled: music.duration>0
                    Accessible.name: "Playback position"
                    onMoved: music.send("seek",String(Math.round(value)))
                    background: Rectangle { x: progress.leftPadding; y: progress.topPadding+progress.availableHeight/2-height/2; width: progress.availableWidth; height: 3; radius: 2; color: "#3b443d"; Rectangle { width: progress.visualPosition*parent.width; height: parent.height; color: progress.hovered ? "#1ed760" : "#c7d1c9"; radius: 2 } }
                    handle: Rectangle { x: progress.leftPadding+progress.visualPosition*(progress.availableWidth-width); y: progress.topPadding+progress.availableHeight/2-height/2; width: 10; height: 10; radius: 5; color: "#e8f0e9"; visible: progress.hovered || progress.pressed || progress.activeFocus }
                }
                Text { text: bar.time(music.duration); color: "#b3b3b3"; font.pixelSize: 10; Layout.preferredWidth: 32 }
            }
        }
        RowLayout {
            spacing: 5; Layout.preferredWidth: bar.width<1100 ? 135 : 180
            IconButton { iconName: "queue"; label: "Show queue"; selected: !!music.state.showQueue; onClicked: music.send("queue") }
            IconButton { iconName: "volume"; label: music.volume>0 ? "Mute" : "Unmute"; onClicked: music.send("volume",music.volume>0 ? "0" : "0.65") }
            Slider {
                id: volume; Layout.fillWidth: true; from: 0; to: 1; value: music.volume; Accessible.name: "Volume"
                onMoved: music.send("volume",String(value))
                background: Rectangle { x: volume.leftPadding; y: volume.topPadding+volume.availableHeight/2-height/2; width: volume.availableWidth; height: 3; color: "#3b443d"; radius: 2; Rectangle { width: volume.visualPosition*parent.width; height: 3; color: "#aebbb1"; radius: 2 } }
                handle: Rectangle { x: volume.leftPadding+volume.visualPosition*(volume.availableWidth-width); y: volume.topPadding+volume.availableHeight/2-5; width: 10; height: 10; radius: 5; color: "#e8f0e9"; visible: volume.hovered || volume.pressed || volume.activeFocus }
            }
        }
    }
}
