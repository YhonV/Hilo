# Recuperación de contraseña

## Configuración en Supabase

1. En Authentication → URL Configuration → Redirect URLs, agregar exactamente `hilo://auth/recovery`.
2. Comprobar que el proveedor Email esté habilitado. No hay un interruptor adicional para recuperación.
3. En la plantilla Reset Password, mantener el enlace `{{ .ConfirmationURL }}`. No sustituirlo por un enlace directo a la app: Supabase debe verificar primero la solicitud.
4. Configurar Custom SMTP para enviar a usuarios reales. El servidor predeterminado solo permite destinatarios del equipo y tiene límites de prueba.
5. Alinear la política de contraseñas del proyecto con el mínimo local de 8 caracteres. Supabase sigue validando su política completa.

El cliente usa PKCE: solicitar y abrir el correo en la misma instalación de Hilo. La app registra el esquema `hilo` y procesa la ruta `auth/recovery`. No se requieren cambios en tablas ni políticas RLS.

## Prueba manual con correo real

- Cuenta existente: pedir enlace, comprobar confirmación genérica, abrirlo en el mismo dispositivo con Hilo cerrado y con Hilo abierto. Debe aparecer Nueva contraseña, sin saltar al inicio al recibir la sesión.
- Correo inexistente: mostrar la misma confirmación sin revelar cuentas.
- Correo inválido: validar antes de enviar. Sin conexión o límite del servidor: mostrar error y desbloquear el botón.
- Reenvío: habilitar después de 60 segundos; abrir el correo más reciente.
- Contraseñas diferentes o de menos de 8 caracteres: impedir guardado. Rechazo del servidor: mantener el formulario con error.
- Guardado correcto: mostrar confirmación, continuar a Hilo y verificar un nuevo inicio de sesión con la contraseña nueva.
- Enlace vencido, usado, malformado u originado en otra instalación: mostrar error y permitir volver al login para solicitar otro.
- Cerrar/reabrir durante recuperación: conservar el formulario mientras exista la sesión; volver al login debe limpiar la sesión local de recuperación.

## Referencias

- https://supabase.com/docs/guides/auth/passwords
- https://supabase.com/docs/guides/auth/redirect-urls
- https://supabase.com/docs/guides/auth/auth-smtp
