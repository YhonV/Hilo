-- Diagnóstico de solo lectura. Ejecutar en Supabase > SQL Editor.
-- Reemplazar el correo de ejemplo por el de la cuenta afectada.
-- No modifica usuarios ni permisos y no muestra contraseñas ni tokens.

-- 1. ¿Existe la cuenta en Auth y tiene exactamente un perfil?
with target as (
  select id from auth.users
  where lower(email) = lower('REEMPLAZAR_POR_CORREO_DE_LA_CUENTA')
)
select
  (select count(*) from target) as auth_accounts,
  (select count(*) from public.users p
   where p.user_id in (select id from target)) as profile_rows;

-- 2. ¿Está activada la seguridad por fila?
select relrowsecurity as rls_enabled, relforcerowsecurity as rls_forced
from pg_class where oid = 'public.users'::regclass;

-- 3. Políticas reales para leer y crear perfiles.
-- Una política RESTRICTIVE por sí sola no concede acceso: también se necesita
-- una política PERMISSIVE aplicable a la operación y al rol authenticated.
select policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'users'
order by policyname;

-- 4. Permisos de tabla del rol utilizado por una sesión iniciada.
select
  has_table_privilege('authenticated', 'public.users', 'SELECT') as can_select,
  has_table_privilege('authenticated', 'public.users', 'INSERT') as can_insert;
