
import http from 'k6/http';
import { check, sleep } from 'k6';

const books = [
  'harry potter',
  'don quijote',
  '1984',
  'el principito',
  'cien años de soledad',
  'dune',
  'the hobbit',
  'fundacion',
  'orgullo y prejuicio',
  'crimen y castigo',
];

export const options = {
  vus: 1,
  iterations: 200,
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const query = books[__ITER % books.length];

  const response = http.get(
    `https://openlibrary.org/search.json?q=${encodeURIComponent(query)}&limit=20`
  );

  check(response, {
    'Respuesta exitosa': (r) => r.status === 200,
    'Tiempo menor a 3 segundos': (r) => r.timings.duration < 3000,
  });

  sleep(2);
}
