/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef KDASIOCONFIG_H
#define KDASIOCONFIG_H

#include <QAudioDevice>
#include <QCheckBox>
#include <QMediaDevices>
#include <QStringConverter>
#include <QMainWindow>
#include <QObject>
#include <QDir>
#include <QProcess>
#include "toml.h"

#include "ui_kdasioconfigbase.h"

class KdASIOConfigBase : public QMainWindow, public Ui::KdASIOConfigBase
{
public:
    KdASIOConfigBase(QWidget *parent = 0);
    virtual ~KdASIOConfigBase();
};

class KdASIOConfig : public KdASIOConfigBase
{
    Q_OBJECT

public:
    explicit KdASIOConfig(QWidget *parent = nullptr);
    void setDefaults();
    void setInstallDefaults(bool exclusive, int bufferSizeSamples = 32);

private:
    QAudioDevice m_inputDeviceInfo;
    QAudioDevice m_outputDeviceInfo;
    QAudioDevice::Mode input_mode = QAudioDevice::Input;
    QAudioDevice::Mode output_mode = QAudioDevice::Output;
    QMediaDevices *m_devices = nullptr;
    QAudioFormat m_settings;
    int bufferSize;
    bool exclusive_mode = false;
    bool input_enabled = true;
    bool input_stereo_emulation = false;
    bool output_stereo_emulation = false;
    QCheckBox *inputEnabledCheckBox;
    QCheckBox *inputStereoCheckBox;
    QCheckBox *outputStereoCheckBox;
    QString outputDeviceName;
    QString inputDeviceName;
    // QString fullpath = QDir::homePath() + "/.KoordASIO-builtin.toml";
    QString fullpath = QDir::homePath() + "/.KoordASIO.toml";
    QString inputAudioSettPath = "mmsys.cpl,,1";
    QString outputAudioSettPath = "mmsys.cpl";
    QList<int> bufferSizes = { 32, 64, 128, 256, 512, 1024, 2048 };
    QProcess *mmcplProc;

private slots:
    void bufferSizeChanged(int idx);
    void bufferSizeDisplayChange(int idx);
//    void exclusiveModeChanged();
    void setOperationMode();
    void sharedModeSet();
    void exclusiveModeSet();
    void writeTomlFile();
    void inputEnabledChanged(int state);
    void inputStereoEmulationChanged(int state);
    void outputStereoEmulationChanged(int state);
    void updateInputControlsEnabled();
    void inputDeviceChanged(int idx);
    void outputDeviceChanged(int idx);

    void setValuesFromToml(toml::ParseResult *pr);
    void inputAudioSettClicked();
    void outputAudioSettClicked();
    void koordLiveClicked();
    void githubClicked();
    void versionButtonClicked();

    void updateInputsList();
    void updateOutputsList();
};

#endif

