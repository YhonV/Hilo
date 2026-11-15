-- Read-only schema report for designing account deletion. Does not return user records.
-- Run in Supabase SQL Editor and share the single JSON result.
select jsonb_pretty(jsonb_build_object(
  'columns', (select jsonb_agg(to_jsonb(c)) from (
    select table_schema, table_name, column_name, data_type, is_nullable, column_default
    from information_schema.columns
    where table_schema = 'public' or (table_schema = 'storage' and table_name = 'objects')
    order by table_schema, table_name, ordinal_position
  ) c),
  'foreign_keys', (select jsonb_agg(to_jsonb(f)) from (
    select con.conname as constraint_name, con.conrelid::regclass::text as source_table,
           con.confrelid::regclass::text as target_table, pg_get_constraintdef(con.oid) as definition
    from pg_constraint con join pg_namespace n on n.oid = con.connamespace
    where con.contype = 'f' and n.nspname in ('public', 'storage')
    order by source_table, constraint_name
  ) f),
  'policies', (select jsonb_agg(to_jsonb(p)) from (
    select schemaname, tablename, policyname, roles, cmd, qual, with_check
    from pg_policies where schemaname in ('public', 'storage')
  ) p),
  'triggers', (select jsonb_agg(to_jsonb(t)) from (
    select event_object_schema, event_object_table, trigger_name, action_statement
    from information_schema.triggers where event_object_schema in ('public', 'auth')
  ) t),
  'buckets', (select jsonb_agg(jsonb_build_object('id', id, 'public', public)) from storage.buckets)
));
