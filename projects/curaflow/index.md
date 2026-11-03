---
layout: project
title: Curaflow
repo: curaflow
eyebrow: Web data · scraping pipelines · Python
tagline: Fetch what changed. Build what depends on it. Show what's different.
lede: >-
  Curaflow keeps a local copy of data you curate from websites and feeds up
  to date. You describe the pages, what to pull out of them and what to
  build from it in one YAML manifest. Each run fetches in parallel, skips
  anything that hasn't changed and records what did.
description: >-
  Curaflow is a Python command-line tool that runs an incremental, parallel
  fetch, normalize and build pipeline over web pages and feeds, with
  hierarchical fan-out and structural diffs.
facts:
  - One YAML manifest, no scraper code for common cases
  - Follows an index page down to entity pages and images
  - Conditional GET and content digests skip unchanged work
  - Diffs of every rebuilt artifact
  - MIT licensed
---

## The problem

You maintain a dataset that lives on someone else's website: a directory of
shops, say, with a page per shop and a logo and photos on each page. You
need it as clean local files, perhaps in two languages, with the images
resized for a display, and you need to know when something changes.

A quick script does the first download. It isn't a good fit for the tenth.
It fetches every page and image again each time, it doesn't notice when a
new shop appears on the index, and it can't tell you that one logo changed
and nothing else did. Every new site means another script with the same
loops, caching and file handling.

<div class="compare">
  <div>
    <h3>A one-off scraper</h3>
    <p>Downloads everything on every run, hard-codes the page structure in
    Python, and leaves you to compare the old and new output yourself.</p>
  </div>
  <div class="good">
    <h3>A Curaflow manifest</h3>
    <p>Describes the pages with CSS selectors, discovers new pages from the
    index, re-downloads only what changed, and writes a diff of every
    artifact it rebuilds.</p>
  </div>
</div>

The repository's own examples show the kind of job it was built for: store,
banner and news listings in Spanish and English, turned into JSON
summaries, Qt Quick (QML) list models and resized images for a display
application.

## How it works

A Curaflow project has two kinds of things. **Sources** are fetched and
normalized into YAML files under `data/sources/`. **Targets** are artifacts
built from sources (or from other targets) into `data/targets/`. A source
can *fan out*: the links it extracts from an index page become new sources,
whose images can become sources in turn, so you describe the levels once
instead of listing every page.

<ol class="steps">
  <li><strong>Plan</strong><span>Write a manifest and let <code>curaflow plan</code> list its sources and targets.</span></li>
  <li><strong>Fetch</strong><span><code>curaflow fetch</code> downloads in parallel, follows fan-out, and skips anything unchanged.</span></li>
  <li><strong>Build</strong><span><code>curaflow build</code> rebuilds only the targets whose inputs are newer, and records a diff.</span></li>
</ol>

## Made for data that keeps changing

Curaflow is meant to be run again and again against the same sites, so
most of its design is about doing as little as possible on each run and
telling you what moved.

<div class="features">
  <div>
    <h3>Quiet when nothing changed</h3>
    <p>It sends ETag and Last-Modified headers, and compares a digest of the
    normalized content, so a page that was re-served but not really changed
    counts as unchanged.</p>
  </div>
  <div>
    <h3>Finds new pages by itself</h3>
    <p>Fan-out turns extracted links into child sources, level by level. A
    new shop on the index page becomes a new source on the next fetch.</p>
  </div>
  <div>
    <h3>Parallel, within limits</h3>
    <p>Sources are fetched concurrently, ten at a time by default. Use
    <code>--max-concurrent</code> to be gentler or faster.</p>
  </div>
  <div>
    <h3>Changes you can read</h3>
    <p>Each rebuilt target gets a structural diff, such as
    <code>/shops/extractions/shop_links: list changed len 2 -&gt; 3</code>,
    which <code>curaflow diff</code> prints back.</p>
  </div>
  <div>
    <h3>Plain files you can inspect</h3>
    <p>Everything is YAML, JSON or the downloaded file itself.
    <code>curaflow table</code> shows any source as a terminal table, sorted
    naturally (1, 2, 10).</p>
  </div>
  <div>
    <h3>Extensible in a few lines</h3>
    <p>A plugin is one decorated Python function. Point
    <code>--plugins</code> at a folder of your own, and it is loaded next to
    the built-in ones.</p>
  </div>
</div>

## What it supports today

Curaflow is at version 1.0.0, a command-line tool for Python 3.10 or newer,
tested in CI on Python 3.10 to 3.12. It is built for the author's own
data-curation work and documented mainly through its README and design
records.

- **Sources:** JSON (`http_json`), HTML with CSS selectors (`http_html`),
  XML feeds (`http_xml`), binary files such as images (`http_bytes`), and
  local LibreOffice `.ods` sheets (`ods_table`). A `multiplex` source
  expands one template into several, for example one per language.
- **Targets:** a JSON bundle of sources (`concat_json`), a field-level
  `watch` summary for change tracking, and `media_convert`, which turns
  downloaded images and videos into PNG or MP4 at a fixed size. Helpers
  make it short to write your own HTML scrapers and QML list-model targets.
- **Requirements:** `media_convert` uses `rsvg-convert`, ImageMagick and
  `ffmpeg`, which you install separately.

Some things are deliberately simple or not there yet. Plugins in your own
Python packages are not discovered automatically, so you import them or use
`--plugins`. Fan-out has no limits on depth or count yet, so keep its
selectors specific. Targets are rebuilt by comparing file times, and they
only depend on the sources you list in `deps`. Curaflow runs when you run
it; scheduling is up to you.

## Get started

Curaflow isn't published on PyPI. You run it from a clone of the
repository with [uv](https://docs.astral.sh/uv/), which sets up the Python
environment for you. A built wheel is also attached to each
[GitHub release](https://github.com/arturormk/curaflow/releases).

<div class="callout">
  <p><strong>Be a polite client.</strong> Curaflow fetches every page and
  file your manifest leads to, in parallel. Check that you may collect data
  from the site, and start with a low <code>--max-concurrent</code> on sites
  you don't control.</p>
</div>

### 1. Install

```bash
# uv manages Python and Curaflow's dependencies
curl -LsSf https://astral.sh/uv/install.sh | sh

git clone https://github.com/arturormk/curaflow.git
cd curaflow
uv sync
uv run curaflow --help
```

### 2. Describe the site

Curaflow writes `data/` and `.curaflow/` in the current directory, so use
a folder of its own for each project. This manifest reads a shop index,
follows each shop link, and downloads the photos on each shop's page:

```yaml
sources:
  - name: shops
    plugin: http_html
    params:
      url: "https://example.com/shops/"
      extract:
        - name: shop_links
          css: ".shop-card a"
          attr: href
      fanout:
        - from: shop_links
          plugin: http_html
          name_template: "shop:{slug}"
          params:
            url: "{absolute_url}"
            extract:
              - name: photos
                css: ".gallery img"
                attr: src
            fanout:
              - from: photos
                plugin: http_bytes
                name_template: "photo:{slug}"
                params:
                  url: "{absolute_url}"

targets:
  - name: directory
    plugin: concat_json
    deps: ["shops"]
```

Each extracted link gets a `slug` and an `absolute_url`, which the
templates use to name and fetch its children. The repository's
[example manifest](https://github.com/arturormk/curaflow/blob/main/example/manifest.yaml)
shows the same pattern with comments.

### 3. Fetch, build, repeat

From your project folder (with `~/curaflow` standing for your clone):

```bash
alias curaflow='uv run --project ~/curaflow curaflow'

curaflow plan -m manifest.yaml
curaflow fetch -m manifest.yaml --max-concurrent 4
curaflow build -m manifest.yaml
```

Run `fetch` and `build` again later. Unchanged pages are reported as
`unchanged` and an up-to-date target is not rebuilt. When something did
change, look at it:

```bash
# What changed in the last build of a target
curaflow diff targets:directory

# Which files exist and which targets need rebuilding
curaflow status -m manifest.yaml

# A source as a table, sorted by its position on the page
curaflow table shops --list-key extractions.shop_links \
    --columns _index,slug,absolute_url --sort +_index
```

## Learn more

- **[README](https://github.com/arturormk/curaflow/blob/main/README.md)**:
  every built-in plugin and its parameters, how names map to files, and how
  to write your own plugins.
- **[Example manifest](https://github.com/arturormk/curaflow/blob/main/example/manifest.yaml)**:
  a commented, three-level fan-out from an index page to images.
- **[Design records](https://github.com/arturormk/curaflow/tree/main/docs/adr)**:
  why fan-out, the plugin registry and the tooling work the way they do.
- **[Contributing](https://github.com/arturormk/curaflow/blob/main/CONTRIBUTING.md)**:
  how changes are proposed, tested and recorded.
- **[Issues](https://github.com/arturormk/curaflow/issues)**: bug reports
  and sites or formats that should be supported but aren't.

Curaflow is MIT licensed. It was written with AI assistance and is curated
by a human maintainer, as its README explains. Its Python dependencies and
the external tools used by `media_convert` are separate projects under
their own licences.
