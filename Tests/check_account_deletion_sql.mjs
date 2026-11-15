// npm install --prefix /tmp/hilo-account-sql-test --ignore-scripts @electric-sql/pglite
// node Tests/check_account_deletion_sql.mjs
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const modulePath = process.env.PGLITE_MODULE ?? '/tmp/hilo-account-sql-test/node_modules/@electric-sql/pglite/dist/index.js';
const { PGlite } = await import(pathToFileURL(modulePath));
const db = new PGlite();
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
await db.exec(`
 create role anon; create role authenticated; create role service_role;
 create schema auth; create schema storage;
 create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid $$;
 create function auth.role() returns text language sql as $$ select current_setting('request.jwt.claim.role', true) $$;
 create table auth.users(id uuid primary key);
 create table public.users(user_id uuid primary key references auth.users(id));
 create table public.books(book_id uuid primary key);
 create table public.user_book(user_book_id uuid primary key, user_id uuid references public.users(user_id), book_id uuid references public.books(book_id), deleted_at timestamptz);
 create table public.quotes(id uuid primary key, user_book_id uuid references public.user_book(user_book_id));
 create table public.quote_shares(id uuid primary key, quote_id uuid references public.quotes(id));
 create table public.reading_logs(id uuid primary key, user_book_id uuid references public.user_book(user_book_id));
 create table public.notification_settings(user_id uuid primary key references public.users(user_id));
 create table public.user_favorite_genres(user_id uuid references public.users(user_id));
 create table storage.objects(bucket_id text, name text, owner_id text);
 alter table storage.objects enable row level security;
 insert into auth.users values ('${a}'), ('${b}');
 insert into public.users values ('${a}'), ('${b}');
 insert into public.books values ('${a}');
 insert into public.user_book values ('${a}','${a}','${a}', now()), ('${b}','${b}','${a}',null);
 insert into public.quotes values ('${a}','${a}'), ('${b}','${b}');
 insert into public.quote_shares values ('${a}','${a}'), ('${b}','${b}');
 insert into public.reading_logs values ('${a}','${a}'), ('${b}','${b}');
 insert into public.notification_settings values ('${a}'), ('${b}');
 insert into public.user_favorite_genres values ('${a}'), ('${b}');
 insert into storage.objects values ('avatars','${a}/avatar.jpg',null), ('other','private.png','${a}'), ('avatars','${b}/avatar.jpg','${b}');
`);
const script = await readFile(new URL('../Database/account_deletion_setup.sql', import.meta.url), 'utf8');
await db.exec(script);
await db.exec(script); // reinstall must be idempotent and non-destructive
assert.equal((await db.query('select count(*)::int n from auth.users')).rows[0].n, 2);
for (const role of ['anon','authenticated','service_role']) {
  assert.equal((await db.query(`select has_function_privilege('${role}', 'public.hilo_delete_personal_rows(uuid)', 'execute') allowed`)).rows[0].allowed, false);
}
await db.exec(`set request.jwt.claim.role = 'authenticated'`);
await assert.rejects(db.query(`select * from public.hilo_account_deletion_files('${a}')`));
await db.exec(`set request.jwt.claim.role = 'service_role'`);
let files = (await db.query(`select * from public.hilo_account_deletion_files('${a}')`)).rows;
assert.equal(files.length, 2);
assert(files.every(f => !f.name.includes(b)));
await db.exec('alter table auth.users disable trigger hilo_delete_personal_data');
await assert.rejects(db.query(`select * from public.hilo_account_deletion_files('${a}')`));
await db.exec('alter table auth.users enable trigger hilo_delete_personal_data');
// Unmodelled RESTRICT references must roll back the WHOLE DB transaction.
await db.exec(`create table public.blocker(user_id uuid references auth.users(id)); insert into public.blocker values ('${a}')`);
await assert.rejects(db.exec(`delete from auth.users where id = '${a}'`));
for (const table of ['users','user_book','quotes','quote_shares','reading_logs','notification_settings','user_favorite_genres']) {
  assert.equal((await db.query(`select count(*)::int n from public.${table}`)).rows[0].n, 2);
}
await db.exec('drop table public.blocker');
await db.exec(`delete from auth.users where id = '${a}'`);
for (const table of ['users','user_book','quotes','quote_shares','reading_logs','notification_settings','user_favorite_genres']) {
  assert.equal((await db.query(`select count(*)::int n from public.${table}`)).rows[0].n, 1);
}
assert.equal((await db.query('select count(*)::int n from public.books')).rows[0].n, 1);
assert.equal((await db.query('select user_id from public.users')).rows[0].user_id, b);
// SQL deliberately leaves binaries/metadata to Storage API, never deletes them directly.
assert.equal((await db.query('select count(*)::int n from storage.objects')).rows[0].n, 3);
await db.exec(`
 grant usage on schema public, storage to authenticated;
 grant select on public.users, storage.objects to authenticated;
 create policy test_permissive on public.users for select to authenticated using(true);
 create policy test_permissive on storage.objects for select to authenticated using(true);
 set role authenticated;
 set request.jwt.claim.sub = '${a}';
`);
assert.equal((await db.query('select count(*)::int n from public.users')).rows[0].n, 0);
assert.equal((await db.query('select count(*)::int n from storage.objects')).rows[0].n, 0);
await db.exec(`set request.jwt.claim.sub = '${b}'`);
assert.equal((await db.query('select count(*)::int n from public.users')).rows[0].n, 1);
await db.close();
console.log('PASS: SQL installation, idempotence, privilege isolation, file ownership, trigger preflight, transactional rollback, full personal deletion, shared catalog preservation and stale-token RLS');
