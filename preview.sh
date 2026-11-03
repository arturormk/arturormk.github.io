#!/usr/bin/env bash
# Preview the site locally with live reload, the way GitHub Pages builds it.
#
#   ./preview.sh              serve on http://localhost:4000 and open a browser
#   ./preview.sh --no-open    serve only
#   PORT=4001 ./preview.sh    another port
#
# Uses a local `bundle` if the github-pages gem is installed, otherwise Docker
# (image ruby:3.3, gems cached in the Docker volume "site-preview-gems").
# Stop with Ctrl-C.

set -euo pipefail

PORT="${PORT:-4000}"
LIVERELOAD_PORT="${LIVERELOAD_PORT:-35729}"
URL="http://localhost:${PORT}/"
OPEN=1

for arg in "$@"; do
    case "$arg" in
        --no-open) OPEN=0 ;;
        -h|--help) sed -n '2,10s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *) echo "preview.sh: unknown option: $arg" >&2; exit 2 ;;
    esac
done

cd "$(dirname "$(readlink -f "$0")")"

JEKYLL_ARGS=(serve --host 0.0.0.0 --port "$PORT" --livereload --livereload-port "$LIVERELOAD_PORT")

if command -v bundle >/dev/null && bundle check >/dev/null 2>&1; then
    server=(bundle exec jekyll "${JEKYLL_ARGS[@]}")
elif command -v docker >/dev/null; then
    volume=site-preview-gems
    if ! docker volume inspect "$volume" >/dev/null 2>&1; then
        docker volume create "$volume" >/dev/null
        # Let the unprivileged container user install gems into the volume.
        docker run --rm -v "$volume":/gems ruby:3.3 chown "$(id -u):$(id -g)" /gems
    fi
    server=(docker run --rm --init
        --user "$(id -u):$(id -g)" -e HOME=/tmp -e BUNDLE_PATH=/gems
        -v "$volume":/gems -v "$PWD":/site -w /site
        -p "127.0.0.1:${PORT}:${PORT}" -p "127.0.0.1:${LIVERELOAD_PORT}:${LIVERELOAD_PORT}"
        ruby:3.3
        sh -c "bundle install --quiet && exec bundle exec jekyll ${JEKYLL_ARGS[*]}")
else
    echo "preview.sh: needs either Docker or Ruby with 'bundle install' done." >&2
    exit 1
fi

if [[ $OPEN == 1 ]]; then
    # Open the browser once the server answers (first run installs gems: slow).
    (
        for _ in $(seq 300); do
            if curl -fsS -o /dev/null "$URL" 2>/dev/null; then
                xdg-open "$URL" >/dev/null 2>&1 || echo "Open $URL in your browser."
                exit 0
            fi
            sleep 1
        done
    ) &
    trap 'kill $! 2>/dev/null || true' EXIT
fi

echo "Serving $URL (Ctrl-C to stop)"
"${server[@]}"
