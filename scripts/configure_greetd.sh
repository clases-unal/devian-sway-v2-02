#!/usr/bin/env bash
#
# configure_greetd.sh
#
# QUÉ HACE:
#   Configura greetd (login manager minimalista, sin entorno gráfico
#   propio) con tuigreet (interfaz de texto en consola) como pantalla de
#   inicio de sesión, apuntando a sway como sesión a lanzar.
#
#   Se eligió este combo sobre alternativas como SDDM porque no añade
#   dependencias de Qt/GTK innecesarias — coherente con el objetivo de
#   evitar paquetes redundantes en la instalación.
#
# QUIÉN LO LLAMA:
#   sway.sh, en el bloque "Login manager (greetd + tuigreet)"
#
# PROGRAMAS QUE USA:
#   - greetd (paquete apt, daemon de login)
#   - tuigreet (paquete apt, interfaz de greetd)
#
# NOTA SOBRE EL USUARIO "greeter":
#   El paquete greetd de Debian crea automáticamente el usuario de sistema
#   "greeter" en su postinstalación. No es necesario crearlo a mano.

set -euo pipefail

echo "==> Instalando greetd + tuigreet"
sudo apt-get install -y greetd tuigreet

GREETD_CONFIG="/etc/greetd/config.toml"

echo "==> Escribiendo configuración en $GREETD_CONFIG"
echo "    (sesión por defecto: tuigreet lanzando sway)"

sudo tee "$GREETD_CONFIG" > /dev/null << 'EOF'
# Archivo generado por configure_greetd.sh — editable manualmente si luego
# se desea ajustar tema, vt, o el comando de sesión.

[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd sway"
user = "greeter"
EOF

echo "==> Habilitando el servicio greetd para que arranque en el inicio del sistema"
sudo systemctl enable greetd.service

echo "==> greetd configurado. Al reiniciar, tuigreet pedirá usuario/contraseña"
echo "    y lanzará sway directamente tras autenticar."
echo "    Flags usadas: --time (reloj en pantalla), --remember (recuerda el"
echo "    último usuario que inició sesión)."
