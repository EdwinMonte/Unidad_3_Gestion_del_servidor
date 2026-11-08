#!/bin/bash
# Retoma solamente CUPS; conserva las pruebas RAID ya realizadas.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BASE"
LOG="evidencias/impresion_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo "Inicio: $(date -Is)"
echo 'DIAGNOSTICO DEL ERROR ANTERIOR'
tail -n 100 /var/log/cups/error_log
echo 'REINTENTO DE PAUSA CON MOTIVO EXPLICITO'
if ! cupsdisable -r 'Prueba de prioridades Unidad 3' U3_PDF; then
    echo 'Reiniciando el planificador antes de repetir la pausa.'
    systemctl restart cups
    sleep 3
    cupsdisable -r 'Prueba de prioridades Unidad 3' U3_PDF
fi
trap 'cupsenable U3_PDF || true' EXIT
lpstat -p U3_PDF -l
baja=$(python3 -c 'import json; print(int(next(j["job-id"] for j in json.load(open("evidencias/jobs_ipp.json")) if j["job-priority"]==10)))')
alta=$(python3 -c 'import json; print(int(next(j["job-id"] for j in json.load(open("evidencias/jobs_ipp.json")) if j["job-priority"]==90)))')
lp -i "U3_PDF-$baja" -H resume
lp -i "U3_PDF-$alta" -H resume
echo 'AMBOS TRABAJOS LISTOS, IMPRESORA AUN PAUSADA'
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
    chown edwinmonte:"$(id -gn edwinmonte)" "evidencias/$archivo"
    stat -c 'PDF generado: %n (%s bytes)' "$f"
done
lpstat -W completed -o U3_PDF
grep -E "\\[Job ($baja|$alta)\\]" /var/log/cups/error_log | tail -n 180 > evidencias/cups_prioridades.log || true
chown edwinmonte:"$(id -gn edwinmonte)" evidencias/cups_prioridades.log
cupsctl --no-debug-logging
echo 'ENSAYO_3_3_TERMINADO'
