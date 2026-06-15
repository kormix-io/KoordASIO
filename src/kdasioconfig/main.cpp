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

#include <QtWidgets>
#include <singleapplication.h>

#include "kdasioconfig.h"

namespace {

bool parseBufferSize(const QString& value, int& bufferSize)
{
    bool ok = false;
    const int parsed = value.toInt(&ok);
    if (!ok) return false;
    const QList<int> allowed = {32, 64, 128, 256, 512, 1024, 2048};
    if (!allowed.contains(parsed)) return false;
    bufferSize = parsed;
    return true;
}

}

int main(int argc, char **argv)
{
    SingleApplication app( argc, argv );
    app.setApplicationName("KoordASIO Control");

    KdASIOConfig audio;

    if (argc >= 2) {
        const QString arg = argv[1];
        if (!arg.compare("-defaults") || !arg.compare("-de")) {
            audio.setInstallDefaults(true);
            return 0;
        }
        if (!arg.compare("-ds")) {
            audio.setInstallDefaults(false);
            return 0;
        }
        if (arg.startsWith("-buffer=")) {
            int bufferSize = 32;
            if (!parseBufferSize(arg.mid(8), bufferSize)) {
                return 1;
            }
            audio.setInstallDefaults(true, bufferSize);
            return 0;
        }
        if (!arg.compare("-exclusive")) {
            audio.setInstallDefaults(true);
            return 0;
        }
        if (!arg.compare("-shared")) {
            audio.setInstallDefaults(false);
            return 0;
        }
    }

    // in normal mode - show GUI
    audio.show();
    return app.exec();
}
