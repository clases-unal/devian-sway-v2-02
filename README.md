# debian-sway-v2

Instalación automatizada de Sway y herramientas asociadas para Debian 13
(trixie) con btrfs, pensada para una instalación limpia, sin duplicar
aplicaciones que cumplan la misma función, y con snapshots del sistema
gestionables desde una interfaz gráfica.

## Prerrequisito de partición (se hace en el instalador de Debian, no aquí)

Este proyecto asume que el sistema ya está instalado con btrfs y los
subvolúmenes correctos, **antes** de clonar este repositorio y correr
`./sway.sh`. Hay dos caminos para llegar a ese punto:

- **Instalación detallada con debootstrap desde un Debian Live**, con
  control total sobre los subvolúmenes (`@`, `@home`, `@log`, `@cache`,
  `@tmp`, `@opt`, `@spool`, `@libvirt`, `@respaldos`) y swap en partición
  separada. Ver la guía completa, paso a paso y explicada para quien no
  tiene experiencia previa con Linux, en
  [`docs/instalacion-debian-btrfs-sway.md`](docs/instalacion-debian-btrfs-sway.md).
  **Este es el método recomendado**, ya que evita tener que migrar `/home`
  a un subvolumen separado después de instalar.

- **Instalador gráfico normal de Debian** con particionado manual:
  EFI 512MB, swap 1.5× tu RAM, y el resto como btrfs en un solo
  subvolumen `@` (sin separar `@home`). Es más simple, pero significa que
  los snapshots de Snapper sobre `/` incluirán todo `/home` también, y
  `scripts/configure_snapper.sh` solo configurará la parte de `root`
  (omitirá `respaldos` con un aviso, sin fallar).

Si sigues la guía detallada, una vez reiniciado el sistema, el flujo de
`./sway.sh` es idéntico en ambos casos — no se necesita ningún cambio en
los scripts según qué método de instalación hayas usado.

## Qué hace este proyecto

Un solo script (`sway.sh`) instala y configura:

- **Sway** + barra de estado (waybar) + buscador de aplicaciones (wofi)
  + notificaciones (mako) + terminal (kitty)
- **Gestión de pantalla**: brillo, calibración de color, monitores
  externos (wdisplays)
- **Redes**: wifi, ethernet, bluetooth (NetworkManager, blueman)
- **Sonido**: altavoces, micrófonos, control de volumen (PipeWire, pamixer)
- **Multimedia**: VLC, Audacity, codecs libres y propietarios (ffmpeg, gstreamer)
- **Acceso**: teclado en inglés internacional, cámara, Thunderbolt
- **Dispositivos externos**: memorias USB, pantallas (udisks2, gvfs)
- **Fuentes**: gestor gráfico (font-manager) + JetBrainsMono Nerd Font
- **Oficina**: TeXStudio + TeX Live mínimo funcional (beamer, tablas,
  ecuaciones, código fuente)
- **Desarrollo**: git, curl, wget, python3, Kate, Ghostwriter (editor
  Markdown con vista previa lado a lado)
- **Snapshots del sistema**: Snapper + Btrfs Assistant (interfaz gráfica)
- **Login manager**: greetd + tuigreet (minimalista, sin Qt/GTK extra)
- **Suspensión e hibernación**: automática tras inactividad y al cerrar
  la tapa, usando el swap configurado en la instalación

Brave se instala con un script aparte (ver más abajo), y no forma parte
del flujo principal de `sway.sh`.

## Estructura del repositorio

```
debian-sway-v2/
├── sway.sh                       # Orquestador principal
├── README.md                     # Este archivo
├── docs/
│   └── instalacion-debian-btrfs-sway.md  # Guía detallada de partición + debootstrap
├── packages/
│   ├── base.txt                  # sway, redes, sonido, brillo, fuentes...
│   ├── multimedia.txt            # vlc, audacity, codecs
│   ├── office.txt                # texstudio, texlive mínimo
│   ├── dev.txt                   # git, python, kate, ghostwriter
│   └── fonts.txt                 # (vacío a propósito, ver el archivo)
├── scripts/
│   ├── configure_greetd.sh       # greetd + tuigreet → sway
│   ├── configure_snapper.sh      # Política de snapshots
│   ├── install_fonts.sh          # JetBrainsMono Nerd Font (GitHub)
│   ├── install_brave.sh          # APARTE del flujo principal
│   ├── setup_xdg_dirs.sh         # Downloads/Documents/etc en $HOME
│   ├── deploy_configs.sh         # Copia config/ a ~/.config/
│   └── generate_shortcuts.sh     # Listado de atajos (usado por Super+K)
└── config/
    ├── sway/config
    ├── waybar/config.json
    ├── waybar/style.css
    ├── wofi/style.css
    ├── kitty/kitty.conf
    └── mako/config
```

## Uso

Desde la raíz del repositorio:

```
./sway.sh
```

El script recorre cada bloque (paquetes base, multimedia, oficina,
desarrollo, fuentes, greetd, snapper, despliegue de configuraciones,
flatpak) de forma secuencial. **Si un bloque falla, el script continúa
con los siguientes** y muestra un resumen al final indicando qué pasos
fallaron, para que puedas revisarlos y volver a ejecutar `./sway.sh`
sin problema (los pasos ya completados son seguros de repetir).

### Pendiente fuera de `sway.sh` (a propósito)

- **Brave**: `bash scripts/install_brave.sh`
- **AppImage**: no requiere instalar nada; simplemente
  `chmod +x archivo.AppImage && ./archivo.AppImage`
- **Reiniciar** el sistema al terminar, para que greetd tome control
  del inicio de sesión gráfico.

## Atajos de teclado esenciales

| Atajo | Acción |
|---|---|
| `Super+K` | **Ver TODOS los atajos activos** (se actualiza solo, lee el config en vivo) |
| `Super+Return` | Abrir terminal (kitty) |
| `Super+D` | Buscador de aplicaciones (wofi) |
| `Super+W` | Abrir Brave (tras instalarlo) |
| `Super+E` | Abrir gestor de archivos (Nemo) |
| `Super+L` | Bloquear pantalla |
| `Super+Escape` | Menú gráfico de apagado/reinicio/suspensión (wlogout) |
| `Super+Shift+Escape` | Mismo menú, modo texto (sin mouse) |
| `Super+P` | Gestor gráfico de pantallas externas (wdisplays) |
| `Super+Shift+V` | Control gráfico de audio (pavucontrol) |
| `Super+Flechas` / `Super+H,J,L` | Cambiar foco entre ventanas |
| `Super+Shift+Flechas` | Mover ventana |
| `Super+1..5` | Cambiar de espacio de trabajo |
| `Super+Shift+C` | Recargar configuración de sway |

Para la lista completa y siempre actualizada, usa **Super+K** en
cualquier momento dentro de sway.

### Limitación conocida del listado de atajos

`Super+K` lista todos los `bindsym`/`bindswitch` del archivo de
configuración, incluyendo los que viven dentro de modos especiales
(como el modo de sistema `Super+Shift+Escape`). Esos atajos comparten
letras simples (`e`, `h`, `l`, `p`, `r`, `s`) que solo tienen sentido
**dentro de ese modo**, así que pueden verse ambiguos en el listado
general sin indicar a qué modo pertenecen. No afecta el funcionamiento,
solo la claridad del listado en ese caso particular.

## Snapshots del sistema

Política configurada por `scripts/configure_snapper.sh`, ahora con dos
configuraciones de Snapper:

**Config `root`** (subvolumen `@`, montado en `/`):
- **10 snapshots diarios** (timeline)
- **10 pares pre/post** por cada operación `apt install/remove/upgrade`
  (el hook se instala automáticamente junto con el paquete `snapper`, y
  está escrito específicamente para esta config)
- **4 snapshots mensuales**
- Limpieza automática una vez al día (systemd timer)

**Config `respaldos`** (subvolumen `@respaldos`, montado en
`/home/Respaldado`, enlazado como `~/Respaldado`):
- **30 snapshots diarios** (más generoso que `root`, ya que es la única
  red de seguridad real para estos archivos personales)
- **6 snapshots mensuales**
- Sin snapshots de apt (no aplica; apt no escribe en esta carpeta)

El resto de subvolúmenes (`@home`, `@log`, `@cache`, `@tmp`, `@opt`,
`@spool`, `@libvirt`) no tienen snapshots propios — están separados de
`@` únicamente para protegerse de rollbacks del sistema, sin generar su
propio historial pesado. Si tienes archivos en `/home` que quieres
proteger con snapshots, muévelos a `~/Respaldado` (ver la guía de
instalación para más detalle sobre por qué se hizo así, dado que tus
archivos personales superan los 200GB regularmente).

Sin timeline por hora en ninguna config (deliberado, para no acumular
snapshots redundantes).

Gestión gráfica: abre **Btrfs Assistant** desde el buscador de
aplicaciones (`Super+D`).

## Notas de hardware

- Las teclas multimedia físicas (brillo, volumen) están mapeadas en
  `config/sway/config` usando los keysyms estándar `XF86*`.
- El teclado está configurado como `us(intl)` (inglés internacional).
- La suspensión-con-hibernación automática (`systemctl
  suspend-then-hibernate`) requiere que el swap esté correctamente
  configurado, como se asume en el prerrequisito de partición arriba.
