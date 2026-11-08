#!/bin/bash
# Baja de una cuenta de laboratorio, con respaldo y conservacion del home.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta con sudo.'; exit 1; }
[[ $# -eq 1 ]] || { echo 'Uso: baja_usuarios.sh usuario'; exit 1; }
usuario=$1
[[ $usuario =~ ^(sis|fin|ope)[0-9]{2}$ ]] || { echo 'Nombre ajeno al laboratorio.'; exit 1; }
case "$usuario" in
    sis01|fin01|ope01) echo 'Cuenta base protegida para las demostraciones.'; exit 1 ;;
esac
registro=$(awk -F: -v u="$usuario" '$1==u {print}' /etc/passwd)
[[ -n $registro ]] || { echo 'La cuenta local no existe.'; exit 1; }
IFS=: read -r nombre clave uid gid comentario carpeta shell <<< "$registro"
[[ $uid -ge 1000 && $carpeta == "/home/$usuario" ]] || exit 1
[[ -d $carpeta && ! -L $carpeta ]] || { echo 'Home inesperado.'; exit 1; }
if mountpoint -q "$carpeta"; then
    echo 'El home es un punto de montaje; revisar manualmente.'; exit 1
fi
if pgrep -u "$uid" >/dev/null; then
    echo 'Hay procesos activos de la cuenta. Cierra su sesion primero.'; exit 1
fi

install -d -m 700 /root/unidad3/bajas
destino=$(mktemp -d "/root/unidad3/bajas/${usuario}.XXXXXXXX")
# Deshabilitar nuevas autenticaciones antes del respaldo y la baja.
usermod -L -e 1970-01-02 -s /usr/sbin/nologin "$usuario"
tar --acls --xattrs --numeric-owner -czf "$destino/home.tar.gz" -C /home "$usuario"
tar -tzf "$destino/home.tar.gz" > "$destino/contenido.txt"
sha256sum "$destino/home.tar.gz" > "$destino/SHA256SUMS"
printf '%s\n' "$registro" > "$destino/cuenta.txt"
id "$usuario" > "$destino/grupos.txt"

# userdel sin -r: conservar los archivos y trasladarlos a una carpeta privada.
userdel "$usuario"
mv -- "$carpeta" "$destino/home_conservado"
if getent passwd "$usuario" >/dev/null; then
    echo 'ERROR: la cuenta sigue registrada.'; exit 1
fi
echo "BAJA VERIFICADA: $usuario"
echo "Respaldo y archivos conservados en: $destino"
