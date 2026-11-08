#!/bin/bash
# Configura permisos y cuotas sobre los discos ya montados. No formatea.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$BASE"
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 evidencias
LOG="evidencias/permisos_cuotas_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
[[ $(findmnt -n -o SOURCE /srv/unidad3) == /dev/sdb ]]
[[ $(findmnt -n -o SOURCE /mnt/unidad3_respaldos) == /dev/sdc ]]
for grupo in sistemas finanzas operaciones; do getent group "$grupo" >/dev/null; done
for usuario in sis01 fin01 ope01; do getent passwd "$usuario" >/dev/null; done
command -v setfacl >/dev/null
command -v setquota >/dev/null

# Directorio compartido con sticky bit: solo propietario o root borra archivos.
mkdir -p /srv/unidad3/comun
chown root:root /srv/unidad3/comun
chmod 1777 /srv/unidad3/comun

# SGID: archivos nuevos heredan el grupo del departamento.
for grupo in sistemas finanzas operaciones; do
    mkdir -p "/srv/unidad3/$grupo"
    chown "root:$grupo" "/srv/unidad3/$grupo"
    chmod 2770 "/srv/unidad3/$grupo"
done

# Finanzas puede consultar Operaciones, pero no modificar sus archivos.
setfacl -m g:finanzas:rx /srv/unidad3/operaciones
setfacl -m d:g:finanzas:rx /srv/unidad3/operaciones
setfacl -m d:m::rwx /srv/unidad3/operaciones

# Límites en KiB, aplicados al volumen de datos.
setquota -u fin01 30720 40960 0 0 /srv/unidad3
setquota -g finanzas 61440 81920 0 0 /srv/unidad3

echo 'PERMISOS:'
ls -ld /srv/unidad3/comun /srv/unidad3/sistemas /srv/unidad3/finanzas /srv/unidad3/operaciones
echo 'ACL OPERACIONES:'
getfacl -p /srv/unidad3/operaciones
echo 'CUOTAS:'
repquota -ug /srv/unidad3
echo 'CONFIGURACION_3_2_VERIFICADA'
