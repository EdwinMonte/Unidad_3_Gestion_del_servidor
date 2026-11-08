# Unidad 3 / Tarea 3.3 - preparación del laboratorio

Servidor: Ubuntu 26.04.1 LTS en VMware.

## Almacenamiento existente (conservar)
- /dev/sda: sistema de 25 GB.
- /dev/sdb: datos y cuotas de la tarea 3.2, 10 GB.
- /dev/sdc: respaldo secundario de la tarea 3.2, 10 GB.

## Nuevo almacenamiento necesario
Dos discos virtuales nuevos y vacíos para RAID 1.
Se identificarán de nuevo por tamaño, firmas, particiones y montajes antes de usarlos.
El RAID tendrá aproximadamente la capacidad de un solo miembro.

## Pruebas previstas
1. Crear RAID 1 con mdadm, montar mediante UUID y guardar configuración.
2. Registrar el estado limpio y la suma SHA-256 de un archivo de prueba.
3. Simular fallo lógico y retirar un miembro con mdadm; comprobar lectura.
4. Reincorporar el miembro y esperar reconstrucción; verificar integridad.
5. Compartir una carpeta mediante Samba y montar el recurso mediante CIFS.
6. Configurar CUPS, una cola compartida por IPP y trabajos de distinta prioridad.
7. Verificar la recepción de un trabajo desde otro equipo por TCP/IP.

La elección del destino físico o virtual de impresión está pendiente de la respuesta del alumno.
La simulación de RAID es de laboratorio: discos virtuales en un mismo anfitrión
no ofrecen independencia frente al fallo físico de ese anfitrión.
