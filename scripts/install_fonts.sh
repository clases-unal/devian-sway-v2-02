#!/usr/bin/env bash
#
# install_fonts.sh
#
# QUÉ HACE:
#   Descarga e instala JetBrainsMono Nerd Font para el usuario actual.
#   Esta fuente NO está empaquetada en los repositorios de Debian (ver
#   packages/fonts.txt para más contexto), así que se obtiene directamente
#   del release oficial en GitHub.
#
#   La URL usada siempre resuelve a la ÚLTIMA versión publicada, sin
#   necesidad de hardcodear un número de versión que quedaría obsoleto.
#
# QUIÉN LO LLAMA:
#   sway.sh, en el bloque "Fuentes tipográficas (JetBrainsMono Nerd Font)"
#
# PROGRAMAS QUE USA:
#   - curl (descarga del release)
#   - tar (extracción de .tar.xz)
#   - fontconfig / fc-cache (registro de la fuente en el sistema)
#
# DESTINO DE INSTALACIÓN:
#   ~/.local/share/fonts/JetBrainsMonoNerdFont/  (solo para el usuario
#   actual, no requiere sudo; consistente con cómo font-manager espera
#   encontrar fuentes de usuario)

set -euo pipefail

FONT_NAME="JetBrainsMono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.tar.xz"
FONT_DEST="${HOME}/.local/share/fonts/${FONT_NAME}NerdFont"
TMP_ARCHIVE="$(mktemp --suffix=.tar.xz)"

echo "==> Descargando ${FONT_NAME} Nerd Font (última versión publicada)"
curl -fL --progress-bar -o "$TMP_ARCHIVE" "$FONT_URL"

echo "==> Extrayendo a $FONT_DEST"
mkdir -p "$FONT_DEST"
tar -xf "$TMP_ARCHIVE" -C "$FONT_DEST"

echo "==> Limpiando archivo temporal"
rm -f "$TMP_ARCHIVE"

echo "==> Actualizando caché de fuentes (fc-cache)"
fc-cache -f "$FONT_DEST" > /dev/null

echo "==> Verificando instalación:"
fc-list | grep -i "jetbrainsmono nerd" | head -n 5 || echo "    AVISO: no se detectó la fuente con fc-list, revisa manualmente."

echo "==> JetBrainsMono Nerd Font instalada para el usuario actual."
echo "    Puedes seleccionarla en font-manager, o ya está referenciada"
echo "    por defecto en config/kitty/kitty.conf y config/waybar/style.css."
