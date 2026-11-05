---
layout: project
title: TypeSketch
repo: typesketch-python
eyebrow: JSON · API exploration · command line · Python
tagline: Pipe in a JSON payload. Get back the shape of it.
lede: >-
  TypeSketch is a tiny command-line tool that reads JSON and prints a short,
  type-oriented YAML summary of it: every field, its type, and hints such as
  url, email or datetime. It is for anyone poking at an unfamiliar API who
  wants a readable sketch of the data, not a full schema.
description: >-
  TypeSketch is a small Python CLI that reads JSON on stdin and infers a
  concise, type-oriented YAML sketch of its structure.
facts:
  - Reads JSON on stdin, writes YAML to stdout
  - Merges many records into one shape
  - Spots urls, emails, datetimes and HTML
  - No dependencies beyond the Python standard library
  - MIT licensed
---

## The problem

You are working with an API you didn't write. You call it with `curl` and get
back a few hundred lines of JSON: a list of records, each with nested
objects, some optional fields, and values whose type you can only guess at by
reading examples. You want to document it, or write the code that consumes
it, and first you need to know what is actually in there.

Scrolling through the raw response doesn't scale, and writing a JSON Schema
by hand is far more than you need just to get your bearings. TypeSketch sits
in between: it reads the example data itself and tells you what it found, in
a format short enough to paste into your notes.

<div class="compare">
  <div>
    <h3>Reading the raw JSON</h3>
    <p>You scroll through every record, trying to spot which fields are
    optional, which ones are sometimes a number and sometimes a string, and
    what that long text field really holds.</p>
  </div>
  <div class="good">
    <h3>Sketching it</h3>
    <p>One pipe gives you every field once, in YAML, with its type, the
    unions it takes across records, and hints like <code>url</code> or
    <code>datetime</code>.</p>
  </div>
</div>

## How it works

TypeSketch looks at every record in the input (up to 200 array items by
default) and merges them into a single shape. Fields seen in more records
come first; fields that only appear now and then sink towards the end.
Values that change type between records become unions such as
`int | number`, and strings are checked for a few common formats.

Given a file with two orders like these:

```json
[
  {"id": 101, "total": 24.5, "paid": true,
   "customer": {"name": "Ana", "email": "ana@example.com"},
   "items": [{"sku": "A-1", "qty": 2}],
   "created": "2025-03-01T09:30:00Z"},
  {"id": 102, "total": 8, "paid": false, "coupon": null,
   "customer": {"name": "Ben", "email": "ben@example.com"},
   "items": [{"sku": "B-7", "qty": 1}],
   "created": "2025-03-02T14:05:00Z",
   "receipt": "https://shop.example.com/r/102"}
]
```

`typesketch --root orders < orders.json` prints:

```yaml
orders:
  -
    created: datetime
    customer:
      email: email
      name: string
    id: int
    items:
      -
        qty: int
        sku: string
    paid: boolean
    total: int | number
    coupon: null
    receipt: url
```

The two fields that only one order has, `coupon` and `receipt`, come last.
Add `--stats` and they say so: `coupon: null  # present in 1 of 2`.

## Small on purpose

<div class="features">
  <div>
    <h3>Fits in any pipeline</h3>
    <p>JSON goes in on stdin and valid YAML comes out on stdout, so it works
    straight after <code>curl</code>, <code>cat</code> or <code>jq</code>.
    Bad input gets a one-line error, not a traceback.</p>
  </div>
  <div>
    <h3>One shape, not many examples</h3>
    <p>A list of records is merged into a single sketch, with fields ordered
    by how often they appear and alphabetically after that.</p>
  </div>
  <div>
    <h3>Format hints for free</h3>
    <p>Strings that look like a <code>url</code>, <code>email</code>,
    <code>datetime</code> or <code>html-string</code> are labelled as such,
    so you see more than just "string".</p>
  </div>
  <div>
    <h3>Nothing gets lost</h3>
    <p>A field that is an object in one record and <code>null</code> in
    another keeps its shape and says <code># also: null</code>. Mixed and
    nested arrays are sketched in full.</p>
  </div>
  <div>
    <h3>Nothing to install around it</h3>
    <p>It uses only the Python standard library, so you can even run it
    straight from a clone without installing anything.</p>
  </div>
  <div>
    <h3>Optional fields at a glance</h3>
    <p>With <code>--stats</code>, every field missing from some records
    tells you how many had it, so you know what you can rely on.</p>
  </div>
</div>

## What it supports today

TypeSketch is at version 0.2.0 and deliberately keeps its scope small: it is a tool for exploring and documenting data, not a
validator.

- Python 3.9 or newer, with no other dependencies
- One JSON document on stdin: an object, a list of objects or a list of
  values
- Types `int`, `number`, `boolean`, `null` and `string`, plus the hints
  `url`, `email`, `datetime` and `html-string`
- Options for a root key (`--root`), treating a single object as a list
  (`--force-list`), how many array items to sample (`--array-samples`),
  the indent width (`--indent`) and presence counts (`--stats`)

It isn't published on PyPI; you install it from a clone of the repository.
The `# also:` and `--stats` notes are YAML comments, so a program that loads
the sketch sees only the shapes, and the counts describe your sample, not
what the API promises. The roadmap lists JSON Schema and OpenAPI output, a
Markdown renderer for docs sites, pluggable detectors and a streaming mode
for very large inputs.

## Get started

### 1. Try it without installing

All you need is Python 3 and `curl`. The repository's own example uses
Open Library's free search API:

```bash
git clone https://github.com/arturormk/typesketch-python.git
cd typesketch-python/src

# Sketch the search results for five books
curl -s 'https://openlibrary.org/search.json?q=python&limit=5' \
  | python3 -m typesketch.cli
```

### 2. Install the command

From the root of the clone, with [pipx](https://pipx.pypa.io/) or `pip`:

```bash
cd typesketch-python
pipx install .
typesketch --version
```

### 3. Use it on your own data

```bash
# Sketch a saved response
typesketch < response.json

# Wrap the result under a name for your notes
typesketch --root Shops < shops.json

# Treat a single object as a one-item list
typesketch --force-list < item.json

# Show which fields are missing from some records
typesketch --stats < response.json
```

`typesketch --help` lists every option.

## Learn more

- **[README](https://github.com/arturormk/typesketch-python/blob/main/README.md)**:
  features, CLI examples and the roadmap.
- **[Design records](https://github.com/arturormk/typesketch-python/tree/main/docs/adr)**:
  the decisions behind the name, the scope and the
  [inference heuristics](https://github.com/arturormk/typesketch-python/blob/main/docs/adr/ADR-0003-heuristics.md).
- **[Examples](https://github.com/arturormk/typesketch-python/tree/main/examples)**:
  ready-to-run scripts for the Open Library API and a local sample file.
- **[Issues](https://github.com/arturormk/typesketch-python/issues)**: bug
  reports and ideas for new format detectors.

TypeSketch is MIT licensed. It is developed with AI assistance and curated by
a human maintainer, as described in its
[curation policy](https://github.com/arturormk/typesketch-python/blob/main/docs/adr/ADR-0010-ai-curation-policy.md).
