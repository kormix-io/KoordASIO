import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 378
    height: 580
    minimumWidth: 378
    maximumWidth: 420
    minimumHeight: 580
    maximumHeight: 580
    visible: true
    title: "KoordASIO Control"
    color: clrBg
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint

    readonly property color clrBg: "#313539"
    readonly property color clrText: "#f0f0f0"
    readonly property color clrMuted: "#9a9a9a"
    readonly property color clrSectionBorder: "#6a6e74"
    readonly property int bufferSteps: Math.max(0, config.bufferSizeChoices.length - 1)

    onClosing: function(close) {
        if (config.systrayEnabled) {
            close.accepted = false
            root.hide()
        } else {
            close.accepted = true
        }
    }

    component SectionPanel: Rectangle {
        property alias title: sectionTitle.text
        default property alias contents: sectionContents.data
        Layout.fillWidth: true
        color: "transparent"
        border.color: clrSectionBorder
        border.width: 1
        radius: 8
        implicitHeight: sectionColumn.implicitHeight + 20

        ColumnLayout {
            id: sectionColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Label {
                id: sectionTitle
                font.bold: true
                font.pixelSize: 11
                color: "#aaa"
            }

            ColumnLayout {
                id: sectionContents
                Layout.fillWidth: true
                spacing: 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: clrBg

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                Item {
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 40

                    Image {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "qrc:/images/logo.png"
                        fillMode: Image.PreserveAspectFit
                        width: 180
                        height: 40
                    }
                }

                Item { Layout.fillWidth: true }

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    Button {
                        id: settingsButton
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        flat: true
                        topPadding: 0
                        bottomPadding: 0
                        leftPadding: 0
                        rightPadding: 0
                        onClicked: settingsPopup.open()
                        background: Item {}
                        contentItem: Item {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 11
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 24
                            height: 18
                            Rectangle { width: 24; height: 3; radius: 1.5; color: clrText; anchors.horizontalCenter: parent.horizontalCenter; y: 0 }
                            Rectangle { width: 24; height: 3; radius: 1.5; color: clrText; anchors.horizontalCenter: parent.horizontalCenter; y: 7.5 }
                            Rectangle { width: 24; height: 3; radius: 1.5; color: clrText; anchors.horizontalCenter: parent.horizontalCenter; y: 15 }
                        }
                    }
                }
            }
        }

        Popup {
            id: settingsPopup
            parent: Overlay.overlay
            width: 260
            modal: true
            focus: true
            padding: 8

            x: {
                const pos = settingsButton.mapToItem(parent, 0, 0)
                return Math.max(8, pos.x + settingsButton.width - width)
            }
            y: {
                const pos = settingsButton.mapToItem(parent, 0, 0)
                return pos.y + settingsButton.height + 4
            }

            background: Rectangle {
                color: clrBg
                border.color: clrSectionBorder
                border.width: 1
                radius: 6
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Label {
                    text: "Settings"
                    color: clrMuted
                    font.bold: true
                    font.pixelSize: 11
                    Layout.leftMargin: 4
                }

                StyledCheckBox {
                    text: "Input audio"
                    checked: config.inputEnabled
                    Layout.fillWidth: true
                    onToggled: config.inputEnabled = checked
                }

                StyledCheckBox {
                    text: "Input mono \u2192 stereo"
                    checked: config.inputStereoEmulation
                    enabled: config.inputEnabled
                    Layout.fillWidth: true
                    onToggled: config.inputStereoEmulation = checked
                }

                StyledCheckBox {
                    text: "Output mono \u2192 stereo"
                    checked: config.outputStereoEmulation
                    Layout.fillWidth: true
                    onToggled: config.outputStereoEmulation = checked
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: clrSectionBorder
                }

                StyledCheckBox {
                    text: "System tray icon"
                    checked: config.systrayEnabled
                    Layout.fillWidth: true
                    onToggled: config.systrayEnabled = checked
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 20

            SectionPanel {
                title: "INPUT DEVICE"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledComboBox {
                        id: inputDeviceCombo
                        Layout.fillWidth: true
                        model: config.inputDevices
                        enabled: config.inputEnabled
                        onActivated: config.inputDevice = config.inputDevices[currentIndex]
                        Component.onCompleted: syncInputDevice()
                        Connections {
                            target: config
                            function onInputDeviceChanged() { inputDeviceCombo.syncInputDevice() }
                            function onInputDevicesChanged() { inputDeviceCombo.syncInputDevice() }
                        }
                        function syncInputDevice() {
                            const i = config.inputDevices.indexOf(config.inputDevice)
                            currentIndex = i >= 0 ? i : 0
                        }
                    }

                    IconButton {
                        iconSource: "qrc:/images/config-btn.png"
                        enabled: config.inputEnabled
                        ToolTip.visible: hovered
                        ToolTip.text: "Windows input settings"
                        onClicked: config.openInputSettings()
                    }
                }
            }

            SectionPanel {
                title: "OUTPUT DEVICE"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledComboBox {
                        id: outputDeviceCombo
                        Layout.fillWidth: true
                        model: config.outputDevices
                        onActivated: config.outputDevice = config.outputDevices[currentIndex]
                        Component.onCompleted: syncOutputDevice()
                        Connections {
                            target: config
                            function onOutputDeviceChanged() { outputDeviceCombo.syncOutputDevice() }
                            function onOutputDevicesChanged() { outputDeviceCombo.syncOutputDevice() }
                        }
                        function syncOutputDevice() {
                            const i = config.outputDevices.indexOf(config.outputDevice)
                            currentIndex = i >= 0 ? i : 0
                        }
                    }

                    IconButton {
                        iconSource: "qrc:/images/config-btn.png"
                        ToolTip.visible: hovered
                        ToolTip.text: "Windows output settings"
                        onClicked: config.openOutputSettings()
                    }
                }
            }

            SectionPanel {
                title: "AUDIO RENDERING MODE"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 37
                    spacing: 0

                    ModeImageButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 37
                        offSource: "qrc:/images/shared-off.png"
                        onSource: "qrc:/images/shared-on.png"
                        checked: !config.exclusiveMode
                        onClicked: config.exclusiveMode = false
                    }

                    ModeImageButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 37
                        offSource: "qrc:/images/exclusive-off.png"
                        onSource: "qrc:/images/exclusive-on.png"
                        checked: config.exclusiveMode
                        onClicked: config.exclusiveMode = true
                    }
                }
            }

            SectionPanel {
                title: "BUFFER SIZE"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    BufferSizeDisplay {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 50
                        Layout.maximumWidth: 56
                        value: config.bufferSize
                    }

                    BufferSizeSlider {
                        id: bufferSlider
                        Layout.fillWidth: true
                        from: 0
                        to: root.bufferSteps
                        stepSize: 1
                        snapMode: Slider.SnapOnRelease
                        value: config.bufferSizeIndex
                        onMoved: config.bufferSizeIndex = Math.round(value)
                        onPressedChanged: if (!pressed) config.bufferSizeIndex = Math.round(value)

                        Connections {
                            target: config
                            function onBufferSizeChanged() {
                                bufferSlider.value = config.bufferSizeIndex
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: clrBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Image {
                    source: "qrc:/images/frame.png"
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredHeight: 9
                    Layout.preferredWidth: 40
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    iconSize: 18
                    iconSource: "qrc:/images/github.png"
                    ToolTip.visible: hovered
                    ToolTip.text: "GitHub repository"
                    onClicked: config.openGitHub()
                }
            }
        }
    }
}
