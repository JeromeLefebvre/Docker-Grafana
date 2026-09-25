#!/usr/bin/env bash
# Copy Homebrew Grafana state into ./grafana-data for the container.
# Run from this folder on the Mac:  ./migrate-from-homebrew.sh
set -euo pipefail

SRC="${SRC:-/opt/homebrew/var/lib/grafana}"
DEST="./grafana-data"

echo "Homebrew Grafana version: $(brew list --versions grafana || echo unknown)"
echo "Make sure GRAFANA_VERSION in docker-compose.yml is >= that version."

# Stop the native service so grafana.db is consistent and DuckDB files
# aren't locked by two Grafana instances at once.
brew services stop grafana || true
sleep 2

mkdir -p "$DEST"
# plugins/ is skipped on purpose: it holds macOS (darwin) binaries.
# The image ships the Linux DuckDB plugin; Grafana re-installs its own core plugins.
rsync -a --exclude 'plugins/' --exclude '.DS_Store' "$SRC/" "$DEST/"

echo "Copied to $DEST:"
ls -la "$DEST"
echo
echo "Next: docker compose up -d --build   then open http://localhost:3000"