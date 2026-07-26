import QtQuick

Rectangle {
    id: root
    width: 34
    height: 30

    property int value: 0

    radius: 3
    border.width: 1
    border.color: "#17191A"
    clip: true

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "#17191A" }
        GradientStop { position: 1.0; color: "#1E2122" }
    }

    Text {
        anchors.fill: parent
        anchors.rightMargin: 3
        anchors.leftMargin: 2
        text: root.value
        color: "#FF9B12"
        font.pixelSize: value >= 1000 ? 11 : (value >= 100 ? 12 : 14)
        font.bold: true
        font.family: "Consolas"
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}
