import { createDeleteAccountHandler } from './handler.js';

const baseURL = Deno.env.get('SUPABASE_URL');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!baseURL || !serviceKey) throw new Error('Missing server configuration');

async function api(path: string, method = 'GET', body?: unknown, bearer = serviceKey) {
  const response = await fetch(`${baseURL}${path}`, {
    method,
    headers: { apikey: serviceKey!, Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw new Error(`Backend request failed: ${response.status}`);
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

Deno.serve(createDeleteAccountHandler({
  // Auth validates the JWT and checks that the account still exists.
  getUser: (jwt: string) => api('/auth/v1/user', 'GET', undefined, jwt),
  listFiles: (id: string) => api('/rest/v1/rpc/hilo_account_deletion_files', 'POST', { p_user_id: id }),
  removeFiles: (bucket: string, paths: string[]) => api(`/storage/v1/object/${encodeURIComponent(bucket)}`, 'DELETE', { prefixes: paths }),
  deleteUser: (id: string) => api(`/auth/v1/admin/users/${encodeURIComponent(id)}`, 'DELETE', { should_soft_delete: false }),
}));
