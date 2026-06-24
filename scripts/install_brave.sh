#!/usr/bin/env bash
#
# install_brave.sh
#
# QUÉ HACE:
#   Instala el navegador Brave usando el script oficial de instalación.
#
# QUIÉN LO LLAMA:
#   NADIE automáticamente. A propósito, este script NO se invoca desde
#   sway.sh ni desde ningún otro script del proyecto. Se ejecuta a mano,
#   cuando el usuario decida instalar Brave:
#
#     bash scripts/install_brave.sh
#
#   Se mantiene separado del flujo principal porque usa un script de
#   terceros descargado por curl, en lugar de un paquete apt verificable
#   de antemano — una capa de instalación distinta al resto del sistema.
#
# PROGRAMAS QUE USA:
#   - curl (descarga el instalador oficial de Brave)
#   - sh (ejecuta el instalador, que internamente usa apt)

set -euo pipefail

echo "==> Instalando Brave Browser (script oficial de Brave)"
curl -fsS https://dl.brave.com/install.sh | sh

echo "==> Brave instalado. Búscalo en wofi (Super+D) o lánzalo con: brave-browser"
