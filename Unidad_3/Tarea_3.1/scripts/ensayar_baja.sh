#!/bin/bash
# Ensayo completo sobre ope99; no modifica las tres cuentas base.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta con sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BASE"
[[ ${SUDO_USER:-} == edwinmonte ]] || { echo 'Ejecuta desde edwinmonte mediante sudo.'; exit 1; }
if getent passwd ope99 >/dev/null || [[ -e /home/ope99 || -L /home/ope99 ]]; then
    echo 'ope99 o su carpeta ya existen. Detenido para evitar sobrescribir datos.'; exit 1
fi
mkdir -p evidencias
LOG="evidencias/ensayo_baja_$(date +%Y%m%d_%H%M%S).txt"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo 'ENSAYO DE ALTA Y BAJA - UNIDAD 3.1'
date -Is
csv=$(mktemp)
trap 'rm -f "$csv"' EXIT
printf '%s\n' 'usuario,nombre,departamento,vigencia_dias' 'ope99,Cuenta para ensayo de baja,operaciones,1' > "$csv"
bash scripts/alta_usuarios.sh "$csv"
id ope99
ls -ld /home/ope99
printf '%s\n' 'Archivo de prueba que debe conservarse despues de la baja.' > /home/ope99/evidencia_baja.txt
chown ope99:ope99 /home/ope99/evidencia_baja.txt
bash scripts/baja_usuarios.sh ope99
if getent passwd ope99 >/dev/null || [[ -e /home/ope99 ]]; then
    echo 'ERROR: la baja no quedo completa.'; exit 1
fi
echo 'OK: ope99 ya no existe y su home fue retirado del directorio /home.'
echo 'COMPROBACION DE CUENTAS BASE'
for usuario in sis01 fin01 ope01; do id "$usuario"; done
echo 'ENSAYO TERMINADO CORRECTAMENTE'
echo "Evidencia: $BASE/$LOG"
