import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../supabase/functions/delete-account/handler.js', import.meta.url), 'utf8');
const { createDeleteAccountHandler } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);

function request(body = { confirmation: 'DELETE' }, token = 'Bearer valid') {
  return new Request('https://example.test/delete-account', {
    method: 'POST', headers: token ? { Authorization: token } : {}, body: JSON.stringify(body),
  });
}
function fixture(files = []) {
  const calls = [];
  const remaining = [...files];
  const backend = {
    async getUser(jwt) { calls.push('auth'); if (jwt !== 'valid') throw Error(); return { id: 'account-a' }; },
    async listFiles(id) { assert.equal(id, 'account-a'); calls.push('list'); return remaining.slice(0, 500); },
    async removeFiles(bucket, paths) {
      calls.push('storage');
      assert(paths.length <= 100);
      for (const path of paths) {
        const index = remaining.findIndex(f => f.bucket_id === bucket && f.name === path);
        assert(index >= 0); remaining.splice(index, 1);
      }
    },
    async deleteUser(id) { assert.equal(id, 'account-a'); assert.equal(remaining.length, 0); calls.push('delete'); },
  };
  return { backend, calls, remaining, handler: createDeleteAccountHandler(backend) };
}
for (const req of [request({}, ''), request({}, 'Bearer invalid')]) {
  const f = fixture();
  assert.equal((await f.handler(req)).status, 401);
  assert(!f.calls.includes('list'));
}
for (const body of [null, {}, { confirmation: 'NO' }, { confirmation: 'DELETE', user_id: 'account-b' }]) {
  const f = fixture();
  assert.equal((await f.handler(request(body))).status, 400);
  assert(!f.calls.includes('list'));
}
{
  const f = fixture();
  assert.equal((await f.handler(new Request('https://example.test'))).status, 405);
  assert.equal(f.calls.length, 0);
}
{
  const f = fixture(Array.from({ length: 1101 }, (_, i) => ({ bucket_id: i % 2 ? 'avatars' : 'other', name: `account-a/${i}` })));
  const response = await f.handler(request());
  assert.deepEqual(await response.json(), { deleted: true });
  assert.equal(f.calls.at(-1), 'delete');
  assert.equal(f.calls.filter(x => x === 'list').length, 4);
}
for (const method of ['listFiles', 'removeFiles', 'deleteUser']) {
  const f = fixture([{ bucket_id: 'avatars', name: 'account-a/avatar.jpg' }]);
  f.backend[method] = async () => { throw Error('private details must never escape'); };
  const response = await f.handler(request());
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), { error: 'deletion_not_completed' });
  assert(!f.calls.includes('delete'));
}
{
  const f = fixture([{ bucket_id: 'avatars', name: 'account-a/avatar.jpg' }]);
  const original = f.backend.deleteUser;
  f.backend.deleteUser = async () => { throw Error(); };
  assert.equal((await f.handler(request())).status, 503);
  assert.equal(f.remaining.length, 0);
  f.backend.deleteUser = original;
  assert.equal((await f.handler(request())).status, 200); // resume after partial Storage cleanup
}
console.log('PASS: authentication, confirmation, identity isolation, 1101-file pagination, batching, failure handling and retry');
