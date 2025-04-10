# 📚 Papermerge 3.3 Homelab Setup – Synology Edition mit Cloudflare Tunnel

Dieser Guide richtet Papermerge 3.3 auf deiner **Synology DS920+ mit Docker** ein – inklusive:
- PostgreSQL + Redis
- Sicherer `.env`-Datei
- Volumes auf `/volume1/docker/papermerge`
- Zugriff via `https://papermerge.deleven.net` über **Cloudflare Tunnel** (kein Traefik notwendig)

---

## ✅ Voraussetzungen

- DSM 7+ mit Docker & Portainer
- `cloudflared` Tunnel aktiv (CT109)
- Subdomain `papermerge.deleven.net` geplant

---

## 📁 1. Ordnerstruktur auf der Synology erstellen

Öffne die **File Station** oder per SSH:

```bash
mkdir -p /volume1/docker/papermerge/{data,media,db}
```

---

## 🗂️ 2. `.env` Datei erstellen

Speichere unter `/volume1/docker/papermerge/.env`:

```dotenv
# == PostgreSQL ==
POSTGRES_DB=papermerge
POSTGRES_USER=papermerge
POSTGRES_PASSWORD=supersecurepassword

# == Django Superuser ==
DJANGO_SUPERUSER_USERNAME=admin # hier dein wunschusername
DJANGO_SUPERUSER_PASSWORD=admin # hier dein wunschpasswort
DJANGO_SUPERUSER_EMAIL=admin@bla.net

# == Papermerge Core Settings ==
SECRET_KEY=change_this_key_later
ALLOWED_HOSTS=*

# == UID/GID für Synology ==
PUID=1000
PGID=100
```

---

## 🐳 3. `docker-compose.yml` für Portainer

In `/volume1/docker/papermerge/docker-compose.yml` oder direkt in Portainer kopieren:

```yaml
version: "3.8"

services:
  db:
    image: postgres:15
    container_name: papermerge-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - /volume1/docker/papermerge/db:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    container_name: papermerge-redis
    restart: unless-stopped

  papermerge:
    image: ghcr.io/papermerge/papermerge/core:3.3.1
    container_name: papermerge
    depends_on:
      - db
      - redis
    ports:
      - 8383:8000
    environment:
      PUID: ${PUID}
      PGID: ${PGID}
      DJANGO_SUPERUSER_USERNAME: ${DJANGO_SUPERUSER_USERNAME}
      DJANGO_SUPERUSER_PASSWORD: ${DJANGO_SUPERUSER_PASSWORD}
      DJANGO_SUPERUSER_EMAIL: ${DJANGO_SUPERUSER_EMAIL}
      PAPERMERGE__MAIN__SECRET_KEY: ${SECRET_KEY}
      PAPERMERGE__DATABASE__TYPE: postgres
      PAPERMERGE__DATABASE__USER: ${POSTGRES_USER}
      PAPERMERGE__DATABASE__PASSWORD: ${POSTGRES_PASSWORD}
      PAPERMERGE__DATABASE__NAME: ${POSTGRES_DB}
      PAPERMERGE__DATABASE__HOST: db
      PAPERMERGE__REDIS__URL: redis://redis:6379/0
      # PAPERMERGE__MAIN__ALLOWED_HOSTS: ${ALLOWED_HOSTS} #Das machte nur Problem
    volumes:
      - /volume1/docker/papermerge/media:/app/media
      - /volume1/docker/papermerge/data:/app/data
    restart: unless-stopped
```

> ⚠️ Achte darauf, dass `.env` und `docker-compose.yml` im selben Ordner liegen!

---

## 🚀 4. Stack in Portainer deployen

1. Öffne Portainer → Stacks → Add Stack
2. Name: `papermerge`
3. Füge den obenstehenden Compose-Code ein
4. Deploy (achtet auf Schreibrechte auf den Volumes!)

---

## 🌐 5. Cloudflared Tunnel einrichten (auf CT109)

Füge in deine Tunnel-Konfiguration (z. B. `/etc/cloudflared/config.yml`) ein:

```yaml
- hostname: papermerge.deleven.net
  service: http://192.168.1.XXX:8383
```

Dann:

```bash
sudo systemctl restart cloudflared
```

Nun ist `https://papermerge.deleven.net` erreichbar! 🎉

---

## 🧪 6. Erstes Login

Rufe im Browser auf:

```
https://papermerge.deleven.net
```

Einloggen mit:
- Benutzer: `admin`
- Passwort: `admin`

Dann **Passwort ändern!**

---

## ✅ Nächste Schritte (optional)

- OCR-Verarbeitung aktivieren
- Import-Folder einrichten
- Backups einrichten (z. B. mit Borg, Restic oder PBS)
- Benutzer & Gruppen anlegen
- Mail-Benachrichtigungen aktivieren

---

Fertig 🎉 Du hast jetzt Papermerge 3.3 modern, sicher und cloudflare-geschützt auf deiner DS920+ laufen!

