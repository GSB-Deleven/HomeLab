## Homelab

Willkommen in meinem HomeLab!  
Dieses Repository dokumentiert alle meine Maschinen, Container, VMs und benutzerdefinierten Skripte, inklusive Setup-Guides und Workflows. Ziel ist eine klare Struktur und einfache Wartung – auch wenn mal etwas Zeit zwischen den Projekten vergeht.

## Struktur

```mermaid
graph TB
    A[Homelab] --> B[custom-scripts]
    B --> B1[ds920_backup]
    B1 --> B1a[ds920_backup.sh]
    B --> B2[homelab-monitor]
    B2 --> B2a[homelab-monitor.sh]
    B2 --> B2b[.env.example]

    A --> C[workflows]
    C --> C1[backup_strategy]

    A --> D[hosts]
    D --> D1[DS920plus]
    D1 --> D1a[Docker]
    D1a --> D1b[Portainer]
    D1b --> D1c[paperless-ngx]

    D --> D2[MacMini]
    D2 --> D2a[Proxmox]
    D2a --> D2a1[LxCs]
    D2a1 --> D2a1a[outline-CT107]
    D2a --> D2a2[VMs]
    D2a2 --> D2a2a[Platzhalter]

    D --> D3[NAB6]
    D3 --> D3a[Proxmox]
    D3a --> D3a1[LxCs]
    D3a1 --> D3a1a[debian-CT100]
    D3a --> D3a2[VMs]
    D3a2 --> D3a2a[nextcloud-CT104]

    A --> E[Archiv]
    E --> E1[papermerge]
```

### Formatierungs Cheatsheet

> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.

```
> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.
```
