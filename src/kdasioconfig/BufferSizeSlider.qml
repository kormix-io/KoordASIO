import QtQuick
import QtQuick.Controls

Slider {
    id: control
    readonly property real handleWidth: 30
    readonly property real handleHeight: 55
    readonly property real grooveHeight: 18
    readonly property color grooveGray: "#2a2c2e"
    readonly property real handleX: control.visualPosition * Math.max(0, control.availableWidth - handleWidth)
    readonly property real orangeWidth: Math.max(0, handleX)
    readonly property real grayRightX: handleX + handleWidth
    readonly property real grayRightWidth: Math.max(0, control.availableWidth - grayRightX)

    implicitHeight: handleHeight

    background: Item {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - grooveHeight) / 2
        width: control.availableWidth
        height: grooveHeight
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: grooveGray
        }

        Rectangle {
            x: 0
            width: orangeWidth
            height: grooveHeight
            radius: 5
            visible: width > 0

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#BF740D" }
                GradientStop { position: 1.0; color: "#FF9B12" }
            }
        }

        Rectangle {
            x: grayRightX
            width: grayRightWidth
            height: grooveHeight
            radius: 5
            color: grooveGray
            visible: width > 0
        }
    }

    handle: Item {
        x: control.leftPadding + control.handleX
        y: control.topPadding + (control.availableHeight - height) / 2
        width: handleWidth
        height: handleHeight
        z: 1

        Image {
            source: "qrc:/images/fader-btn.png"
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
            width: handleWidth
            height: handleHeight
        }
    }
}
