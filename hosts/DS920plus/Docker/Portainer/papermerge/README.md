## 🗂️ Papermerge 3.4 Setup (Docker Stack via Portainer)

### 🔒 Ziel
Einfaches Setup von Papermerge auf der Synology DS920+ im Ordner `/volume1/docker/papermerge`, erreichbar über `http://<NAS-IP>:8383`, inkl. OCR-Verarbeitung und persistenter Speicherung auf dem NAS.

---

## 📁 Ordnerstruktur (vorab auf der Synology anlegen)

Erstelle in der FileStation oder per SSH folgende Verzeichnisse:

```bash
/volume1/docker/papermerge/media
/volume1/docker/papermerge/db
```

---

## ⚙️ .env-Datei (Speicherort: `/volume1/docker/papermerge/.env`)

```bash
# Zugangsdaten Admin
PAPERMERGE__AUTH__USERNAME=admin
PAPERMERGE__AUTH__PASSWORD=admin

# Secret Key für Django (32+ Zeichen, keine Sonderzeichen wie $)
PAPERMERGE__SECURITY__SECRET_KEY=bitteändern1234567890abcdef

# Medien- und Datenbankpfade (werden im Stack gemountet)
MEDIA_ROOT=/media
DB_ROOT=/db

# PostgreSQL-Datenbank
POSTGRES_USER=coco
POSTGRES_PASSWORD=jumbo
POSTGRES_DB=pmgdb
```

---

## 🐳 docker-compose.yml (für Portainer Stack)

```yaml
version: "3.9"

services:
  webapp:
    image: papermerge/papermerge:3.4.1
    container_name: papermerge-web
    environment:
      PAPERMERGE__SECURITY__SECRET_KEY: ${PAPERMERGE__SECURITY__SECRET_KEY}
      PAPERMERGE__AUTH__USERNAME: ${PAPERMERGE__AUTH__USERNAME}
      PAPERMERGE__AUTH__PASSWORD: ${PAPERMERGE__AUTH__PASSWORD}
      PAPERMERGE__DATABASE__URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      PAPERMERGE__MAIN__MEDIA_ROOT: ${MEDIA_ROOT}
      PAPERMERGE__REDIS__URL: redis://redis:6379/0
      PAPERMERGE__OCR__LANG_CODES: "eng,deu"
      PAPERMERGE__OCR__DEFAULT_LANG_CODE: "deu"
    volumes:
      - /volume1/docker/papermerge/media:${MEDIA_ROOT}
    ports:
      - "8383:80"
    depends_on:
      - db
      - redis

  ocr_worker:
    image: papermerge/ocrworker:0.3.1
    container_name: papermerge-ocr
    command: worker
    environment:
      PAPERMERGE__DATABASE__URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      PAPERMERGE__REDIS__URL: redis://redis:6379/0
      PAPERMERGE__MAIN__MEDIA_ROOT: ${MEDIA_ROOT}
      OCR_WORKER_ARGS: "-Q ocr -c 2"
    depends_on:
      - db
      - redis
    volumes:
      - /volume1/docker/papermerge/media:${MEDIA_ROOT}

  db:
    image: postgres:16.1
    container_name: papermerge-db
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
    volumes:
      - /volume1/docker/papermerge/db:${DB_ROOT}

  redis:
    image: bitnami/redis:7.2
    container_name: papermerge-redis
    environment:
      ALLOW_EMPTY_PASSWORD: "yes"
```

---

## 🚀 Start

1. Gehe im **Portainer** auf „Stacks“ → „Add Stack“
2. Name: `papermerge`
3. Füge den `docker-compose.yml` Inhalt ein
4. Aktiviere unten `.env file` und verlinke `/volume1/docker/papermerge/.env`
5. **Deploy Stack** klicken

---

## ✅ Zugriff & Login

Öffne im Browser:
```
http://<IP-deines-NAS>:8383
```
Login:
- Benutzername: `admin`
- Passwort: `admin`

---

## ✅ Fertig – alle Daten persistent auf dem NAS gespeichert.

Fragen oder Probleme? Sag einfach Bescheid 😄