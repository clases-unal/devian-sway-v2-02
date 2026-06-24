#!/usr/bin/env bash
#
# generate_shortcuts.sh
#
# QUÉ HACE:
#   Lee el archivo de configuración real de sway (~/.config/sway/config)
#   y extrae TODAS las líneas "bindsym" (atajos de teclado) y "bindswitch"
#   (atajos de switches, ej. tapa de laptop), generando un listado legible.
#
#   No mantiene una lista separada a mano: como lee el config en vivo cada
#   vez que se ejecuta, si agregas, editas o borras un atajo en el config,
#   el listado se actualiza solo la próxima vez que lo invoques. No requiere
#   recordar actualizar nada.
#
# QUIÉN LO LLAMA:
#   El propio config de sway, vía el atajo Super+K:
#     bindsym $mod+k exec kitty --class=floating_shortcuts -e bash -c \
#       "~/.config/sway/scripts/generate_shortcuts.sh | less -R"
#
# PROGRAMAS QUE USA:
#   - bash, grep, sed, awk (todos parte de coreutils, ya presentes en
#     cualquier Debian base; no se instala nada adicional)
#
# SALIDA:
#   Texto plano formateado en columnas, pensado para verse en una terminal
#   kitty flotante con `less` (búsqueda con "/" incluida gratis por less).

set -euo pipefail

SWAY_CONFIG="${HOME}/.config/sway/config"

if [[ ! -f "$SWAY_CONFIG" ]]; then
    echo "No se encontró el archivo de configuración en: $SWAY_CONFIG"
    exit 1
fi

echo "================================================================"
echo "  ATAJOS DE TECLADO ACTIVOS — generado desde sway/config en vivo"
echo "================================================================"
echo

# Extrae líneas bindsym/bindswitch, ignorando las que están comentadas (#).
# Formato esperado en el config: bindsym $mod+Shift+q kill  # comentario opcional
#
# Estrategia:
#   1. Filtra líneas que empiezan (tras espacios) con bindsym o bindswitch.
#   2. Descarta comentarios de línea completa.
#   3. Separa la combinación de teclas del comando, y si existe un comentario
#      "# texto" al final de la línea, lo usa como descripción legible;
#      si no existe comentario, muestra el comando crudo como descripción.

grep -E '^\s*bind(sym|switch)\s' "$SWAY_CONFIG" \
    | grep -v '^\s*#' \
    | sed -E 's/^\s*bind(sym|switch)\s+//' \
    | awk -F'#' '
        {
            # $1 contiene "[--flags...] combinacion comando..."; $2 (si
            # existe) es el comentario tras el "#" al final de la línea.
            split($1, parts, /[ \t]+/)

            # Salta cualquier flag inicial (--locked, --whole-window,
            # --border, --release, etc.) hasta llegar a la combinación
            # real de teclas, que es el primer token que NO empieza con "-".
            start = 1
            while (start <= length(parts) && substr(parts[start], 1, 1) == "-") {
                start++
            }
            combo = parts[start]

            cmd = ""
            for (i = start + 1; i <= length(parts); i++) {
                cmd = cmd " " parts[i]
            }
            gsub(/^ +/, "", cmd)

            desc = $2
            gsub(/^ +/, "", desc)
            gsub(/ +$/, "", desc)

            if (desc == "") {
                desc = cmd
            }

            printf "%-32s %s\n", combo, desc
        }
    ' \
    | sort -u

echo
echo "----------------------------------------------------------------"
echo "Tip: usa '/' para buscar (ej. /workspace) y 'q' para salir."
echo "Para añadir descripciones legibles, comenta tus bindsym así:"
echo '  bindsym $mod+Shift+q kill  # Cerrar ventana activa'
echo "----------------------------------------------------------------"
