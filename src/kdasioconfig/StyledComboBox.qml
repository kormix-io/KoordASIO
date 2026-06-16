import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: control
    Layout.fillWidth: true
    Layout.preferredHeight: 36
    font.pixelSize: 12
    rightPadding: 26

    delegate: ItemDelegate {
        width: control.width
        contentItem: Text {
            text: modelData !== undefined ? modelData : model.text
            color: "#f0f0f0"
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
        background: Rectangle {
            color: parent.highlighted ? "#333" : "transparent"
        }
    }

    indicator: Text {
        x: control.width - width - 8
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "\u25BE"
        color: "#d0d0d0"
        font.pixelSize: 16
        font.bold: true
    }

    contentItem: Text {
        text: control.displayText
        color: control.enabled ? "#f0f0f0" : "#777"
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        leftPadding: 10
        rightPadding: control.indicator.width + control.spacing
    }

    background: Rectangle {
        color: "#000000"
        border.color: "#444"
        radius: 5
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            border.color: "#444"
            color: "#000000"
            radius: 5
        }
    }
}
