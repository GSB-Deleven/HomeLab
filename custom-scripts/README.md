# custom-scripts/ README.md

## ⚡ TL;DR – Schnellstart
1. Repo klonen: `git clone <repository-url>`
2. `.env` aus Vorlage anlegen: Kopiere `.env.example` zu `.env` und passe die Werte an.
3. Abhängigkeiten installieren: Führe `pip install -r requirements.txt` aus.
4. Skripte ausführbar machen: Optional, führe `chmod +x *.sh` aus.
5. Bot starten oder Monitor-Skript manuell testen: Starte den Bot mit `python bot.py` oder teste das Monitor-Skript mit `bash homelab-monitor.sh`.

## 📦 Übersicht
Dieses Verzeichnis enthält verschiedene Skripte zur Automatisierung und Überwachung von HomeLab-Umgebungen. Die Skripte sind so konzipiert, dass sie einfach zu verwenden und anzupassen sind.

## 🚀 Voraussetzungen
Um die Skripte erfolgreich auszuführen, benötigen Sie folgende Voraussetzungen:
- Python 3.x
- Zugriff auf die Kommandozeile
- Die notwendigen Berechtigungen für die Ausführung von Skripten

## 🔁 GitHub-Workflow & Installation
Diese Anleitung zeigt Schritt für Schritt, wie man das Repository installiert und alle Skripte vorbereitet – auch für absolute Einsteiger.
0. Installieren Sie Git, falls noch nicht geschehen:
   ```bash
   sudo apt update
   sudo apt install git -y
   ```
1. Klonen Sie das Repository: `git clone <repository-url>`
2. Wechseln Sie in das Verzeichnis: `cd custom-scripts`
3. Erstellen Sie eine `.env`-Datei: Kopieren Sie die `.env.example`-Datei und passen Sie die Werte in der neuen `.env`-Datei an.
4. Optional: Machen Sie die Skripte ausführbar mit 
   ```bash
   chmod +x homelab-monitor.sh
   chmod +x ds920_backup.sh
   ```
5. Installieren Sie die Python-Abhängigkeiten: Führen Sie `pip install -r requirements.txt` aus.
6. Testen Sie den Bot und die Skripte: Starten Sie den Bot mit `python bot.py` oder testen Sie das Monitor-Skript manuell mit `bash homelab-monitor.sh`.
> Wenn Sie den Bot als Dienst laufen lassen möchten, finden Sie später in der Dokumentation Hinweise zur Einrichtung mit `systemd`.

## ⚙️ Einrichtung (.env-Datei)
Für die Konfiguration der Skripte ist eine `.env`-Datei erforderlich. Diese Datei sollte sensible Informationen enthalten und sollte **nicht** ins Repository eingecheckt werden. Eine Beispielvorlage finden Sie in der Datei `.env.example`. Stellen Sie sicher, dass Sie auch `GIT_REPO_PATH` definieren, da alle Pfade dynamisch berechnet werden.

### Beispiel `.env`-Inhalt
```
# Beispielkonfiguration
API_KEY=your_api_key
DATABASE_URL=your_database_url
GIT_REPO_PATH=/path/to/your/repo
```

## 🤖 Discord-Bot (bot.py)
Das Skript `bot.py` ermöglicht die Interaktion mit Discord über einen Bot, der in einem beliebigen Container läuft. Der Bot lädt die `.env`-Datei und kommuniziert via SSH mit dem Monitoring-Host. Er führt `homelab-monitor.sh` und `ds920_backup.sh` auf dem Zielsystem remote aus. Über den Bot sind die Slash-Commands `/serverstatus`, `/nasbackup` usw. verfügbar.

### Beispielbefehl zur Ausführung
```bash
python bot.py
```

## 📊 System-Monitoring (homelab-monitor.sh)
Das Skript `homelab-monitor.sh` überwacht verschiedene Systemparameter und wird auf dem Proxmox-Host (z. B. NAB6) ausgeführt. Es wird durch den Bot per SSH remote ausgelöst oder manuell mit `--manual`. Das Skript generiert eine JSON-Ausgabe für Discord Embeds und sendet diese an den Bot.

### Beispielbefehl zur Ausführung
```bash
bash homelab-monitor.sh
```

## 💾 NAS-Backup (ds920_backup.sh)
Das Skript `ds920_backup.sh` führt regelmäßige Backups auf einem NAS durch und läuft direkt auf dem Host (nicht im Bot-Container). Start, Stop und Status werden remote via SSH durch den Bot angestoßen. Es nutzt Variablen aus der `.env`-Datei, führt rclone-/rsync-Backups aus und sendet Discord-Benachrichtigungen.

### Beispielbefehl zur Ausführung
```bash
bash ds920_backup.sh
```

## 🛠️ Automatisierung (Cron + systemd)
Um die Skripte regelmäßig auszuführen, können Sie Cron-Jobs oder systemd-Dienste einrichten. 

### Beispiel für einen Cron-Job
```bash
0 * * * * /path/to/homelab-monitor.sh
```

## 🔒 Sicherheit & Hinweise
Achten Sie darauf, dass sensible Daten nicht in das Repository gelangen. Verwenden Sie die `.env`-Datei für alle vertraulichen Informationen und überprüfen Sie regelmäßig die Berechtigungen Ihrer Skripte.
