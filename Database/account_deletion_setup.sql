-- Hilo account deletion, based on the supplied public-schema diagram.
-- Run once in Supabase SQL Editor BEFORE deploying delete-account.
-- Installation does not delete existing accounts. Future HARD deletions in Auth
-- (including Dashboard/Admin API) will remove the corresponding personal rows.
begin;

-- SQL-language body is checked against the real tables/columns at installation.
create or replace function public.hilo_delete_personal_rows(p_user_id uuid)
returns void language sql security definer set search_path = '' as $$
  delete from public.quote_shares s using public.quotes q, public.user_book ub
    where s.quote_id = q.id and q.user_book_id = ub.user_book_id and ub.user_id = p_user_id;
  delete from public.quotes q using public.user_book ub
    where q.user_book_id = ub.user_book_id and ub.user_id = p_user_id;
  delete from public.reading_logs l using public.user_book ub
    where l.user_book_id = ub.user_book_id and ub.user_id = p_user_id;
  delete from public.user_favorite_genres where user_id = p_user_id;
  delete from public.notification_settings where user_id = p_user_id;
  delete from public.user_book where user_id = p_user_id;
  delete from public.users where user_id = p_user_id;
$$;
revoke all on function public.hilo_delete_personal_rows(uuid) from public, anon, authenticated, service_role;

create or replace function public.hilo_on_auth_user_delete()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.hilo_delete_personal_rows(old.id);
  return old;
end;
$$;
revoke all on function public.hilo_on_auth_user_delete() from public, anon, authenticated, service_role;
drop trigger if exists hilo_delete_personal_data on auth.users;
create trigger hilo_delete_personal_data before delete on auth.users
  for each row execute function public.hilo_on_auth_user_delete();

-- A bounded manifest; the Edge Function repeatedly removes these through Storage API.
-- Never DELETE storage.objects directly: that would orphan the underlying files.
create or replace function public.hilo_account_deletion_files(p_user_id uuid)
returns table(bucket_id text, name text)
language plpgsql security definer set search_path = '' as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
  if not exists (select 1 from pg_catalog.pg_trigger
    where tgrelid = 'auth.users'::regclass and tgname = 'hilo_delete_personal_data'
      and tgenabled in ('O', 'A')
      and tgfoid = 'public.hilo_on_auth_user_delete()'::regprocedure) then
    raise exception 'Account deletion trigger is missing';
  end if;
  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'Account no longer exists';
  end if;
  return query select o.bucket_id::text, o.name::text
    from storage.objects o
    where coalesce(to_jsonb(o)->>'owner_id', to_jsonb(o)->>'owner') = p_user_id::text
       or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = p_user_id::text)
    order by o.bucket_id, o.name limit 500;
end;
$$;
revoke all on function public.hilo_account_deletion_files(uuid) from public, anon, authenticated;
grant execute on function public.hilo_account_deletion_files(uuid) to service_role;

-- An unexpired JWT must not grant direct table/Storage access after Auth deletion.
-- Restrictive policies are ANDed with existing permissive policies; they do not grant access.
create or replace function public.hilo_account_exists()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from auth.users where id = auth.uid());
$$;
revoke all on function public.hilo_account_exists() from public, anon;
grant execute on function public.hilo_account_exists() to authenticated;

do $$
declare relation text;
begin
  foreach relation in array array['users', 'user_book', 'reading_logs', 'quotes',
    'quote_shares', 'user_favorite_genres', 'notification_settings'] loop
    execute format('alter table public.%I enable row level security', relation);
    execute format('drop policy if exists hilo_existing_account_required on public.%I', relation);
    execute format('create policy hilo_existing_account_required on public.%I as restrictive for all to authenticated using ((select public.hilo_account_exists())) with check ((select public.hilo_account_exists()))', relation);
  end loop;
end $$;
drop policy if exists hilo_existing_account_required on storage.objects;
create policy hilo_existing_account_required on storage.objects as restrictive
  for all to authenticated using ((select public.hilo_account_exists()))
  with check ((select public.hilo_account_exists()));

commit;
