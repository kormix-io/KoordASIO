# KoordASIO, a user-friendly universal ASIO driver

### [⬇ Download KoordASIO for Windows][download]

Run the installer and KoordASIO appears in the ASIO device list of any host
application. No account, no configuration files, nothing else to install.

There is a [project page][site] with a short overview, and older versions and
release notes are on the [releases page][releases].

> **Note:** KoordASIO is no longer distributed through the Microsoft Store.
> The installer above is the only supported download.

## Description

KoordASIO is a universal [ASIO][] driver, meaning that it is not tied to
specific audio hardware. You can use it with any audio hardware that doesn't come
with its own drivers, or where you need features that aren't available with your
bundled ASIO drivers. KoordASIO is a derivative of [FlexASIO][] that focuses on
WASAPI and user convenience.

![The KoordASIO Control window](docs/screenshot.png)

KoordASIO adds an intuitive Control GUI that gives users an easy way to configure
low-latency WASAPI operation without editing config files. KoordASIO focuses on
simplicity, with a choice of WASAPI Shared Mode (mix ASIO audio with other
application audio) and WASAPI Exclusive Mode (lowest-latency, bit-perfect
operation).

## Requirements

 - 64-bit Windows (Vista or later)
 - Any compatible ASIO host application, 32-bit or 64-bit

## Usage

After running the [installer][download], KoordASIO should appear in the ASIO
driver list of any ASIO Host Application (e.g. Ableton, Cubase, Reaper). The Control
GUI (KoordASIOControl.exe) can be launched at any time by clicking on the "ASIO Setup"
button in your host software, or as usual via the Windows launcher.

The installer contains both a 32-bit and a 64-bit driver and registers both, so
hosts of either architecture — including older 32-bit versions of Ableton Live
and Reaper, and 32-bit plugin bridges — find KoordASIO without you having to
pick a build. The control panel itself is 64-bit, which is why 64-bit Windows is
required.

The installer sets up a working configuration straight away:

 - WASAPI [Shared Mode][BACKENDS] — accepts any sample rate your host asks
   for, and plays alongside other applications
 - The Windows default recording and playback audio devices
 - 32-bit float sample type
 - 128-sample buffer size
 - Minimum "suggested" latency

The KoordASIO Control GUI lets you select your Input/Output audio devices
(with a link to the relevant Windows control panel), choose between Shared or
Exclusive mode, and change the Buffer Size in steps between 32 and 2048
samples. The device selectors start on **"Windows default"**, which follows
whatever Windows makes the default device — plug things in, unplug them,
change the default in Windows Sound settings, and KoordASIO follows with
nothing to reconfigure. Picking a specific device pins it; if a pinned device
later disappears or Windows renumbers it (a USB port change is enough),
KoordASIO re-matches it, or falls back to the Windows default rather than
refusing to load.

For the lowest possible latency and bit-perfect output, switch to
[Exclusive Mode][BACKENDS]; note that Exclusive Mode locks the device to one
application and requires your host to run at a sample rate the device supports
natively (usually 48000 Hz). If the rates don't match, KoordASIO tells you
exactly that when the host tries to start audio, and offers to switch you back
to Shared Mode.
The menu button in the top right holds the less-used options: disabling input
when it isn't needed, and turning the system tray icon on or off.

KoordASIO keeps its settings in `.KoordASIO.toml` in your user folder, and
writes the file as soon as you change anything — there is no Save button.

## Logging

To enable driver logging, create an empty file called `KoordASIO.log` in your
user folder (`C:\Users\<you>\KoordASIO.log`), then reproduce the problem. The
driver only logs while that file exists — delete it to switch logging off
again.

Two things to know:

 - Logging is **very** verbose while audio is streaming (it can write hundreds
   of megabytes per minute), and it does blocking file I/O from the audio
   path, so do not leave it enabled during normal use.
 - The driver **stops logging once the file exceeds 1 GiB** and stays silent
   from then on. If your log ends abruptly and later sessions add nothing,
   delete (or rename) the file and create a fresh empty one to re-enable
   logging.

## Troubleshooting
Hopefully KoordASIO should work seamlessly out-of-the-box for you. If you do notice
problems, please create an issue on [the Issues page][issues].

---

*ASIO is a trademark and software of Steinberg Media Technologies GmbH*

[ASIO]: http://www.steinberg.net/en/company/technologies/asio.html
[FlexASIO]: https://github.com/dechamps/FlexASIO
[download]: https://github.com/kormix-io/KoordASIO/releases/latest/download/KoordASIO-Setup.exe
[releases]: https://github.com/kormix-io/KoordASIO/releases
[site]: https://kormix-io.github.io/KoordASIO/
[issues]: https://github.com/kormix-io/KoordASIO/issues
[BACKENDS]: BACKENDS.md
