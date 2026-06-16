import QtQuick
import QtQuick.Controls

// Dark-themed CheckBox (from kormix-app SettingsView.qml).
CheckBox {
    id: control

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        radius: 3
        color: control.down ? "#2a2a2a" : "#353535"
        border.color: control.enabled ? "#666" : "#444"
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: "\u2713"
            color: "#f7a219"
            font.pixelSize: 13
            font.bold: true
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        color: control.enabled ? "#f0f0f0" : "#777"
        leftPadding: control.indicator.width + 6
        verticalAlignment: Text.AlignVCenter
    }
}
