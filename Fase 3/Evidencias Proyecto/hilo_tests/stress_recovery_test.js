
import http from 'k6/http';
import { check, sleep, fail } from 'k6';

const URL = __ENV.SUPABASE_URL;
const API_KEY = __ENV.SUPABASE_KEY;

export const options = {
  scenarios: {
    baseline: {
      executor: 'constant-vus',
      vus: 10,
      duration: '2m',
      startTime: '0s',
      gracefulStop: '0s',
    },

    overload: {
      executor: 'ramping-vus',
      startTime: '2m',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 100 },
        { duration: '1m45s', target: 100 },
        { duration: '15s', target: 200 },
        { duration: '1m45s', target: 200 },
      ],
      gracefulRampDown: '0s',
      gracefulStop: '0s',
    },

    recovery: {
      executor: 'constant-vus',
      vus: 10,
      duration: '5m',
      startTime: '6m',
      gracefulStop: '0s',
    },
  },

  thresholds: {
    'http_req_duration{scenario:recovery}': [
      'p(95)<=1000',
    ],
    'http_req_failed{scenario:recovery}': [
      'rate<=0.01',
    ],
    checks: ['rate>=0.99'],
  },
};

const accounts = [
  { email: __ENV.EMAIL_1 },
  { email: __ENV.EMAIL_2 },
];

export function setup() {
  return accounts.map((account) => {
    const response = http.post(
      `${URL}/auth/v1/token?grant_type=password`,
      JSON.stringify({
        email: account.email,
        password: __ENV.TEST_PASSWORD,
      }),
      {
        headers: {
          apikey: API_KEY,
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.status !== 200) {
      fail(`Error de autenticación: HTTP ${response.status}`);
    }

    const session = response.json();

    return {
      token: session.access_token,
      userId: session.user.id,
    };
  });
}

export default function (sessions) {
  const user = sessions[(__VU - 1) % sessions.length];

  const response = http.get(
    `${URL}/rest/v1/user_book?select=user_id,book_id&deleted_at=is.null&limit=100`,
    {
      headers: {
        apikey: API_KEY,
        Authorization: `Bearer ${user.token}`,
      },
    }
  );

  let books = [];

  try {
    books = response.json();
  } catch {
    // Respuesta no válida.
  }

  check(response, {
    'HTTP 200': (r) => r.status === 200,

    '100 libros recibidos': () =>
      Array.isArray(books) && books.length === 100,

    'Sin datos de otros usuarios': () =>
      Array.isArray(books) &&
      books.length === 100 &&
      books.every(b => b.user_id === user.userId),
  });

  if (response.status !== 200) {
    console.error(`VU ${__VU}: HTTP ${response.status}`);
  }

  sleep(1);
}
