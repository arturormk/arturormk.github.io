---
layout: project
title: Syncplayer
repo: syncplayer
eyebrow: Video installations · Rust · GStreamer
tagline: Every screen plays its own file. They all keep the same time.
lede: >-
  Syncplayer is a video player for multi-screen and projection
  installations. Each Linux PC or Raspberry Pi plays its own local media,
  and all of them follow one Master's timeline, cue for cue, to within a
  millisecond or so.
description: >-
  Syncplayer is a Rust and GStreamer video player that keeps independent
  local media on several networked Linux hosts synchronized to one
  Master timeline.
facts:
  - Media stays local, only timing crosses the network
  - Sub-millisecond sync across four Raspberry Pis over 17 hours
  - Slaves keep playing if the Master goes away
  - Built-in console and sync diagnostics
  - MIT or Apache-2.0
---

## The problem

You are building an installation: three projectors across a wall, a row of
screens in a museum, a display that has to change at the exact moment a
light comes on. Each screen shows a different video, and they only work
together if they stay in step for hours, every day.

Starting the same file on several machines at "the same time" doesn't hold
up. Clocks drift, decoders stall, a machine reboots, and after a while one
screen is visibly behind. Streaming the video from one central computer
avoids the drift but puts all your media on the network.

<div class="compare">
  <div>
    <h3>Separate players</h3>
    <p>Each host plays its file on its own clock. They start roughly together
    and slowly drift apart, and a restarted host never finds its place
    again.</p>
  </div>
  <div class="good">
    <h3>With Syncplayer</h3>
    <p>Each host still decodes its own local file, but against one shared
    clock and one authoritative position from the Master. Late or restarted
    players join in step.</p>
  </div>
</div>

This has been measured, not just watched: four Raspberry Pis (one Master,
three Slaves) played a looping three-cue program for over 17 hours. Across
the analysed 17.16 hours the worst pairwise separation was 4.4 ms, the 99th
percentile stayed under 0.4 ms, and no corrective resynchronization was
ever needed. The
[soak report](https://github.com/arturormk/syncplayer/blob/main/docs/reports/2026-10-17-four-raspberry-pi-soak-test.md)
has the full numbers.

## How it works

One host is the **Master**. It plays the program from its own clock,
exports that clock on the network with GStreamer, and sends the current
position several times a second. Every other host is a **Slave**: it locks
onto the Master's clock, plays its own rendition of the same cue, and
corrects itself if it drifts. Video files never leave the machines they're
on.

<ol class="steps">
  <li><strong>Describe the show</strong><span>Write one TOML program: an ordered list of cues, and which local file each player shows for each cue.</span></li>
  <li><strong>Validate on each host</strong><span><code>syncplayer validate</code> probes every file, checks durations and prints the program's hash.</span></li>
  <li><strong>Start Master and Slaves</strong><span>Slaves connect, check they have the same program, calibrate the clock and start in step.</span></li>
</ol>

## Built for unattended installations

<div class="features">
  <div>
    <h3>No media on the network</h3>
    <p>Only clock, control and state messages cross the LAN. Each player
    can use a rendition suited to its own decoder, as long as the cues
    match in length.</p>
  </div>
  <div>
    <h3>Joins without interrupting</h3>
    <p>A Slave that starts late or reconnects gets a future release time
    and joins the running show without disturbing the Master or the
    others.</p>
  </div>
  <div>
    <h3>Keeps playing through outages</h3>
    <p>If the Master or the network disappears, Slaves free-run on their
    last clock estimate and reconnect in the background.</p>
  </div>
  <div>
    <h3>Corrects drift gently</h3>
    <p>Small sustained drift can be corrected by changing playback speed
    by at most 2%. Only large errors trigger a seek, and a frame watchdog exits
    a wedged player so its supervisor can restart it.</p>
  </div>
  <div>
    <h3>Timed events on each host</h3>
    <p>A cue can run a local command or send a UDP message at a set time,
    for example to dim the lights 12.5 seconds into the main video.</p>
  </div>
  <div>
    <h3>You can see how well it syncs</h3>
    <p>An optional console pauses, seeks and loops the whole installation,
    shows an on-screen overlay and reports each player's timing error.
    A CSV log and an analysis script give you the full picture.</p>
  </div>
</div>

## What it supports today

Syncplayer's MVP is feature-complete and the project calls itself a **v1.0
release candidate**. The remaining work is qualification and packaging
rather than new features.

- **Platforms:** x86-64 Linux and 64-bit Raspberry Pi OS, built natively
  from source with Rust and GStreamer 1.20 or newer.
- **Proven so far:** the four-Raspberry-Pi topology described above, with
  hardware H.264 decoding.
- **Still open for v1.0:** one unexplained crash at the start of the soak
  test, deliberate network-loss and recovery testing, qualification on
  Ubuntu PCs and of the fullscreen and display paths, and a supported way
  to install and supervise it (packaging, a systemd unit).
- **Deliberately not in v1:** automatic Master election, media transfer
  between hosts, multicast, a GUI or web UI, and live program reloads.

Everything that's done and still to do is tracked in the
[release checklist](https://github.com/arturormk/syncplayer/blob/main/docs/TODO.md).
All hosts must run the same Syncplayer build.

## Get started

<div class="callout">
  <p><strong>The console has no authentication.</strong> It is off by
  default. When you enable it, bind it to <code>127.0.0.1</code> unless
  you trust everyone on the installation network.</p>
</div>

### 1. Build it on each host

On Ubuntu, Debian or Raspberry Pi OS (64-bit):

```bash
git clone https://github.com/arturormk/syncplayer.git
cd syncplayer
# Offers to install missing packages and Rust, then builds
./quickstart.sh
```

The script prints the path of the finished `syncplayer` executable; the
commands below assume it is on your `PATH`. It builds natively; there is
no cross-compilation.

### 2. Prepare the media

Give every video the same size, frame rate and audio layout. One script
targets PCs and one targets the Raspberry Pi's hardware decoder:

```bash
./tools/prepare-video-for-pc.sh -o media/main-pc.mp4 main.mov
./tools/prepare-video-for-rpi.sh -o media/main-rpi.mp4 main.mov
```

### 3. Write and validate the program

Put the same `show.toml` on every host, adjusting only the paths each
host plays:

```toml
version = 1

[program]
id = "simple-show"
loop = true

[[program.cue]]
id = "intro"

[[program.cue]]
id = "main"

[players.default.intro]
video = "media/intro.mp4"

[players.default.main]
video = "media/main.mp4"
```

```bash
syncplayer validate show.toml
```

### 4. Start the Master, then the Slaves

```bash
# On the Master
syncplayer master show.toml --player-id master \
    --console-bind 127.0.0.1:2323

# On each Slave, using the Master's LAN address
syncplayer slave show.toml --player-id left-wall \
    --master <master-ip>:46000
```

Allow TCP port 46000 and UDP port 46001 to the Master, and each Slave's
UDP state port, through the host firewalls. Then type
`nc 127.0.0.1 2323` on the Master and try `status` and `diagnostics`.
Ctrl-C stops a player cleanly.

## Learn more

- **[README](https://github.com/arturormk/syncplayer/blob/main/README.md)**:
  every command-line option, the console commands and the synchronization
  behaviour in detail.
- **[Media preparation](https://github.com/arturormk/syncplayer/blob/main/docs/media-preparation.md)**:
  formats, options and keeping per-host renditions in step.
- **[Example programs](https://github.com/arturormk/syncplayer/blob/main/examples/full-show.toml)**:
  aliases, per-player files, external audio and timed events.
- **[Design blueprint](https://github.com/arturormk/syncplayer/blob/main/docs/BLUEPRINT.md)**
  and **[architecture decisions](https://github.com/arturormk/syncplayer/tree/main/docs/adr)**:
  how and why it works the way it does.
- **[Issues](https://github.com/arturormk/syncplayer/issues)**: bug reports
  and questions.

Syncplayer is dual-licensed under MIT or Apache-2.0, at your option.
