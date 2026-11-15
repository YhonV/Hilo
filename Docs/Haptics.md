# Respuesta háptica

`Hilo/Helpers/AppHaptics.swift` centraliza los eventos explícitos de interfaz en el actor principal. Solo emite feedback con la aplicación activa. Usa los patrones nativos de UIKit; el sistema decide si el dispositivo puede reproducirlos.

- Selección: pestaña, edición de libro, estado de lectura, plantilla de cita y cuadrícula/carrusel.
- Acción suave: abrir progreso de lectura, agregar una cita, editar perfil/plantilla y presentar una imagen para compartir. Abrir Compartir no indica que se haya compartido.
- Éxito: una operación confirmada de acceso, recuperación, registro, edición del perfil, guardado/eliminación de libro o cita, progreso, finalización/reinicio de lectura, guardado en Fotos y eliminación de cuenta.
- Advertencia: presentar confirmaciones destructivas o denegación de acceso a Fotos.
- Error: validación o fallo de una operación iniciada por el usuario.

Los controles nativos de recordatorios, metas y filtros conservan su respuesta del sistema. El calendario conserva sus eventos SwiftUI de selección. No se añaden vibraciones a cada tecla, al desplazamiento, a la restauración de sesión ni a las cargas automáticas. No se usan gestos globales que intercepten los botones o el scroll.

La confirmación se emite antes de cerrar una hoja; no requiere retrasar el cierre. Un fallo al refrescar la biblioteca después de guardar un libro no emite un error de guardado. Los mensajes y estados visuales existentes siguen siendo independientes de la vibración.

## Comprobación en un iPhone físico

1. Cambiar de pestaña y alternar cuadrícula/carrusel: pulso breve por cambio.
2. Seleccionar una edición: un solo pulso; tocar la misma edición no repite la selección.
3. Guardar un libro, una cita o el perfil: confirmación después del resultado, no al comenzar la petición.
4. Actualizar páginas, terminar un libro con/sin total de páginas y comenzar/reiniciar una lectura: confirmación antes del cierre de la hoja.
5. Abrir una confirmación destructiva y cancelar: advertencia al abrir, sin éxito al cancelar. Usar cuentas y contenido de prueba si se confirma el borrado.
6. Probar validación y errores de red en acciones de guardado: feedback de error, sin éxito falso.
7. Guardar una imagen de cita en Fotos: éxito después del guardado; aviso si se deniega el permiso.
8. Abrir pantallas, cargar datos y desplazar listas: sin vibraciones añadidas. Revisar que los controles de recordatorios no tengan pulsos duplicados.

El simulador valida compilación y flujos, pero no permite evaluar la sensación física. Referencia: https://developer.apple.com/design/human-interface-guidelines/playing-haptics
