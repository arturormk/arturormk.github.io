---
layout: project
title: GoBro
repo: gb-cplusplus
eyebrow: GoPro MAX · 360° video · GPS telemetry · Linux
tagline: A GoPro companion for Linux.
lede: >-
  GoBro plays original GoPro MAX recordings on Linux, with no conversion
  step: look around the 360° picture while the GPS route, speed and height
  follow along on a live map. When you want to share a ride, it exports a
  framed video with the map and the numbers drawn in.
description: >-
  GoBro is an open-source Linux player and toolkit for GoPro MAX recordings
  and photos, with synchronized GPS telemetry, an OpenStreetMap route map
  and video export with map and telemetry overlays.
facts:
  - Plays original MAX .360 files directly
  - GPS, map and graphs in step with the frame
  - Exports videos with map and telemetry overlays
  - Never modifies your recordings
  - GPL-3.0-or-later
---

## The problem

You come back from a hike or a ride with a GoPro MAX and a folder of
`.360` files, and you work on Linux. Those files are not ordinary videos.
Each one holds **two HEVC video streams**, one per lens, packed in a
camera-specific cube layout, plus a separate track of **GPMF telemetry**
with the GPS record of where you were and how fast you were going. Long
recordings are split across several chapter files.

A generic video player sees two strange video streams and ignores the
telemetry. The usual way out is a conversion step before you can even
watch the footage, and the GPS data ends up in yet another tool.

<div class="compare">
  <div>
    <h3>The usual way</h3>
    <p>Convert each <code>.360</code> file to a flat panorama, open it in a
    360° player, and load the GPS track separately to see where you
    were.</p>
  </div>
  <div class="good">
    <h3>With GoBro</h3>
    <p>Open the original file. The two lens streams are reconstructed on
    the GPU as it plays, and the map, telemetry and graphs follow the
    frame on screen.</p>
  </div>
</div>

GoBro is built on evidence from real files: its reconstruction and timing
were verified on recordings and photos from a GoPro MAX (2025), and the
findings are written up in the repository.

## How it works

GoBro is one desktop player, `gb-player`, plus a set of command-line tools
that share its libraries. The player is for watching and framing; the
exporter, `gb-render`, turns that framing into a video.

<ol class="steps">
  <li><strong>Watch</strong><span>Open a <code>.360</code>, MP4 or MAX photo in <code>gb-player</code>. Drag to look around, click the route on the map to jump there.</span></li>
  <li><strong>Frame</strong><span>Switch to Capture mode, pick a view and an aspect ratio, and save stills or the framing as a settings file.</span></li>
  <li><strong>Export</strong><span>Run <code>gb-render</code> with those settings to produce an MP4 with the map, speed, height and time drawn in.</span></li>
</ol>

## Made for looking back at a trip

<div class="features">
  <div>
    <h3>No conversion step</h3>
    <p>Original <code>.360</code> files play directly, with both lenses
    decoded in lockstep. Choose rectilinear, fisheye, Little Planet, the
    full panorama or either raw lens.</p>
  </div>
  <div>
    <h3>Everything in step with the frame</h3>
    <p>The map marker, telemetry panel and height/speed graph always show
    the GPS record nearest the frame on screen. Positions are never
    interpolated or invented.</p>
  </div>
  <div>
    <h3>A map you can click</h3>
    <p>The route is drawn on OpenStreetMap, travelled part in orange. Click
    it to seek there; if you passed that spot twice, pick which time.</p>
  </div>
  <div>
    <h3>Ready-to-share videos</h3>
    <p><code>gb-render</code> exports H.264 or HEVC with a route map,
    telemetry text and graphs, over the picture or on a side panel, even
    across chapters, and faster than real time if you like.</p>
  </div>
  <div>
    <h3>Your files stay yours</h3>
    <p>Recordings are opened read-only. Exported videos carry no GPS track
    or camera serial numbers, and the map server only ever sees the area
    you are viewing.</p>
  </div>
  <div>
    <h3>Tools for the curious</h3>
    <p>Command-line tools inspect the container and GPMF metadata, export
    GPS to GPX, GeoJSON, CSV or JSON, and extract exact frames, all with
    versioned JSON output.</p>
  </div>
</div>

## What it supports today

GoBro is in its first public development series (0.1) and is working
towards v1.0. It runs on **Linux**: Ubuntu 22.04 or newer is the supported
baseline, and `.rpm` packages are also built and tested on Fedora.

- **Camera**: the GoPro MAX (2025) is the first and only validated camera.
- **Videos**: MAX dual-stream `.360` files, and single-stream MP4 shown
  flat with zoom and pan. Chapters open in order and play on from one to
  the next.
- **Photos**: MAX JPEG photos, with spherical views for 360° and
  superwide shots, their position on the map and their capture settings.
- **Audio**: the stereo track plays in sync. It stays silent while you
  scrub or seek, so you never hear sound fragments.
- **Display**: needs an OpenGL 3.3 (or OpenGL ES 3.0) driver; the Mesa
  drivers in Ubuntu 22.04 are enough.

Not there yet: TimeWarp and TimeLapse videos and lens-mode names for
videos (both planned for v1.0), the MAX spatial audio track, hardware
decoding, stabilization and a single timeline across chapters in the
player. Other GoPro models have not been verified.

## Get started

There are no prebuilt downloads yet: you build GoBro from source. The
quickstart script does it in one go on Ubuntu.

<div class="callout">
  <p><strong>The script installs packages with sudo.</strong> It checks
  for missing build packages (compiler, CMake, FFmpeg, Qt 6, SDL2) and
  installs them with <code>apt-get</code>, which may ask for your
  password. Use <code>--no-install-deps</code> to install them
  yourself.</p>
</div>

### 1. Build and test

```bash
git clone https://github.com/arturormk/gb-cplusplus.git
cd gb-cplusplus
# installs missing packages, builds, runs the tests
./quickstart.sh
```

The binaries end up in `build/dev/install/bin`. Run from a terminal, the
script also offers to build a `.deb` or `.rpm` package and install it
system-wide, so the tools are on your `PATH`.

### 2. Play a recording

```bash
cd build/dev/install/bin
./gb-player /data/gopro/GS010047.360

# open straight into the full panorama, two minutes in
./gb-player --time 120 --view panorama /data/gopro/GS010047.360
```

Drag to look around, use the mouse wheel to zoom, and press `1` to `8` to
switch views. Space plays and pauses. If you'd rather not touch the
network, `--map-no-network` uses cached map tiles only.

### 3. Export a video

Frame the shot in the player's Capture mode and save the settings as
`framing.ini`. Then start from the commented example for the overlays:

```bash
./gb-render --example-settings > ride.ini

# a quick 10-second draft to check the layout
./gb-render /data/gopro/GS010047.360 --settings framing.ini \
    --settings ride.ini --duration 10 --draft -o test.mp4

# the full export
./gb-render /data/gopro/GS010047.360 --settings framing.ini \
    --settings ride.ini -o ride.mp4
```

`--dry-run` reports the range, frame count and map tiles without
rendering anything.

### 4. Take the GPS track elsewhere

```bash
./gb-telemetry --format gpx /data/gopro/GS010047.360 > route.gpx
```

The player can do the same from its telemetry panel, for every chapter of
a recording at once.

## Learn more

- **[README](https://github.com/arturormk/gb-cplusplus/blob/main/README.md)**:
  building, every tool at a glance, and the JSON report formats.
- **[gb-player](https://github.com/arturormk/gb-cplusplus/blob/main/apps/gb-player/README.md)**:
  views, keyboard controls, Capture mode, the map and its tile policy.
- **[gb-render](https://github.com/arturormk/gb-cplusplus/blob/main/tools/gb-render/README.md)**:
  the settings file in full: placement, fields, map scale, graphs and
  output.
- **[Format support](https://github.com/arturormk/gb-cplusplus/blob/main/docs/format-support.md)**
  and **[blueprint](https://github.com/arturormk/gb-cplusplus/blob/main/docs/BLUEPRINT.md)**:
  what has been verified, what hasn't, and where the project is going.
- **[Issues](https://github.com/arturormk/gb-cplusplus/issues)**: bug
  reports, and recordings that don't play as they should.

GoBro is licensed under GPL-3.0-or-later. It uses the system FFmpeg, Qt 6
and SDL2 libraries under their own licences, and map data is ©
OpenStreetMap contributors. GoBro is not affiliated with, endorsed by or
sponsored by GoPro.
