#!/usr/bin/env bash
#
# setup_xdg_dirs.sh
#
# QUÉ HACE:
#   Resuelve el problema original detectado en la instalación mínima de
#   Debian: sin un entorno de escritorio completo, $HOME solo contiene
#   "Desktop/" y faltan las carpetas estándar (Downloads, Documents,
#   Pictures, Videos, Music, Public, Templates).
#
#   xdg-user-dirs-update lee (o crea con valores por defecto) el archivo
#   ~/.config/user-dirs.dirs y crea físicamente cada carpeta ahí declarada.
#
# QUIÉN LO LLAMA:
#   sway.sh, en el bloque "Carpetas estándar de usuario (XDG)"
#
# PROGRAMAS QUE USA:
#   - xdg-user-dirs (paquete apt, ya en packages/base.txt)
#   - xdg-user-dirs-gtk (opcional, integra con diálogos de apps GTK)

set -euo pipefail

echo "==> Creando carpetas estándar de usuario (Downloads, Documents, etc.)"

# Por si este script se ejecuta antes de que sway.sh instale base.txt,
# se asegura el paquete aquí también (idempotente, no reinstala si ya está).
sudo apt-get install -y xdg-user-dirs xdg-user-dirs-gtk

# Genera ~/.config/user-dirs.dirs con las rutas estándar (en español si el
# locale del sistema es es_*, en inglés en caso contrario) y crea las
# carpetas físicas correspondientes en $HOME.
xdg-user-dirs-update

echo "==> Carpetas creadas. Verificando resultado:"
xdg-user-dirs-update --force 2>/dev/null || true
grep -v '^#' "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" 2>/dev/null || true

echo "==> Listo. Las rutas exactas quedaron registradas en:"
echo "    ${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
