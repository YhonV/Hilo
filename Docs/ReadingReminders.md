# Recordatorios de lectura

Acceso: Perfil → engranaje → Recordatorios de lectura.

## Regla de esta primera versión

- Desactivado por defecto. Un recordatorio diario, a las 20:00 inicialmente; hora editable.
- Solo se programa si la cuenta tiene al menos un libro con `status_id = 1` (Leyendo).
- Una sola notificación para todas las lecturas, sin títulos privados en el mensaje.
- Se cancela al desactivar, cerrar sesión, revocar permisos o terminar/quitar la última lectura activa.
- Si la preferencia sigue activada, se reanuda al empezar otra lectura o recuperar el permiso.
- Preferencia, hora y último estado conocido de la biblioteca se guardan por cuenta en este dispositivo.
- El horario sigue la hora local del dispositivo. Registrar progreso no omite el recordatorio del día.
- La programación usa UserNotifications; no requiere servidor ni permisos de push remoto.
- Los cambios de biblioteca hechos desde otro dispositivo se reflejan cuando se carga una nueva biblioteca; una notificación local no consulta el servidor antes de entregarse.
- Al tocar la notificación se abre Hilo; esta versión no navega a un libro específico.

## Verificación automatizada

`python3 Tests/check_reading_reminders.py`

Ejecuta el coordinador real con un centro de notificaciones simulado: activación voluntaria, permisos, hora, cancelación por ausencia de lecturas, desactivación, aislamiento de cuentas, persistencia, error de programación y cierre de sesión durante una programación pendiente.

`python3 Tests/check_localization.py`

## Prueba manual pendiente en iPhone

1. Con un libro en Leyendo, abrir el módulo y activar. Aceptar el permiso.
2. Elegir una hora unos minutos después y enviar Hilo al fondo. Confirmar recepción de una única notificación (los modos de concentración y los ajustes de iOS pueden silenciarla).
3. Cambiar la hora; comprobar que no llega una segunda notificación a la hora anterior.
4. Desactivar antes de la hora programada; confirmar que no llega.
5. Activar y terminar/quitar la última lectura; verificar el estado sin lecturas y ausencia de entrega. Empezar otra lectura y comprobar reanudación.
6. Rechazar permisos en una instalación nueva; confirmar estado bloqueado y acceso a Ajustes. Permitir desde Ajustes y volver a Hilo.
7. Revocar permisos desde Ajustes y regresar; verificar que el módulo deja de indicar programación activa.
8. Cerrar sesión antes de la entrega; confirmar cancelación. Entrar con otra cuenta y comprobar sus valores iniciales. Volver a la primera y comprobar su hora guardada.
9. Cerrar y abrir la app; verificar persistencia. Repetir sin red después de haber cargado la biblioteca.

La prueba automatizada no demuestra entrega física de banners ni interacción con el diálogo nativo de permisos.

## Recordatorio por inactividad

Acceso en el mismo módulo, sección **Retomar el hábito**, desactivado por defecto e independiente del aviso diario.

- Criterio: 3 días calendario sin actividad, configurable a 7. Usa la misma hora local que el aviso diario (20:00 inicialmente).
- Actividad: empezar/retomar, avanzar páginas o finalizar un libro. Abrir la app, ver libros o guardar citas no cuenta.
- Se consulta `get_calendar_activities` desde CalendarService y se toma la fecha máxima de actividad distinta de cita. La consulta reutiliza el RPC autenticado existente y no requiere migración. Actualmente recupera el historial; para bibliotecas grandes conviene agregar un RPC agregado de última actividad.
- Los avances locales exitosos reinician el plazo inmediatamente; los fallos al guardar y correcciones de página hacia atrás no lo reinician localmente.
- Sin historial se usa la fecha de activación. Si la primera consulta falla y no hay datos guardados, no se programa hasta poder consultar o registrar lectura.
- No requiere libros en Leyendo: también permite volver al hábito después de terminar todos los libros.
- Un aviso no repetitivo por período. La fecha prevista se conserva por cuenta para que abrir o reiniciar la app no posponga ni repita el aviso. Una nueva actividad reinicia el período; cambiar el plazo/hora o reactivar la opción vuelve a calcular la programación.
- Si al activarlo ya pasó el plazo, se usa la próxima ocurrencia de la hora elegida, sin aviso inmediato.
- Desactivar o cerrar sesión cancela el aviso. Los permisos son los mismos del recordatorio diario; se revisan al volver a primer plano.
- Si están activadas ambas opciones, cada una puede generar su propio aviso.
- Las actividades de otro dispositivo se conocen al volver a primer plano o consultar la biblioteca. Una notificación local no puede consultar el servidor con la app cerrada.

### Validación de inactividad

Las pruebas automatizadas cubren fechas controladas, 3/7 días, cuentas sin historial, errores de consulta, avances locales frente a resultados antiguos del servidor, permisos revocados, cancelación, vencimiento del plazo y ausencia de repetición después de relanzar la app. También se conserva la regresión del recordatorio diario.

Pendiente en iPhone:

1. Activar solo inactividad; comprobar solicitud de permiso, fecha de última actividad y próximo aviso.
2. Con una cuenta cuya última lectura sea de hace más de 3 días, seleccionar una hora unos minutos posterior y enviar la app al fondo; comprobar una sola entrega.
3. Antes de la entrega, avanzar páginas: el aviso anterior debe cancelarse y la fecha debe pasar al tercer día calendario desde hoy.
4. Cambiar a 7 días y revisar la fecha. Desactivar y comprobar cancelación.
5. Abrir/cerrar la app antes y después del aviso: no debe posponerlo ni generar otro para el mismo período.
6. Probar permiso denegado, cambio de cuenta y cuenta sin historial, además de desconexión al consultar por primera vez.

## Meta semanal de páginas

Acceso: Perfil → Recordatorios de lectura → Meta semanal. La meta inicial es de 100 páginas y se puede editar entre 10 y 5000 en pasos de 10. El interruptor de avisos es independiente y viene desactivado. Meta y preferencia se guardan por cuenta en este dispositivo.

### Datos y cálculo

- Semana local fija: lunes a las 00:00 hasta el siguiente lunes, límite final excluido.
- Fuente: `reading_logs.pages_read`, unido a `user_book` y filtrado por `user_book.user_id` de la sesión.
- Se suman todos los registros de `log_date` dentro de la semana, con paginación. No se usa la página actual acumulada de los libros.
- Las correcciones negativas restan. El total mostrado se limita a un mínimo de cero; el porcentaje visual, a un máximo de 100 %. Se muestra el total real aunque supere la meta.
- Los libros retirados posteriormente de la biblioteca conservan su aporte mientras existan sus registros de lectura.
- Solo cuentan páginas presentes en `reading_logs`: empezar o terminar un libro aporta páginas si la operación correspondiente escribe registros en esa tabla.
- No se agregó una migración. La consulta requiere que la API exponga la relación `reading_logs → user_book` y que la sesión pueda leer sus registros bajo las políticas existentes. Si la consulta falla, la pantalla muestra un error y pausa los avisos de meta; no interpreta el error como cero páginas.

### Regla del aviso

Se programan como máximo dos avisos no repetitivos de la semana actual, a la misma hora configurada para los otros recordatorios:

- Miércoles: si el total es menor que `ceil(meta × 3 / 7)`.
- Sábado: si el total es menor que `ceil(meta × 6 / 7)`.

Por ejemplo, con meta de 100 páginas, los umbrales son 43 y 86. No se programan horas que ya pasaron. Al llegar a 100 páginas se cancelan ambos. Al cambiar la meta, la hora o el avance se recalculan los avisos. Al desactivar, cerrar sesión o revocar permisos se cancelan.

Al iniciar, volver a primer plano, entrar al módulo o cambiar el progreso se consulta el total. Durante la consulta o si falla, se cancelan los avisos que dependían de un total anterior. Una semana nueva exige consultar nuevamente; no se reutiliza el avance anterior ni se dejan avisos recurrentes de semanas futuras. Los cambios en otros dispositivos se reflejan al actualizar; el sistema local no consulta Supabase con la app cerrada.

### Verificación semanal

`python3 Tests/check_weekly_goal.py`

Cubre semana lunes/domingo, cambio de año, porcentaje, umbrales, sobrecumplimiento, cambios de meta/hora, errores de datos, permisos, nueva semana, separación de cuentas y cierre de sesión durante una programación pendiente.

Pendiente en iPhone con la cuenta real:

1. Comparar el total mostrado con la suma de `reading_logs.pages_read` de esta semana. Registrar un avance y comprobar que suma solo la diferencia. Corregir páginas hacia atrás y comprobar que resta.
2. Activar el aviso y verificar el próximo miércoles/sábado futuro según el avance. Subir/bajar la meta y revisar el cambio.
3. Alcanzar la meta y comprobar el estado cumplido y ausencia de avisos pendientes.
4. Probar desconexión durante la consulta, permisos denegados, desactivación y cambio de cuenta.
5. En un miércoles/sábado, elegir una hora próxima con avance insuficiente, enviar la app al fondo y comprobar la entrega real.

## Resumen de meta en Home

El Home muestra una tarjeta entre las lecturas actuales y el calendario, usando la misma instancia de `WeeklyGoalReminderService`: rango semanal, anillo de porcentaje, páginas registradas/meta, páginas restantes y estado del recordatorio. Al completar la meta cambia a un estado de celebración. Tanto el botón de ajustes como la fila del aviso abren la configuración existente. No modifica preferencias ni solicita permisos al visualizarla.

El estado de carga/error evita presentar un total desconocido como cero. La tarjeta admite texto grande y movimiento reducido, respeta los colores claro/oscuro de la app y permite actualizar el avance al deslizar hacia abajo. Revisar visualmente en iPhone los estados de cero páginas, avance parcial, meta superada, error de consulta y notificaciones desactivadas/denegadas.

La opción **Mostrar meta semanal en Inicio**, en la sección Meta semanal de la configuración, permite ocultar únicamente la tarjeta del Home. Está activada por defecto y se persiste por cuenta en este dispositivo. No cambia la meta ni la programación de sus notificaciones. Para volver a mostrarla, entrar desde Perfil → engranaje → Recordatorios de lectura.
