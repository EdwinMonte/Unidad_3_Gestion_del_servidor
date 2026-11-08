# Política de respaldo - laboratorio Unidad 3

Origen: /srv/unidad3. Destino: disco virtual secundario en /mnt/unidad3_respaldos.

- Respaldo completo: domingo 02:00 UTC; también la primera ejecución.
- Incremental: lunes a sábado 02:00 UTC.
- RPO objetivo: 24 horas (pérdida máxima prevista desde el último respaldo programado).
- RTO objetivo: 2 horas para recuperar un archivo pequeño del laboratorio.
- Verificación por ejecución: listado íntegro del tar y suma SHA-256.
- Retención propuesta: cuatro cadenas semanales completas e incrementales asociados.

La retención requiere un procedimiento de poda verificado antes de automatizar borrados.
Los objetivos RPO/RTO se considerarán demostrados solo tras una prueba de programación y restauración.
El disco secundario es otro volumen virtual; si reside físicamente en el mismo equipo,
no protege frente a pérdida total de ese equipo. La práctica debe documentar esta limitación.
