import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
ApplicationWindow {
    id: window
    visible: true; width: app.compact ? 980 : 1320; height: 820; minimumWidth: 900; minimumHeight: 700
    title: "Kyna Music"; color: "#000000"
    font.family: "Helvetica Neue"
    palette.window: "#242424"; palette.windowText: "#f1f4f1"; palette.text: "#f1f4f1"; palette.buttonText: "#f1f4f1"; palette.base: "#181818"; palette.button: "#282828"; palette.highlight: "#1db954"
    property var app: music.state
    Shortcut { sequence: "Ctrl+Shift+L"; onActivated: music.send("compact") }
    Shortcut { sequence: "Ctrl+O"; onActivated: files.open() }
    Shortcut { sequence: "Ctrl+F"; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Space"; enabled: !search.activeFocus && !playlistName.activeFocus; onActivated: music.send("toggle") }
    FileDialog { id: files; title: "Add music to your library"; fileMode: FileDialog.OpenFiles; nameFilters: ["Audio files (*.mp3 *.wav *.flac *.m4a *.aac *.ogg *.opus *.aiff *.aif)"]; onAccepted: music.send("import",JSON.stringify(selectedFiles.map(function(url){return String(url)}))) }
    Dialog {
        id: playlistDialog; anchors.centerIn: parent; title: "A playlist of your own"; modal: true; width: 380
        standardButtons: Dialog.Save | Dialog.Cancel
        ColumnLayout { anchors.fill: parent; spacing: 12; Label { text: "Give your new playlist a name."; color: "#b3b3b3" } TextField { id: playlistName; Layout.fillWidth: true; placeholderText: "e.g. Sunday kind of mood"; maximumLength: 80; Accessible.name: "Playlist name"; onAccepted: { if(text.trim().length>0)playlistDialog.accept() } } }
        onOpened: { playlistName.text=""; playlistName.forceActiveFocus() }
        onAccepted: { if(playlistName.text.trim().length>0)music.send("playlist-create",playlistName.text.trim()) }
    }
    Rectangle {
        id: sidebar; width: window.width > 1200 ? 276 : 226; color: "#121212"; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: player.top
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 10
            RowLayout {
                Layout.topMargin: 8; Layout.bottomMargin: 14; spacing: 10
                Rectangle { width: 31; height: 31; radius: 10; color: "#1ed760"; Row { anchors.centerIn: parent; spacing: 3; Repeater { model: [10,18,14]; Rectangle { required property int modelData; width: 3; height: modelData; radius: 2; color: "#173422"; anchors.verticalCenter: parent.verticalCenter } } } }
                Text { text: "kyna"; color: "#f1f7f2"; font.pixelSize: 26; font.weight: Font.Bold; font.letterSpacing: -1 }
                Text { text: "music"; color: "#b0bcb3"; font.pixelSize: 15; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 4 }
            }
            Repeater {
                model: [{label:"Home",key:"home",icon:"home"},{label:"Your Library",key:"library",icon:"library"},{label:"Liked songs",key:"liked",icon:"heart"}]
                Button {
                    required property var modelData; Layout.fillWidth: true; Layout.preferredHeight: 42
                    Accessible.name: modelData.label
                    onClicked: music.send("navigate",modelData.key)
                    background: Rectangle { radius: 6; color: window.app.view===parent.modelData.key ? "#282828" : parent.hovered ? "#242424" : "transparent"; border.width: parent.activeFocus ? 1 : 0; border.color: "#ffffff" }
                    contentItem: RowLayout { spacing: 13; Image { source: "icons/"+parent.parent.modelData.icon+".svg"; Layout.preferredWidth: 19; Layout.preferredHeight: 19; Layout.leftMargin: 10 } Text { text: parent.parent.modelData.label; color: window.app.view===parent.parent.modelData.key ? "#ffffff" : "#b3b3b3"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true } }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#253028"; Layout.topMargin: 16; Layout.bottomMargin: 10 }
            RowLayout { Layout.fillWidth: true; Text { text: "Playlists"; color: "#b3b3b3"; font.pixelSize: 10; font.letterSpacing: 0; Layout.fillWidth: true } IconButton { iconName: "plus"; label: "Create playlist"; width: 28; height: 28; onClicked: playlistDialog.open() } }
            Repeater {
                model: window.app.playlists || []
                Button {
                    required property var modelData; Layout.fillWidth: true; Layout.preferredHeight: 48
                    Accessible.name: "Open playlist " + modelData.name
                    background: Rectangle { radius: 5; color: window.app.playlistId===parent.modelData.id && window.app.view==="playlist" ? "#282828" : parent.hovered ? "#242424" : "transparent"; border.width: parent.activeFocus ? 1 : 0; border.color: "#ffffff" }
                    contentItem: RowLayout { spacing: 10; Rectangle { width: 32; height: 32; radius: 4; color: "#2c3c31"; Image { anchors.centerIn: parent; width: 17; height: 17; source: "icons/library.svg" } } ColumnLayout { spacing: 3; Layout.fillWidth: true; Text { text: parent.parent.parent.modelData.name; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true } Text { text: parent.parent.parent.modelData.tracks.length+" songs"; color: "#b3b3b3"; font.pixelSize: 10 } } }
                    onClicked: music.send("playlist",modelData.id)
                }
            }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 112; color: "#242424"; radius: 10
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 9
                    Text { text: "Make yourself at home."; color: "#dce6de"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Text { text: "Bring your own music.\nKeep it close."; color: "#899b8e"; font.pixelSize: 11; lineHeight: 1.25 }
                    Button { text: "+  Add music"; font.pixelSize: 11; implicitHeight: 26; Accessible.name: "Import local audio files"; onClicked: files.open() }
                }
            }
            Text { text: "BUILT WITH KYNA"; color: "#b3b3b3"; font.pixelSize: 9; font.letterSpacing: 2; Layout.topMargin: 10; Layout.bottomMargin: 5 }
        }
    }
    Rectangle {
        id: main; anchors.left: sidebar.right; anchors.right: queuePanel.visible ? queuePanel.left : nowPlaying.visible ? nowPlaying.left : parent.right; anchors.top: parent.top; anchors.bottom: player.top; anchors.margins: 8; anchors.leftMargin: 0; radius: 8; color: "#121212"; clip: true
        Rectangle {
            id: toolbar; width: parent.width; height: 68; color: "#121212"; z: 2
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 28; anchors.rightMargin: 28; spacing: 14
                IconButton { iconName: "arrow"; label: "Back to home"; onClicked: music.send("navigate","home") }
                Rectangle {
                    Layout.preferredWidth: 330; Layout.fillWidth: true; Layout.maximumWidth: 380; height: 38; radius: 20; color: "#242424"; border.color: search.activeFocus ? "#85af91" : "#333333"; border.width: 1
                    Image { source: "icons/search.svg"; width: 17; height: 17; anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter }
                    TextField { id: search; anchors.fill: parent; anchors.leftMargin: 34; anchors.rightMargin: 10; background: Item {} font.pixelSize: 12; color: "#ebf3ee"; placeholderText: "What do you want to listen to?"; placeholderTextColor: "#89998e"; Accessible.name: "Search songs, artists and albums"; text: window.app.query || ""; onTextEdited: music.send("search",text) }
                }
                Item { Layout.fillWidth: true }
                Text { text: "YOUR MUSIC. YOUR SPACE."; visible: main.width>880; color: "#738a7b"; font.pixelSize: 9; font.letterSpacing: 1.6 }
                IconButton { iconName: "library"; label: window.app.compact ? "Use wide window" : "Use compact window"; selected: !!window.app.compact; onClicked: music.send("compact") }
                Rectangle { width: 31; height: 31; radius: 16; color: "#bccf9e"; Text { anchors.centerIn: parent; text: "K"; font.pixelSize: 13; font.weight: Font.Bold; color: "#203524" } Accessible.name: "Local music library" }
            }
        }
        Flickable {
            anchors.top: toolbar.bottom; anchors.bottom: parent.bottom; width: parent.width; contentHeight: content.height+30; clip: true
            ScrollBar.vertical: ScrollBar { }
            Column {
                id: content; x: 22; width: parent.width-44; spacing: 28
                Column {
                    width: parent.width; spacing: 18; visible: window.app.view==="home"
                    Text { text: "Good to have you here"; color: "white"; font.pixelSize: 26; font.weight: Font.Bold }
                    Grid {
                        width: parent.width; columns: width>580 ? 3 : 2; spacing: 10
                        Repeater { model: (window.app.recommendations || []).slice(0,6)
                            Button {
                                required property var modelData
                                width: (parent.width-(parent.columns-1)*10)/parent.columns; height: 60
                                Accessible.name: "Play " + modelData.title
                                background: Rectangle { radius: 4; color: parent.hovered ? "#444444" : "#303033"; border.width: parent.activeFocus ? 2 : 0; border.color: "white" }
                                contentItem: RowLayout { spacing: 10; Image { source: parent.parent.modelData.art; Layout.preferredWidth: 60; Layout.preferredHeight: 60 } Text { text: parent.parent.modelData.title; Layout.fillWidth: true; Layout.rightMargin: 8; color: "white"; font.pixelSize: 13; font.weight: Font.Bold; wrapMode: Text.WordWrap } }
                                leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
                                onClicked: music.send("play",modelData.id)
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 18; visible: window.app.view==="home"
                    RowLayout { width: parent.width; Text { text: "Made for you"; color: "#ecf3ed"; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.fillWidth: true } Button { text: "View all"; flat: true; font.pixelSize: 11; onClicked: music.send("navigate","library") } }
                    Row { width: parent.width; spacing: 20; Repeater { model: (window.app.recommendations || []).slice(0,main.width>700 ? 4 : 3); AlbumCard { required property var modelData; track: modelData; width: (content.width-(main.width>700 ? 3 : 2)*20)/(main.width>700 ? 4 : 3) } } }
                }
                Column {
                    width: parent.width; spacing: 16
                    RowLayout {
                        width: parent.width
                        ColumnLayout { spacing: 7; Layout.fillWidth: true; Text { text: window.app.heading || "Made for you"; color: "#edf4ee"; font.pixelSize: window.app.view==="home" ? 20 : 30; font.weight: Font.DemiBold } Text { visible: window.app.view!=="home"; text: (window.app.tracks || []).length+" songs · Saved on this device"; color: "#b3b3b3"; font.pixelSize: 12 } }
                        Button { visible: window.app.view!=="home"; text: "Play all"; onClicked: music.send("play-all") }
                        IconButton { visible: window.app.view==="playlist"; iconName: "close"; label: "Delete this playlist"; onClicked: deleteDialog.open() }
                    }
                    RowLayout { width: parent.width; height: 20; Text { text: "#"; color: "#6f8276"; font.pixelSize: 10; Layout.preferredWidth: 37; horizontalAlignment: Text.AlignHCenter } Text { text: "TITLE"; color: "#b3b3b3"; font.pixelSize: 9; font.letterSpacing: 1.5; Layout.fillWidth: true } Text { visible: content.width>630; text: "ALBUM"; color: "#b3b3b3"; font.pixelSize: 9; font.letterSpacing: 1.5; Layout.preferredWidth: 150 } Text { text: "TIME"; color: "#b3b3b3"; font.pixelSize: 9; font.letterSpacing: 1.5; Layout.preferredWidth: 135 } }
                    Column { width: parent.width; Repeater { model: window.app.tracks || []; TrackRow { required property var modelData; required property int index; width: content.width; track: modelData; number: index+1 } } }
                    Column { visible: (window.app.tracks || []).length===0; width: parent.width; spacing: 12; topPadding: 30; bottomPadding: 50; Text { text: window.app.query ? "No tracks found" : "Room for something good"; color: "#d7e3db"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter } Text { text: window.app.query ? "Try another song, artist or album." : "Add music, like a song, or add tracks from the song menu."; color: "#8c9e92"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter } }
                }
            }
        }
    }
    Dialog { id: deleteDialog; anchors.centerIn: parent; modal: true; title: "Delete this playlist?"; standardButtons: Dialog.Yes | Dialog.Cancel; Label { text: "Your audio files and liked songs will stay in your library." } onAccepted: music.send("playlist-delete") }
    Rectangle {
        id: queuePanel; visible: !!window.app.showQueue; width: 270; anchors.top: parent.top; anchors.right: parent.right; anchors.bottom: player.top; color: "#121212"
        ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 18
            RowLayout { Layout.fillWidth: true; Text { text: "Up next"; color: "#e7f0e9"; font.pixelSize: 18; font.weight: Font.DemiBold; Layout.fillWidth: true } IconButton { iconName: "close"; label: "Close queue"; onClicked: music.send("queue") } }
            Text { text: "Your listening queue"; color: "#839b8b"; font.pixelSize: 11 }
            ListView {
                Layout.fillHeight: true; Layout.fillWidth: true; clip: true; spacing: 6; model: window.app.queueTracks || []
                delegate: Rectangle {
                    required property var modelData; required property int index; width: ListView.view.width; height: 66; color: "#181818"; radius: 6
                    RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 9; Image { source: modelData.art; Layout.preferredWidth: 40; Layout.preferredHeight: 40 } ColumnLayout { Layout.fillWidth: true; Text { text: modelData.title; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true } Text { text: modelData.artist; color: "#b3b3b3"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true } } IconButton { iconName: "close"; label: "Remove " + modelData.title + " from queue"; width: 26; onClicked: music.send("queue-remove",String(index)) } }
                }
                Label { visible: parent.count===0; text: "Nothing queued yet.\nAdd a song from its ••• menu."; color: "#93a498"; width: parent.width; wrapMode: Text.WordWrap; lineHeight: 1.5 }
            }
        }
    }
    Rectangle {
        id: nowPlaying; visible: window.width>=1200 && !queuePanel.visible; width: 260
        anchors.top: parent.top; anchors.topMargin: 8; anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: player.top; anchors.bottomMargin: 8; radius: 8; color: "#121212"
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 18
            Text { text: "Now playing"; color: "white"; font.pixelSize: 15; font.weight: Font.Bold }
            Image { source: (window.app.current || {}).art || "art/01.svg"; Layout.fillWidth: true; Layout.preferredHeight: 228; fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(456,456) }
            Text { text: (window.app.current || {}).title || "Your next favorite"; color: "white"; font.pixelSize: 23; font.weight: Font.Bold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Text { text: (window.app.current || {}).artist || "Choose a song to start listening"; color: "#b3b3b3"; font.pixelSize: 13; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 164; radius: 8; color: "#242424"
                Column { anchors.fill: parent; anchors.margins: 16; spacing: 14
                    Text { text: "About this music"; color: "white"; font.pixelSize: 14; font.weight: Font.Bold }
                    Text { width: parent.width; text: "Six original instrumentals. A library that stays on your device. Add your own tracks and make it yours."; color: "#b3b3b3"; font.pixelSize: 13; wrapMode: Text.WordWrap; lineHeight: 1.25 }
                }
            }
            Button { text: "Open queue"; Layout.fillWidth: true; onClicked: music.send("queue") }
            Item { Layout.fillHeight: true }
            Text { text: "Kyna Music · Local listening"; color: "#b3b3b3"; font.pixelSize: 11 }
        }
    }
    PlayerBar { id: player; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom }
    Rectangle {
        visible: !!window.app.notice; anchors.horizontalCenter: main.horizontalCenter; anchors.bottom: player.top; anchors.bottomMargin: 18; width: Math.min(620,noticeText.implicitWidth+80); height: Math.max(48,noticeText.implicitHeight+24); radius: 9; color: "#334c3b"; border.color: "#5f8e6e"; z: 10
        Text { id: noticeText; anchors.left: parent.left; anchors.right: dismiss.left; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16; text: window.app.notice || ""; color: "#ecf8ef"; font.pixelSize: 12; wrapMode: Text.WordWrap; Accessible.role: Accessible.StaticText; Accessible.name: text }
        IconButton { id: dismiss; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 6; iconName: "close"; label: "Dismiss message"; onClicked: music.send("dismiss") }
    }
}
