---
layout: project
title: Replant
repo: replant
eyebrow: Linux deployment · Clonezilla · open source
tagline: Capture the installed system once. Replant it wherever it fits.
lede: >-
  Replant turns a Clonezilla image of a Linux PC into a compact package that
  restores onto another PC, even one whose disk is smaller than the
  original's. One script on a USB stick, and the new machine boots the
  system you saved.
description: >-
  Replant converts Clonezilla disk images into size-independent restore
  packages, so a Linux installation saved from a large disk can be restored
  onto a smaller or larger one.
facts:
  - Restores onto smaller or larger disks
  - Plain Bash restorer, runs from an Ubuntu Live USB
  - Checks everything before it writes anything
  - MIT licensed
---

## The problem

You set up one Linux PC exactly the way you want it, save it with
[Clonezilla](https://clonezilla.org/), and plan to roll the same system out to
more machines. Then the next machine turns out to have a 64 GB eMMC chip
instead of the 256 GB SSD you started from.

A Clonezilla image is a copy of the disk's *partitions*, and its filesystems
are as big as the partitions they came from. Restoring onto a smaller disk
simply doesn't fit, even when the system only uses a fraction of the space.

<div class="compare">
  <div>
    <h3>Restoring the Clonezilla image</h3>
    <p>256 GB of partitions onto a 64 GB disk: it does not fit, even though
    only 17 GB of it is actually used.</p>
  </div>
  <div class="good">
    <h3>Replanting it</h3>
    <p>Only the 17 GB of files are packed (about 4 GB compressed). The restorer
    sizes the partitions to the new disk and puts the files back.</p>
  </div>
</div>

Replant works at the level of **files, not blocks**. It unpacks your
Clonezilla image, archives the filesystems themselves, and generates a
restore script that rebuilds them at whatever size the target disk allows.
The restored system keeps its original filesystem and partition IDs, so the
boot loader and `/etc/fstab` work without any edits.

This isn't theoretical: a system saved from a 256 GB NVMe drive has been
restored with Replant onto a mini PC with a 62.5 GB eMMC disk, and it booted.

## How it works

<ol class="steps">
  <li><strong>Prepare</strong><span>Install Replant on your own Linux machine. You only do this once.</span></li>
  <li><strong>Process</strong><span>Point it at a Clonezilla image. It checks the image and builds a restore package.</span></li>
  <li><strong>Apply</strong><span>Boot the target PC from an Ubuntu Live USB and run the package's <code>restore.sh</code>.</span></li>
</ol>

## Built to be careful

Restoring a disk is destructive by nature, so Replant checks at every step
and explains itself when it says no.

<div class="features">
  <div>
    <h3>Read-only on your image</h3>
    <p>Your Clonezilla image is never modified. <code>replant inspect</code> tells you
    up front whether the image is supported, and why not if it isn't.</p>
  </div>
  <div>
    <h3>Verified at every stage</h3>
    <p>Checksums, Partclone's own checks and filesystem checks
    (<code>e2fsck</code>, <code>fsck.fat</code>) all run before the package
    is accepted.</p>
  </div>
  <div>
    <h3>Dry run first</h3>
    <p>The restorer shows what is on the target disk now and the layout it
    will create, and writes nothing until you ask it to.</p>
  </div>
  <div>
    <h3>Hard to aim at the wrong disk</h3>
    <p>It refuses disks that are mounted, in use, too small or holding the
    package, and makes you type the disk name to confirm.</p>
  </div>
  <div>
    <h3>No special restore media</h3>
    <p>The restorer is a standalone Bash script that runs from a stock
    Ubuntu Desktop Live USB. It doesn't need Python or Replant installed.</p>
  </div>
  <div>
    <h3>Minimal root access</h3>
    <p>Building a package needs <code>sudo</code> for a single, auditable
    step. Everything else runs as your own user.</p>
  </div>
</div>

## What it supports today

Replant is young (alpha), and version 1 deliberately supports one common
layout really well: the one a **default Ubuntu installation** creates.

- A whole-disk Clonezilla image (`savedisk`) of a **UEFI** system with a **GPT** disk
- Exactly two partitions: the EFI System Partition and an **ext4** root
- Saved with Zstandard compression (Clonezilla's `-z9p` option)

Other layouts (legacy BIOS/MBR, LVM, encrypted disks, extra partitions,
gzip-compressed images) are detected and refused with an explanation rather
than half-handled. Secure Boot after a restore has not been specifically
verified yet.

## Get started

<div class="callout">
  <p><strong>Restoring erases the target disk completely.</strong> Every
  partition and every file on it is replaced by the system from your image.
  That is the whole point, but back up anything you care about on the target
  PC first.</p>
</div>

### 1. Prepare (once)

On an Ubuntu or Debian machine with `sudo`:

```bash
sudo apt-get install git zstd e2fsprogs dosfstools util-linux tar
# uv runs Replant with the right Python setup
curl -LsSf https://astral.sh/uv/install.sh | sh

git clone https://github.com/arturormk/replant.git
cd replant
# build current Partclone and fsarchiver into ./bin-tools
tools/build-tools.sh
```

You need free space for roughly the data actually *used* on the original
disk, plus the package: about 17 GB + 4 GB for a typical Ubuntu desktop, not
the full disk size.

### 2. Process the image

```bash
# Is the image supported?
uv run replant inspect /data/images/office-pc-img

# Rebuild and verify its filesystems (prints the run directory)
uv run replant extract --tools bin-tools /data/images/office-pc-img

# Build the restore package
uv run replant pack --tools bin-tools replant-work/<run> \
    --output replant-packages/office-pc
```

`pack` ends by telling you the **smallest disk** the package fits on. The
package holds a full copy of the system, password hashes included, so
treat it as sensitive.

### 3. Apply it to the target PC

Copy `replant-packages/office-pc/` to a USB stick, boot the target PC from an
Ubuntu Desktop Live USB (26.04 LTS or newer, UEFI mode, "Try Ubuntu"),
connect to the network, and open a terminal in the package folder:

```bash
# Find the target disk: check sizes and models carefully
lsblk -o NAME,SIZE,MODEL,TYPE

# Install missing tools, check the package (writes nothing)
sudo bash restore.sh --check --install-deps

# The full plan for this disk (still writes nothing)
sudo bash restore.sh --disk /dev/nvme0n1 --dry-run

# The real thing: asks you to type the disk name, then restores
sudo bash restore.sh --disk /dev/nvme0n1
```

When it says `Done`, remove the USB sticks and reboot into the replanted system.

## Learn more

- **[Quick start](https://github.com/arturormk/replant/blob/main/QUICKSTART.md)**:
  the same three steps in full detail, including what to do if something goes wrong.
- **[README](https://github.com/arturormk/replant/blob/main/README.md)**:
  every command, option and exit status.
- **[Design blueprint](https://github.com/arturormk/replant/blob/main/docs/BLUEPRINT.md)**
  and **[package format](https://github.com/arturormk/replant/blob/main/docs/package-format.md)**:
  how it works inside.
- **[Issues](https://github.com/arturormk/replant/issues)**: bug reports and
  images that should be supported but aren't.

Replant is MIT licensed. It drives external tools (Partclone, fsarchiver,
e2fsprogs and others) that are separate programs under their own licences.
