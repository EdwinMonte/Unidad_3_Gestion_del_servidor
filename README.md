# Unidad 3: Gestión del servidor

Prácticas de laboratorio con Ubuntu Server 26.04.1 LTS en VMware y un cliente Windows 11.

| Actividad | Contenido | Documento |
|---|---|---|
| 3.1 | Altas y bajas, grupos, sudo, horarios y bloqueo de cuentas | [Manual](Unidad_3/Tarea_3.1/docs/Manual_Tarea_3_1.pdf) |
| 3.2 | POSIX, ACL, SGID, sticky bit, cuotas, respaldo y recuperación | [Reporte](Unidad_3/Tarea_3.2/docs/Reporte_Tarea_3_2.pdf) |
| 3.3 | RAID 1, fallo/reconstrucción, Samba y CUPS-PDF por IPP | [Reporte](Unidad_3/Tarea_3.3/docs/Reporte_Tarea_3_3.pdf) |

## Estado de las pruebas

- 3.1: cuentas creadas; carpetas aisladas; cambio inicial; sudo limitado; horarios y bloqueo probados. Baja de ope99 verificada.
- 3.2: límites de usuario y grupo probados; completo e incremental verificados; archivo borrado recuperado; cron ejecutado.
- 3.3: RAID sano tras fallo lógico y reconstrucción; escritura CIFS comprobada; impresión Windows-Ubuntu y prioridades verificadas.

## Reproducción

Leer el documento de cada actividad antes de ejecutar sus scripts. Las operaciones administrativas requieren sudo.
Los instaladores de discos se usan únicamente con discos nuevos vacíos: no repetirlos sobre volúmenes existentes.
El laboratorio conserva las cuentas principales y sus datos para las demostraciones posteriores.
Los scripts de impresión requieren primero enviar los trabajos desde Windows con scripts/prueba_ipp.py
y copiar el jobs_ipp.json producido a evidencias/jobs_ipp.json del servidor. Ajustar IP y rutas según el entorno.
Los registros de ensayo y cierre contienen los resultados reales; los logs anteriores conservan incidencias resueltas.

## Alcance y límites

- Las políticas de horario y bloqueo de la 3.1 afectan a los nuevos accesos SSH de sis01, fin01 y ope01.
- La cuota se aplica al volumen de datos de la 3.2. La retención de cuatro cadenas semanales requiere poda manual.
- RAID simulado con discos virtuales del mismo anfitrión; no sustituye un respaldo externo.
- El montaje CIFS se probó por loopback en Ubuntu; la impresión IPP sí se envió desde Windows.
- La impresión es virtual a PDF; confirmar aceptación con el docente. No se probó impresora física.
- Las horas de los registros y cron se expresan en UTC. La máquina debe estar encendida para ejecutar cron.

## Publicación y videos

Los videos con cámara inferior derecha y sus enlaces de YouTube están pendientes de grabación.
No se incluyen contraseñas temporales, la llave privada SSH ni las credenciales Samba.
Las IP y nombres visibles pertenecen al laboratorio privado; revisar cualquier adaptación antes de publicar.
