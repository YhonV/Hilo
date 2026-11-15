
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 1,
  iterations: 200,
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const url = `${__ENV.SUPABASE_URL}/rest/v1/user_book?select=*&limit=100`;

  const response = http.get(url, {
    headers: {
      apikey: __ENV.SUPABASE_KEY,
      Authorization: `Bearer ${__ENV.ACCESS_TOKEN}`,
    },
  });

  check(response, {
    'Respuesta HTTP 200': (r) => r.status === 200,
    'Respuesta JSON valida': (r) => {
      try {
        return Array.isArray(r.json());
      } catch {
        return false;
      }
    },
    'Biblioteca con 100 libros': (r) => {
  try {
    return r.json().length === 100;
  } catch {
    return false;
  }
},
  });

  sleep(1);
}
