import QtQuick
import QtQuick.Controls
Button {
    id: control
    property string iconName: "play"
    property string label: ""
    property bool selected: false
    property bool prominent: false
    implicitWidth: 36; implicitHeight: 36
    Accessible.name: label
    ToolTip.visible: hovered && label.length > 0
    ToolTip.text: label; ToolTip.delay: 600
    background: Rectangle {
        radius: width / 2
        color: control.prominent ? (control.down ? "#45bc78" : "#1ed760") : control.hovered ? "#343936" : "transparent"
        border.width: control.activeFocus ? 2 : 0; border.color: "#ffffff"
    }
    contentItem: Image {
        source: "icons/" + control.iconName + ".svg"
        sourceSize: Qt.size(21,21); fillMode: Image.Pad
        opacity: control.enabled ? 1 : 0.3
    }
    Rectangle { visible: control.selected; width: 4; height: 4; radius: 2; color: "#1ed760"; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom }
}
