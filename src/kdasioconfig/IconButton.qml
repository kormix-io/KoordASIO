import QtQuick
import QtQuick.Controls

Button {
    id: control
    implicitWidth: 32
    implicitHeight: 32
    padding: 4

    property url iconSource: ""
    property int iconSize: 22

    background: Rectangle {
        color: control.down ? "#171819" : (control.hovered ? "#252729" : "transparent")
        border.color: control.enabled ? "#444" : "#333"
        border.width: 1
        radius: 4
    }

    contentItem: Image {
        source: control.iconSource
        fillMode: Image.PreserveAspectFit
        anchors.centerIn: parent
        width: control.iconSize
        height: control.iconSize
        // Sources are 96-112px square drawn at ~18-22px; decode at 2x and
        // mipmap so the downscale doesn't alias.
        sourceSize.width: control.iconSize * 2
        mipmap: true
        smooth: true
        opacity: control.enabled ? 1.0 : 0.4
    }
}
