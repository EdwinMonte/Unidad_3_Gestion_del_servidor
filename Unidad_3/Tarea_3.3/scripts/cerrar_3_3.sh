#!/bin/bash
# Recoge evidencia administrativa sin repetir las pruebas.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta con sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BASE"
LOG=evidencias/cierre_3_3.log
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo "Verificacion final: $(date -Is)"
mdadm --detail /dev/md/unidad3
sha256sum -c evidencias/raid.sha256
findmnt /mnt/unidad3_red
lpstat -p U3_PDF -l
lpstat -W completed -o U3_PDF
for f in Red_Windows_PDF__DF.pdf Prioridad_alta.pdf Prioridad_baja.pdf; do
    test -s "/home/edwinmonte/PDF/$f"
    head -c 5 "/home/edwinmonte/PDF/$f" | grep -q '%PDF-'
    cp "/home/edwinmonte/PDF/$f" "evidencias/$f"
    chown edwinmonte:"$(id -gn edwinmonte)" "evidencias/$f"
    echo "PDF comprobado: $f"
done
grep -E '\[Job (2|3)\]' /var/log/cups/error_log | tail -n 250 > evidencias/cups_prioridades.log || true
chown edwinmonte:"$(id -gn edwinmonte)" evidencias/raid.sha256 evidencias/cups_prioridades.log
chmod 600 evidencias/raid.sha256 evidencias/cups_prioridades.log
cupsctl --no-debug-logging
echo 'ENSAYO_3_3_TERMINADO'
