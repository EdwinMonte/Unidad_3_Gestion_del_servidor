#!/bin/bash
# Ensayo de fallo logico/reconstruccion de RAID y prioridades de impresion.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BASE"
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 evidencias
LOG="evidencias/ensayo_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
MD=/dev/md/unidad3
nombre=$(basename "$(readlink -f "$MD")")
[[ $(cat "/sys/block/$nombre/md/level") == raid1 ]]
[[ $(cat "/sys/block/$nombre/md/degraded") == 0 ]]
test -e "/sys/block/$nombre/slaves/sde"
[[ $(findmnt -no SOURCE /srv/raid_unidad3) == "$(readlink -f "$MD")" ]]
echo "Inicio: $(date -Is)"
echo 'ESTADO SANO'
mdadm --detail "$MD"
printf 'Integridad RAID 1 - Unidad 3.3\n' > /srv/raid_unidad3/validacion_raid.txt
sha256sum /srv/raid_unidad3/validacion_raid.txt > evidencias/raid.sha256
sync
# Si el ensayo falla, intentar reincorporar el miembro retirado.
recuperar() {
    resultado=$?
    if [[ $(cat "/sys/block/$nombre/md/degraded") != 0 ]]; then
        echo 'Intentando reincorporar sde tras una interrupcion del ensayo.'
        mdadm "$MD" --add /dev/sde || true
    fi
    exit "$resultado"
}
trap recuperar EXIT
echo 'SIMULACION: FALLO LOGICO Y RETIRO DE SDE'
mdadm "$MD" --fail /dev/sde --remove /dev/sde
mdadm --detail "$MD"
cat /proc/mdstat
[[ $(cat "/sys/block/$nombre/md/degraded") == 1 ]]
sha256sum -c evidencias/raid.sha256
printf 'Escritura con RAID degradado\n' > /srv/raid_unidad3/escritura_degradado.txt
sync
echo 'REINCORPORACION Y RECONSTRUCCION'
mdadm "$MD" --add /dev/sde
cat /proc/mdstat
mdadm --wait "$MD" || true
[[ $(cat "/sys/block/$nombre/md/degraded") == 0 ]]
[[ $(cat "/sys/block/$nombre/md/sync_action") == idle ]]
mdadm --detail "$MD"
sha256sum -c evidencias/raid.sha256
grep -Fxq 'Escritura con RAID degradado' /srv/raid_unidad3/escritura_degradado.txt
echo 'OK: RAID reconstruido, lectura y escritura verificadas.'

echo 'RECURSO DE RED'
findmnt /mnt/unidad3_red
cat /mnt/unidad3_red/prueba_red.txt

echo 'COLA DE IMPRESION Y PRIORIDADES'
lpstat -p U3_PDF -l
lpstat -o U3_PDF
cupsctl --debug-logging
cupsdisable -r 'Prueba de prioridades Unidad 3' U3_PDF
# Ambos trabajos fueron enviados desde Windows por IPP, con prioridades 10 y 90.
baja=$(python3 -c 'import json; print(int(next(j["job-id"] for j in json.load(open("evidencias/jobs_ipp.json")) if j["job-priority"]==10)))')
alta=$(python3 -c 'import json; print(int(next(j["job-id"] for j in json.load(open("evidencias/jobs_ipp.json")) if j["job-priority"]==90)))')
lp -i "U3_PDF-$baja" -H resume
lp -i "U3_PDF-$alta" -H resume
lpstat -o U3_PDF
cupsenable U3_PDF
for intento in $(seq 1 45); do
    if [[ -f /home/edwinmonte/PDF/Prioridad_alta.pdf && -f /home/edwinmonte/PDF/Prioridad_baja.pdf ]]; then break; fi
    sleep 1
done
for archivo in Red_Windows_PDF__DF.pdf Prioridad_alta.pdf Prioridad_baja.pdf; do
    f="/home/edwinmonte/PDF/$archivo"
    test -s "$f"
    head -c 5 "$f" | grep -q '%PDF-'
    cp "$f" "evidencias/$archivo"
    stat -c 'PDF generado: %n (%s bytes)' "$f"
done
lpstat -W completed -o U3_PDF
grep -E "\\[Job ($baja|$alta)\\]" /var/log/cups/error_log | tail -n 120 > evidencias/cups_prioridades.log || true
cupsctl --no-debug-logging
chown edwinmonte:"$(id -gn edwinmonte)" evidencias/raid.sha256 evidencias/*.pdf evidencias/cups_prioridades.log
chmod 600 evidencias/raid.sha256 evidencias/*.pdf evidencias/cups_prioridades.log
echo 'ENSAYO_3_3_TERMINADO'
