#!/bin/bash
# Instala una prueba unica que sera lanzada por cron en el siguiente minuto.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Ejecuta con sudo.'; exit 1; }
BASE=/home/edwinmonte/Unidad_3/Tarea_3.2
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 "$BASE/evidencias"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$BASE/evidencias/prueba_cron.log"
cat > /usr/local/sbin/unidad3_prueba_cron <<'RUNNER'
#!/bin/bash
set -euo pipefail
exec 8>/run/lock/unidad3_prueba_cron.lock
flock -n 8 || exit 0
# Retirar exclusivamente la programacion temporal de esta prueba.
rm -f /etc/cron.d/unidad3_prueba
BASE=/home/edwinmonte/Unidad_3/Tarea_3.2
exec > "$BASE/evidencias/prueba_cron.log" 2>&1
echo "Ejecucion calendarizada iniciada: $(date -Is)"
/bin/bash "$BASE/backup.sh"
echo "CRON_RESPALDO_VERIFICADO: $(date -Is)"
RUNNER
chown root:root /usr/local/sbin/unidad3_prueba_cron
chmod 700 /usr/local/sbin/unidad3_prueba_cron
printf '%s\n' '* * * * * root /usr/local/sbin/unidad3_prueba_cron' > /etc/cron.d/unidad3_prueba
chmod 644 /etc/cron.d/unidad3_prueba
systemctl is-active cron
echo 'PRUEBA_PROGRAMADA: se ejecutara una vez en el siguiente minuto.'
