## Homelab

Willkommen in meinem HomeLab!  
Dieses Repository dokumentiert alle meine Maschinen, Container, VMs und benutzerdefinierten Skripte, inklusive Setup-Guides und Workflows. Ziel ist eine klare Struktur und einfache Wartung – auch wenn mal etwas Zeit zwischen den Projekten vergeht.

## Struktur

```mermaid
graph TB
    A[Homelab] --> B[custom-scripts]
    A --> C[workflows]
    C --> C1[backup_strategy]
    A --> D[hosts]

    D --> D1[NAB6]
    D1 --> D1x[Proxmox]
    D1x --> D1a[LXCs]
    D1a --> D1a1[debian-CT100]
    D1x --> D1b[VMs]
    D1b --> D1b1[nextcloud-CT104]

    D --> D2[MacMini]
    D2 --> D2x[Proxmox]
    D2x --> D2a[LXCs]
    D2a --> D2a1[outline-CT107]
    D2x --> D2b[VMs]
    D2b --> D2b1[Platzhalter]

    D --> D3[Raspberry Pi]
```
