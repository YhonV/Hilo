import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const { PGlite } = await import(pathToFileURL(process.env.PGLITE_MODULE ?? '/tmp/hilo-account-sql-test/node_modules/@electric-sql/pglite/dist/index.js'));
const db = new PGlite();
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
await db.exec(`
create schema auth; create schema storage;
create table auth.users(id uuid primary key, email text);
create table public.users(user_id uuid references auth.users(id));
create table storage.objects(bucket_id text, name text, owner_id text);
create function public.hilo_on_auth_user_delete() returns trigger language plpgsql as $$
begin delete from public.users where user_id = old.id; return old; end $$;
create trigger hilo_delete_personal_data before delete on auth.users for each row execute function public.hilo_on_auth_user_delete();
insert into auth.users values ('${a}', 'target@example.test'), ('${b}', 'other@example.test');
insert into public.users values ('${a}'), ('${b}');
`);
const script = await readFile(new URL('../Database/delete_account_by_email.sql', import.meta.url), 'utf8');
const withEmail = email => script.replace("target_email text := 'REEMPLAZAR_POR_CORREO'", `target_email text := '${email}'`);
await assert.rejects(db.exec(script), /Reemplaza/);
await assert.rejects(db.exec(withEmail('missing@example.test')), /No existe/);
await db.exec('alter table auth.users disable trigger hilo_delete_personal_data');
await assert.rejects(db.exec(withEmail('target@example.test')), /Falta el trigger/);
await db.exec('alter table auth.users enable trigger hilo_delete_personal_data');
await db.exec(`insert into storage.objects values ('avatars', '${a}/avatar.jpg', null)`);
await assert.rejects(db.exec(withEmail('target@example.test')), /archivos en Storage/);
await db.exec('delete from storage.objects'); // Fixture only; never done by the script.
await db.exec(`create table blocker(id uuid references auth.users(id)); insert into blocker values ('${a}')`);
await assert.rejects(db.exec(withEmail('target@example.test')));
assert.equal((await db.query('select count(*)::int n from public.users')).rows[0].n, 2);
await db.exec('drop table blocker');
await db.exec(withEmail(' TARGET@example.test '));
assert.deepEqual((await db.query('select id from auth.users')).rows, [{ id: b }]);
assert.deepEqual((await db.query('select user_id from public.users')).rows, [{ user_id: b }]);
// A missing profile must not prevent deleting an orphaned Auth account.
await db.exec(`delete from public.users where user_id = '${b}'`);
await db.exec(withEmail('other@example.test'));
assert.equal((await db.query('select count(*)::int n from auth.users')).rows[0].n, 0);
await db.close();
console.log('PASS: target selection, missing account, trigger guard, Storage guard, atomic rollback, other-account preservation, orphaned Auth deletion');
