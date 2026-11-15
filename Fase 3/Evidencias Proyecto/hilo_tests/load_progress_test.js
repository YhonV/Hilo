
import http from 'k6/http';
import { check, sleep, fail } from 'k6';

const URL = __ENV.SUPABASE_URL;
const API_KEY = __ENV.SUPABASE_KEY;

export const options = {
  scenarios: {
    progress: {
      executor: 'constant-vus',
      vus: 25,
      duration: '5m',
    },
  },
  thresholds: {
    'http_req_duration{operation:progress}': ['p(95)<=1500'],
    'http_req_failed{operation:progress}': ['rate<0.01'],
    checks: ['rate>=0.99'],
  },
};

const accounts = [
  {
    email: __ENV.EMAIL_1,
    books: [
      '6424561f-c84e-419b-9dff-73f86dc9b50a',
      'cde31e89-9ca8-4c7d-a9c5-47027a5d9ecb',
      '3e2c7cb8-2067-4f5f-810b-45695f9f4429',
      'b9ec9eba-4eba-47bb-9255-3566768ab3cf',
      '848e5509-2c78-4e0c-9394-30b8b3a70eda',
    ],
  },
  {
    email: __ENV.EMAIL_2,
    books: [
      '210cd76b-453e-4cf9-b8f5-1fb27fda6792',
      '865e44d0-d71a-49e4-b3cb-86c622b8a95f',
      '21db196c-7699-476c-a0a5-a73c85e4dc91',
      '8140a232-d958-4858-95bf-7f4965b8273e',
      '773243b0-25bf-4255-a563-34a5dd8407fe',
    ],
  },
];

// Autenticar usuarios y obtener progreso inicial
export function setup() {
  const sessions = [];

  for (const account of accounts) {
    const auth = http.post(
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

    if (auth.status !== 200) {
      fail(`Error autenticando ${account.email}: HTTP ${auth.status}`);
    }

    const token = auth.json().access_token;

    for (const bookId of account.books) {
      const response = http.get(
        `${URL}/rest/v1/user_book?user_book_id=eq.${bookId}&select=current_page`,
        {
          headers: {
            apikey: API_KEY,
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.status !== 200) {
        fail(`Error consultando libro ${bookId}`);
      }

      const books = response.json();

      if (books.length !== 1) {
        fail(`Libro no encontrado: ${bookId}`);
      }

      const currentPage = books[0].current_page;

      // Reservar páginas suficientes para 5 minutos
      if (currentPage > 95) {
        fail(`Libro ${bookId} tiene progreso demasiado alto`);
      }

      sessions.push({
        token,
        bookId,
        currentPage,
      });
    }
  }

  return sessions;
}

// Estado independiente de cada VU
let nextPage = null;

export default function (sessions) {
 const session = sessions[(__VU - 1) % sessions.length];

if (!session) {
  throw new Error(`No existe sesión para el VU ${__VU}`);
}

  if (nextPage === null) {
    nextPage = session.currentPage + 1;
  }

  // Los libros seleccionados tienen al menos 200 páginas
  if (nextPage > 200) {
    sleep(3);
    return;
  }

  const response = http.post(
    `${URL}/rest/v1/rpc/update_book_progress`,
    JSON.stringify({
      p_user_book_id: session.bookId,
      p_new_page: nextPage,
      p_log_date: '2026-11-15',
    }),
    {
      headers: {
        apikey: API_KEY,
        Authorization: `Bearer ${session.token}`,
        'Content-Type': 'application/json',
      },
      tags: {
        operation: 'progress',
      },
    }
  );

  const success =
    response.status === 200 ||
    response.status === 204;

  check(response, {
    'Actualizacion exitosa': () => success,
  });

  if (success) {
    nextPage++;
  } else {
    console.error(
      `VU ${__VU}: HTTP ${response.status} - ${response.body}`
    );
  }

  sleep(3);
}
