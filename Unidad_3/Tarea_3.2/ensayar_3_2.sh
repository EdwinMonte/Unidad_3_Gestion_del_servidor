#!/bin/bash
# Valida ACL, sticky bit, SGID, cuotas, respaldo y restauración.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$BASE"
[[ $(findmnt -n -o SOURCE /srv/unidad3) == /dev/sdb ]]
[[ $(findmnt -n -o SOURCE /mnt/unidad3_respaldos) == /dev/sdc ]]
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 evidencias
LOG="evidencias/ensayo_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo "Inicio: $(date -Is)"
echo 'ESTADO DE PERMISOS Y CUOTAS'
ls -ld /srv/unidad3/comun /srv/unidad3/{sistemas,finanzas,operaciones}
getfacl -p /srv/unidad3/operaciones
repquota -ug /srv/unidad3

echo 'PRUEBA SGID Y ACL'
runuser -u ope01 -- sh -c "printf 'Lectura autorizada para Finanzas.\n' > /srv/unidad3/operaciones/acl_prueba.txt"
stat -c 'Archivo: %n Propietario: %U Grupo: %G' /srv/unidad3/operaciones/acl_prueba.txt
runuser -u fin01 -- cat /srv/unidad3/operaciones/acl_prueba.txt
if runuser -u fin01 -- sh -c "printf 'No autorizado\n' >> /srv/unidad3/operaciones/acl_prueba.txt"; then
    echo 'ERROR: Finanzas pudo modificar el archivo de Operaciones.'; exit 1
fi
echo 'OK: Finanzas lee, pero no modifica el archivo de Operaciones.'

echo 'PRUEBA STICKY BIT'
runuser -u fin01 -- sh -c "printf 'Archivo de Finanzas\n' > /srv/unidad3/comun/sticky_prueba.txt"
if runuser -u ope01 -- rm -f -- /srv/unidad3/comun/sticky_prueba.txt </dev/null; then
    echo 'ERROR: Operaciones borró un archivo ajeno.'; exit 1
fi
test -f /srv/unidad3/comun/sticky_prueba.txt
rm /srv/unidad3/comun/sticky_prueba.txt
echo 'OK: Operaciones no pudo borrar el archivo ajeno.'

echo 'PRUEBA CUOTA DE USUARIO'
if runuser -u fin01 -- dd if=/dev/zero of=/srv/unidad3/finanzas/cuota_prueba.bin bs=1M count=45 status=none; then
    echo 'ERROR: la cuota de 40 MiB no se aplicó.'; exit 1
fi
stat -c 'Archivo parcial (bytes): %s' /srv/unidad3/finanzas/cuota_prueba.bin
repquota -ug /srv/unidad3
rm /srv/unidad3/finanzas/cuota_prueba.bin
echo 'OK: el límite de usuario detuvo la escritura.'

echo 'PRUEBA CUOTA DE GRUPO'
# sis01 no tiene cuota individual aquí; se ejecuta con el grupo Finanzas.
if runuser -u sis01 -g finanzas -- dd if=/dev/zero of=/srv/unidad3/finanzas/cuota_grupo_prueba.bin bs=1M count=85 status=none; then
    echo 'ERROR: la cuota de grupo de 80 MiB no se aplicó.'; exit 1
fi
stat -c 'Archivo parcial: %s bytes, usuario %U, grupo %G' /srv/unidad3/finanzas/cuota_grupo_prueba.bin
repquota -ug /srv/unidad3
rm /srv/unidad3/finanzas/cuota_grupo_prueba.bin
echo 'OK: el límite del grupo detuvo la escritura.'

echo 'PRUEBA RESPALDO Y RESTAURACIÓN'
runuser -u fin01 -- sh -c "printf 'version inicial\n' > /srv/unidad3/finanzas/recuperacion_prueba.txt"
U3_BACKUP_TIPO=completo bash "$BASE/backup.sh"
completo=$(ls -t /mnt/unidad3_respaldos/unidad3/archivos/completo_*.tar.gz | head -n 1)
runuser -u fin01 -- sh -c "printf 'version actualizada\n' > /srv/unidad3/finanzas/recuperacion_prueba.txt"
U3_BACKUP_TIPO=incremental bash "$BASE/backup.sh"
incremental=$(ls -t /mnt/unidad3_respaldos/unidad3/archivos/incremental_*.tar.gz | head -n 1)
sha256sum -c "$completo.sha256"
sha256sum -c "$incremental.sha256"
rm /srv/unidad3/finanzas/recuperacion_prueba.txt
restauracion=$(mktemp -d /tmp/unidad3_restauracion.XXXXXXXX)
tar --acls --xattrs --listed-incremental=/dev/null -xzf "$completo" -C "$restauracion"
tar --acls --xattrs --listed-incremental=/dev/null -xzf "$incremental" -C "$restauracion"
cat "$restauracion/unidad3/finanzas/recuperacion_prueba.txt"
grep -Fxq 'version actualizada' "$restauracion/unidad3/finanzas/recuperacion_prueba.txt"
test ! -e /srv/unidad3/finanzas/recuperacion_prueba.txt
echo 'OK: se recuperó la versión actualizada desde los respaldos en el disco secundario.'

echo 'PROGRAMACIÓN'
printf '%s\n' '0 2 * * * root /bin/bash /home/edwinmonte/Unidad_3/Tarea_3.2/backup.sh' > config_cron.txt
install -o root -g root -m 644 config_cron.txt /etc/cron.d/unidad3_backup
systemctl is-active cron
cat /etc/cron.d/unidad3_backup
echo 'ENSAYO_3_2_TERMINADO'
