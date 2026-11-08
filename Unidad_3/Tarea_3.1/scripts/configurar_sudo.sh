#!/bin/bash
# Autoriza una consulta administrativa concreta al grupo Sistemas.
set -euo pipefail
umask 077

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo."
    exit 1
fi

getent group sistemas > /dev/null
test -x /usr/bin/systemctl

temporal=$(mktemp)
trap 'rm -f "$temporal"' EXIT

# Se especifican el comando y sus argumentos exactos.
# --no-pager evita abrir un visor interactivo con privilegios.
echo '%sistemas ALL=(root) /usr/bin/systemctl --no-pager status ssh.service' > "$temporal"

# Comprobar la regla antes de instalarla.
visudo -cf "$temporal"

install -o root -g root -m 0440 \
    "$temporal" /etc/sudoers.d/unidad3_sistemas

visudo -c
echo "Permiso limitado configurado para Sistemas."
