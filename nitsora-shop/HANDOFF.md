# Nitsora Shop (cosmetics) — developer handoff to the platform team

This repo contains **application code only**. Everything needed to build, ship,
run and watch it (Dockerfiles, nginx, Kubernetes, Terraform, CI/CD, Argo CD,
monitoring) is the platform team's job — that's you.

## What runs

| Component | Tech | Listens on | Notes |
|---|---|---|---|
| auth | Python 3.12, FastAPI (uvicorn) | 8000 | register / login / JWT |
| products | Python 3.12, FastAPI | 8000 | catalogue, stock |
| orders | Python 3.12, FastAPI | 8000 | calls products + payments |
| payments | Python 3.12, FastAPI | 8000 | mock or Stripe; calls orders |
| frontend | static HTML/JS/CSS in `frontend/public/` | — | needs a web server **and** an API gateway (see below) |
| database | PostgreSQL 16 | 5432 | one database per service is ideal; one shared DB with one schema works too |

Start command for every Python service (from inside `services/<name>/`, after
`pip install ../../libs/shopcommon -r requirements.txt`):

```
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

`libs/shopcommon` is a shared library every service needs installed — it is
**not** on PyPI, so your build has to copy it in.

## Endpoints every service has

| Path | Meaning |
|---|---|
| `/healthz` | process is alive (liveness) — never touches the DB |
| `/readyz` | 200 if the DB is reachable, 503 if not (readiness) |
| `/metrics` | Prometheus metrics: `http_requests_total`, `http_request_duration_seconds`, plus business counters (`shop_*`) |

Logs are JSON lines on stdout. Each request carries an `X-Request-ID`.

## Configuration (environment variables)

All services:

| Variable | Required? | Example | Notes |
|---|---|---|---|
| `APP_ENV` | yes | `production` | in `production` the secrets below **must** be set or the service refuses to start |
| `DATABASE_URL` | yes | `postgresql+psycopg://user:pass@host:5432/shop` | **secret** |
| `JWT_SECRET` | yes | 32+ random bytes | **secret**, same value in all 4 services |
| `INTERNAL_TOKEN` | yes | random string | **secret**, same value in all 4 services; guards `/internal/*` calls between services |
| `SERVICE_NAME` | no | `auth` | used in logs and metrics labels |
| `LOG_LEVEL` | no | `INFO` | |

Per service:

| Service | Variable | Notes |
|---|---|---|
| auth | `ADMIN_EMAIL`, `ADMIN_PASSWORD` | if set, an admin user is created at startup. Password is a **secret** |
| products | `SEED_SAMPLE_DATA` | `true` loads demo products into an empty DB |
| orders | `PRODUCTS_URL`, `PAYMENTS_URL` | default `http://products:8000`, `http://payments:8000` |
| payments | `ORDERS_URL` | default `http://orders:8000` |
| payments | `PAYMENT_PROVIDER` | `mock` (default) or `stripe` |
| payments | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` | only for `stripe`; the first two are **secrets** |

## Gateway / routing the frontend expects

The browser only talks to one origin. It calls:

| Browser path | Must go to |
|---|---|
| `/` and static files | `frontend/public/` (unknown paths → `index.html`) |
| `/api/auth/...` | auth service, with the `/api/auth` prefix stripped |
| `/api/products/...` | products, prefix stripped |
| `/api/orders/...` | orders, prefix stripped |
| `/api/payments/...` | payments, prefix stripped |

Security asks from the dev team:
- `/api/<svc>/internal/*`, `/api/<svc>/metrics`, `/api/<svc>/docs` and `/openapi.json` must **not** be reachable from the internet.
- Please rate-limit `/api/auth/login` (the service also throttles per account after 5 failures).
- Payments needs `https://js.stripe.com` allowed in the Content-Security-Policy when Stripe is on.

## Tests

```
cd services/auth
pip install ../../libs/shopcommon -r requirements.txt pytest
pytest
```

Same for products, orders, payments and `libs/shopcommon`. Tests use SQLite —
no database needed. Lint config (ruff) is in the root `pyproject.toml`.
