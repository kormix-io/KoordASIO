# KoordASIO, a user-friendly universal ASIO driver

**If you are looking for an installer, see the
[GitHub releases page][releases], or install directly from the [Microsoft App Store][windowstore].**

## Description

KoordASIO is a universal [ASIO][] driver, meaning that it is not tied to
specific audio hardware. You can use it with any audio hardware that doesn't come
with its own drivers, or where you need features that aren't available with your
bundled ASIO drivers. KoordASIO is a derivative of [FlexASIO][] that focuses on
WASAPI and user convenience.

![KoordASIOScreenshot1a](https://user-images.githubusercontent.com/584572/184341896-1544a755-ebed-466f-b61e-e1d82c4530af.png)

KoordASIO adds an intuitive Control GUI that gives users an easy way to configure
low-latency WASAPI operation without editing config files. KoordASIO focuses on
simplicity, with a choice of WASAPI Shared Mode (mix ASIO audio with other
application audio) and WASAPI Exclusive Mode (lowest-latency, bit-perfect
operation).

## Requirements

 - Windows Vista or later
 - Compatible 64-bit ASIO Host Applications

## Usage

After running the [installer][releases], KoordASIO should appear in the ASIO
driver list of any ASIO Host Application (e.g. Ableton, Cubase, Reaper). The Control
GUI (KoordASIOControl.exe) can be launched at any time by clicking on the "ASIO Setup"
button in your host software, or as usual via the Windows launcher.

The default settings are as follows:

 - WASAPI [Shared Mode][BACKENDS]
 - Uses the Windows default recording and playback audio devices
 - 32-bit float sample type
 - 32-sample buffer size
 - Minimum "suggested" latency

The KoordASIO Control GUI lets you select your Input/Output audio devices (with
a link to the relevant Windows control panel), choose between Shared or
Exclusive mode, disable input when not needed, present mono devices as stereo
when an ASIO host expects two channels, and change the Buffer Size in steps
between 32 and 2048 samples.

## Troubleshooting
Hopefully KoordASIO should work seamlessly out-of-the-box for you. If you do notice
problems, please create an issue on [the Issues page][issues].

---

*ASIO is a trademark and software of Steinberg Media Technologies GmbH*

[ASIO]: http://www.steinberg.net/en/company/technologies/asio.html
[FlexASIO]: https://github.com/dechamps/FlexASIO
[releases]: https://github.com/kormix-io/KoordASIO/releases
[issues]: https://github.com/kormix-io/KoordASIO/issues
[BACKENDS]: BACKENDS.md
[windowstore]: https://apps.microsoft.com/store/detail/koordasio-universal-driver/XP9CSS6NZBDV21
