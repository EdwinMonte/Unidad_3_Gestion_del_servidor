#!/bin/bash
# Configura el bloqueo de las cuentas de practica por SSH.
set -euo pipefail
umask 077

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo."
    exit 1
fi

BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
PAM=/etc/pam.d/sshd
RESPALDO=/root/unidad3/sshd.pam.antes_bloqueo

# Comprobar archivos y modulos antes de instalar.
test -f "$BASE/config/faillock_unidad3.conf"
test -f "$BASE/config/unidad3-ssh-auth"

for modulo in pam_faillock pam_succeed_if pam_unix pam_permit pam_deny; do
    test -f "/usr/lib/x86_64-linux-gnu/security/$modulo.so"
done

# Admitir la configuracion original o una ejecucion previa del script.
cantidad=$(grep -Ec '^@include[[:space:]]+common-auth[[:space:]]*$|^auth[[:space:]]+substack[[:space:]]+unidad3-ssh-auth[[:space:]]*$' "$PAM" || true)
if [[ "$cantidad" != 1 ]]; then
    echo "Configuracion SSH inesperada. No se realizaron cambios."
    exit 1
fi

install -d -m 700 /root/unidad3
if [[ ! -e "$RESPALDO" ]]; then
    cp -p "$PAM" "$RESPALDO"
fi

install -o root -g root -m 0644 \
    "$BASE/config/faillock_unidad3.conf" \
    /etc/security/faillock_unidad3.conf

install -o root -g root -m 0644 \
    "$BASE/config/unidad3-ssh-auth" \
    /etc/pam.d/unidad3-ssh-auth

temporal=$(mktemp)
trap 'rm -f "$temporal"' EXIT

# Sustituir solamente la entrada de autenticacion de SSH.
# Se conservan las reglas de cuenta, horario, sesion y contraseña.
sed -E 's/^@include[[:space:]]+common-auth[[:space:]]*$/auth substack unidad3-ssh-auth/' \
    "$PAM" > "$temporal"

install -o root -g root -m 0644 "$temporal" "$PAM"

echo "Configuracion instalada; falta comprobarla con inicios de sesion."
echo "Respaldo anterior: $RESPALDO"
