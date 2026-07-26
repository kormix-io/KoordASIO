import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 302
    minimumWidth: 302
    maximumWidth: 336
    // Derived, not hardcoded: a fixed height smaller than the layout needs
    // silently clips the footer, and one larger leaves a dead gap above it.
    height: mainColumn.implicitHeight
    minimumHeight: mainColumn.implicitHeight
    maximumHeight: mainColumn.implicitHeight
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
        id: mainColumn
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62
            color: clrBg

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.leftMargin: 8
                anchors.rightMargin: 6
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
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            Layout.leftMargin: 8
            Layout.rightMargin: 8
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
                        ToolTip.visible: hovered && !popup.visible
                        ToolTip.delay: 400
                        ToolTip.text: config.inputEnabled
                            ? "Recording device KoordASIO captures from"
                            : "Input is switched off in Settings"
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
                        ToolTip.visible: hovered && !popup.visible
                        ToolTip.delay: 400
                        ToolTip.text: "Playback device KoordASIO sends audio to"
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
                        active: !config.exclusiveMode
                        ToolTip.visible: hovered
                        ToolTip.delay: 400
                        ToolTip.text: "Shared: other apps can play through this device at the same time"
                        onClicked: config.exclusiveMode = false
                    }

                    ModeImageButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 37
                        offSource: "qrc:/images/exclusive-off.png"
                        onSource: "qrc:/images/exclusive-on.png"
                        active: config.exclusiveMode
                        ToolTip.visible: hovered
                        ToolTip.delay: 400
                        ToolTip.text: "Exclusive: KoordASIO takes sole use of the device for lowest latency"
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
                        ToolTip.visible: hovered || pressed
                        ToolTip.delay: pressed ? 0 : 400
                        ToolTip.text: config.bufferSize + " samples — lower is less latency, higher is more robust"
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

        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: clrBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
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

                Item { Layout.fillWidth: true }

                Label {
                    text: "v" + config.version
                    color: clrMuted
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }

                IconButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    iconSize: 18
                    iconSource: "qrc:/images/github.png"
                    Layout.alignment: Qt.AlignVCenter
                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: "GitHub repository"
                    onClicked: config.openGitHub()
                }
            }

            // Centred on the window rather than placed in the row above, so it
            // sits mid-footer regardless of how wide the version string is.
            Button {
                id: siteButton
                anchors.centerIn: parent
                flat: true
                topPadding: 2
                bottomPadding: 2
                leftPadding: 7
                rightPadding: 7
                ToolTip.visible: hovered
                ToolTip.delay: 400
                // The URL is too long to sit in the footer at this window width,
                // so it lives here and the button just reads "Website".
                ToolTip.text: "kormix-io.github.io/KoordASIO"
                onClicked: config.openWebsite()

                background: Rectangle {
                    color: siteButton.down ? "#171819" : (siteButton.hovered ? "#252729" : "transparent")
                    border.color: siteButton.hovered ? "#4a4f55" : "transparent"
                    border.width: 1
                    radius: 3
                }

                contentItem: Text {
                    text: "Website"
                    color: siteButton.hovered ? "#FF9B12" : clrMuted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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

        // Size goes in the log because a zero content height is exactly how this
        // popup previously failed, and it looks identical to "nothing happened".
        onOpened: console.info("settings popup opened: " + width + "x" + height)

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

            // Each box re-reads its value on change: clicking a CheckBox assigns
            // its own `checked`, which drops the declared binding, so without
            // this an external edit to the config would leave them showing the
            // state from before the reload.
            StyledCheckBox {
                id: inputEnabledBox
                text: "Input audio"
                checked: config.inputEnabled
                Layout.fillWidth: true
                onToggled: config.inputEnabled = checked
                Connections {
                    target: config
                    function onInputEnabledChanged() { inputEnabledBox.checked = config.inputEnabled }
                }
            }

            StyledCheckBox {
                id: inputStereoBox
                text: "Input mono → stereo"
                checked: config.inputStereoEmulation
                enabled: config.inputEnabled
                Layout.fillWidth: true
                onToggled: config.inputStereoEmulation = checked
                Connections {
                    target: config
                    function onInputStereoEmulationChanged() { inputStereoBox.checked = config.inputStereoEmulation }
                }
            }

            StyledCheckBox {
                id: outputStereoBox
                text: "Output mono → stereo"
                checked: config.outputStereoEmulation
                Layout.fillWidth: true
                onToggled: config.outputStereoEmulation = checked
                Connections {
                    target: config
                    function onOutputStereoEmulationChanged() { outputStereoBox.checked = config.outputStereoEmulation }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                color: clrSectionBorder
            }

            StyledCheckBox {
                id: systrayBox
                text: "System tray icon"
                checked: config.systrayEnabled
                Layout.fillWidth: true
                onToggled: config.systrayEnabled = checked
                Connections {
                    target: config
                    function onSystrayEnabledChanged() { systrayBox.checked = config.systrayEnabled }
                }
            }
        }
    }
}
