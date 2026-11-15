# Eliminación definitiva de cuenta

## Instalación en Supabase

1. Ejecutar `Database/account_deletion_setup.sql` en el SQL Editor del proyecto. La instalación no borra cuentas: añade funciones, un trigger de eliminación y políticas restrictivas. El cuerpo SQL verifica los nombres de tablas y columnas al instalarse. Si la instalación falla, la transacción revierte sus cambios.
2. Desde la raíz del repositorio, con Supabase CLI autenticado, desplegar:

   ```sh
   supabase functions deploy delete-account --project-ref smfstophtxtnbavxyljr
   ```

   `supabase/config.toml` desactiva la verificación heredada del gateway para esta función; la función valida obligatoriamente el bearer token contra `/auth/v1/user`. No acepta una identidad enviada por el cliente. Requiere las variables de servidor `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` provistas por Supabase. Nunca copiar la clave service role a iOS, Info.plist o el repositorio.
3. Probar primero con una cuenta de prueba que contenga avatar, libros, avances, citas y preferencias. La eliminación es real, sin papelera.

No se han ejecutado estos pasos en el proyecto remoto desde este chat.

## Flujo

Perfil → engranaje → Eliminar cuenta. Se muestran los datos afectados, una casilla de aceptación y una segunda confirmación destructiva. La app llama a `delete-account` con el token de la sesión y `{ "confirmation": "DELETE" }`.

La función valida la identidad con Auth, comprueba la presencia del trigger mediante el manifiesto y elimina los objetos pertenecientes al usuario mediante Storage API, en lotes. También incluye los archivos bajo `avatars/<uuid>/`, incluso si se subieron administrativamente y no tienen owner. Después realiza un hard delete mediante Admin Auth.

Un trigger `BEFORE DELETE` de `auth.users` elimina, en orden:

- `quote_shares` de sus citas.
- `quotes` de su biblioteca.
- `reading_logs` de sus libros.
- `user_favorite_genres`.
- `notification_settings`.
- `user_book`, incluidos los registros con `deleted_at`.
- `users`.

Estas operaciones y la eliminación de Auth comparten transacción. No dependen de que las relaciones existentes tengan `ON DELETE CASCADE`. El trigger también se ejecuta ante un hard delete desde Dashboard/Admin API; no debe usarse soft delete para este flujo.

Se conservan `books`, `book_editions`, `authors`, `genres`, `status`, `book_authors`, `book_genres` y `share_templates`, porque son catálogo compartido.

Al recibir `{ "deleted": true }`, iOS cancela las notificaciones de los tres tipos, borra las preferencias de recordatorios/meta del usuario, limpia búsquedas y caché HTTP, retira la sesión local del SDK y vuelve al acceso. No intenta eliminar cuentas de Firebase: el proyecto usa Supabase para los datos reales.

## Fallos y límites

- Si falla el manifiesto o Storage, no se elimina Auth. Puede haber archivos ya borrados: Storage y PostgreSQL no comparten transacción. Reintentar elimina los restantes.
- Si falla una relación de base de datos, se revierten los borrados de filas. Una nueva tabla personal debe añadirse al script y a sus pruebas antes de usarse en producción.
- Si la conexión se pierde después del borrado, iOS muestra que no pudo confirmar el resultado, no un éxito inventado. Al intentar renovar/iniciar sesión, la cuenta eliminada ya no será válida.
- Las políticas restrictivas impiden acceso directo con un JWT todavía no vencido una vez que ya no exista su usuario de Auth. Conservan las políticas permisivas existentes, que siguen siendo necesarias. El script habilita RLS en las tablas personales; si alguna carecía de políticas, necesitará las correspondientes políticas de acceso normal. Funciones ajenas con `SECURITY DEFINER` deben seguir validando identidad y propiedad.
- El esquema permite `quotes.user_book_id` nulo. Una cita histórica ya desvinculada de cualquier usuario no puede atribuirse con este esquema. La app actual exige `user_book_id`. Antes de producción conviene comprobar si existen citas huérfanas y resolver su propiedad; no se eliminan arbitrariamente.
- Archivos almacenados fuera del ownership de Storage o de la carpeta de avatar no pueden atribuirse con estos datos. La app actual sube el avatar a esa carpeta.
- Preferencias/notificaciones guardadas en otros dispositivos se limpian cuando esos dispositivos detectan que la sesión ya no es válida. Una app cerrada en otro dispositivo no puede cancelar inmediatamente sus avisos locales.
- Copias de seguridad, retención de logs del proveedor y copias de contenido compartido fuera de Hilo no se purgan con este flujo. El borrado cubre los datos activos identificables del esquema y Storage.

## Validación

```sh
node Tests/check_account_deletion.mjs
npm install --prefix /tmp/hilo-account-sql-test --ignore-scripts @electric-sql/pglite
node Tests/check_account_deletion_sql.mjs
python3 Tests/check_localization.py
```

El test SQL usa PostgreSQL embebido con tablas mínimas que reproducen las relaciones del diagrama; no accede a Supabase. Verifica instalación repetible, privilegios, selección de archivos, rollback ante FK inesperada, preservación de otra cuenta y del catálogo, y rechazo de acceso con JWT de usuario eliminado. El test de función comprueba autenticación, confirmación, rechazo de IDs enviados por el cliente, más de 1000 objetos, lotes, fallos y reintentos.

Pendiente de validación en el proyecto real: despliegue, permisos/trigger reales, Storage y diálogo de iPhone. Comprobar con dos cuentas de prueba que solo desaparecen las filas y el avatar de la cuenta eliminada, que ya no puede iniciar sesión y que se cancelan sus recordatorios.

Referencias oficiales:
- https://supabase.com/docs/guides/auth/managing-user-data
- https://supabase.com/docs/guides/storage/management/delete-objects
