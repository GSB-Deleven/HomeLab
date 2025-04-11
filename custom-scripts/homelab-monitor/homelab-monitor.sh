#!/bin/bash

ENV_FILE="$GITHUB_REPO/custom-scripts/.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
BOT_DIR="${GIT_REPO_PATH}/custom-scripts/discord-bot"
BACKUP_SCRIPT_PATH="${GIT_REPO_PATH}/custom-scripts/ds920/ds920_backup.sh"

REMOTE_HOST="$REMOTE_HOST"
REMOTE_SCRIPT_PATH="${GIT_REPO_PATH}/custom-scripts/homelab-monitor/homelab-monitor.sh"
SSH_USER="$SSH_USER"

if [[ "$1" == "--manual" ]]; then
    IS_REMOTE_EXECUTION=1
    IS_MANUAL_MODE=1
fi

if [[ "$IS_REMOTE_EXECUTION" != "1" ]]; then
    ssh "$SSH_USER@$REMOTE_HOST" IS_REMOTE_EXECUTION=1 IS_MANUAL_MODE="$IS_MANUAL_MODE" bash "$REMOTE_SCRIPT_PATH" "$@"
    exit 0
fi

JSON_OUTPUT="{}"
append_json() {
    local key="$1"
    local value="$2"
    JSON_OUTPUT=$(jq --arg k "$key" --arg v "$value" '. + {($k): $v}' <<< "$JSON_OUTPUT")
}

get_human_load() {
    load_avg=$(awk '{print $1}' /proc/loadavg)
    cpu_cores=$(nproc)
    load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_avg / $cpu_cores) * 100}")
    echo "$load_avg ($load_percent%) von $cpu_cores"
}

append_json "uptime" "$(uptime -p)"
append_json "load" "$(get_human_load)"

host_mem=$(ssh "$SSH_USER@$REMOTE_HOST" "awk '/MemTotal/ {t=\$2} /MemAvailable/ {a=\$2} END {print t, t-a}' /proc/meminfo")
total=$(echo "$host_mem" | awk '{print int($1/1024)}')
used=$(echo "$host_mem" | awk '{print int($2/1024)}')

append_json "ram" "${used} MB / ${total} MB"
append_json "disk" "$(df -h / | awk 'END{print $3 " / " $2 " (" $5 ")"}')"
append_json "temp" "$(command -v sensors &> /dev/null && sensors | grep -m 1 'Package id 0:' | awk '{print $4}' || echo "nicht verfügbar")"
append_json "ip" "$(curl -s $PUBLIC_IP_URL)"
append_json "ping" "$(ping -c 2 1.1.1.1 > /dev/null && echo "✅ OK" || echo "❌ FAIL")"
append_json "logins" "$(last -n 2 | grep -v 'wtmp begins' | grep -v 'still logged in' | paste -sd ';' -)"
append_json "devices" "$(ip neigh | grep -v 'FAILED' | wc -l)"
if pgrep -f "$BACKUP_SCRIPT_NAME" > /dev/null; then
    start_time=$(ps -eo pid,lstart,cmd | grep "$BACKUP_SCRIPT_NAME" | grep -v grep | head -n 1 | tr -s ' ' | cut -d' ' -f2-6 | tr '\n' ' ')
    append_json "backup" "🟢 Läuft seit: $start_time"
else
    append_json "backup" "🔴 Kein laufendes Backup."
fi
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
append_json "updates" "🔔 $updates Updates verfügbar"
syslog_errors=$(journalctl -p 3 -xb | tail -n 3 | tr '\n' ';')
append_json "logs" "$syslog_errors"
vscode_status=$(pgrep -f ".vscode-server" > /dev/null && echo "🟢 aktiv" || echo "🔴 nicht aktiv")

cpu_cores=$(nproc)
load_avg=$(awk '{print $1}' /proc/loadavg)
load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_avg / $cpu_cores) * 100}")

if [[ "$IS_MANUAL_MODE" == "1" ]]; then
  echo "$JSON_OUTPUT"
  exit 0
fi
