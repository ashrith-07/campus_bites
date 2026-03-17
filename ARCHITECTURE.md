# Campus Bites – Architecture, Workflow & DevOps Explanation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Repository Structure](#3-repository-structure)
4. [CI/CD Workflow](#4-cicd-workflow)
5. [Testing Strategy](#5-testing-strategy)
6. [Linting & Code Quality](#6-linting--code-quality)
7. [Dependabot Configuration](#7-dependabot-configuration)
8. [AWS EC2 Deployment](#8-aws-ec2-deployment)
9. [Idempotent Scripts](#9-idempotent-scripts)
10. [Design Decisions](#10-design-decisions)
11. [Challenges & Solutions](#11-challenges--solutions)

---

## 1. Project Overview

Campus Bites is a full-stack food ordering platform for college campuses.

| Layer    | Technology                                      |
|----------|-------------------------------------------------|
| Frontend | Next.js 16, React 19, Tailwind CSS              |
| Backend  | Express 5, Prisma ORM, MySQL                    |
| Realtime | Pusher (order status push notifications)        |
| Auth     | JWT (jsonwebtoken + bcryptjs)                   |
| Storage  | Cloudinary (image uploads)                      |
| Hosting  | Frontend → Vercel / EC2, Backend → Vercel / EC2 |

### User Roles
- **CUSTOMER** – browse menu, add to cart, place orders, track status
- **VENDOR** – manage menu items, view all orders, update order status

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Browser / Mobile                       │
│               Next.js 16 (App Router, React 19)              │
│   Pages: /, /auth/login, /auth/signup, /checkout,            │
│          /order-tracking, /vendor, /profile                   │
│   Contexts: AuthContext, CartContext, PusherContext           │
└────────────────────────┬─────────────────────────────────────┘
                         │ HTTPS REST API calls (lib/api.js)
                         │ + Pusher WebSocket (realtime)
┌────────────────────────▼─────────────────────────────────────┐
│                  Express 5 Backend (Node.js)                  │
│  Routes:  /api/auth  /api/menu  /api/orders                   │
│           /api/users /api/store /api/upload                   │
│  Middleware: authenticateToken, checkVendorRole               │
│  Validation: Zod schemas                                      │
└──────────┬──────────────────────────┬────────────────────────┘
           │ Prisma ORM               │ Pusher SDK
┌──────────▼──────────┐    ┌──────────▼──────────┐
│   MySQL Database    │    │   Pusher Channels    │
│   (PlanetScale /    │    │   (order updates,    │
│    AWS RDS)         │    │    vendor alerts)    │
└─────────────────────┘    └─────────────────────┘
           │
  Cloudinary (image storage)
```

### Data Flow – Place an Order
1. Customer adds items → `CartContext` holds state in memory
2. `/checkout` page calls `POST /api/orders/checkout` → gets mock order ID
3. `POST /api/orders/confirm` → Prisma creates `Order` + `OrderItem` records
4. Backend calls `global.sendVendorOrderAlert` → Pusher notifies vendor dashboard
5. Backend calls `global.sendOrderUpdate` → Pusher notifies customer's order-tracking page

---

## 3. Repository Structure

```
campus-bites/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml          ← Main CI (lint + test + build on push/PR)
│   │   ├── pr-lint.yml     ← PR gate: ESLint + Prettier must pass
│   │   └── deploy.yml      ← SSH deploy to EC2 on push to main
│   └── dependabot.yml      ← Auto dependency update PRs
│
├── backend/
│   ├── src/
│   │   ├── controllers/    ← Business logic (auth, menu, orders, …)
│   │   ├── middleware/     ← JWT auth, vendor role check
│   │   ├── routes/         ← Express routers
│   │   ├── utils/          ← Prisma client, Pusher, Cloudinary helpers
│   │   ├── validations/    ← Zod schemas
│   │   └── tests/
│   │       ├── unit/       ← Controller + middleware unit tests (Jest)
│   │       └── integration/← HTTP route integration tests (Supertest)
│   ├── prisma/
│   │   ├── schema.prisma   ← DB schema (User, MenuItem, Order, OrderItem)
│   │   ├── migrations/     ← Versioned SQL migrations
│   │   └── seed.js         ← Idempotent seed data
│   ├── server.js           ← Express app entry point
│   ├── .eslintrc.js        ← ESLint rules for Node.js
│   └── .prettierrc         ← Prettier config
│
├── frontend/
│   ├── app/                ← Next.js App Router pages
│   ├── components/ui/      ← Reusable React components
│   ├── contexts/           ← AuthContext, CartContext, PusherContext
│   ├── lib/api.js          ← Central API client (fetch wrapper)
│   ├── __tests__/          ← Jest + Testing Library unit tests
│   ├── e2e/                ← Playwright end-to-end tests
│   ├── jest.setup.js       ← Testing Library DOM matchers
│   ├── playwright.config.js← Playwright configuration
│   ├── eslint.config.mjs   ← ESLint (Next.js flat config)
│   └── .prettierrc         ← Prettier config
│
└── scripts/
    ├── setup-ec2.sh        ← One-time idempotent server bootstrap
    ├── deploy.sh           ← Idempotent deploy (git pull + restart)
    ├── seed-db.sh          ← Idempotent DB seed
    └── rollback.sh         ← Roll back one commit + restart
```

---

## 4. CI/CD Workflow

### Pipelines

#### `ci.yml` – runs on every `push` and `pull_request`

```
push / pull_request
        │
   ┌────▼────┐        ┌────────────┐
   │ backend │        │  frontend  │
   │─────────│        │────────────│
   │ npm ci  │        │ npm ci     │
   │ ESLint  │        │ ESLint     │
   │ unit    │        │ unit tests │
   │ integr. │        │ next build │
   └────┬────┘        └─────┬──────┘
        └──────────┬─────────┘
              ┌────▼────┐
              │   e2e   │  (only on push to main)
              │─────────│
              │Playwright│
              └─────────┘
```

#### `pr-lint.yml` – blocks PR merge if linting fails
- Runs `eslint` on both frontend and backend
- Runs `prettier --check` to enforce formatting
- PR **cannot be merged** unless this workflow is green

#### `deploy.yml` – auto deploys to EC2 on push to `main`
- Uses `appleboy/ssh-action` with secrets stored in GitHub
- Runs `deploy.sh` over SSH
- Zero-downtime: PM2 `restart` keeps the process alive during file swap

### Required GitHub Secrets for Deployment

| Secret        | Description                         |
|---------------|-------------------------------------|
| `EC2_HOST`    | Public IP or hostname of EC2        |
| `EC2_USER`    | SSH username (e.g. `ubuntu`)        |
| `EC2_SSH_KEY` | Private key (PEM) for SSH access    |
| `EC2_PORT`    | SSH port (default 22)               |
| `DATABASE_URL`| MySQL connection string             |

---

## 5. Testing Strategy

### Backend – Unit Tests (`src/tests/unit/`)

| File                        | What it tests                                  |
|-----------------------------|------------------------------------------------|
| `authController.test.js`    | signup/login: validation, duplicates, JWT gen  |
| `menuController.test.js`    | CRUD for menu items, error codes (P2002/P2025) |
| `authMiddleware.test.js`    | JWT verification, role checks                  |
| `orderController.test.js`   | checkout, confirmOrder, status updates         |

All unit tests **mock Prisma and bcrypt** — no real database connection needed.

### Backend – Integration Tests (`src/tests/integration/`)

| File                              | What it tests                                   |
|-----------------------------------|-------------------------------------------------|
| `auth.integration.test.js`        | Full HTTP POST /auth/signup + /auth/login flows |
| `menu.integration.test.js`        | GET/POST/DELETE /menu/items with auth checks    |

Uses **Supertest** to spin up the real Express app with mocked Prisma.
This validates that routes, middleware, and controllers are wired correctly end-to-end.

### Frontend – Unit Tests (`__tests__/`)

| File                      | What it tests                                    |
|---------------------------|--------------------------------------------------|
| `MenuCard.test.jsx`       | Rendering, Add button, Popular badge, price      |
| `api.test.js`             | All API methods: request shape, auth headers     |
| `CartContext.test.jsx`    | Add, increment, updateQuantity, clear, totals    |

Uses **Jest + Testing Library** with a jsdom environment.
Components are rendered in isolation with mocked contexts and `fetch`.

### E2E Tests (`e2e/userFlows.spec.js`)

Playwright simulates complete user journeys in a real browser:
1. Home page loads and shows menu (guest)
2. Unauthenticated Add redirects to login
3. Sign-up with new account
4. Login with valid/invalid credentials
5. Add to cart → proceed to checkout
6. Order tracking page loads

---

## 6. Linting & Code Quality

### ESLint

**Backend** (`.eslintrc.js`):
- Environment: `node`, `jest`
- Key rules: `prefer-const`, `no-var`, `eqeqeq`, `semi`, `quotes: single`
- Run: `npm run lint`
- Auto-fix: `npm run lint:fix`

**Frontend** (`eslint.config.mjs`):
- Extends `next/core-web-vitals`
- Key rules: `prefer-const`, `no-var`, `no-unused-vars`
- Run: `npm run lint`

### Prettier

Consistent code formatting across the whole project.
- Backend: single quotes, trailing commas, 100-char print width
- Frontend: double quotes (JSX convention), 100-char print width
- Check: `npm run format:check`
- Fix: `npm run format`

### PR Gate

The `pr-lint.yml` workflow **blocks merging** if either ESLint or Prettier checks fail.
This enforces that all code in `main` is consistently formatted and lint-free.

---

## 7. Dependabot Configuration

`.github/dependabot.yml` configures three update targets:

| Ecosystem        | Directory   | Schedule      | Labels                     |
|------------------|-------------|---------------|----------------------------|
| npm (backend)    | `/backend`  | Weekly Monday | `dependencies`, `backend`  |
| npm (frontend)   | `/frontend` | Weekly Monday | `dependencies`, `frontend` |
| GitHub Actions   | `/`         | Monthly       | `dependencies`, `actions`  |

**Ignored major bumps**: `next`, `react`, `react-dom`, `prisma` — these require manual testing before major version upgrades.

Dependabot PRs automatically trigger the CI pipeline, so you see whether an update breaks tests before merging.

---

## 8. AWS EC2 Deployment

### Architecture on EC2

```
Internet → Nginx (port 80/443)
               ├── / → PM2: campus-bites-frontend (Next.js :3000)
               └── /api/ → PM2: campus-bites-backend (Express :3001)
```

### Setup Steps

1. **Launch EC2**: Ubuntu 24.04 LTS, t3.small or larger
2. **Security Group**: allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
3. **Bootstrap** (one time):
   ```bash
   scp scripts/setup-ec2.sh ubuntu@<EC2_IP>:~/
   ssh ubuntu@<EC2_IP> "bash ~/setup-ec2.sh"
   ```
4. **Fill in secrets**: Edit `/home/ubuntu/campus-bites/backend/.env`
5. **Deploy**: Push to `main` → GitHub Actions runs `deploy.yml` automatically

### GitHub Actions → EC2 Connection

```yaml
- uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ secrets.EC2_HOST }}
    username: ${{ secrets.EC2_USER }}
    key: ${{ secrets.EC2_SSH_KEY }}
    script: |
      cd /home/ubuntu/campus-bites
      git pull origin main
      # ... install + restart
```

The private key is stored as a GitHub secret (`EC2_SSH_KEY`).
It **never appears** in logs or workflow files.

---

## 9. Idempotent Scripts

Idempotency means: **running a script multiple times produces the same result as running it once**. This is critical for deployment scripts because network failures, retries, and re-runs must not corrupt the system state.

### How Each Script Achieves Idempotency

| Script          | Idempotent Patterns Used                                        |
|-----------------|-----------------------------------------------------------------|
| `setup-ec2.sh`  | `mkdir -p`, `apt-get -y`, nvm check before install, `ln -sf`   |
| `deploy.sh`     | `git reset --hard` (not pull), `pm2 restart OR pm2 start`       |
| `seed-db.sh`    | Prisma `migrate deploy` (skips applied), seed uses `upsert`    |
| `rollback.sh`   | `pm2 restart \|\| true` (no error if already stopped)           |

### Bad vs Good Patterns

```bash
# ❌ BAD – fails on second run because directory already exists
mkdir project

# ✅ GOOD – safe to run any number of times
mkdir -p project
```

```bash
# ❌ BAD – creates duplicate PM2 process on re-run
pm2 start server.js --name backend

# ✅ GOOD – restarts if running, starts if not
pm2 describe backend > /dev/null 2>&1 \
  && pm2 restart backend \
  || pm2 start server.js --name backend
```

```bash
# ❌ BAD – fails or creates duplicate on second run
git clone https://repo.git .

# ✅ GOOD – pull if repo exists, clone if not
if [ -d ".git" ]; then git pull; else git clone https://repo.git .; fi
```

---

## 10. Design Decisions

### Why Prisma ORM?
- Type-safe queries reduce runtime errors
- Migration system (`prisma migrate dev/deploy`) gives version-controlled schema changes
- Schema-first approach makes the DB structure easy to understand

### Why Pusher for Realtime?
- No infrastructure to maintain (vs self-hosted Socket.io server)
- Works through NAT and firewalls (WebSocket with HTTP fallback)
- Built-in channel authentication model fits the customer/vendor separation

### Why Next.js App Router?
- Server-side rendering improves initial page load and SEO
- File-system routing keeps pages organized
- Built-in API route support (not used here but available)

### Why JWT over Sessions?
- Stateless: no session store needed, scales horizontally
- Works cleanly with the mobile API without cookies
- 7-day expiry balances security and UX

### Why Mock Prisma in Tests (not use a test DB)?
- Tests run in CI without a real MySQL instance
- Faster test execution (no network I/O)
- Unit tests should test logic, not the DB driver
- Integration tests use Supertest + mocked Prisma to validate the HTTP + middleware stack

---

## 11. Challenges & Solutions

### Challenge 1: Prisma in a Test Environment
**Problem**: Prisma requires a real database connection on import, crashing tests in CI.  
**Solution**: Mock `@prisma/client` entirely in unit tests. For integration tests, mock only the shared `utils/prisma.js` module. The Express app boots cleanly because `require.main === module` prevents auto-listen.

### Challenge 2: `server.js` auto-starting when required by Supertest
**Problem**: `app.listen()` was called at module load, causing port conflicts in tests.  
**Solution**: Wrapped `app.listen()` in `if (require.main === module)`. Supertest imports the app without triggering `listen()`.

### Challenge 3: Next.js App Router component testing
**Problem**: `useRouter`, `useCart`, `useAuth` hooks make components tightly coupled to their providers.  
**Solution**: Jest module mocking (`jest.mock(...)`) replaces all context hooks with simple stubs, letting components be tested in isolation.

### Challenge 4: Idempotent Deployment
**Problem**: Deployment scripts that use `git clone` or `pm2 start` fail on re-runs.  
**Solution**: All scripts check current state before acting (`if [ -d .git ]`, `pm2 describe`) and use flags like `mkdir -p`, `ln -sf`, `npm ci`.

### Challenge 5: Dependabot + Major Version Pinning
**Problem**: Dependabot's auto-PRs for `next` v17 or `prisma` v7 could break the app without warning.  
**Solution**: Added `ignore` rules in `dependabot.yml` to block major version bumps for critical packages. These are upgraded manually after testing.
