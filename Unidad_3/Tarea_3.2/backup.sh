#!/bin/bash
# Respaldo semanal completo y diario incremental del laboratorio.
set -euo pipefail
umask 077
[[ $EUID -eq 0 ]] || { echo 'Ejecuta con sudo.'; exit 1; }
exec 9>/run/lock/unidad3_backup.lock
flock -n 9 || { echo 'Ya existe otro respaldo en ejecucion.'; exit 1; }
ORIGEN=/srv/unidad3
MEDIO=/mnt/unidad3_respaldos
[[ -d $ORIGEN ]] || { echo 'No existe el origen.'; exit 1; }
[[ -d $MEDIO ]] || { echo 'No existe el medio de respaldo.'; exit 1; }
mountpoint -q "$ORIGEN" || { echo 'El volumen de datos no esta montado.'; exit 1; }
mountpoint -q "$MEDIO" || { echo 'El volumen de respaldo no esta montado.'; exit 1; }
origen_dev=$(findmnt -T "$ORIGEN" -no SOURCE)
destino_dev=$(findmnt -T "$MEDIO" -no SOURCE)
[[ $origen_dev != "$destino_dev" ]] || {
    echo 'El destino no es un volumen secundario montado.'; exit 1;
}
CARPETA="$MEDIO/unidad3"
mkdir -p "$CARPETA/archivos" "$CARPETA/logs" "$CARPETA/estado"
fecha=$(date +%Y%m%d_%H%M%S_%N)
registro="$CARPETA/logs/backup_$fecha.log"
exec > >(tee "$registro") 2>&1
echo "Inicio: $(date -Is)"
echo "Origen: $ORIGEN ($origen_dev)"
echo "Destino: $MEDIO ($destino_dev)"

# La primera ejecución o el domingo inician una cadena nueva.
snap="$CARPETA/estado/incremental.snar"
if [[ ${U3_BACKUP_TIPO:-} == completo || ( ${U3_BACKUP_TIPO:-} != incremental && ( ! -f $snap || $(date +%u) == 7 ) ) ]]; then
    tipo=completo
else
    tipo=incremental
fi
archivo="$CARPETA/archivos/${tipo}_$fecha.tar.gz"
trabajo=$(mktemp "$CARPETA/estado/.trabajo.XXXXXXXX")
trap 'rm -f "$trabajo"' EXIT
if [[ $tipo == incremental ]]; then
    test -f "$snap"
    cp "$snap" "$trabajo"
else
    rm "$trabajo"
fi
tar --acls --xattrs --numeric-owner --listed-incremental="$trabajo" \
    -czf "$archivo" -C /srv unidad3
tar -tzf "$archivo" >/dev/null
sha256sum "$archivo" > "$archivo.sha256"
mv "$trabajo" "$snap"
echo "Tipo: $tipo"
echo "Archivo: $archivo"
echo "Verificación: archivo legible y SHA-256 generado."
echo "Fin: $(date -Is)"
