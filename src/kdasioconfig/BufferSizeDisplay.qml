import QtQuick

Rectangle {
    id: root
    width: 56
    height: 50

    property int value: 0

    radius: 4
    border.width: 2
    border.color: "#17191A"
    clip: true

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "#17191A" }
        GradientStop { position: 1.0; color: "#1E2122" }
    }

    Text {
        anchors.fill: parent
        anchors.rightMargin: 5
        anchors.leftMargin: 4
        text: root.value
        color: "#FF9B12"
        font.pixelSize: value >= 1000 ? 16 : (value >= 100 ? 18 : 21)
        font.bold: true
        font.family: "Consolas"
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}
