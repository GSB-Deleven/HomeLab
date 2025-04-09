## Homelab

Willkommen in meinem HomeLab!  
Dieses Repository dokumentiert alle meine Maschinen, Container, VMs und benutzerdefinierten Skripte, inklusive Setup-Guides und Workflows. Ziel ist eine klare Struktur und einfache Wartung – auch wenn mal etwas Zeit zwischen den Projekten vergeht.

## Struktur

```mermaid
graph TB
    A[Homelab] --> B[custom-scripts]
    A --> C[workflows]
    C --> C1[backup-strategy]
    A --> D[hosts]
    D --> D1[NAB6]
    D1 --> D1x[Proxmox]
    D1x --> D1a[LXCs]
    D1x --> D1b[VMs]
    D --> D2[Mac Mini]
    D2 --> D2x[Proxmox]
    D2x --> D2a[LXCs]
    D2x --> D2b[VMs]
    D --> D3[Raspberry Pi]
