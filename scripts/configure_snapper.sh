#!/usr/bin/env bash
#
# configure_snapper.sh
#
# QUÉ HACE:
#   Configura Snapper para gestionar snapshots de DOS subvolúmenes:
#
#   1. "root" -> subvolumen @ (montado en /), con la política:
#     - Snapshots DIARIOS automáticos (timeline), límite: 10
#     - Snapshots PRE/POST automáticos en cada operación apt, límite: 10 pares
#     - Snapshots MENSUALES, límite: 4
#     - Limpieza automática corre una vez al día (systemd timer ya incluido
#       en el paquete snapper: snapper-cleanup.timer)
#
#   2. "respaldos" -> subvolumen @respaldos (montado en /home/Respaldado,
#      enlazado simbólicamente como ~/Respaldado), con la política:
#     - Snapshots DIARIOS automáticos (timeline), límite: 30 (más
#       generoso que root, ya que es la única red de seguridad real
#       para estos archivos personales)
#     - SIN snapshots pre/post de apt (no aplica; apt no toca esta carpeta)
#
#   El resto de subvolúmenes (@home, @log, @cache, @tmp, @opt, @spool,
#   @libvirt) NO tienen configuración de snapper propia. Están separados
#   de @ únicamente para PROTEGERSE de rollbacks del sistema (un rollback
#   de "root" nunca los toca, por vivir en subvolúmenes distintos), pero
#   no tienen su propio historial de snapshots — evita que /home (200GB+)
#   genere snapshots pesados. Si quieres proteger archivos específicos de
#   /home con snapshots, muévelos a ~/Respaldado (ver docs/).
#
#   NO se activa el timeline por HORA en ninguna config (deliberado):
#   generaría demasiados snapshots redundantes para el uso descrito.
#
#   El hook de apt (pre/post snapshot en cada "apt install/remove/upgrade")
#   se instala automáticamente por el propio paquete "snapper" de Debian en
#   /etc/apt/apt.conf.d/80snapper. Ese hook está escrito explícitamente
#   para la config "root" (ejecuta "snapper create -c root ..."), así que
#   NUNCA toca la config "respaldos" sin que este script tenga que hacer
#   nada especial al respecto — los NUMBER_LIMIT=0 en "respaldos" abajo
#   son solo para que, si alguna vez creas snapshots manuales tipo
#   "number" en esa config, no se acumulen sin límite.
#
# QUIÉN LO LLAMA:
#   sway.sh, en el bloque "Snapshots del sistema (Snapper + Btrfs Assistant)"
#
# PROGRAMAS QUE USA:
#   - snapper (paquete apt, ya debe estar instalado por packages/base.txt
#     o se instala aquí mismo como red de seguridad)
#   - systemctl (control de timers, parte de systemd)
#
# REQUIERE:
#   - El subvolumen "/" debe estar montado como subvolumen btrfs "@".
#   - El subvolumen "@respaldos" debe estar montado en /home/Respaldado
#     (ver docs/instalacion-debian-btrfs-sway.md). Si no existe, el
#     bloque de "respaldos" se omite con un aviso, sin detener el script.

set -euo pipefail

echo "==> Configurando Snapper para snapshots del sistema (subvolumen raíz)"

# --- Instalación de paquetes (red de seguridad si no vinieron de base.txt)
sudo apt-get install -y snapper btrfs-assistant

# --- Crear configuración "root" para snapper si no existe ya -------------
if ! sudo snapper list-configs | grep -q "^root "; then
    echo "==> Creando configuración de snapper para / (config: root)"
    sudo snapper -c root create-config /
else
    echo "==> La configuración 'root' de snapper ya existe, se omite create-config"
fi

SNAPPER_CONFIG="/etc/snapper/configs/root"

if [[ ! -f "$SNAPPER_CONFIG" ]]; then
    echo "ERROR: no se encontró $SNAPPER_CONFIG tras create-config. Abortando."
    exit 1
fi

echo "==> Aplicando política de retención (sin timeline horario)"

# --- TIMELINE: snapshots automáticos diarios -------------------------------
sudo snapper -c root set-config "TIMELINE_CREATE=yes"
sudo snapper -c root set-config "TIMELINE_CLEANUP=yes"
sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=0"
sudo snapper -c root set-config "TIMELINE_LIMIT_DAILY=10"
sudo snapper -c root set-config "TIMELINE_LIMIT_WEEKLY=0"
sudo snapper -c root set-config "TIMELINE_LIMIT_MONTHLY=4"
sudo snapper -c root set-config "TIMELINE_LIMIT_YEARLY=0"

# --- NUMBER: snapshots pre/post de apt (gestionados por el hook 80snapper) -
sudo snapper -c root set-config "NUMBER_CLEANUP=yes"
sudo snapper -c root set-config "NUMBER_LIMIT=10"
sudo snapper -c root set-config "NUMBER_LIMIT_IMPORTANT=10"

# --- EMPTY-PRE-POST: borra pares pre/post sin cambios relevantes entre sí -
sudo snapper -c root set-config "EMPTY_PRE_POST_CLEANUP=yes"
sudo snapper -c root set-config "EMPTY_PRE_POST_MIN_AGE=1800"

echo "==> Habilitando timers de systemd (timeline + limpieza automática)"
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

echo "==> Verificando que el hook de apt esté presente (lo instala el paquete snapper)"
if [[ -f /etc/apt/apt.conf.d/80snapper ]]; then
    echo "    OK: /etc/apt/apt.conf.d/80snapper presente. apt creará snapshots pre/post automáticamente."
else
    echo "    AVISO: no se encontró /etc/apt/apt.conf.d/80snapper. Verifica la versión del paquete snapper."
fi

echo "==> Configuración de Snapper completa para 'root'."
echo "    Resumen: 10 daily | 10 apt pre/post pairs | 4 monthly | limpieza diaria"

# ---------------------------------------------------------------------
# CONFIGURACIÓN "respaldos" -> subvolumen @respaldos en /home/Respaldado
# ---------------------------------------------------------------------

RESPALDOS_PATH="/home/Respaldado"

if [[ ! -d "$RESPALDOS_PATH" ]] || ! mountpoint -q "$RESPALDOS_PATH"; then
    echo ""
    echo "==> AVISO: $RESPALDOS_PATH no existe o no es un punto de montaje."
    echo "    Se omite la configuración de snapper para 'respaldos'."
    echo "    Si todavía no creaste el subvolumen @respaldos, consulta"
    echo "    docs/instalacion-debian-btrfs-sway.md para hacerlo."
else
    echo ""
    echo "==> Configurando Snapper para snapshots de $RESPALDOS_PATH"

    if ! sudo snapper list-configs | grep -q "^respaldos "; then
        echo "==> Creando configuración de snapper para $RESPALDOS_PATH (config: respaldos)"
        sudo snapper -c respaldos create-config "$RESPALDOS_PATH"
    else
        echo "==> La configuración 'respaldos' de snapper ya existe, se omite create-config"
    fi

    RESPALDOS_CONFIG="/etc/snapper/configs/respaldos"

    if [[ ! -f "$RESPALDOS_CONFIG" ]]; then
        echo "ERROR: no se encontró $RESPALDOS_CONFIG tras create-config. Se omite el resto de este bloque."
    else
        # Timeline diario, más generoso que root: es la única red de
        # seguridad real para estos archivos personales.
        sudo snapper -c respaldos set-config "TIMELINE_CREATE=yes"
        sudo snapper -c respaldos set-config "TIMELINE_CLEANUP=yes"
        sudo snapper -c respaldos set-config "TIMELINE_LIMIT_HOURLY=0"
        sudo snapper -c respaldos set-config "TIMELINE_LIMIT_DAILY=30"
        sudo snapper -c respaldos set-config "TIMELINE_LIMIT_WEEKLY=0"
        sudo snapper -c respaldos set-config "TIMELINE_LIMIT_MONTHLY=6"
        sudo snapper -c respaldos set-config "TIMELINE_LIMIT_YEARLY=0"

        # Esta config nunca recibe snapshots de apt (el hook 80snapper
        # está escrito explícitamente para "root"); estos límites solo
        # acotan snapshots manuales tipo "number" que crees a mano.
        sudo snapper -c respaldos set-config "NUMBER_CLEANUP=yes"
        sudo snapper -c respaldos set-config "NUMBER_LIMIT=0"
        sudo snapper -c respaldos set-config "NUMBER_LIMIT_IMPORTANT=0"

        echo "==> Configuración de Snapper completa para 'respaldos'."
        echo "    Resumen: 30 daily | 6 monthly | sin snapshots de apt | limpieza diaria"
    fi
fi

echo ""
echo "==> Gestión gráfica de todos los snapshots disponible vía: btrfs-assistant"
echo "    (buscar en wofi con Super+D)"
