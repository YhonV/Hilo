
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '5m',
  thresholds: {
    http_req_duration: ['p(95)<=1000'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>=0.99'],
  },
};

const url = __ENV.SUPABASE_URL;
const apiKey = __ENV.SUPABASE_KEY;

const accounts = [
  { email: __ENV.EMAIL_1, password: __ENV.TEST_PASSWORD },
  { email: __ENV.EMAIL_2, password: __ENV.TEST_PASSWORD },
];

// Autenticar ambas cuentas una sola vez
export function setup() {
  return accounts.map((account) => {
    const response = http.post(
      `${url}/auth/v1/token?grant_type=password`,
      JSON.stringify(account),
      {
        headers: {
          apikey: apiKey,
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.status !== 200) {
      throw new Error(`Error autenticando ${account.email}: HTTP ${response.status}`);
    }

    const session = response.json();

    return {
      token: session.access_token,
      userId: session.user.id,
    };
  });
}

export default function (sessions) {
  // Distribuir los VU entre las dos cuentas
  const user = sessions[(__VU - 1) % sessions.length];

  const response = http.get(
    `${url}/rest/v1/user_book?select=user_id,book_id&deleted_at=is.null&limit=100`,
    {
      headers: {
        apikey: apiKey,
        Authorization: `Bearer ${user.token}`,
      },
    }
  );

  if (response.status !== 200) {
  console.error(
    `Error HTTP ${response.status}: ${response.body}`
  );
}

  check(response, {
    'HTTP 200': (r) => r.status === 200,

    '100 libros recibidos': (r) => {
      try {
        return r.json().length === 100;
      } catch {
        return false;
      }
    },

    'Sin datos de otros usuarios': (r) => {
      try {
        const books = r.json();
        return Array.isArray(books) &&
          books.every(b => b.user_id === user.userId);
      } catch {
        return false;
      }
    },
  });

  sleep(1);
}


