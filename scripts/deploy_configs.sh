#!/usr/bin/env bash
#
# deploy_configs.sh
#
# QUÉ HACE:
#   Copia los archivos de configuración versionados en este repositorio
#   (carpeta config/) a las rutas reales donde cada programa los espera
#   dentro de ~/.config/. Si ya existe una configuración previa, la
#   respalda con sufijo .bak antes de sobrescribir (no se pierde nada).
#
# QUIÉN LO LLAMA:
#   sway.sh, en el bloque "Despliegue de archivos de configuración"
#
# PROGRAMAS QUE USA:
#   - bash, cp, mkdir (coreutils, ya presentes)
#
# MAPEO DE RUTAS (origen -> destino):
#   config/sway/config        -> ~/.config/sway/config
#   config/waybar/config.json -> ~/.config/waybar/config.json
#   config/waybar/style.css   -> ~/.config/waybar/style.css
#   config/wofi/style.css     -> ~/.config/wofi/style.css
#   config/kitty/kitty.conf   -> ~/.config/kitty/kitty.conf
#   config/mako/config        -> ~/.config/mako/config
#
# IMPORTANTE:
#   Este script asume que se ejecuta desde la raíz del repositorio
#   (donde vive sway.sh), ya que usa rutas relativas a "config/".

set -euo pipefail

# Detecta la raíz del repo a partir de la ubicación de este script,
# para que funcione sin importar desde qué directorio se invoque.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_SRC="$REPO_ROOT/config"
CONFIG_DEST="${HOME}/.config"

if [[ ! -d "$CONFIG_SRC" ]]; then
    echo "ERROR: no se encontró la carpeta de configuraciones en $CONFIG_SRC"
    exit 1
fi

# --- Caso especial: generate_shortcuts.sh -------------------------------
# El atajo Super+K en config/sway/config invoca este script desde
# ~/.config/sway/scripts/generate_shortcuts.sh. Se copia aquí (en vez de
# solo dejarlo en el repo) para que el atajo funcione sin depender de en
# qué ruta del disco quedó clonado el repositorio.
SHORTCUTS_SRC="$REPO_ROOT/scripts/generate_shortcuts.sh"
SHORTCUTS_DEST_DIR="$CONFIG_DEST/sway/scripts"
SHORTCUTS_DEST="$SHORTCUTS_DEST_DIR/generate_shortcuts.sh"

if [[ -f "$SHORTCUTS_SRC" ]]; then
    mkdir -p "$SHORTCUTS_DEST_DIR"
    cp "$SHORTCUTS_SRC" "$SHORTCUTS_DEST"
    chmod +x "$SHORTCUTS_DEST"
    echo "==> Copiado generate_shortcuts.sh a $SHORTCUTS_DEST (usado por Super+K)"
else
    echo "AVISO: no se encontró $SHORTCUTS_SRC; el atajo Super+K no funcionará hasta corregir esto."
fi

# Lista de pares "subcarpeta/archivo" a copiar.
declare -a FILES=(
    "sway/config"
    "waybar/config.json"
    "waybar/style.css"
    "wofi/style.css"
    "kitty/kitty.conf"
    "mako/config"
)

echo "==> Desplegando archivos de configuración a $CONFIG_DEST"

for relpath in "${FILES[@]}"; do
    src="$CONFIG_SRC/$relpath"
    dest="$CONFIG_DEST/$relpath"
    dest_dir="$(dirname "$dest")"

    if [[ ! -f "$src" ]]; then
        echo "    AVISO: no existe $src, se omite."
        continue
    fi

    mkdir -p "$dest_dir"

    if [[ -f "$dest" ]]; then
        cp "$dest" "${dest}.bak"
        echo "    Respaldo creado: ${dest}.bak"
    fi

    cp "$src" "$dest"
    echo "    Copiado: $relpath"
done

echo "==> Configuraciones desplegadas."
echo "    Si sway ya estaba corriendo, recarga con: Mod+Shift+c"
