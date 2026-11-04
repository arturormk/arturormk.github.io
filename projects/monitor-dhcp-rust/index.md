---
layout: project
title: monitor-dhcp
repo: monitor-dhcp-rust
eyebrow: DHCPv4 · commercial displays · Linux · Rust
tagline: A known address for the monitor that only speaks DHCP.
lede: >-
  monitor-dhcp is a deliberately small DHCP server for one dedicated Ethernet
  link. It gives each known monitor the address you wrote down for it, and
  every unknown device one predictable default, so you always know where to
  find the screen your PC controls.
description: >-
  monitor-dhcp is a minimal, deterministic DHCPv4 server for Linux that
  assigns fixed addresses to devices on one dedicated Ethernet interface.
facts:
  - One TOML file is the whole state
  - Same address every time, no lease database
  - Runs as an unprivileged, hardened systemd service
  - MIT licensed
---

## The problem

You have a PC wired straight to a commercial monitor, and you want to control
the monitor over the network. The monitor insists on getting its address by
DHCP and offers no way to set a static one. There is no router on that cable,
and nothing else should be.

The usual answer is a full DHCP server such as `dnsmasq`, `isc-dhcp-server`
or Kea, or NetworkManager's connection sharing. They all work, but they are
built for networks: address pools, lease files, DNS, and settings that decide
which address a device *probably* gets. For one cable and one screen, you
want something smaller that always gives the same answer.

<div class="compare">
  <div>
    <h3>A general-purpose DHCP server</h3>
    <p>Pools, leases kept on disk, often DNS as well. The monitor's address
    depends on lease history, and there is a lot of configuration to get
    right for a single cable.</p>
  </div>
  <div class="good">
    <h3>monitor-dhcp</h3>
    <p>A short TOML file maps the monitor's MAC to its address. Any other
    device gets one fixed default. Nothing is remembered between requests,
    so the answer never drifts.</p>
  </div>
</div>

## How it works

monitor-dhcp listens on exactly one interface. When a request arrives, it
looks up the client's MAC address in the `[hosts]` table of its
configuration. A known MAC gets its reserved address; anything else gets
`default_ip`. It answers discovery, requests, renewals and reboots, and keeps
no lease state at all: the configuration file is the source of truth.

<ol class="steps">
  <li><strong>Address the link</strong><span>Give the dedicated Ethernet port a static address with no gateway or DNS.</span></li>
  <li><strong>Describe it</strong><span>Write the interface, the server address and the monitor's MAC in one TOML file.</span></li>
  <li><strong>Run it</strong><span>Start the service. The monitor comes up at the address you chose.</span></li>
</ol>

## Small on purpose

The design rule is "do the smallest thing that works reliably", and most of
the strengths follow from what monitor-dhcp leaves out.

<div class="features">
  <div>
    <h3>Predictable by design</h3>
    <p>No pool and no lease database. The same MAC gets the same address
    every time, and an unknown device always gets <code>default_ip</code>.</p>
  </div>
  <div>
    <h3>Stays on its own cable</h3>
    <p>It binds to one named interface and never changes addresses or
    routes. Your other network connections are left alone.</p>
  </div>
  <div>
    <h3>Safe reloads</h3>
    <p>A <code>systemctl reload</code> applies a valid new configuration
    atomically. An invalid one is rejected, and the last good one keeps
    running.</p>
  </div>
  <div>
    <h3>Check before you start</h3>
    <p><code>monitor-dhcp --check</code> validates the configuration without
    touching the network, so mistakes show up before anything is bound.</p>
  </div>
  <div>
    <h3>Least privilege</h3>
    <p>The supplied systemd unit runs it as its own unprivileged account,
    with only the two Linux capabilities needed to bind the DHCP port.</p>
  </div>
  <div>
    <h3>Tested against a real client</h3>
    <p>A network-namespace test suite runs <code>dhclient</code> against it:
    acquisition, renewal, reloads, malformed packets and interface
    isolation.</p>
  </div>
</div>

## What it supports today

monitor-dhcp is at version 1.0. It targets Ubuntu 20.04 and newer and other
reasonably modern Linux distributions. The release on GitHub is a statically
linked x86_64 binary; the build helper can also produce ARMv6 and ARMv7
executables.

- One dedicated, isolated Ethernet interface per process
- Reserved addresses for known MACs, one default address for everyone else
- Two monitors on one PC, either through a Linux bridge over two USB
  Ethernet adapters, or with one service instance per interface

Because every unknown device gets the same `default_ip`, only one unknown
client should be active on the link at a time. There is no conflict
detection. Pools, DNS, gateways, IPv6, relays, PXE and routing are
intentionally out of scope. Devices that need a link-layer unicast reply
before they have an address may not work, since initial replies are sent as
broadcasts.

## Get started

<div class="callout">
  <p><strong>Use a dedicated, isolated link.</strong> Never attach
  monitor-dhcp to a production network or to an interface that already has
  a DHCP server. If you work over SSH, make sure the monitor's port is not
  the one carrying your session.</p>
</div>

### 1. Build and install

With a Rust toolchain on Linux:

```bash
git clone https://github.com/arturormk/monitor-dhcp-rust.git
cd monitor-dhcp-rust
cargo build --release
sudo install -Dm0755 target/release/monitor-dhcp \
    /usr/bin/monitor-dhcp
```

Prefer not to build? The
[releases page](https://github.com/arturormk/monitor-dhcp-rust/releases)
has a static x86_64 archive with a SHA-256 checksum.

### 2. Write the configuration

Find the wired interface with `ip link`. You also need the monitor's wired
MAC address; the remote validation guide (below) shows how to capture it.
Then create `/etc/monitor-dhcp/config.toml`:

```toml
interface = "enp3s0"
server_ip = "192.168.50.1"
subnet_mask = "255.255.255.0"
default_ip = "192.168.50.2"

[hosts]
"00:11:22:33:44:55" = "192.168.50.10"
```

Check it (this does not touch the network):

```bash
monitor-dhcp --config /etc/monitor-dhcp/config.toml --check
```

### 3. Try it in the foreground

Give the interface the server address, then run the server and switch the
monitor on:

```bash
sudo ip addr add 192.168.50.1/24 dev enp3s0
sudo ip link set enp3s0 up
sudo monitor-dhcp --config /etc/monitor-dhcp/config.toml
```

The log shows `DISCOVER`, `OFFER`, `REQUEST` and `ACK`, and then
`ping 192.168.50.10` reaches the monitor.

### 4. Make it permanent

Set the same static address in Netplan or NetworkManager (without connection
sharing, which starts its own DHCP server), then install the hardened unit:

```bash
sudo groupadd --system monitor-dhcp
sudo useradd --system --gid monitor-dhcp --no-create-home \
    --shell /usr/sbin/nologin monitor-dhcp
sudo install -Dm0644 packaging/monitor-dhcp.service \
    /etc/systemd/system/monitor-dhcp.service
sudo systemctl daemon-reload
sudo systemctl enable --now monitor-dhcp
```

Follow it with `journalctl -u monitor-dhcp -f`. After editing the
configuration, `sudo systemctl reload monitor-dhcp` applies it.

## Learn more

- **[README](https://github.com/arturormk/monitor-dhcp-rust/blob/main/README.md)**:
  building, configuring the interface, systemd, tests, releases and
  limitations.
- **[Remote installation guide](https://github.com/arturormk/monitor-dhcp-rust/blob/main/HOW-TO.md)**:
  a step-by-step install on a host you reach over SSH, with Netplan and
  NetworkManager examples and troubleshooting.
- **[Validate a monitor remotely](https://github.com/arturormk/monitor-dhcp-rust/blob/main/docs/HOWTO-RemotePreflight.md)**:
  test the monitor and a full DHCP exchange before changing anything
  permanently.
- **[Run it as a system service](https://github.com/arturormk/monitor-dhcp-rust/blob/main/docs/HOWTO-systemd.md)**
  and **[two monitors through a bridge](https://github.com/arturormk/monitor-dhcp-rust/blob/main/docs/HOWTO-NetworkBridge.md)**:
  hardened services, multiple instances and a two-monitor setup.
- **[Design blueprint](https://github.com/arturormk/monitor-dhcp-rust/blob/main/docs/BLUEPRINT.md)**:
  the requirements and the deliberate non-goals.
- **[Issues](https://github.com/arturormk/monitor-dhcp-rust/issues)**: bug
  reports and interoperability problems. Please describe the topology and
  the client, and leave out real MAC addresses.

monitor-dhcp is MIT licensed. It builds on a vendored copy of the
`dhcproto` library, which is MIT licensed too.
