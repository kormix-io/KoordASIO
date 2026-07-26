import QtQuick
import QtQuick.Controls

// Which image shows is driven solely by `active`, a value read back from the
// config. A checkable Button owns its own checked state, so clicking the
// selected mode untoggled it and left neither mode showing as active.
Button {
    id: control
    flat: true
    padding: 0

    property bool active: false
    property url offSource: ""
    property url onSource: ""

    background: Item {}
    contentItem: Image {
        source: control.active ? control.onSource : control.offSource
        fillMode: Image.PreserveAspectFit
        anchors.fill: parent
        sourceSize.width: Math.max(1, control.width * 2)
        mipmap: true
        smooth: true
        opacity: control.enabled ? 1.0 : 0.45
    }
}
