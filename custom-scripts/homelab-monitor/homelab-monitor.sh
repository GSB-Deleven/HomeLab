#!/bin/bash

# Konfigurationsdatei für das Skript
CONFIG_FILE="/root/homelab-monitor.cfg"
ENV_FILE="$GITHUB_REPO/custom-scripts/.env"
# Wenn die Konfigurationsdatei existiert, lade sie
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

# Definition des Remote-Hosts und des Pfads zum Skript auf dem Remote-Host
REMOTE_HOST="$REMOTE_HOST"
REMOTE_SCRIPT_PATH="$GITHUB_REPO/custom-scripts/homelab-monitor/homelab-monitor.sh"
# Benutzername für SSH-Verbindung
SSH_USER="$SSH_USER"

# Überprüfen, ob das Skript im manuellen Modus ausgeführt wird
if [[ "$1" == "--manual" ]]; then
    IS_REMOTE_EXECUTION=1  # Indikator für Remote-Ausführung
    IS_MANUAL_MODE=1       # Indikator für manuellen Modus
fi

# Wenn das Skript nicht im Remote-Modus ausgeführt wird
if [[ "$IS_REMOTE_EXECUTION" != "1" ]]; then
    # Kopiere das Skript auf den Remote-Host
    scp "$0" "$SSH_USER@$REMOTE_HOST:$REMOTE_SCRIPT_PATH" >/dev/null
    # Führe das Skript auf dem Remote-Host aus und übergebe die Umgebungsvariablen
    ssh "$SSH_USER@$REMOTE_HOST" IS_REMOTE_EXECUTION=1 IS_MANUAL_MODE="$IS_MANUAL_MODE" bash "$REMOTE_SCRIPT_PATH" "$@"
    exit 0  # Beende das Skript nach der Remote-Ausführung
fi

# Initialisiere eine leere JSON-Ausgabe
JSON_OUTPUT="{}"
# Funktion zum Hinzufügen von Schlüssel-Wert-Paaren zur JSON-Ausgabe
append_json() {
    local key="$1"   # Schlüssel für das JSON-Objekt
    local value="$2" # Wert für das JSON-Objekt
    JSON_OUTPUT=$(jq --arg k "$key" --arg v "$value" '. + {($k): $v}' <<< "$JSON_OUTPUT")  # Füge das Paar zur JSON-Ausgabe hinzu
}

# Funktion zur Ermittlung der menschlich lesbaren Systemlast
get_human_load() {
    load_avg=$(awk '{print $1}' /proc/loadavg)  # Lade den Durchschnitt der Systemlast
    cpu_cores=$(nproc)                           # Zähle die CPU-Kerne
    load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_avg / $cpu_cores) * 100}")  # Berechne den Prozentsatz der Last
    echo "$load_avg ($load_percent%) von $cpu_cores"  # Gebe die Last und die Anzahl der Kerne aus
}

# Füge Informationen zur Systemauslastung zur JSON-Ausgabe hinzu
append_json "uptime" "$(uptime -p)"  # Systemlaufzeit
append_json "load" "$(get_human_load)"  # Systemlast

# Host-RAM-Auslastung via SSH ermitteln
host_mem=$(ssh "$SSH_USER@$REMOTE_HOST" "awk '/MemTotal/ {t=\$2} /MemAvailable/ {a=\$2} END {print t, t-a}' /proc/meminfo")
total=$(echo "$host_mem" | awk '{print int($1/1024)}')  # Gesamt-RAM in MB
used=$(echo "$host_mem" | awk '{print int($2/1024)}')   # Genutztes RAM in MB

# Füge die RAM-Auslastung zur JSON-Ausgabe hinzu
append_json "ram" "${used} MB / ${total} MB"

# Füge die Festplattenspeicherung zur JSON-Ausgabe hinzu
append_json "disk" "$(df -h / | awk 'END{print $3 " / " $2 " (" $5 ")"}')"
# Füge die Temperatur zur JSON-Ausgabe hinzu
append_json "temp" "$(command -v sensors &> /dev/null && sensors | grep -m 1 'Package id 0:' | awk '{print $4}' || echo "nicht verfügbar")"
# Füge die öffentliche IP-Adresse zur JSON-Ausgabe hinzu
append_json "ip" "$(curl -s $PUBLIC_IP_URL)"
# Füge den Ping-Status zur JSON-Ausgabe hinzu
append_json "ping" "$(ping -c 2 1.1.1.1 > /dev/null && echo "✅ OK" || echo "❌ FAIL")"
# Füge die letzten Logins zur JSON-Ausgabe hinzu
append_json "logins" "$(last -n 2 | grep -v 'wtmp begins' | grep -v 'still logged in' | paste -sd ';' -)"
# Füge die Anzahl der verbundenen Geräte zur JSON-Ausgabe hinzu
append_json "devices" "$(ip neigh | grep -v 'FAILED' | wc -l)"
# Überprüfen, ob das Backup-Skript läuft
if pgrep -f "$BACKUP_SCRIPT_NAME" > /dev/null; then
    start_time=$(ps -eo pid,lstart,cmd | grep "$BACKUP_SCRIPT_NAME" | grep -v grep | head -n 1 | tr -s ' ' | cut -d' ' -f2-6 | tr '\n' ' ')
    # Füge den Status des Backups zur JSON-Ausgabe hinzu
    append_json "backup" "🟢 Läuft seit: $start_time"
else
    # Füge an, dass kein Backup läuft
    append_json "backup" "🔴 Kein laufendes Backup."
fi
# Überprüfen, ob Updates verfügbar sind
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
# Füge die Anzahl der verfügbaren Updates zur JSON-Ausgabe hinzu
append_json "updates" "🔔 $updates Updates verfügbar"
# Füge die letzten Fehlerprotokolle zur JSON-Ausgabe hinzu
syslog_errors=$(journalctl -p 3 -xb | tail -n 3 | tr '\n' ';')
append_json "logs" "$syslog_errors"
# Überprüfen, ob VSCode-Server aktiv ist
vscode_status=$(pgrep -f ".vscode-server" > /dev/null && echo "🟢 aktiv" || echo "🔴 nicht aktiv")

# Überwachung der CPU-Last
cpu_cores=$(nproc)  # Zähle die CPU-Kerne
load_avg=$(awk '{print $1}' /proc/loadavg)  # Lade den 1-Minuten-Load
load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_avg / $cpu_cores) * 100}")  # Berechne den Prozentsatz

# Wenn das Skript im manuellen Modus ausgeführt wird, gebe die JSON-Ausgabe aus
if [[ "$IS_MANUAL_MODE" == "1" ]]; then
  echo "$JSON_OUTPUT"
  exit 0  # Beende das Skript nach der Ausgabe
fi
