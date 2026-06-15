import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 420
    height: 640
    minimumWidth: 380
    minimumHeight: 560
    visible: true
    title: "KoordASIO Control"
    color: "#1e1e1e"

    onClosing: function(close) {
        close.accepted = false
        root.hide()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: "KoordASIO Control"
            font.pixelSize: 20
            font.bold: true
            color: "#f0f0f0"
        }

        Label {
            text: "open-source universal ASIO driver"
            color: "#9a9a9a"
            font.pixelSize: 12
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Input"
            label: Label { color: "#d0d0d0" }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                CheckBox {
                    text: "Enable input"
                    checked: config.inputEnabled
                    onToggled: config.inputEnabled = checked
                }

                ComboBox {
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

                CheckBox {
                    text: "Present mono device as stereo"
                    checked: config.inputStereoEmulation
                    enabled: config.inputEnabled
                    onToggled: config.inputStereoEmulation = checked
                }

                Button {
                    text: "Windows input settings"
                    enabled: config.inputEnabled
                    onClicked: config.openInputSettings()
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Output"
            label: Label { color: "#d0d0d0" }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                ComboBox {
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

                CheckBox {
                    text: "Present mono device as stereo"
                    checked: config.outputStereoEmulation
                    onToggled: config.outputStereoEmulation = checked
                }

                Button {
                    text: "Windows output settings"
                    onClicked: config.openOutputSettings()
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Rendering mode"
            label: Label { color: "#d0d0d0" }

            RowLayout {
                anchors.fill: parent
                ButtonGroup { id: renderModeGroup }

                RadioButton {
                    text: "Shared"
                    checked: !config.exclusiveMode
                    ButtonGroup.group: renderModeGroup
                    onClicked: config.exclusiveMode = false
                }
                RadioButton {
                    text: "Exclusive"
                    checked: config.exclusiveMode
                    ButtonGroup.group: renderModeGroup
                    onClicked: config.exclusiveMode = true
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Buffer size (samples)"
            label: Label { color: "#d0d0d0" }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                ComboBox {
                    id: bufferCombo
                    Layout.fillWidth: true
                    model: config.bufferSizeChoices
                    onActivated: config.bufferSizeIndex = currentIndex
                    Component.onCompleted: currentIndex = config.bufferSizeIndex
                    Connections {
                        target: config
                        function onBufferSizeChanged() { bufferCombo.currentIndex = config.bufferSizeIndex }
                    }
                }

                Label {
                    text: "Current: " + config.bufferSize + " samples"
                    color: "#bdbdbd"
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "v" + config.version
                color: "#8a8a8a"
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Releases"
                flat: true
                onClicked: config.openReleases()
            }

            Button {
                text: "GitHub"
                flat: true
                onClicked: config.openGitHub()
            }
        }
    }
}
