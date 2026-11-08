#!/bin/bash
# Prepara dos discos virtuales NUEVOS para datos y respaldos.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
DATOS=/dev/sdb
RESPALDOS=/dev/sdc
ORIGEN=/srv/unidad3
DESTINO=/mnt/unidad3_respaldos
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$BASE"
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 evidencias
LOG="evidencias/preparacion_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo "Inicio: $(date -Is)"
echo 'Discos detectados:'
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS
[[ $(findmnt -no SOURCE /) != "$DATOS" && $(findmnt -no SOURCE /) != "$RESPALDOS" ]]
for disco in "$DATOS" "$RESPALDOS"; do
    [[ -b $disco ]]
    [[ $(lsblk -nrpo TYPE "$disco") == disk ]]
    [[ $(blockdev --getsize64 "$disco") -ge 9000000000 ]]
    [[ $(blockdev --getsize64 "$disco") -le 12000000000 ]]
    [[ -z $(lsblk -nro FSTYPE "$disco") ]]
    [[ -z $(wipefs -n "$disco") ]]
    [[ -z $(findmnt -nS "$disco") ]]
done
echo 'Verificación: sdb y sdc sin particiones, firmas ni montajes; ambos de aproximadamente 10 GB.'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y acl quota
mkfs.ext4 -F -L U3_DATOS "$DATOS"
mkfs.ext4 -F -L U3_BACKUP "$RESPALDOS"
mkdir -p "$ORIGEN" "$DESTINO"
ud=$(blkid -s UUID -o value "$DATOS")
ur=$(blkid -s UUID -o value "$RESPALDOS")
cp -p /etc/fstab "/root/unidad3/fstab.antes_3_2.$(date +%Y%m%d_%H%M%S)"
printf 'UUID=%s %s ext4 defaults,usrquota,grpquota 0 2\n' "$ud" "$ORIGEN" >> /etc/fstab
printf 'UUID=%s %s ext4 defaults 0 2\n' "$ur" "$DESTINO" >> /etc/fstab
mount "$ORIGEN"
mount "$DESTINO"
chmod 700 "$DESTINO"
quotacheck -cugm "$ORIGEN"
quotaon -vug "$ORIGEN"
echo 'Montajes preparados:'
findmnt "$ORIGEN"
findmnt "$DESTINO"
echo 'Estado inicial de cuotas:'
repquota -ug "$ORIGEN"
echo 'PREPARACION_3_2_TERMINADA'
