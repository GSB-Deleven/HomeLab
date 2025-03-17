*Dieser Container wurde auf basis von https://github.com/RPiList/SynVideos/blob/main/Videos/DockerPaperlessNGX/docker-compose-v4.yml erstellt.  
Probleme wurden mit Chat GPT behoben und die zusammenfassung wurde auch von Chat GPT geschrieben*

---
# 🚀 Paperless-NGX auf Proxmox LXC mit NFS-Storage & Portainer Stack

## 📌 Übersicht

Diese Anleitung beschreibt die Installation von **Paperless-NGX** in einem **LXC-Container auf Proxmox**, wobei die Daten auf einem **Synology NAS (NFS-Share)** gespeichert werden.

### ✅ Was wird eingerichtet?

- **LXC-Container auf Proxmox (CT200)** für Docker
- **NAS-Storage **``** als NFS-Mount** für Paperless-Daten
- **Docker-Container für Paperless, Redis, Tika & Gotenberg**
- **Persistente Datenablage & richtige Berechtigungen**
- **Portainer Stack für einfaches Management**

---

## 🛠 1. NFS-Share auf dem Proxmox-Host einrichten

Da der LXC-Container das NAS-Volume nicht direkt mounten soll, wird es zuerst auf **Proxmox (nicht LXC!)** gemountet.

### 1️⃣ Stelle sicher, dass der NFS-Client installiert ist

Auf **Proxmox (Host)** ausführen:

```bash
apt update && apt install -y nfs-common
```

### 2️⃣ Prüfe, ob das NAS erreichbar ist

```bash
showmount -e 192.168.1.222
```

Falls das NAS den Export zeigt, ist alles bereit.

### 3️⃣ Erstelle den NFS-Mount auf dem Proxmox-Host

```bash
mkdir -p /mnt/DS920_docker
mount -t nfs 192.168.1.222:/volume1/docker /mnt/DS920_docker
```

Falls erfolgreich, den Mount in `/etc/fstab` eintragen:

```bash
nano /etc/fstab
```

Füge hinzu:

```ini
192.168.1.222:/volume1/docker /mnt/DS920_docker nfs defaults 0 0
```

Dann den Mount neu laden:

```bash
mount -a
```

### 4️⃣ Prüfe, ob der Mount korrekt funktioniert

```bash
ls -lah /mnt/DS920_docker
```

Falls du Dateien siehst, funktioniert der Mount! ✅

---

## 🛠 2. LXC-Container (CT200) konfigurieren

### 1️⃣ LXC-Container (CT200) stoppen

```bash
pct stop 200
```

### 2️⃣ Füge den NFS-Mount zur LXC-Config hinzu

Bearbeite die LXC-Config auf **Proxmox (Host)**:

```bash
nano /etc/pve/lxc/200.conf
```

Füge folgende Zeile hinzu:

```ini
lxc.mount.entry: /mnt/DS920_docker/paperless-ngx/data usr/src/paperless/data none bind,create=dir 0 0,rw
```

Speichern mit `CTRL + X`, `Y`, `ENTER`.

### 3️⃣ Starte den LXC-Container neu

```bash
pct start 200
```

Falls der Container nicht startet, Logs prüfen:

```bash
journalctl -xe | tail -50
```

---

## 🛠 3. Berechtigungen für Paperless-Daten setzen

### 1️⃣ Korrigiere die Berechtigungen auf Proxmox (Host)

```bash
chown -R 1000:1000 /mnt/DS920_docker/paperless-ngx
chmod -R 770 /mnt/DS920_docker/paperless-ngx
```

Falls weiterhin "`Permission denied`", temporär testen mit:

```bash
chmod -R 777 /mnt/DS920_docker/paperless-ngx
```

(⚠️ Nur für Tests! Danach wieder auf `770` setzen!)

### 2️⃣ Berechtigungen innerhalb des Containers prüfen

Gehe in den Container:

```bash
docker exec -it paperless-ngx-webserver sh
```

Prüfe die Berechtigungen:

```bash
ls -lah /usr/src/paperless/data
```

Falls `root:root`, dann setzen:

```bash
chown -R paperless:paperless /usr/src/paperless/data
chmod -R 770 /usr/src/paperless/data
```

Dann den Container verlassen und Paperless neu starten:

```bash
exit
docker restart paperless-ngx-webserver
```

---

## 🛠 4. Portainer Stack für Paperless-NGX

### 1️⃣ Füge Umgebungsvariablen in Portainer hinzu

In Portainer kannst du die benötigten Umgebungsvariablen direkt über `Stacks` → `Environment variables` → `Advanced` hinzufügen. Dort kannst du die Werte für `PAPERLESS_REDIS`, `PAPERLESS_ADMIN_USER`, `PAPERLESS_ADMIN_PASSWORD` usw. definieren, anstatt eine `.env`-Datei manuell zu erstellen.

```ini
PAPERLESS_REDIS=redis://broker:6379
PAPERLESS_ADMIN_USER=admin
PAPERLESS_ADMIN_PASSWORD=CHANGEME # 32 Zeichen, und keine $ \ oder "
PAPERLESS_SECRET_KEY=CHANGEME_SECRET_KEY # 32 Zeichen, und keine $ \ oder "
PAPERLESS_OCR_LANGUAGE=deu+eng
PAPERLESS_CONSUMER_DELETE_DUPLICATES=true
PAPERLESS_CONSUMER_ENABLE_BARCODES=true
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000
PAPERLESS_TIKA_ENDPOINT=http://tika:9998
USERMAP_UID=1000
USERMAP_GID=1000
```

---

### 2️⃣ Erstelle den Portainer Stack

```yaml
version: "3.4"

services:
  broker:
    image: docker.io/library/redis:7
    container_name: paperless-ngx-broker
    restart: unless-stopped
    volumes:
      - /mnt/DS920_docker/paperless-ngx/redisdata:/data

  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    container_name: paperless-ngx-webserver
    restart: unless-stopped
    depends_on:
      - broker
    ports:
      - 8810:8000
    healthcheck:
      test: ["CMD", "curl", "-fs", "-S", "--max-time", "2", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - /mnt/DS920_docker/paperless-ngx/data:/usr/src/paperless/data
      - /mnt/DS920_docker/paperless-ngx/media:/usr/src/paperless/media
      - /mnt/DS920_docker/paperless-ngx/export:/usr/src/paperless/export
      - /mnt/DS920_docker/paperless-ngx/consume:/usr/src/paperless/consume
    environment:
      PAPERLESS_REDIS: ${PAPERLESS_REDIS}
      PAPERLESS_SECRET_KEY: [DEIN_GEHEIMER_SCHLUESSEL]
      PAPERLESS_ADMIN_USER: ${PAPERLESS_ADMIN_USER}
      PAPERLESS_ADMIN_PASSWORD: [DEIN_PASSWORT]
      PAPERLESS_OCR_LANGUAGE: ${PAPERLESS_OCR_LANGUAGE}
      PAPERLESS_CONSUMER_DELETE_DUPLICATES: ${PAPERLESS_CONSUMER_DELETE_DUPLICATES}
      PAPERLESS_CONSUMER_ENABLE_BARCODES: ${PAPERLESS_CONSUMER_ENABLE_BARCODES}
      PAPERLESS_TIKA_ENABLED: ${PAPERLESS_TIKA_ENABLED}
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT: ${PAPERLESS_TIKA_GOTENBERG_ENDPOINT}
      PAPERLESS_TIKA_ENDPOINT: ${PAPERLESS_TIKA_ENDPOINT}
      USERMAP_UID: ${USERMAP_UID}
      USERMAP_GID: ${USERMAP_GID}

  gotenberg:
    image: docker.io/gotenberg/gotenberg:8
    container_name: paperless-ngx-gotenberg
    restart: unless-stopped
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"

  tika:
    image: ghcr.io/paperless-ngx/tika:latest
    container_name: paperless-ngx-tika
    restart: unless-stopped

volumes:
  data:
  media:
  redisdata:
```





