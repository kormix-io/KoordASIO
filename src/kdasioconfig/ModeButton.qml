import QtQuick
import QtQuick.Controls

Button {
    id: control
    checkable: true
    padding: 10

    property color activeColor: "#4080ff"
    property color activeBorder: "#6090ff"
    property color inactiveColor: "#454545"

    background: Rectangle {
        color: control.checked ? control.activeColor
                               : (control.down ? "#3a3a3a" : control.inactiveColor)
        border.color: control.checked ? control.activeBorder : "#666"
        border.width: 1
        radius: 5
    }

    contentItem: Text {
        text: control.text
        color: control.enabled ? "#f0f0f0" : "#777"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: control.checked
    }
}
