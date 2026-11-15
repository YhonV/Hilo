-- Ejecutar TODO el archivo en el SQL Editor del mismo proyecto que usa la app:
-- smfstophtxtnbavxyljr
-- Reemplazar el correo de ejemplo. No modifica datos ni políticas.
-- Simula la identidad y el rol de la cuenta únicamente dentro de esta transacción.
begin;
set transaction read only;

do $$
declare
  target_id uuid;
begin
  select id into strict target_id from auth.users
  where lower(email) = lower('REEMPLAZAR_POR_CORREO_DE_LA_CUENTA');

  perform set_config('request.jwt.claim.sub', target_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', target_id::text, 'role', 'authenticated')::text, true);
end;
$$;

set local role authenticated;

select
  current_user as request_role,
  auth.uid() is not null as identity_present,
  public.hilo_account_exists() as account_exists_check,
  (select count(*) from public.users where user_id = auth.uid()) as visible_profile_rows;

rollback;
