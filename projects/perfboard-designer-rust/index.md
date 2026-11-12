---
layout: project
title: Perfboard Designer
repo: perfboard-designer-rust
eyebrow: Perfboard · electronics · MCP · desktop · Rust
tagline: Design perfboard circuits together with your coding agent.
lede: >-
  Perfboard Designer is a desktop editor for laying out small circuits on
  isolated-pad perfboard. It has a built-in MCP server, so Claude Code or
  Codex can read the board you have open, place parts, route wires and
  check the result, working on the same design as you, in real time.
description: >-
  Perfboard Designer is an open-source, local-first desktop app for
  designing circuits on isolated-pad perfboard, with deterministic routing
  and an MCP server that lets Claude Code and Codex edit the open design.
facts:
  - MCP server for Claude Code and Codex
  - Agents edit the same design you see, live
  - Electrical changes wait for your approval
  - Every step can be undone, committed and compared
  - MIT
---

## The problem

Perfboard is the quickest way to turn a breadboard prototype into
something that lasts: an Arduino Nano, a couple of breakout modules, a
few resistors and connectors. The hard part is the layout. Every wire
has to fit between the holes, it can't cross a pin you have already
soldered, and the order you solder things in suddenly matters.

Most people plan it on squared paper or in a spreadsheet. PCB tools can
do it, but they were made for something else and don't understand a
board where you solder every wire and bridge by hand.

<div class="compare">
  <div>
    <h3>The usual way</h3>
    <p>Sketch the layout on paper, count holes, rub out and redraw, and
    hope you didn't miss a connection before you pick up the soldering
    iron.</p>
  </div>
  <div class="good">
    <h3>With Perfboard Designer</h3>
    <p>Place parts on a hole-accurate board, let the router suggest wire
    runs, and ask your coding agent to finish, check and tidy up the
    layout while you watch.</p>
  </div>
</div>

## Built to be shared with an agent

The core idea is that **a human and an AI agent are equal participants
in the same design**. Both go through the same Rust engine, the same
validation and the same history, so there is one source of truth and
nothing to import or export.

<ol class="steps">
  <li><strong>Open</strong><span>Start the desktop app and open your design. It announces itself to local MCP clients and to nothing else.</span></li>
  <li><strong>Ask</strong><span>In Claude Code or Codex, describe what you want: "connect the RS-485 module to the Nano's serial pins and route the RJ45 jacks".</span></li>
  <li><strong>Review</strong><span>Agent edits appear on the board as they happen, marked in the history with the agent's reasons. You accept, undo or commit.</span></li>
</ol>

<figure class="shot">
  <img src="nano-rs485-board.png" width="1600" height="1000"
    alt="Perfboard Designer showing an Arduino Nano, an RS-485 module and two RJ45 connectors on a 20 by 26 hole perfboard, with coloured wires, bridges and resistors">
  <figcaption>An Arduino Nano RS-485 node with two RJ45 jacks: the parts
  library on the left, the board in the middle, and the inspector with
  Problems and History on the right.</figcaption>
</figure>

The MCP server gives the agent the same tools you have, and no more:

<div class="features">
  <div>
    <h3>Read the design</h3>
    <p>The full project, the board, the parts library with each part's
    documentation, the validation report and a rendered picture of either
    side of the board.</p>
  </div>
  <div>
    <h3>Edit it</h3>
    <p>Place, move and rotate parts, create nets, draw wires, bridges and
    rails, all as grouped operations that land as one step in the
    history.</p>
  </div>
  <div>
    <h3>Route with the engine</h3>
    <p>Ask the deterministic router for suggested wire runs, or have it
    evaluate a route the agent drew itself before committing to it.</p>
  </div>
  <div>
    <h3>Keep a history</h3>
    <p>Commit named checkpoints with a description, compare any two
    revisions and restore an earlier one, just like the History tab.</p>
  </div>
</div>

### You stay in charge

An agent is good at electronic common sense and tedious routing. It is
not the one holding the soldering iron. So:

- **Electrical changes need your approval.** Connections an agent
  proposes show up under *Needs your approval* in the Nets panel and stay
  inactive until you accept them. Routing nets you have already approved
  is just layout and doesn't ask again.
- **No lost edits.** Every write must quote the revision it was based on.
  If you changed the board in the meantime, the agent's write is refused
  and it has to look again, so neither side overwrites the other.
- **Agent steps are visible.** They are marked in violet in the History
  tab, with the rationale the agent gave, and undo like any other step.
- **A narrow door.** The bridge listens only on the local loopback
  interface and authenticates every request with a token created for that
  launch. It offers no file or shell access.

### House rules in plain English

Because the agent reads your instructions as well as the board, you can
hand it the conventions you build by. These are the rules used for the
Nano RS-485 example:

> 1. Run every wire from an empty perfboard hole to an empty perfboard hole.
> 2. To connect a wire to a component pin, end the wire in a neighbouring
>    empty hole and bridge the gap after the other soldering is complete.
> 3. Route wires only horizontally or vertically, with 90-degree bends.
> 4. Don't route a wire across a soldered component pin.

The engine checks the geometry; the agent applies the judgment.

## Also a good editor on its own

Perfboard Designer is fully usable without an agent.

<div class="features">
  <div>
    <h3>Hole-accurate board</h3>
    <p>Parts snap to the 2.54 mm grid. Switch between the component side
    and a mirrored solder side, exactly as the board looks when you flip
    it over.</p>
  </div>
  <div>
    <h3>Wires, bridges and rails</h3>
    <p>Draw wires pin to pin with bends where you click. Unrouted
    connections show as dashed lines; click one for a suggested route.</p>
  </div>
  <div>
    <h3>Problems with advice</h3>
    <p>Overlaps, out-of-bounds parts and unrouted nets are listed with
    advice, and clicking a problem frames it on the board.</p>
  </div>
  <div>
    <h3>Your own parts</h3>
    <p>The Part designer edits body outlines, pins, keepouts and
    documentation. Parts are plain TOML and Markdown files you can keep
    in Git.</p>
  </div>
  <div>
    <h3>Ready for the bench</h3>
    <p>Print a build drawing with both sides of the board and a cut list
    of every wire.</p>
  </div>
  <div>
    <h3>Local files</h3>
    <p>A design is a single human-readable JSON file. No account, no
    cloud.</p>
  </div>
</div>

## Where it stands

Perfboard Designer is in its first public development series (0.1). It
has reached what I'd call a minimum usable product: you can design a
real board from start to finish, by hand or with an agent, and print it
to build. It is still very much in development, and file formats and
tools may change.

- **Platform**: developed and tested on **Linux**. The code is written to
  be portable, but macOS and Windows haven't been tried yet.
- **Agents**: Claude Code and Codex are configured in the repository.
  Other MCP clients that speak stdio should work, but haven't been
  tested.
- **Parts library**: a small starter set (Arduino Nano, resistors,
  RS-485 breakouts, RJ45 jacks, Dupont pins and jumpers), plus the Part
  designer for your own.

Not there yet: assembly planning (the order to solder things in), and
creating parts through MCP, which agents can only read today. Passing
validation means the geometry and connections are consistent. It is
never a guarantee that a circuit is electrically correct or safe.

## Get started

There are no prebuilt downloads yet: you build it from source. You need
Rust 1.90 or newer, Node.js 22 or newer, the
[Tauri 2 system dependencies](https://v2.tauri.app/start/prerequisites/)
and the Tauri CLI.

### 1. Build and run

```bash
cargo install tauri-cli --version '^2' --locked
git clone https://github.com/arturormk/perfboard-designer-rust.git
cd perfboard-designer-rust
./quickstart.sh
./target/release/perfboard-designer
```

The app opens on an empty perfboard, ready for your own project. Pick
parts from the library on the left and click a hole to place them, or
use **File → New board…** to choose another size first.

### 2. Connect your agent

Keep the app running and start your agent **from the repository
folder**. It picks up the checked-in MCP configuration and asks you to
trust it on first use.

```bash
# Claude Code reads .mcp.json
claude mcp get perfboard-designer

# Codex reads .codex/config.toml
codex mcp list
```

The first start compiles the MCP server and can take a minute. Then ask
away: "what's on the board?", "route the unrouted nets", "check the
design for problems and fix them".

## Learn more

- **[README](https://github.com/arturormk/perfboard-designer-rust/blob/main/README.md)**:
  building, the editor, the Part designer and MCP setup in detail.
- **[Blueprint](https://github.com/arturormk/perfboard-designer-rust/blob/main/docs/BLUEPRINT.md)**:
  the product scope, the design principles and what it deliberately
  isn't.
- **[MCP session bridge](https://github.com/arturormk/perfboard-designer-rust/blob/main/docs/adr/0007-local-mcp-session-bridge.md)**:
  how the agent reaches the running app, and the security boundary.
- **[Issues](https://github.com/arturormk/perfboard-designer-rust/issues)**:
  bug reports and ideas.

Perfboard Designer is licensed under MIT. It was built with AI coding
agents: Codex designed and wrote the Rust engine, the MCP server and the
first UI, and Claude Code reworked the UI into the editor you see above.
