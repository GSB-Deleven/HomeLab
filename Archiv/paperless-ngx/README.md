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

```bash:Archiv/paperless-ngx/.env.example
```

⚠️ Wichtig: Alle Schlüssel und Passwörter müssen **genau 32 Zeichen lang** sein und dürfen **keine Sonderzeichen wie $ \ oder "** enthalten. Du kannst dir z. B. mit einem Passwort-Generator (wie [bitwarden.com/password-generator](https://bitwarden.com/password-generator)) ein sicheres Passwort erzeugen.

### 2️⃣ docker-compose.yaml (Portainer Stack)

```yaml:Archiv/paperless-ngx/docker-compose.yml
```

<!-- Hinweis: Diese Anleitung basiert auf einem externen YouTube-Tutorial. Probleme wurden mit ChatGPT gelöst und die Anleitung entsprechend überarbeitet. -->
