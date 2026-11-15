
import http from 'k6/http';
import { check, sleep, fail } from 'k6';

const URL = __ENV.SUPABASE_URL;
const API_KEY = __ENV.SUPABASE_KEY;

export const options = {
  stages: [
    { duration: '15s', target: 10 },
    { duration: '2m', target: 10 },

    { duration: '15s', target: 25 },
    { duration: '2m', target: 25 },

    { duration: '15s', target: 50 },
    { duration: '2m', target: 50 },

    { duration: '15s', target: 100 },
    { duration: '2m', target: 100 },

    { duration: '15s', target: 0 },
  ],
  thresholds: {
    'http_req_duration{operation:progress}': ['p(95)<=1500'],
    'http_req_failed{operation:progress}': [{
      threshold: 'rate<0.05',
      abortOnFail: true,
      delayAbortEval: '30s',
    }],
    checks: ['rate>=0.99'],
  },
};

const accounts = [
  { email: __ENV.EMAIL_1 },
  { email: __ENV.EMAIL_2 },
];

export function setup() {
  const accountBooks = [];

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
      fail(`Error de autenticación: HTTP ${auth.status}`);
    }

    const token = auth.json().access_token;

    const response = http.get(
      `${URL}/rest/v1/user_book?select=user_book_id,current_page,book_editions!inner(number_of_pages)&deleted_at=is.null&limit=200`,
      {
        headers: {
          apikey: API_KEY,
          Authorization: `Bearer ${token}`,
        },
      }
    );

    if (response.status !== 200) {
      fail(`Error consultando libros: HTTP ${response.status}`);
    }

    const books = response.json()
      .filter(b =>
        b.book_editions &&
        b.book_editions.number_of_pages - b.current_page >= 100
      )
      .sort((a, b) =>
        a.user_book_id.localeCompare(b.user_book_id)
      )
      .slice(0, 50);

    if (books.length < 50) {
      fail(`La cuenta ${account.email} tiene menos de 50 libros válidos`);
    }

    accountBooks.push(books.map(book => ({
      token,
      bookId: book.user_book_id,
      currentPage: book.current_page,
      maxPage: book.book_editions.number_of_pages,
    })));
  }

  // Alternar las cuentas para distribuir la carga.
  const sessions = [];

  for (let i = 0; i < 50; i++) {
    sessions.push(accountBooks[0][i]);
    sessions.push(accountBooks[1][i]);
  }

  return sessions;
}

let nextPage = null;

export default function (sessions) {
  const session = sessions[__VU - 1];

  if (!session) {
    fail(`No existe libro asignado al VU ${__VU}`);
  }

  if (nextPage === null) {
    nextPage = session.currentPage + 1;
  }

  if (nextPage > session.maxPage) {
    sleep(6);
    return;
  }

  const response = http.post(
    `${URL}/rest/v1/rpc/update_book_progress`,
    JSON.stringify({
      p_user_book_id: session.bookId,
      p_new_page: nextPage,
      p_log_date: new Date().toISOString().slice(0, 10),
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

  const success = response.status === 200 ||
                  response.status === 204;

  check(response, {
    'Actualización exitosa': () => success,
  });

  if (success) {
    nextPage++;
  } else {
    console.error(
      `VU ${__VU}: Error HTTP ${response.status}`
    );
  }

  sleep(6);
}
