#!/bin/bash

# === Konfiguration ===
source "$(dirname "$0")/../.env"
# Erwartete Variablen aus .env:
# MNT_PHOTO, MNT_PROXMOX, MNT_PROXMOX_BACKUPS, MNT_DOCKER, MNT_HOMES_USER, MNT_NEXTCLOUD, MNT_BACKUP_TARGET
# DST_* Gegenstücke entsprechend (z. B. DST_PHOTO)
logdir="/var/log/rclone-backups"
log_retention_days=30
inactivity_timeout=300
discord_webhook="$DISCORD_WEBHOOK"
dryrun_flag=0

# === Initialisierung ===
mkdir -p "$logdir"
total_errors=0
summary_md=""
start_time=$(date '+%Y-%m-%d %H:%M:%S')
total_start=$(date +%s)

# === Discord-Funktion ===
send_discord_msg() {
  local content="$1"
  jq -n --arg msg "$content" '{content: $msg}' | \
    curl -s -H "Content-Type: application/json" -X POST -d @- "$discord_webhook" > /dev/null
}

send_discord_msg "🛡️ **Backup gestartet** um: $start_time"

# === Mount-Prüfung ===
check_mounts=(
  "$MNT_PHOTO"
  "$MNT_PROXMOX"
  "$MNT_PROXMOX_BACKUPS"
  "$MNT_DOCKER"
  "$MNT_HOMES_USER"
  "$MNT_NEXTCLOUD"
  "$MNT_BACKUP_TARGET"
)

error_flag=0
for mount in "${check_mounts[@]}"; do
  if mountpoint -q "$mount"; then
    echo "✅ Mount aktiv: $mount"
  else
    echo "❌ MOUNT FEHLT: $mount"
    error_flag=1
  fi
done

if [ $error_flag -ne 0 ]; then
  send_discord_msg "❌ **Backup abgebrochen** – Mindestens ein Mount fehlt."
  exit 1
fi

# === Backup-Funktion ===
backup() {
  local name="$1"
  local source="$2"
  local target="$3"
  local mode="$4" # "rsync" oder "rclone"

  local logfile="$logdir/backup_${name}_$(date '+%Y-%m-%d_%H-%M-%S').log"
  local start_ts=$(date +%s)

  send_discord_msg "📁 Starte Backup: \`$name\`"
  echo -e "\n📂 Starte Backup $name ($mode): $source → $target"
  echo -e "📄 Logfile: $logfile"

  touch "$logfile"

  if [[ "$mode" == "rsync" ]]; then
    rsync -av --delete --stats "$source/" "$target/" >> "$logfile" 2>&1 &
  else
    local opts="--create-empty-src-dirs --skip-links"
    [ $dryrun_flag -eq 1 ] && opts="$opts --dry-run"

    rclone sync $opts \
      "$source" "$target" \
      --stats=5s --stats-one-line --stats-log-level INFO \
      --log-file="$logfile" --log-level=INFO >> "$logfile" 2>&1 &
  fi

  local pid=$!

  # === Watchdog-Prozess ===
  (
    last_size=$(stat -c%s "$logfile")
    idle=0
    while sleep 5; do
      current_size=$(stat -c%s "$logfile")
      if [ "$current_size" -eq "$last_size" ]; then
        idle=$((idle + 5))
        if [ "$idle" -ge "$inactivity_timeout" ]; then
          echo "⏰ Inaktivität erkannt bei $name – abbrechen..."
          kill -TERM "$pid" 2>/dev/null
          exit
        fi
      else
        idle=0
        last_size=$current_size
      fi
    done
  ) &
  local watchdog_pid=$!

  wait "$pid"
  local exit_code=$?
  kill "$watchdog_pid" 2>/dev/null

  local end_ts=$(date +%s)
  local runtime=$((end_ts - start_ts))

  if [ $exit_code -eq 143 ]; then
    send_discord_msg "⏰ \`$name\` **abgebrochen** – keine Aktivität seit ${inactivity_timeout}s"
    summary_md+="- ⏰ \`$name\`: Inaktivität\n"
    total_errors=$((total_errors+1))
  elif grep -q "ERROR" "$logfile"; then
    send_discord_msg "❌ Fehler bei \`$name\` – siehe Logfile: \`$logfile\`"
    summary_md+="- ❌ \`$name\`: Fehler – siehe Log\n"
    total_errors=$((total_errors+1))
  else
    size=$(grep -i "Transferred:" "$logfile" | tail -n1 | sed 's/^.*Transferred: *//' || echo "0 B")
    [ -z "$size" ] && size="0 B"
    if [[ "$size" == "0 B" ]]; then
      send_discord_msg "ℹ️ \`$name\`: nichts zu tun – keine Daten übertragen"
      summary_md+="- ℹ️ \`$name\`: nichts zu tun\n"
    else
      send_discord_msg "✅ \`$name\` abgeschlossen – ⏱ ${runtime}s, 📀 $size"
      summary_md+="- ✅ \`$name\`: ${runtime}s, $size\n"
    fi
  fi
}

# === Backups ausführen ===

backup "photo"            "$MNT_PHOTO"            "$MNT_BACKUP_TARGET/photo"            "rclone"
backup "proxmox"          "/mnt/ds920/proxmox/dump"     "$MNT_BACKUP_TARGET/proxmox"          "rsync"
backup "proxmox_backups"  "/mnt/ds920/proxmox_backups"  "$MNT_BACKUP_TARGET/proxmox_backups"  "rsync"
backup "docker"           "$MNT_DOCKER"           "$MNT_BACKUP_TARGET/docker"           "rclone"
backup "homes_user"       "$MNT_HOMES_USER"       "$DST_HOMES_USER"                     "rclone"
backup "nextcloud"        "$MNT_NEXTCLOUD"        "$MNT_BACKUP_TARGET/nextcloud"        "rclone"

# === Aufräumen ===
find "$MNT_BACKUP_TARGET" -type d -name "*.tmp" -exec rm -rf {} +
find "$logdir" -type f -name "*.log" -mtime +$log_retention_days -exec rm -f {} \;

# === Abschluss & Zusammenfassung ===
total_end=$(date +%s)
total_runtime=$((total_end - total_start))
end_time=$(date '+%Y-%m-%d %H:%M:%S')

send_discord_msg "📊 **Backup abgeschlossen**\n🕒 **Dauer:** ${total_runtime}s\n📂 **Zusammenfassung:**\n$summary_md"

echo -e "\n========================================="
echo -e "✅ Backup abgeschlossen um: $end_time"
echo -e "📁 Logs: $logdir"
echo -e "📊 Zusammenfassung:\n$summary_md"
echo -e "========================================="
