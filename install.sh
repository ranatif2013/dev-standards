#!/usr/bin/env bash
# Install ops tools on a server (run from a checkout of dev-standards). Safe to re-run.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/ops/bin" "$HOME/ops/projects" "$HOME/projects"
cp "$SRC"/bin/* "$HOME/ops/bin/"; chmod +x "$HOME/ops/bin/"*
rm -rf "$HOME/ops/template"; cp -a "$SRC/template" "$HOME/ops/template"
cp -a "$SRC/agents/." "$HOME/ops/" 2>/dev/null || true   # agent instructions, e.g. ~/ops/NEXORA.md
grep -q 'ops/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/ops/bin:$PATH"' >> "$HOME/.bashrc"
echo "ops tools installed in ~/ops/bin. Run: source ~/.bashrc"
