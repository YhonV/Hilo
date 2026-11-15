
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 1,
  iterations: 200,
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate==1'],
  },
};

export default function () {
  const url = `${__ENV.SUPABASE_URL}/rest/v1/rpc/get_calendar_activities`;

  const payload = JSON.stringify({
    p_start_date: '2026-11-01',
    p_end_date: '2026-11-30',
  });

  const response = http.post(url, payload, {
    headers: {
      apikey: __ENV.SUPABASE_KEY,
      Authorization: `Bearer ${__ENV.ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
  });

  if (response.status !== 200) {
    console.error(
      `Error HTTP ${response.status}: ${response.body}`
    );
  }

  check(response, {
    'Respuesta HTTP 200': (r) => r.status === 200,
    'Respuesta JSON valida': (r) => {
      try {
        return Array.isArray(r.json());
      } catch {
        return false;
      }
    },
    'Calendario con actividades': (r) => {
      try {
        return r.json().length > 0;
      } catch {
        return false;
      }
    },
  });

  sleep(1);
}
