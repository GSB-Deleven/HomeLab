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

```ini:hosts/DS920plus/Docker/Portainer/papermerge/.env.example
```

---

## 🐳 docker-compose.yml (für Portainer Stack)

```yaml:hosts/DS920plus/Docker/Portainer/papermerge/docker.compose.yml
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