# arturormk.github.io

Source of <https://arturormk.github.io>: a home page listing my public
projects, plus a friendly overview page for some of them.

GitHub Pages builds the site with Jekyll on every push to `main`; there is
no build step to run and no generated files to commit.

## Layout

| Path | What it is |
| --- | --- |
| `_data/projects.yml` | the project list shown on the home page |
| `index.html` | home page |
| `projects/<repo>/index.md` | a project's overview page (layout `project`) |
| `_layouts/`, `_includes/` | page templates |
| `assets/css/style.css` | the only stylesheet (plain CSS) |

## Adding a project page

1. Create `projects/<repo>/index.md` with `layout: project` and the front
   matter used in `projects/replant/index.md` (`repo`, `tagline`, `lede`,
   `facts`, …).
2. Add `page: /projects/<repo>/` to the project's entry in
   `_data/projects.yml`.

A project without a `page` still appears on the home page and links straight
to its GitHub repository.

## Previewing locally

```bash
./preview.sh              # serves http://localhost:4000 with live reload, opens a browser
./preview.sh --no-open    # serve only; PORT=4001 ./preview.sh for another port
```

It uses `bundle exec jekyll serve` if Ruby and the `github-pages` gem are
installed (`bundle install`, which needs `ruby-dev`), and Docker otherwise.
The first Docker run downloads the gems (about half a minute); they are
cached in the Docker volume `site-preview-gems`. The script is excluded from
the published site in `_config.yml`.
