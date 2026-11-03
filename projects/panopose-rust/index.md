---
layout: project
title: PanoPose
repo: panopose-rust
eyebrow: 360° panoramas · astronomy · Stellarium · Linux
tagline: Line up your panorama with the real sky.
lede: >-
  PanoPose is a Linux desktop app for orienting full-sphere 360° panoramas
  against the Sun, Moon, planets and stars. Once the picture matches the
  sky, you can export it as a calibrated panorama or a ready-to-install
  Stellarium landscape for planning your observing site.
description: >-
  PanoPose is an open-source Linux desktop app for manually orienting
  equirectangular 360° panoramas against astronomical markers and
  exporting them as calibrated panoramas or Stellarium landscapes.
facts:
  - Align against Sun, Moon, planet and star markers
  - Exports Stellarium landscape ZIPs
  - Never modifies your source panorama
  - Works offline, with a bundled star catalogue
  - MIT or Apache-2.0
---

## The problem

You want to know what your observing site can actually see: which part
of the sky the trees hide, how low you can follow a planet before it
drops behind the roof next door. Stellarium can show your own horizon
instead of a generic one, if you give it a panorama of the site. So you
take one with a 360° camera, or stitch one from several photos.

Then the hard part starts. For the landscape to be useful, North in the
picture has to be true North, and the horizon has to sit where the real
horizon is. A camera on a tripod is never perfectly level, and a compass
reading is only approximate. A few degrees off, and the planner tells you
a star clears the trees when it doesn't.

<div class="compare">
  <div>
    <h3>Guessing the orientation</h3>
    <p>Rotate the panorama by eye using a compass bearing, and hope the
    camera was level. Errors of a few degrees go unnoticed.</p>
  </div>
  <div class="good">
    <h3>Aligning with PanoPose</h3>
    <p>Drag the Sun, or a bright star or planet, in your picture onto
    the marker computed for your site and time. The sky itself fixes
    the orientation.</p>
  </div>
</div>

PanoPose reads the capture time and GPS position from the image's
metadata, works out where the Sun, Moon, planets and bright stars were
at that moment, and draws them over the panorama with an Alt/Az grid.
You turn and tilt the panorama until the real objects sit on their
markers. Nothing is guessed automatically: you make the match, and you
can see exactly how good it is.

## How it works

<ol class="steps">
  <li><strong>Load</strong><span>Open a 2:1 equirectangular panorama. Time and site come from its EXIF/XMP metadata, or you type them in.</span></li>
  <li><strong>Align</strong><span>Drag a visible object onto its marker, then pin it and roll around it to match a second one.</span></li>
  <li><strong>Export</strong><span>Save the pose in the image's metadata, or export a calibrated PNG or a Stellarium landscape ZIP.</span></li>
</ol>

The orientation is a true spherical rotation, so PanoPose won't let you
do something physically impossible. You can't lift the whole horizon
uniformly: tilting it raises one side and lowers the opposite side by the
same amount, which is exactly what a camera that wasn't level does.

## Made for careful alignment

<div class="features">
  <div>
    <h3>Two stars, no drift</h3>
    <p>In <code>Roll Target</code> mode, the first click pins the sky direction
    under the pointer. Roll around it to bring a second star, planet or
    landmark into place without losing the first.</p>
  </div>
  <div>
    <h3>The image stays under your hand</h3>
    <p><code>Align Target</code> drags along the sphere, so the point you grab
    stays under the cursor in every direction, including diagonals.</p>
  </div>
  <div>
    <h3>A sky to match against</h3>
    <p>Planetarium mode toggles the 1500 brightest catalogue stars above
    your horizon with one button, so you can blink between the picture
    and the computed sky.</p>
  </div>
  <div>
    <h3>Compare with a reference</h3>
    <p>Load an already calibrated panorama from the same spot as a
    reference layer, then fade or blink between the two to line up the
    shared landscape.</p>
  </div>
  <div>
    <h3>Your originals stay untouched</h3>
    <p><code>Save As</code> only writes metadata, and exports are new files.
    The source pixels are never remapped or re-encoded.</p>
  </div>
  <div>
    <h3>Ready for Stellarium</h3>
    <p>Exports a landscape ZIP with <code>landscape.ini</code>, your site's
    coordinates and the oriented panorama, with optional transparent sky
    and a cap to hide the tripod.</p>
  </div>
</div>

One technique the README describes in detail: a GoPro MAX can take
several night shots in quick succession, which you can stack to bring
out faint stars. Calibrate that night panorama against the stars, then
use it as the reference for a daytime panorama taken from the same
camera position.

## What it supports today

PanoPose is at version 1.4, with release packages (`.deb`, `.rpm` and
`.AppImage`) built for **amd64 Linux**. It works with:

- Full-sphere 2:1 equirectangular panoramas in JPG, PNG or TIFF
- Capture time, timezone, GPS position and pose from EXIF/XMP metadata
- Upright, sideways and upside-down captures
- Sun, Moon, planet and bright-star markers; the star catalogue is
  bundled, so no network is needed

Two features rely on external programs you install separately.
`Save As` writes metadata with [ExifTool](https://exiftool.org/), and
the optional `Remove Sky` uses
[skyseg-ncnn](https://github.com/knyipab/skyseg-ncnn) to make the sky
transparent. Without them, everything else, including PNG and Stellarium
export, still works.

Alignment is manual by design. PanoPose doesn't detect stars or estimate
the orientation for you, and it doesn't project ordinary phone photos
onto the sphere: from those it only imports the time and site.

## Get started

### 1. Install

On amd64 Debian or Ubuntu, download the `.deb` from the
[latest release](https://github.com/arturormk/panopose-rust/releases/latest)
(an `.rpm` and an `.AppImage` are there too) and install it:

```bash
sudo apt install ./PanoPose_*_amd64.deb
```

To write orientation back into your images with `Save As`, also install
ExifTool:

```bash
sudo apt install libimage-exiftool-perl
```

### 2. Or build it from source

You need Rust, Node.js and npm. The quickstart script builds the release
app and offers to install the package it produces:

```bash
git clone https://github.com/arturormk/panopose-rust.git
cd panopose-rust
./quickstart-panopose.sh
```

For the optional sky removal, `./quickstart-skyseg-ncnn.sh` builds and
installs `skyseg-ncnn` under `~/.local`, asking before it starts.

### 3. Align your first panorama

Start `panopose` and open your panorama. Then:

1. Check the latitude, longitude and capture time. If the fields are
   blank, the image has no location metadata: type them in.
2. Switch to `Align Target` (key `A`) and drag the Sun, or a bright
   planet or star, onto its marker.
3. If it still doesn't fit, switch to `Roll Target` (key `R`), click the
   matched object and drag sideways until a second object meets its
   marker.
4. Use `Export Stellarium ZIP`, fill in the landscape name, and install
   the ZIP using
   [Stellarium's landscape instructions](https://stellarium.org/landscapes.html).

## Learn more

- **[README](https://github.com/arturormk/panopose-rust/blob/main/README.md)**:
  every feature, the full alignment workflow, the GoPro MAX night-to-day
  technique and exactly what each export produces.
- **[Design blueprint](https://github.com/arturormk/panopose-rust/blob/main/docs/BLUEPRINT.md)**:
  the product direction, coordinate conventions and orientation model.
- **[Building skyseg-ncnn](https://github.com/arturormk/panopose-rust/blob/main/docs/HOW-TO-skyseg-ncnn.md)**:
  manual build notes for the optional sky removal.
- **[Changelog](https://github.com/arturormk/panopose-rust/blob/main/CHANGELOG.md)**,
  **[releases](https://github.com/arturormk/panopose-rust/releases)** and
  **[issues](https://github.com/arturormk/panopose-rust/issues)**: what
  changed, packages to download, and bug reports.

PanoPose is dual-licensed under MIT or Apache-2.0, at your option. Its
bright-star data is derived from the Yale Bright Star Catalog, and
ExifTool and skyseg-ncnn are separate programs under their own licences.
