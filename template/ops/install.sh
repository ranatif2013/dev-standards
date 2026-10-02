#!/usr/bin/env bash
# Install the Rana health check on a server (machine03 / machine02). Safe to re-run. Needs sudo.
# usage: sudo ./install.sh <host-config>      e.g. ./install.sh machine03   (uses ops/<host>/health.conf)
set -euo pipefail
HOSTCONF="${1:?usage: install.sh <machine03|machine02>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
install -d /opt/rana-ops/bin /etc/rana-ops /var/lib/rana-ops
install -m 755 "$HERE/bin/rana-health.sh" /opt/rana-ops/bin/rana-health.sh
[ -f /etc/rana-ops/health.conf ] && cp /etc/rana-ops/health.conf /etc/rana-ops/health.conf.prev || true
install -m 644 "$HERE/$HOSTCONF/health.conf" /etc/rana-ops/health.conf
[ -f /etc/rana-ops/alert.env ] || install -m 600 "$HERE/alert.env.example" /etc/rana-ops/alert.env   # secrets stay on the server, never in git
install -m 644 "$HERE/systemd/rana-healthcheck.service" "$HERE/systemd/rana-healthcheck.timer" /etc/systemd/system/
ln -sf /opt/rana-ops/bin/rana-health.sh /usr/local/bin/rana-health
systemctl daemon-reload
systemctl enable --now rana-healthcheck.timer
echo "Installed. Latest result:  rana-health --now     History: tail -f /var/log/rana-health.log     Timer: systemctl list-timers rana-healthcheck.timer"
