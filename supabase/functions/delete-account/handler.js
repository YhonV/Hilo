// Pure request orchestration, shared with Node tests. No client-supplied user IDs.
export function createDeleteAccountHandler(backend) {
  const json = (status, body) => new Response(JSON.stringify(body), {
    status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
  });
  return async (request) => {
    if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });
    const match = /^Bearer\s+(\S+)$/i.exec(request.headers.get('Authorization') ?? '');
    if (!match) return json(401, { error: 'unauthorized' });
    let user;
    try { user = await backend.getUser(match[1]); }
    catch { return json(401, { error: 'unauthorized' }); }
    if (!user?.id) return json(401, { error: 'unauthorized' });
    let body;
    try {
      const raw = await request.text();
      if (raw.length > 1024) return json(413, { error: 'request_too_large' });
      body = JSON.parse(raw);
    } catch { return json(400, { error: 'invalid_request' }); }
    if (!body || body.confirmation !== 'DELETE' || Object.keys(body).some(k => k !== 'confirmation')) {
      return json(400, { error: 'confirmation_required' });
    }
    try {
      // Bounded to avoid an endless deletion loop under concurrent uploads.
      // Any failure keeps the Auth account, and a retry resumes remaining files.
      for (let batch = 0; batch < 100; batch++) {
        const files = await backend.listFiles(user.id);
        if (!Array.isArray(files)) throw new Error('Invalid manifest');
        if (files.length === 0) {
          // Hard deletion fires the DB trigger in the same Auth transaction.
          await backend.deleteUser(user.id);
          return json(200, { deleted: true });
        }
        const buckets = new Map();
        for (const file of files) {
          if (typeof file.bucket_id !== 'string' || typeof file.name !== 'string') {
            throw new Error('Invalid object');
          }
          const paths = buckets.get(file.bucket_id) ?? [];
          paths.push(file.name);
          buckets.set(file.bucket_id, paths);
        }
        for (const [bucket, paths] of buckets) {
          for (let offset = 0; offset < paths.length; offset += 100) {
            await backend.removeFiles(bucket, paths.slice(offset, offset + 100));
          }
        }
      }
      return json(503, { error: 'deletion_retry_required' });
    } catch {
      // Do not leak database details, object names, user identifiers or tokens.
      return json(503, { error: 'deletion_not_completed' });
    }
  };
}
