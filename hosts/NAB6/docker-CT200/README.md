# 🚀 Paperless-NGX auf Proxmox LXC mit NFS-Storage & Portainer Stack

## 📌 Übersicht

Diese Anleitung beschreibt die Installation von **Paperless-NGX** in einem **LXC-Container auf Proxmox**, wobei die Daten auf einem **NAS (NFS-Share)** gespeichert werden.

### ✅ Was wird eingerichtet?

* LXC-Container (z. B. CT200) für Docker
* NAS-Storage als NFS-Mount für Paperless-Daten
* Docker-Container für Paperless, Redis, Tika & Gotenberg
* Persistente Datenablage & passende Berechtigungen
* Portainer Stack für einfaches Management

---

## 🛠 1. NFS-Share auf dem Proxmox-Host einrichten

Da der LXC-Container das NAS-Volume nicht direkt mounten soll, wird es zuerst auf **Proxmox (nicht LXC!)** gemountet.

### 1️⃣ NFS-Client installieren

```bash
apt update && apt install -y nfs-common
```

### 2️⃣ NAS-Erreichbarkeit prüfen

```bash
showmount -e [NAS-IP]
```

### 3️⃣ NFS-Mount erstellen

```bash
mkdir -p /mnt/<YOUR_NFS_FOLDER>
mount -t nfs [NAS-IP]:/volume1/docker /mnt/<YOUR_NFS_FOLDER>
```

Mount dauerhaft eintragen:

```bash
nano /etc/fstab
```

```ini
[NAS-IP]:/volume1/docker /mnt/<YOUR_NFS_FOLDER> nfs defaults 0 0
```

```bash
mount -a
```

### 4️⃣ Mount prüfen

```bash
ls -lah /mnt/<YOUR_NFS_FOLDER>
```

---

## 🛠 2. LXC-Container vorbereiten

### 1️⃣ LXC stoppen

```bash
pct stop 200
```

### 2️⃣ Mount zur LXC-Config hinzufügen

```bash
nano /etc/pve/lxc/200.conf
```

```ini
lxc.mount.entry: /mnt/<YOUR_NFS_FOLDER>/paperless-ngx/data usr/src/paperless/data none bind,create=dir 0 0,rw
```

### 3️⃣ Container starten

```bash
pct start 200
```

---

## 🛠 3. Berechtigungen setzen

### Auf dem Proxmox-Host:

```bash
chown -R 1000:1000 /mnt/<YOUR_NFS_FOLDER>/paperless-ngx
chmod -R 770 /mnt/<YOUR_NFS_FOLDER>/paperless-ngx
```

### Im Container:

```bash
docker exec -it paperless-ngx-webserver sh
ls -lah /usr/src/paperless/data
chown -R paperless:paperless /usr/src/paperless/data
chmod -R 770 /usr/src/paperless/data
exit
docker restart paperless-ngx-webserver
```

---

## 🛠 4. Portainer Stack

### 1️⃣ Umgebungsvariablen im Stack setzen

```bash
PAPERLESS_REDIS=redis://broker:6379
PAPERLESS_ADMIN_USER=<adminuser>
PAPERLESS_ADMIN_PASSWORD=<sicheres_passwort>
PAPERLESS_SECRET_KEY=<geheimer_schluessel>
PAPERLESS_OCR_LANGUAGE=deu+eng
PAPERLESS_CONSUMER_DELETE_DUPLICATES=true
PAPERLESS_CONSUMER_ENABLE_BARCODES=true
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000
PAPERLESS_TIKA_ENDPOINT=http://tika:9998
USERMAP_UID=1000
USERMAP_GID=1000
NFS_PATH=/mnt/<YOUR_NFS_FOLDER>
```

⚠️ Wichtig: Alle Schlüssel und Passwörter müssen **genau 32 Zeichen lang** sein und dürfen **keine Sonderzeichen wie $ \ oder "** enthalten. Du kannst dir z. B. mit einem Passwort-Generator (wie [bitwarden.com/password-generator](https://bitwarden.com/password-generator)) ein sicheres Passwort erzeugen.

### 2️⃣ docker-compose.yaml (Portainer Stack)

```yaml
version: "3.4"

services:
  broker:
    image: docker.io/library/redis:7
    container_name: paperless-ngx-broker
    restart: unless-stopped
    volumes:
      - ${NFS_PATH}/paperless-ngx/redisdata:/data

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
      - ${NFS_PATH}/paperless-ngx/data:/usr/src/paperless/data
      - ${NFS_PATH}/paperless-ngx/media:/usr/src/paperless/media
      - ${NFS_PATH}/paperless-ngx/export:/usr/src/paperless/export
      - ${NFS_PATH}/paperless-ngx/consume:/usr/src/paperless/consume
    environment:
      PAPERLESS_REDIS: ${PAPERLESS_REDIS}
      PAPERLESS_SECRET_KEY: ${PAPERLESS_SECRET_KEY}
      PAPERLESS_ADMIN_USER: ${PAPERLESS_ADMIN_USER}
      PAPERLESS_ADMIN_PASSWORD: ${PAPERLESS_ADMIN_PASSWORD}
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
```

<!-- Hinweis: Diese Anleitung basiert auf einem externen YouTube-Tutorial. Probleme wurden mit ChatGPT gelöst und die Anleitung entsprechend überarbeitet. -->
