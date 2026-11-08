#!/bin/bash
# Crea cuentas por lotes a partir del CSV del laboratorio.
set -euo pipefail
umask 077

# Solo el administrador puede crear cuentas.
if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo."
    exit 1
fi

CSV="${1:-config/usuarios.csv}"

if [[ ! -f "$CSV" ]]; then
    echo "No se encontro el archivo: $CSV"
    exit 1
fi

# Validar todos los registros antes de realizar cambios.
if ! awk -F, '
NR == 1 {
    if ($0 != "usuario,nombre,departamento,vigencia_dias") exit 1
    next
}
{
    if (NF != 4) exit 1
    if ($1 !~ /^(sis|fin|ope)[0-9][0-9]$/) exit 1
    if ($2 == "") exit 1
    if ($3 !~ /^(sistemas|finanzas|operaciones)$/) exit 1
    if ($4 !~ /^[1-9][0-9]*$/ || $4 > 365) exit 1
    if (vistos[$1]++) exit 1
}
END { if (NR < 2) exit 1 }
' "$CSV"; then
    echo "CSV invalido. Revisa sus campos y registros."
    exit 1
fi

# Las claves se guardan fuera del proyecto y solo root puede leerlas.
install -d -m 700 /root/unidad3
CLAVES=$(mktemp /root/unidad3/credenciales.XXXXXX)

while IFS=, read -r usuario nombre departamento dias; do
    # No modificar cuentas que ya existen.
    if getent passwd "$usuario" > /dev/null; then
        echo "OMITIDO: $usuario ya existe."
        continue
    fi

    if ! getent group "$departamento" > /dev/null; then
        groupadd "$departamento"
    fi

    vencimiento=$(date -d "+$dias days" +%F)
    clave=$(od -An -N12 -tx1 /dev/urandom | tr -d ' \n')

    # Grupo principal privado y departamento como grupo secundario.
    useradd -m -U -s /bin/bash \
        -c "$nombre" \
        -G "$departamento" \
        -e "$vencimiento" \
        -K UMASK=077 \
        "$usuario"

    chmod 700 "/home/$usuario"
    printf '%s:%s\n' "$usuario" "$clave" | chpasswd

    # Obligar a cambiar la contraseña en el primer inicio de sesión.
    chage -d 0 "$usuario"

    printf '%s:%s\n' "$usuario" "$clave" >> "$CLAVES"
    unset clave
    echo "CREADO: $usuario | Grupo: $departamento | Vence: $vencimiento"
done < <(tail -n +2 "$CSV")

echo "Archivo privado de claves temporales: $CLAVES"
