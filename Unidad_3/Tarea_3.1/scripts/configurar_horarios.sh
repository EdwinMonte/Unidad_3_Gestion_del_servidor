#!/bin/bash
# Instala la restriccion de horario SSH del laboratorio.
set -euo pipefail
umask 077

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo."
    exit 1
fi

BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ORIGEN="$BASE/config/horarios.conf"
DESTINO=/etc/security/unidad3-time.conf
PAM=/etc/pam.d/sshd
RESPALDO=/root/unidad3/sshd.pam.antes_horarios

# Comprobar los archivos necesarios antes de modificar PAM.
test -f "$ORIGEN"
test -f "$PAM"
test -f /usr/lib/x86_64-linux-gnu/security/pam_time.so

install -d -m 700 /root/unidad3

# Conservar la configuracion anterior en la primera ejecucion.
if [[ ! -e "$RESPALDO" ]]; then
    cp -p "$PAM" "$RESPALDO"
fi

install -o root -g root -m 0644 "$ORIGEN" "$DESTINO"

# Agregar la regla una sola vez.
REGLA="account required pam_time.so conffile=$DESTINO"
if ! grep -Fxq "$REGLA" "$PAM"; then
    printf '\n%s\n' "$REGLA" >> "$PAM"
fi

echo "Politica instalada: lunes a viernes, 08:00 a 18:00 UTC."
echo "Usuarios: sis01, fin01 y ope01."
