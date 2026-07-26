import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 378
    height: 530
    minimumWidth: 378
    maximumWidth: 420
    minimumHeight: 530
    maximumHeight: 530
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
            Layout.preferredHeight: 86
            color: clrBg

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    spacing: 3

                    Image {
                        source: "qrc:/images/logo.png"
                        fillMode: Image.PreserveAspectFit
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 19
                        // Source is 692x72; decode at 2x the drawn size and mipmap
                        // so the downscale stays crisp instead of aliasing.
                        sourceSize.width: 360
                        mipmap: true
                        smooth: true
                    }

                    Label {
                        text: "universal ASIO driver"
                        color: clrMuted
                        font.pixelSize: 12
                        font.letterSpacing: 0.4
                        Layout.leftMargin: 2
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: settingsButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    flat: true
                    padding: 0
                    onClicked: settingsPopup.opened ? settingsPopup.close() : settingsPopup.open()
                    ToolTip.visible: hovered
                    ToolTip.text: "Settings"

                    background: Rectangle {
                        color: settingsButton.down ? "#171819"
                             : (settingsButton.hovered ? "#252729" : "transparent")
                        radius: 4
                    }

                    contentItem: Item {
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Repeater {
                                model: 3
                                Rectangle { width: 24; height: 3; radius: 1.5; color: clrText }
                            }
                        }
                    }
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
                    spacing: 12

                    BufferSizeDisplay {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 30
                        Layout.maximumWidth: 34
                        value: config.bufferSize
                    }

                    BufferSizeSlider {
                        id: bufferSlider
                        Layout.fillWidth: true
                        from: 0
                        to: root.bufferSteps
                        stepSize: 1
                        snapMode: Slider.SnapAlways
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
                spacing: 8

                Image {
                    source: "qrc:/images/frame.png"
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredHeight: 11
                    Layout.preferredWidth: 40
                    sourceSize.width: 80
                    mipmap: true
                    smooth: true
                }

                Label {
                    text: "v" + config.version
                    color: clrMuted
                    font.pixelSize: 11
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

    Popup {
        id: settingsPopup
        parent: Overlay.overlay
        width: 260
        modal: true
        focus: true
        padding: 10
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // Anchor to the hamburger each time it opens. Bindings evaluated at
        // construction resolve before the header has been laid out.
        onAboutToShow: {
            const pos = settingsButton.mapToItem(settingsPopup.parent, 0, 0)
            x = Math.max(8, pos.x + settingsButton.width - width)
            y = pos.y + settingsButton.height + 6
        }

        background: Rectangle {
            color: clrBg
            border.color: clrSectionBorder
            border.width: 1
            radius: 6
        }

        // Must be the contentItem, not an anchors.fill child: Popup derives its
        // height from contentItem's implicit size, and anchoring leaves that at 0.
        contentItem: ColumnLayout {
            spacing: 6

            Label {
                text: "SETTINGS"
                color: clrMuted
                font.bold: true
                font.pixelSize: 11
                Layout.leftMargin: 2
                Layout.bottomMargin: 2
            }

            StyledCheckBox {
                text: "Input audio"
                checked: config.inputEnabled
                Layout.fillWidth: true
                onToggled: config.inputEnabled = checked
            }

            StyledCheckBox {
                text: "Input mono → stereo"
                checked: config.inputStereoEmulation
                enabled: config.inputEnabled
                Layout.fillWidth: true
                onToggled: config.inputStereoEmulation = checked
            }

            StyledCheckBox {
                text: "Output mono → stereo"
                checked: config.outputStereoEmulation
                Layout.fillWidth: true
                onToggled: config.outputStereoEmulation = checked
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                Layout.bottomMargin: 2
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
}
