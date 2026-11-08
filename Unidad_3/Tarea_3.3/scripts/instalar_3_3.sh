#!/bin/bash
# Instala RAID 1, recurso Samba autenticado y una cola virtual CUPS-PDF.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta mediante sudo.'; exit 1; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$BASE"
install -d -o edwinmonte -g "$(id -gn edwinmonte)" -m 750 evidencias config
LOG="evidencias/instalacion_$(date +%Y%m%d_%H%M%S).log"
install -o edwinmonte -g "$(id -gn edwinmonte)" -m 600 /dev/null "$LOG"
exec > >(tee "$LOG") 2>&1
echo "Inicio: $(date -Is)"
MD=/dev/md/unidad3
RAIZ=/srv/raid_unidad3
[[ ! -e $MD ]] || { echo 'El arreglo ya existe. Revisar antes de repetir.'; exit 1; }
for disco in /dev/sdd /dev/sde; do
    [[ -b $disco ]]
    [[ $(lsblk -nrpo TYPE "$disco") == disk ]]
    [[ $(blockdev --getsize64 "$disco") -eq 10737418240 ]]
    [[ -z $(lsblk -nro FSTYPE "$disco") ]]
    [[ -z $(wipefs -n "$disco") ]]
    [[ -z $(findmnt -nS "$disco") ]]
done
[[ $(findmnt -n -o SOURCE /srv/unidad3) == /dev/sdb ]]
[[ $(findmnt -n -o SOURCE /mnt/unidad3_respaldos) == /dev/sdc ]]
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y mdadm samba smbclient cifs-utils cups cups-client printer-driver-cups-pdf
install -d -m 700 /root/unidad3
mdadm --create "$MD" --metadata=1.2 --level=1 --raid-devices=2 --name=unidad3 /dev/sdd /dev/sde --run
echo 'Esperando sincronizacion inicial del RAID...'
mdadm --wait "$MD" || true
nombre=$(basename "$(readlink -f "$MD")")
[[ $(cat "/sys/block/$nombre/md/degraded") == 0 ]]
[[ $(cat "/sys/block/$nombre/md/sync_action") == idle ]]
mdadm --detail "$MD"
mkfs.ext4 -F -L U3_RAID1 "$MD"
mkdir -p "$RAIZ"
uuid=$(blkid -s UUID -o value "$MD")
cp -p /etc/fstab /root/unidad3/fstab.antes_raid
printf 'UUID=%s %s ext4 defaults,nofail 0 2\n' "$uuid" "$RAIZ" >> /etc/fstab
mount "$RAIZ"
cp -p /etc/mdadm/mdadm.conf /root/unidad3/mdadm.conf.antes_raid
mdadm --detail --scan "$MD" > config/mdadm_unidad3.conf
cat config/mdadm_unidad3.conf >> /etc/mdadm/mdadm.conf
update-initramfs -u

echo 'CONFIGURACION SAMBA'
if ! getent passwd u3red >/dev/null; then
    useradd --system --user-group --no-create-home --shell /usr/sbin/nologin u3red
fi
mkdir -p "$RAIZ/compartido"
chown u3red:u3red "$RAIZ/compartido"
chmod 2770 "$RAIZ/compartido"
clave=$(od -An -N18 -tx1 /dev/urandom | tr -d ' \n')
printf '%s\n%s\n' "$clave" "$clave" | smbpasswd -s -a u3red
printf 'username=u3red\npassword=%s\n' "$clave" > /root/unidad3/samba.credentials
chmod 600 /root/unidad3/samba.credentials
unset clave
cp -p /etc/samba/smb.conf /root/unidad3/smb.conf.antes_unidad3
cat > config/smb.conf <<'SMB'
[global]
    workgroup = WORKGROUP
    server role = standalone server
    security = user
    map to guest = Never
    interfaces = lo ens33
    bind interfaces only = yes
    hosts allow = 127.0.0.1 192.168.246.0/24
    server min protocol = SMB2

[Unidad3]
    path = /srv/raid_unidad3/compartido
    browseable = yes
    read only = no
    valid users = u3red
    create mask = 0660
    directory mask = 2770
SMB
testparm -s config/smb.conf
install -o root -g root -m 644 config/smb.conf /etc/samba/smb.conf
systemctl enable --now smbd
systemctl restart smbd
mkdir -p /mnt/unidad3_red
mount -t cifs //127.0.0.1/Unidad3 /mnt/unidad3_red -o credentials=/root/unidad3/samba.credentials,vers=3.0
printf '%s\n' '//127.0.0.1/Unidad3 /mnt/unidad3_red cifs credentials=/root/unidad3/samba.credentials,vers=3.0,_netdev,nofail,x-systemd.automount,x-systemd.requires=smbd.service 0 0' >> /etc/fstab
printf 'Prueba de escritura mediante SMB\n' > /mnt/unidad3_red/prueba_red.txt
cmp /mnt/unidad3_red/prueba_red.txt "$RAIZ/compartido/prueba_red.txt"
findmnt /mnt/unidad3_red
echo 'OK: recurso Samba montado mediante CIFS y escritura verificada.'

echo 'CONFIGURACION CUPS'
systemctl enable --now cups
modelo=$(lpinfo -m | awk 'tolower($0) ~ /cups-pdf/ && !encontrado {print $1; encontrado=1}')
[[ -n $modelo ]] || { echo 'No se encontro el controlador CUPS-PDF.'; exit 1; }
echo "Controlador seleccionado: $modelo"
lpadmin -p U3_PDF -E -v cups-pdf:/ -m "$modelo"
cupsctl --share-printers
lpadmin -p U3_PDF -o printer-is-shared=true
lpstat -p U3_PDF -l
lpstat -v U3_PDF
cp /etc/cups/cupsd.conf config/cupsd.conf
chown -R edwinmonte:"$(id -gn edwinmonte)" config
echo 'INSTALACION_3_3_TERMINADA'
