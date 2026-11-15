-- Ejecutar completo en Supabase > SQL Editor, con el rol postgres.
-- Reemplaza SOLO el correo de abajo. Eliminación definitiva.
-- Requiere el trigger instalado por account_deletion_setup.sql.
-- Si hay archivos, se detiene: elimínalos desde Storage o usa delete-account.
-- No borra directamente storage.objects, porque dejaría archivos huérfanos.

do $$
declare
  target_email text := 'REEMPLAZAR_POR_CORREO';
  target_id uuid;
  deleted_count integer;
begin
  if btrim(target_email) = '' or target_email = 'REEMPLAZAR_POR_CORREO' then
    raise exception 'Reemplaza el correo antes de ejecutar.';
  end if;

  -- STRICT rechaza tanto cero coincidencias como múltiples coincidencias.
  select id into strict target_id
  from auth.users
  where lower(email) = lower(btrim(target_email))
  for update;

  if not exists (
    select 1 from pg_catalog.pg_trigger
    where tgrelid = 'auth.users'::regclass
      and tgname = 'hilo_delete_personal_data'
      and tgenabled in ('O', 'A')
      and tgfoid = to_regprocedure('public.hilo_on_auth_user_delete()')
  ) then
    raise exception 'Falta el trigger de eliminación. Ejecuta account_deletion_setup.sql primero.';
  end if;

  if exists (
    select 1 from storage.objects o
    where coalesce(to_jsonb(o)->>'owner_id', to_jsonb(o)->>'owner') = target_id::text
       or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = target_id::text)
  ) then
    raise exception 'La cuenta % tiene archivos en Storage. Elimínalos desde Storage o usa la función delete-account antes de borrar Auth.', target_id;
  end if;

  -- El trigger llama a hilo_delete_personal_rows y elimina los datos de Hilo.
  -- Todo el bloque es atómico: si falla una dependencia, se revierte el borrado.
  delete from auth.users where id = target_id;
  get diagnostics deleted_count = row_count;
  if deleted_count <> 1 then
    raise exception 'No se eliminó exactamente una cuenta; operación revertida.';
  end if;
  raise notice 'Cuenta eliminada: % (id: %)', target_email, target_id;
exception
  when no_data_found then
    raise exception 'No existe una cuenta de Auth con ese correo.';
  when too_many_rows then
    raise exception 'Hay varias cuentas con ese correo; no se eliminó ninguna.';
end;
$$;
