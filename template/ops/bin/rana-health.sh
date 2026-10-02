#!/usr/bin/env bash
# rana-health: checks that every service this server must run is UP. Runs 2 min after boot, then every 10 min (systemd timer).
# Writes: /var/log/rana-health.log (history), /var/lib/rana-ops/status.txt (latest table).
# Alerts (only on change, and a reminder every 6 h while still down): Telegram if /etc/rana-ops/alert.env has TELEGRAM_BOT_TOKEN +
# TELEGRAM_CHAT_ID; e-mail if ALERT_EMAIL is set and `mail` exists. Until then the log file is the alert.
# Config: /etc/rana-ops/health.conf  (SYSTEMD_SERVICES, DOCKER_CONTAINERS, HTTP_CHECKS, CHECK_GPU, CERT_WARN_DAYS, DISK_WARN_PCT)
# Usage: rana-health.sh [--now]   (--now = print the table, same checks)
set -uo pipefail

CONF=/etc/rana-ops/health.conf
ENVF=/etc/rana-ops/alert.env
LOG=/var/log/rana-health.log
STATE_DIR=/var/lib/rana-ops
STATUS=$STATE_DIR/status.txt
PREV=$STATE_DIR/down.prev
NOW_MODE=0; [ "${1:-}" = "--now" ] && NOW_MODE=1     # --now = read-only table (works without sudo, writes/alerts nothing)
if [ "$NOW_MODE" = 0 ]; then mkdir -p "$STATE_DIR"; touch "$LOG"; fi

SYSTEMD_SERVICES=""; DOCKER_CONTAINERS=""; HTTP_CHECKS=""; CHECK_GPU=1; CERT_WARN_DAYS=14; DISK_WARN_PCT=90
[ -f "$CONF" ] && . "$CONF"
[ -r "$ENVF" ] && . "$ENVF"
HOST=$(hostname)
NOW=$(date '+%Y-%m-%d %H:%M:%S')
rows=(); down=()

add() { # name status detail
  rows+=("$(printf '%-34s %-5s %s' "$1" "$2" "$3")")
  [ "$2" = "DOWN" ] && down+=("$1: $3")
}

for s in $SYSTEMD_SERVICES; do
  st=$(systemctl is-active "$s" 2>&1)
  if [ "$st" = "active" ]; then add "service:$s" UP ""; else add "service:$s" DOWN "state=$st"; fi
done

if [ -n "$DOCKER_CONTAINERS" ]; then
  running=$(docker ps --format '{{.Names}}' 2>/dev/null)
  for c in $DOCKER_CONTAINERS; do
    if echo "$running" | grep -qx "$c"; then
      h=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$c" 2>/dev/null)
      if [ "$h" = "unhealthy" ]; then add "container:$c" DOWN "unhealthy"; else add "container:$c" UP "$h"; fi
    else
      add "container:$c" DOWN "not running"
    fi
  done
fi

for hc in $HTTP_CHECKS; do   # name|url|ok-codes(comma)
  IFS='|' read -r n u ok <<<"$hc"
  code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "$u" 2>/dev/null)
  if echo ",$ok," | grep -q ",$code,"; then add "http:$n" UP "$code"; else add "http:$n" DOWN "got $code, expected $ok"; fi
done

if [ "$CHECK_GPU" = "1" ]; then
  if out=$(nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>&1); then add "gpu" UP "$out"; else add "gpu" DOWN "$(echo "$out" | head -1)"; fi
fi

for pem in /etc/letsencrypt/live/*/cert.pem; do
  [ -f "$pem" ] || continue
  end=$(openssl x509 -enddate -noout -in "$pem" 2>/dev/null | cut -d= -f2)
  [ -z "$end" ] && continue
  days=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
  name=$(basename "$(dirname "$pem")")
  if [ "$days" -lt "$CERT_WARN_DAYS" ]; then add "cert:$name" DOWN "expires in $days days"; else add "cert:$name" UP "$days days left"; fi
done

pct=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if [ "${pct:-0}" -ge "$DISK_WARN_PCT" ]; then add "disk:/" DOWN "${pct}% used"; else add "disk:/" UP "${pct}% used"; fi

TMPF=$(mktemp)
{ echo "rana-health $HOST $NOW  (UP=$(( ${#rows[@]} - ${#down[@]} )) checks, DOWN=${#down[@]})"; printf '%s\n' "${rows[@]}"; } > "$TMPF"
if [ "$NOW_MODE" = 1 ]; then cat "$TMPF"; rm -f "$TMPF"; exit 0; fi
install -m 644 "$TMPF" "$STATUS"; rm -f "$TMPF"

if [ "${#down[@]}" -eq 0 ]; then echo "$NOW OK all ${#rows[@]} checks up" >> "$LOG"; else
  for d in "${down[@]}"; do echo "$NOW DOWN $d" >> "$LOG"; done
fi

# ---- alerts: only when the set of DOWN items changes, or every 6 h while still down
cur=$(printf '%s\n' "${down[@]}" | sed 's/: .*//' | sort | tr '\n' ',')
prev=$( [ -f "$PREV" ] && head -1 "$PREV" || echo "" )
stamp=$( [ -f "$PREV" ] && sed -n 2p "$PREV" || echo 0 )
now_s=$(date +%s)
send() {
  msg="[$HOST] $1"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -s -m 15 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=$msg" >/dev/null || echo "$NOW telegram send failed" >> "$LOG"
  fi
  if [ -n "${ALERT_EMAIL:-}" ] && command -v mail >/dev/null 2>&1; then echo "$msg" | mail -s "[$HOST] health alert" "$ALERT_EMAIL" || true; fi
  echo "$NOW ALERT $1" >> "$LOG"
}
if [ "$cur" != "$prev" ] || { [ -n "$cur" ] && [ $((now_s - stamp)) -ge 21600 ]; }; then
  if [ -n "$cur" ]; then send "DOWN: $(printf '%s; ' "${down[@]}")"; elif [ -n "$prev" ]; then send "RECOVERED: all checks up again"; fi
  printf '%s\n%s\n' "$cur" "$now_s" > "$PREV"
fi
exit 0
