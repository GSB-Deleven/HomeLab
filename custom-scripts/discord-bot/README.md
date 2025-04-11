### 📘 Dokumentation: HomeLab Discord Bot mit Slash-Commands

Diese Anleitung beschreibt **idiotensicher Schritt für Schritt**, wie du einen Discord-Bot aufsetzt, der Systemstatusdaten deines `${MONITOR_HOST}` via `/serverstatus` in einem hübschen Discord-Embed anzeigt.


---

## 🧾 Übersicht der beteiligten Geräte und Rollen

| Gerät | Rolle |
|----|----|
| **Debian Bot-Host** | Führt `${BOT_DIR}/bot.py` aus, enthält den Discord-Bot |
| **NAB6** | Führt `${MONITOR_SCRIPT}` aus (per SSH) |


---

## 🔧 1. Vorbereitung am **Debian Bot-Host**

### 1.1 Verzeichnis anlegen

```bash
mkdir -p ${BOT_DIR}
cd ${BOT_DIR}
```

### 1.2 Python und Pakete installieren (falls noch nicht vorhanden)

```bash
apt update && apt install -y python3 python3-pip jq
pip install -U discord.py python-dotenv
```

### 1.3 .env-Datei erstellen

```bash
nano /root/homelab/.env
```

Inhalt (ersetzen mit echten Werten):

```
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
DISCORD_GUILD_ID=${DISCORD_GUILD_ID}
MONITOR_HOST=${MONITOR_HOST}
```


---

## 🧠 2. Monitoring-Skript `${MONITOR_SCRIPT}` erstellen auf dem **Bot-Host**

→ Dieses wird automatisch auf **NAB6** kopiert und dort ausgeführt.

```bash
nano ${MONITOR_SCRIPT}
```

➡️ Inhalt siehe vollständiges Skript unter Abschnitt **[homelab-monitor.sh]()** weiter unten.


:::info
Wichtig: Datei ausführbar machen:

```bash
chmod +x ${MONITOR_SCRIPT}
```

:::


---

## 🤖 3. Discord-Bot `${BOT_DIR}/bot.py` auf dem **Bot-Host** erstellen

```bash
nano ${BOT_DIR}/bot.py
```

➡️ Inhalt siehe vollständiges Skript unter Abschnitt **[bot.py]()** weiter unten.


:::info
Wichtig: Datei ausführbar machen:

```bash
chmod +x ${BOT_DIR}/bot.py
```

:::


---

## 🛠️ 4. Bot als systemd-Service einrichten (auf dem **Bot-Host**)

```bash
nano /etc/systemd/system/homelabbot.service
```

Inhalt:

```ini
[Unit]
Description=HomeLab Discord Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=${BOT_DIR}
ExecStart=/usr/bin/python3 ${BOT_DIR}/bot.py
Restart=always
User=root
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
```

### Aktivieren & Starten

```bash
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable homelabbot.service
systemctl start homelabbot.service
```

### Log ansehen

```bash
journalctl -u homelabbot.service -f
```


---

## 📡 5. Test: Auf dem **NAB6** direkt prüfen ob JSON stimmt

```bash
ssh root@${MONITOR_HOST} "${MONITOR_SCRIPT} --manual | jq ."
```

Wenn kein Fehler: ✅ JSON-Ausgabe korrekt, Bot funktioniert.


---

## 🧩 6. Slash-Command in Discord nutzen

In einem Discord-Channel `/serverstatus` aufrufen. Wenn alles richtig ist: 🟢 schöner Embed mit Statusdaten deines `${MONITOR_HOST}`.

![Screenshot]()


---

## 🧼 7. Fehlerbehandlung

* Keine Ausgabe vom Script? → Prüfen mit `--manual` auf NAB6
* Bot reagiert nicht? → Logs checken mit `journalctl -u homelabbot.service -f`
* JSON-Fehler im Bot? → Scriptausgabe auf Sonderzeichen oder Zeilenumbrüche prüfen


---

## 🔄 8. Erweiterung um weitere Slash-Commands


In `${BOT_DIR}/bot.py` weitere `@bot.tree.command(...)` Blöcke ergänzen. Beispiel für `/nasstatus`:

```python
@bot.tree.command(name="nasstatus", description="Zeigt NAS Backup Status")
async def nasstatus(interaction: discord.Interaction):
    await interaction.response.send_message("🔄 NAS Status wird abgefragt...")
```

Danach im `setup_hook()`:

```python
await self.tree.sync(guild=discord.Object(id=DISCORD_GUILD_ID))
```


---

## 📄 Vollständiger Code: [homelab-monitor.sh]()

```bash
#!/bin/bash

CONFIG_FILE="/root/homelab-monitor.cfg"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

REMOTE_HOST="${MONITOR_HOST}"
REMOTE_SCRIPT_PATH="${MONITOR_SCRIPT}"
SSH_USER="root"

if [[ "$1" == "--manual" ]]; then
    IS_REMOTE_EXECUTION=1
    IS_MANUAL_MODE=1
fi

if [[ "$IS_REMOTE_EXECUTION" != "1" ]]; then
    scp "$0" "$SSH_USER@$REMOTE_HOST:$REMOTE_SCRIPT_PATH" >/dev/null
    ssh "$SSH_USER@$REMOTE_HOST" IS_REMOTE_EXECUTION=1 IS_MANUAL_MODE="$IS_MANUAL_MODE" DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL" bash "$REMOTE_SCRIPT_PATH" "$@"
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
append_json "ram" "$(free -h | awk '/Mem:/ {print $3 " / " $2}')"
append_json "disk" "$(df -h / | awk 'END{print $3 " / " $2 " (" $5 ")"}')"
append_json "temp" "$(command -v sensors &> /dev/null && sensors | grep -m 1 'Package id 0:' | awk '{print $4}' || echo "nicht verfügbar")"
append_json "ip" "$(curl -s ifconfig.me)"
append_json "ping" "$(ping -c 2 1.1.1.1 > /dev/null && echo "✅ OK" || echo "❌ FAIL")"
append_json "logins" "$(last -n 2 | grep -v 'wtmp begins' | grep -v 'still logged in' | paste -sd ';' -)"
append_json "devices" "$(ip neigh | grep -v 'FAILED' | wc -l)"
if pgrep -f "${BACKUP_SCRIPT_PATH}" > /dev/null; then
    start_time=$(ps -eo pid,lstart,cmd | grep "${BACKUP_SCRIPT_PATH}" | grep -v grep | head -n 1 | tr -s ' ' | cut -d' ' -f2-6 | tr '
' ' ')
    append_json "backup" "🟢 Läuft seit: $start_time"
else
    append_json "backup" "🔴 Kein laufendes Backup."
fi
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
append_json "updates" "🔔 $updates Updates verfügbar"
syslog_errors=$(journalctl -p 3 -xb | tail -n 3 | tr '
' ';')
append_json "logs" "$syslog_errors"
vscode_status=$(pgrep -f ".vscode-server" > /dev/null && echo "🟢 aktiv" || echo "🔴 nicht aktiv")
append_json "vscode" "$vscode_status"

if [[ "$IS_MANUAL_MODE" == "1" ]]; then
  echo "$JSON_OUTPUT"
  exit 0
fi
```


---

## 📄 Vollständiger Code: [bot.py]()

```python
import discord
from discord import app_commands
from discord.ext import commands
import os
import subprocess
import json
import traceback
from dotenv import load_dotenv

load_dotenv()
TOKEN = os.getenv("DISCORD_BOT_TOKEN")
GUILD_ID = int(os.getenv("DISCORD_GUILD_ID"))
NAB6_IP = os.getenv("MONITOR_HOST")

class HomeLabBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        guild = discord.Object(id=GUILD_ID)
        self.tree.copy_global_to(guild=guild)
        await self.tree.sync(guild=guild)

bot = HomeLabBot()

@bot.event
async def on_ready():
    print(f"✅ Bot ist online als {bot.user}!")

@bot.tree.command(name="serverstatus", description="Zeigt den Systemstatus als hübschen Embed")
async def serverstatus(interaction: discord.Interaction):
    try:
        await interaction.response.defer()
        result = subprocess.run(["ssh", f"root@{NAB6_IP}", "${MONITOR_SCRIPT} --manual"], capture_output=True, text=True, timeout=15)
        data = json.loads(result.stdout.strip())
        embed = discord.Embed(title="📊 HomeLab Systemstatus", color=0x00ffcc)
        embed.add_field(name="🕒 Uptime", value=data.get("uptime", "-"), inline=True)
        embed.add_field(name="🚦 CPU-Last", value=data.get("load", "-"), inline=True)
        embed.add_field(name="🧠 RAM", value=data.get("ram", "-"), inline=True)
        embed.add_field(name="📀 Speicher", value=data.get("disk", "-"), inline=True)
        embed.add_field(name="🔥 Temperatur", value=data.get("temp", "-"), inline=True)
        embed.add_field(name="🌐 IP", value=data.get("ip", "-"), inline=True)
        embed.add_field(name="🔌 Ping", value=data.get("ping", "-"), inline=True)
        embed.add_field(name="👤 SSH Logins", value=data.get("logins", "-"), inline=False)
        embed.add_field(name="🚀 Netzwerkgeräte", value=str(data.get("devices", "-")), inline=True)
        embed.add_field(name="📦 Updates", value=data.get("updates", "-"), inline=True)
        embed.add_field(name="💾 Backup", value=data.get("backup", "-"), inline=False)
        embed.add_field(name="🚨 Fehlerlogs", value=data.get("logs", "-"), inline=False)
        embed.add_field(name="🖥️ VS Code Remote", value=data.get("vscode", "-"), inline=True)
        embed.set_footer(text="HomeLabBot Statusreport")
        await interaction.followup.send(embed=embed)
    except Exception as e:
        print("❌ FEHLER:", str(e))
        traceback.print_exc()
        try:
            await interaction.followup.send(f"Fehler beim Statusabruf:\n```{e}```", ephemeral=True)
        except:
            print("⚠️ Konnte dem User keinen Fehler mehr senden (vermutlich zu spät).")

bot.run(TOKEN)
```


---


---

## 🗂️ Konfigurationsdateien

### 📄 .env (auf dem Bot-Host unter `/root/homelab/.env`)

Diese Datei enthält die sensiblen Zugangsdaten und Verbindungsinfos:

```env
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
DISCORD_GUILD_ID=${DISCORD_GUILD_ID}
MONITOR_HOST=${MONITOR_HOST}
```

> 🔐 Niemals öffentlich teilen!

### 📄 homelab-monitor.cfg (auf NAB6 unter `/root/homelab-monitor.cfg`)

Diese Datei enthält Variablen zur Steuerung des Monitorings und die Discord Webhook URL:

```bash
# /root/homelab-monitor.cfg

DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL}"

# Checks aktivieren
CHECK_SYSTEM=true
CHECK_NETWORK=true
CHECK_BACKUP=true
CHECK_SECURITY=true
CHECK_UPDATES=true
CHECK_LOGS=true
CHECK_PBS=false
CHECK_NAS_BACKUP=false
```

> Diese Datei wird automatisch durch `${MONITOR_SCRIPT}` eingelesen, wenn vorhanden.


---

## ✅ 10. Fertig – so sieht’s aus:

![Screenshot]()