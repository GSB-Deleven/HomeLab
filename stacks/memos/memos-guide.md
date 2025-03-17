# 🚀 Memos auf Proxmox LXC mit Portainer Stack & NFS

## 📌 Übersicht

Diese Anleitung beschreibt, wie **Memos** in einem **Portainer-Stack** innerhalb eines **LXC-Containers (CT200) auf Proxmox** eingerichtet wird.  
Die Daten werden auf einem **NAS (NFS-Share)** gespeichert.

### ✅ Was wird eingerichtet?
- **Memos als Docker-Container innerhalb von Portainer**
- **Persistente Speicherung auf einem NFS-Share**
- **Einfache Verwaltung mit `.env`-Variablen in Portainer**

---

## 🛠 1. NFS-Share sicherstellen

Falls noch nicht geschehen, sollte das **NFS-Share bereits auf dem Host oder im LXC-Container (CT200) gemountet sein**.  
Überprüfe das mit:

```bash
mount | grep "/mnt"
```

Falls das Share fehlt, stelle sicher, dass es in `/etc/fstab` korrekt eingetragen ist:

```ini
192.168.xxx.xxx:/pfad/zum/nfs-share /mnt/nfs_mount nfs defaults,_netdev,noatime,nolock,bg 0 0
```

Dann **mounten**:

```bash
mount -a
```

---

## 🛠 2. Erstelle den Portainer Stack für Memos

Gehe in **Portainer** → **Stacks** → **"Add Stack"** und füge den folgenden Stack ein:

```yaml
version: "3.0"

services:
  memos:
    image: neosmemo/memos:latest
    container_name: memos
    restart: unless-stopped
    volumes:
      - ${Docker_Mount}/memos/config:/var/opt/memos
    ports:
      - ${memos_PORT}:5230
```

### 🔹 **Erklärung des Stacks**
- Nutzt das **offizielle Memos-Image** von Docker Hub.
- **Persistente Datenablage** im gemounteten NFS-Share.
- **Port wird über eine Umgebungsvariable (`memos_PORT`) gesetzt**.

---

## 🛠 3. Füge Umgebungsvariablen in Portainer hinzu

1️⃣ **In Portainer unter "Environment variables" → "Advanced"** die folgenden anonymisierten Variablen setzen:

```ini
# Pfad zum gemounteten NFS-Verzeichnis
Docker_Mount=/mnt/nfs_mount

# Externer Port für Memos (Standard: 5230)
memos_PORT=5230
```

2️⃣ **Stack deployen** → Klicke auf **"Deploy the Stack"**.

---

## ✅ 4. Überprüfung

Nach dem Deployment kannst du testen, ob Memos läuft:

```bash
docker ps | grep memos
```

Falls alles korrekt ist, sollte der Container aktiv sein.  
Öffne Memos in deinem Browser:

```
http://<DEINE-IP>:5230
```

---

## 📌 Fazit

🎉 **Memos ist jetzt erfolgreich als Portainer-Stack eingerichtet und speichert Daten auf einem NFS-Share!**  
Falls du Änderungen an den Variablen machen willst, kannst du das einfach in **Portainer unter "Environment Variables"** tun. 🚀

