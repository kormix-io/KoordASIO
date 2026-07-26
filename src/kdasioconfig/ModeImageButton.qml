import QtQuick
import QtQuick.Controls

Button {
    id: control
    checkable: true
    flat: true
    padding: 0

    property url offSource: ""
    property url onSource: ""

    background: Item {}
    contentItem: Image {
        source: control.checked ? control.onSource : control.offSource
        fillMode: Image.PreserveAspectFit
        anchors.fill: parent
        sourceSize.width: Math.max(1, control.width * 2)
        mipmap: true
        smooth: true
        opacity: control.enabled ? 1.0 : 0.45
    }
}
