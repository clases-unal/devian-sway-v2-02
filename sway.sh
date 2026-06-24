#!/usr/bin/env bash
#
# sway.sh
#
# Orquestador principal del proyecto. Instala y configura Sway y todas
# las herramientas descritas en el README, en Debian 13 (trixie) con
# btrfs como sistema de archivos.
#
# CADA BLOQUE de este archivo:
#   - Está delimitado por comentarios "### ---" que indican qué gestiona
#     y qué programas usa.
#   - Se ejecuta de forma independiente: si un bloque falla, el script
#     NO se detiene; continúa con los siguientes y deja constancia del
#     fallo en el resumen final (ver función run_step más abajo).
#
# Este script NO instala Brave (ver scripts/install_brave.sh, aparte
# a propósito) y asume que ya tienes el repositorio descargado en disco;
# no descarga nada de sí mismo ni se configura como ejecutable.
#
# Uso:
#   chmod +x sway.sh   (si aún no lo hiciste)
#   ./sway.sh

set -uo pipefail
# NOTA: deliberadamente NO se usa "set -e" a nivel global. Cada bloque se
# ejecuta a través de run_step, que captura el código de salida sin abortar
# el resto del script. Esto es intencional: un fallo en, por ejemplo, la
# instalación de TeX Live no debe impedir que se configuren los atajos de
# teclado o Snapper.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Acumulador de fallos para el resumen final ---------------------------
declare -a FAILED_STEPS=()
declare -a OK_STEPS=()

# run_step "Nombre descriptivo" comando arg1 arg2 ...
run_step() {
    local description="$1"
    shift
    echo ""
    echo "=================================================================="
    echo "==> $description"
    echo "=================================================================="
    if "$@"; then
        OK_STEPS+=("$description")
    else
        echo "##  FALLÓ: $description (continuando con el resto del script)"
        FAILED_STEPS+=("$description")
    fi
}

# install_from_list "ruta/al/archivo.txt"
# Instala todos los paquetes listados en un archivo packages/*.txt,
# ignorando líneas vacías y comentarios (#).
install_from_list() {
    local list_file="$1"
    local packages=()

    while IFS= read -r line; do
        line="${line%%#*}"          # corta todo lo que sigue a un "#"
        line="$(echo -n "$line" | xargs)"  # recorta espacios
        [[ -z "$line" ]] && continue
        packages+=("$line")
    done < "$list_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "    ($list_file no contiene paquetes para instalar, se omite)"
        return 0
    fi

    sudo apt-get install -y "${packages[@]}"
}

echo "##################################################################"
echo "  Instalación de Sway + herramientas — Debian 13 (trixie) + btrfs"
echo "##################################################################"

### ------------------------------------------------------------------
### ACTUALIZACIÓN DEL SISTEMA
### ------------------------------------------------------------------
# Gestiona: índices de paquetes actualizados antes de instalar nada.
# Programas: apt.

run_step "Actualizar índices de paquetes (apt update)" \
    sudo apt-get update

### ------------------------------------------------------------------
### PAQUETES BASE: sway, redes, sonido, brillo/color, fuentes (gestor),
### flatpak, gestor de archivos, carpetas xdg
### ------------------------------------------------------------------
# Gestiona: el núcleo del entorno gráfico y gestión de hardware básico.
# Programas: ver packages/base.txt para el detalle completo.

run_step "Instalar paquetes base (sway, wofi, waybar, redes, sonido...)" \
    install_from_list "packages/base.txt"

### ------------------------------------------------------------------
### CARPETAS ESTÁNDAR DE USUARIO (XDG)
### ------------------------------------------------------------------
# Gestiona: crea Downloads/Documents/Pictures/Videos/Music/etc en $HOME.
# Programas: scripts/setup_xdg_dirs.sh (xdg-user-dirs).

run_step "Crear carpetas estándar de usuario (Downloads, Documents, etc.)" \
    bash scripts/setup_xdg_dirs.sh

### ------------------------------------------------------------------
### PAQUETES MULTIMEDIA: vlc, audacity, codecs
### ------------------------------------------------------------------
# Gestiona: reproducción y edición de audio/video, codecs libres y
# propietarios.
# Programas: ver packages/multimedia.txt.

run_step "Instalar paquetes multimedia (vlc, audacity, codecs)" \
    install_from_list "packages/multimedia.txt"

### ------------------------------------------------------------------
### PAQUETES DE OFICINA: TeXStudio + TeX Live mínimo funcional
### ------------------------------------------------------------------
# Gestiona: redacción de documentos LaTeX (incluye beamer para
# presentaciones, paquetes de tablas/ecuaciones/gráficos).
# Programas: ver packages/office.txt.

run_step "Instalar TeXStudio + TeX Live mínimo (con soporte beamer)" \
    install_from_list "packages/office.txt"

### ------------------------------------------------------------------
### PAQUETES DE DESARROLLO: git, curl, wget, python, kate, ghostwriter
### ------------------------------------------------------------------
# Gestiona: herramientas básicas de desarrollo y edición de texto.
# Programas: ver packages/dev.txt.

run_step "Instalar herramientas de desarrollo (git, python, kate, ghostwriter...)" \
    install_from_list "packages/dev.txt"

### ------------------------------------------------------------------
### FUENTES TIPOGRÁFICAS: JetBrainsMono Nerd Font
### ------------------------------------------------------------------
# Gestiona: descarga e instalación de la fuente (no empaquetada en apt).
# Programas: scripts/install_fonts.sh.

run_step "Instalar JetBrainsMono Nerd Font" \
    bash scripts/install_fonts.sh

### ------------------------------------------------------------------
### LOGIN MANAGER: greetd + tuigreet
### ------------------------------------------------------------------
# Gestiona: pantalla de inicio de sesión minimalista que lanza sway.
# Programas: scripts/configure_greetd.sh (greetd, tuigreet).

run_step "Configurar greetd + tuigreet (login manager)" \
    bash scripts/configure_greetd.sh

### ------------------------------------------------------------------
### SNAPSHOTS DEL SISTEMA: Snapper + Btrfs Assistant
### ------------------------------------------------------------------
# Gestiona: snapshots automáticos del subvolumen raíz (diarios + pre/post
# de apt), con límites de retención para no llenar el disco, más una
# interfaz gráfica para gestionarlos sin necesidad de programar.
# Programas: scripts/configure_snapper.sh (snapper, btrfs-assistant).

run_step "Configurar Snapper + Btrfs Assistant (snapshots del sistema)" \
    bash scripts/configure_snapper.sh

### ------------------------------------------------------------------
### DESPLIEGUE DE ARCHIVOS DE CONFIGURACIÓN
### ------------------------------------------------------------------
# Gestiona: copia config/sway, config/waybar, config/wofi, config/kitty
# y config/mako a sus rutas reales en ~/.config/. También copia el
# script de atajos a ~/.config/sway/scripts/ para que Super+K funcione.
# Programas: scripts/deploy_configs.sh.

run_step "Desplegar archivos de configuración a ~/.config/" \
    bash scripts/deploy_configs.sh

### ------------------------------------------------------------------
### SERVICIOS ADICIONALES: flatpak (soporte AppImage manual)
### ------------------------------------------------------------------
# Gestiona: habilita el remoto de Flathub para flatpak (ya instalado en
# el bloque de paquetes base). El soporte de AppImage no requiere un
# paquete dedicado en Debian: basta con dar permisos de ejecución al
# .AppImage descargado (chmod +x archivo.AppImage && ./archivo.AppImage).
# Esto se documenta en el README en vez de automatizarse, porque no hay
# nada que instalar de antemano para "soportar" AppImage en Debian.
# Programas: flatpak.

run_step "Habilitar el remoto Flathub para flatpak" \
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo ""
echo "##################################################################"
echo "  RESUMEN"
echo "##################################################################"

if [[ ${#OK_STEPS[@]} -gt 0 ]]; then
    echo ""
    echo "Pasos completados correctamente:"
    for step in "${OK_STEPS[@]}"; do
        echo "  [OK] $step"
    done
fi

if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
    echo ""
    echo "Pasos que fallaron (revisa el log más arriba para el detalle):"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  [FALLÓ] $step"
    done
    echo ""
    echo "El resto de la instalación se completó igualmente. Puedes"
    echo "volver a ejecutar ./sway.sh; los pasos ya completados (como"
    echo "instalación de paquetes) son seguros de repetir."
else
    echo ""
    echo "Todos los pasos se completaron sin errores."
fi

echo ""
echo "Pendiente fuera de este script (a propósito):"
echo "  - Instalar Brave manualmente:  bash scripts/install_brave.sh"
echo "  - Reiniciar el sistema para que greetd/tuigreet tomen control"
echo "    del inicio de sesión gráfico."
echo "  - Soporte AppImage: no requiere instalación; solo"
echo "    chmod +x archivo.AppImage && ./archivo.AppImage"
echo ""
echo "Para ver todos los atajos de teclado disponibles dentro de sway:"
echo "  Super+K"
