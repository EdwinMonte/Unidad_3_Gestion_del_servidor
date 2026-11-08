# Unidad 3 / Tarea 3.1

Scripts y evidencia del laboratorio Ubuntu Server 26.04.1 LTS.
Consultar Manual_Tarea_3_1.pdf para procedimiento, alcance y validación.

## Ejecución
Desde Unidad_3/Tarea_3.1, usar sudo para scripts administrativos.
Las cuentas base son sis01, fin01 y ope01. El ensayo de baja usa ope99.
Las políticas PAM de horarios y fallos afectan solo a las tres cuentas base por SSH.
Horario normal: lunes a viernes 08:00-18:00 UTC.
Los archivos horarios_prueba_* son exclusivamente para ensayos temporales.
Restaurar siempre con scripts/configurar_horarios.sh.

## Datos privados
No publicar /root/unidad3/credenciales.*, llaves privadas ni contraseñas.
Las evidencias incluidas contienen nombres e IP privadas del laboratorio.
Revisar las capturas antes de hacer público el repositorio.

## Estado
Ensayo técnico realizado; publicación de GitHub y video pendientes.
La baja conserva los datos en /root/unidad3/bajas y no borra los home respaldados.
