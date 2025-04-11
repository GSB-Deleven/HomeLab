# 📦 DS920+ Backup-Skript

> ✅ Zentrales Backup-Skript zur Spiegelung wichtiger Verzeichnisse deiner Synology DS920+ auf das PR4100.
> 
> > [!NOTE]
> > Das Skript ist speziell auf dein Homelab abgestimmt und funktioniert am besten in Kombination mit deinem bestehenden Discord Bot und den Mount-Points auf CT100.
>
> - Unterstützt Discord-Benachrichtigungen
> - Enthält Watchdog gegen Inaktivität
> - Mit Logrotation und Status-Summary

Willkommen im Ordner `custom-scripts/ds920`. Dieses Skript wurde speziell für dein Homelab-Backup entwickelt und automatisiert die Sicherung via `rclone` vom NAS DS920+ auf das PR4100. Es nutzt zentrale Umgebungsvariablen aus einer `.env`-Datei und ist für manuelle oder automatisierte Ausführung optimiert.

---

## 🔄 Ziel des Skripts

Das Skript `ds920_backup.sh` sichert mehrere definierte Verzeichnisse auf deinem NAS.  
Die exakten Pfade werden über Umgebungsvariablen in der `.env`-Datei gesteuert.

> [!TIP]
> Die Backup-Pfade kannst du flexibel in der `.env` anpassen – so musst du das Skript selbst nie ändern.

---

## 📂 Ordnerstruktur

```bash
custom-scripts/ds920/
├── ds920_backup.sh     # Haupt-Backup-Skript
├── README.md           # Diese Anleitung
```

---

## ⚙️ Funktionsweise

```mermaid
graph TD
    A[Start Backup-Skript] --> B[Mounts prüfen]
    B --> C[rclone ausführen je Verzeichnis]
    C --> D[Fehler zählen + Markdown-Summary]
    D --> E[Discord-Benachrichtigung bei Start/Ende/Fehler]
```

```mermaid
graph LR
    X[ENV Variablen laden] --> Y{Mount vorhanden?}
    Y -- ja --> Z[rclone Backup starten]
    Y -- nein --> F[Fehler loggen]
    Z --> G[Fehler zählen & Logging]
    G --> H[Discord Nachricht senden]
```

---

## 🖥️ Ausführungsumgebung

Das Skript läuft auf dem Debian-LXC-Container `CT100`, in dem auch dein Discord-Bot betrieben wird.  
Von hier aus kann es manuell oder über einen Bot-Slash-Command gestartet werden.

Die Datei befindet sich unter:

- Skript: `$GITHUB_REPO/custom-scripts/ds920/ds920_backup.sh`
- Umgebungsvariablen: `$GITHUB_REPO/custom-scripts/.env`

Der Basispfad `$GITHUB_REPO` wird in der `.env` gesetzt und auf allen Systemen einheitlich verwendet.

---

## 🧾 Benötigte `.env`

> [!IMPORTANT]
> Ohne korrekt gesetzte `.env`-Datei kann das Skript nicht funktionieren – prüfe vor dem Start alle Pfade und Webhook-URLs.

Die `.env`-Datei definiert alle benötigten Variablen wie z. B.:

- den Discord Webhook für Benachrichtigungen (`DISCORD_WEBHOOK`)
- Quellpfade der Daten auf dem NAS (`MNT_*`)
- Zielpfade für das Backup (`MNT_BACKUP_TARGET`, `DST_*`)

Eine vollständige Vorlage findest du in `custom-scripts/.env.example`.

---

## 🚀 Ausführung

### Manuell starten:
```bash
bash ds920_backup.sh
```

Optional mit nur einem spezifischen Ordner:
```bash
bash ds920_backup.sh --only docker
```

Oder bestimmte Ordner überspringen:
```bash
bash ds920_backup.sh --skip nextcloud
```

---

## 📦 Logging & Watchdog

- Logs werden nach `/var/log/rclone-backups/` geschrieben
- Alte Logs werden nach 30 Tagen gelöscht
- Wenn das Skript länger als 5 Minuten inaktiv ist, wird abgebrochen
- Fehler werden gezählt und in der Discord-Zusammenfassung gemeldet

---

## 🔔 Discord-Integration

> [!TIP]
> Verwende verschiedene Discord Webhooks für mehrere Backup-Typen, um Benachrichtigungen übersichtlich zu halten.

Es werden automatisch Nachrichten bei Start, Erfolg oder Fehlern gesendet. Beispiel:
```text
🛡️ **Backup gestartet** um: 2025-04-10 01:00:00
📁 Sicherung abgeschlossen in 12m 34s
❌ Fehler: 1 (z. B. Mount fehlgeschlagen)
```

---

## 🧠 Tipps

- Du kannst das Skript auch per zentralem Cronjob oder Discord-Bot triggern
- Nutze `--only` und `--skip` für selektive Backups
- Bei Problemen prüfe zuerst die Mounts und Logdateien

---

## 🛡️ Sicherheitshinweise

> [!WARNING]
> Deine `.env` enthält sensible Zugangsdaten – sie darf niemals öffentlich gemacht oder in ein öffentliches Repository gepusht werden!

- Die `.env`-Datei niemals committen!
- Stattdessen ein `.env.example` nutzen
- `.gitignore` sollte beinhalten:
  ```bash
  *.env
  ```

---

## 📌 Nächste Ideen

- [ ] Parallelisierung der rclone-Jobs
- [ ] Unterstützung für differenzielle Backups
- [ ] Optionaler ZIP-Export der Logs für Audits

---

Fragen oder Anregungen?  
Meld dich wie immer direkt im Discord!
