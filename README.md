<div align="center">

# 🍔 Campus Bites

**A production-grade full-stack food ordering platform for college campuses**

[![Next.js](https://img.shields.io/badge/Next.js-16-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?style=for-the-badge&logo=node.js)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker)](https://docs.docker.com/compose/)
[![Terraform](https://img.shields.io/badge/Terraform-AWS-7B42BC?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![License](https://img.shields.io/badge/License-ISC-blue?style=for-the-badge)](LICENSE)

[**🌐 Live Demo**](https://campus-bites-web.vercel.app/) · [**📐 Architecture**](./ARCHITECTURE.md) · [**🐛 Report Bug**](https://github.com/ashrith-07/campus-bites/issues)

</div>

---

## 📋 Table of Contents

- [🍔 Campus Bites](#-campus-bites)
  - [📋 Table of Contents](#-table-of-contents)
  - [🎯 Overview](#-overview)
    - [User Roles](#user-roles)
  - [🛠 Tech Stack](#-tech-stack)
  - [🏗 System Architecture](#-system-architecture)
    - [Order Flow](#order-flow)
  - [📁 Repository Structure](#-repository-structure)
  - [🚀 Getting Started](#-getting-started)
    - [Prerequisites](#prerequisites)
    - [Local Development](#local-development)
    - [Docker (Recommended)](#docker-recommended)
  - [☁️ AWS Deployment (Terraform + Docker)](#️-aws-deployment-terraform--docker)
    - [1. Provision Infrastructure](#1-provision-infrastructure)
    - [2. Bootstrap the Server (one time only)](#2-bootstrap-the-server-one-time-only)
    - [3. Deploy (via GitHub Actions — one click)](#3-deploy-via-github-actions--one-click)
  - [🔄 CI/CD Pipeline](#-cicd-pipeline)
    - [`ci.yml` — Quality Gate (every push \& PR)](#ciyml--quality-gate-every-push--pr)
    - [`pr-lint.yml` — PR Gate](#pr-lintyml--pr-gate)
    - [`deploy.yml` — AWS EC2 Deploy](#deployyml--aws-ec2-deploy)
  - [🧪 Testing Strategy](#-testing-strategy)
    - [Backend Unit Tests (`src/tests/unit/`)](#backend-unit-tests-srctestsunit)
    - [Backend Integration Tests (`src/tests/integration/`)](#backend-integration-tests-srctestsintegration)
    - [Frontend Unit Tests (`__tests__/`)](#frontend-unit-tests-__tests__)
    - [E2E Tests (`e2e/userFlows.spec.js`)](#e2e-tests-e2euserflowsspecjs)
  - [🔐 Environment Variables](#-environment-variables)
    - [Backend (`backend/.env`)](#backend-backendenv)
    - [Frontend (`frontend/.env.local`)](#frontend-frontendenvlocal)
  - [🗄 Database Schema](#-database-schema)
  - [📜 Scripts Reference](#-scripts-reference)
  - [💡 Design Decisions](#-design-decisions)
  - [📦 Dependabot](#-dependabot)
  - [🤝 Contributing](#-contributing)

---

## 🎯 Overview

Campus Bites is a **real-time food ordering system** purpose-built for college campuses. Students browse a live menu, add items to their cart, and track order status in real time. Vendors manage their menu and receive instant order alerts — all without refreshing the page.

The project follows a **production-grade DevOps workflow** with full CI/CD automation, Infrastructure-as-Code provisioning on AWS, multi-layer testing (unit → integration → E2E), and idempotent deployment scripts.

### User Roles

| Role         | Capabilities                                                                         |
| ------------ | ------------------------------------------------------------------------------------ |
| **Customer** | Browse menu · Add to cart · Checkout · Real-time order tracking                      |
| **Vendor**   | Manage menu items · View all orders · Update order status · Toggle store open/closed |

---

## 🛠 Tech Stack

| Layer                | Technology                                         |
| -------------------- | -------------------------------------------------- |
| **Frontend**         | Next.js 16, React 19, Tailwind CSS, Lucide Icons   |
| **Backend**          | Express 5, Node.js 20, Prisma ORM                  |
| **Database**         | MySQL (PlanetScale / AWS RDS compatible)           |
| **Real-time**        | Pusher Channels (WebSocket push notifications)     |
| **Auth**             | JWT (`jsonwebtoken` + `bcryptjs`), 7-day expiry    |
| **Image Storage**    | Cloudinary                                         |
| **Validation**       | Zod schemas (backend)                              |
| **Containerization** | Docker, Docker Compose                             |
| **Infrastructure**   | Terraform (AWS EC2 + Security Groups)              |
| **CI/CD**            | GitHub Actions (3 pipelines)                       |
| **Testing**          | Jest, Supertest, React Testing Library, Playwright |
| **Code Quality**     | ESLint, Prettier, Dependabot                       |

---

## 🏗 System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Browser / Mobile                      │
│               Next.js 16 (App Router, React 19)              │
│   Pages: / · /auth/login · /auth/signup · /checkout          │
│          /order-tracking · /vendor · /profile                │
│   Contexts: AuthContext · CartContext · PusherContext        │
└────────────────────────┬─────────────────────────────────────┘
                         │ HTTPS REST API calls (lib/api.js)
                         │ + Pusher WebSocket (real-time)
┌────────────────────────▼─────────────────────────────────────┐
│                  Express 5 Backend (Node.js)                 │
│  Routes:  /api/auth · /api/menu · /api/orders                │
│           /api/users · /api/store · /api/upload              │
│  Middleware: authenticateToken · checkVendorRole             │
│  Validation: Zod schemas                                     │
└──────────┬──────────────────────────┬────────────────────────┘
           │ Prisma ORM               │ Pusher SDK
┌──────────▼──────────┐    ┌──────────▼──────────┐
│   MySQL Database    │    │   Pusher Channels   │
│  (AWS RDS / Local)  │    │  order updates +    │
│                     │    │  vendor alerts      │
└─────────────────────┘    └─────────────────────┘
           │
  Cloudinary (image storage)
```

### Order Flow

```
Customer → Cart → POST /api/orders/checkout → order ID
       → POST /api/orders/confirm   → Prisma writes Order + OrderItems
       → Pusher trigger             → Vendor dashboard notified instantly
       → Pusher trigger             → Customer order-tracking page updated
```

---

## 📁 Repository Structure

```
campus-bites/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml          ← Lint + test + build on every push/PR
│   │   ├── pr-lint.yml     ← Blocks PR merge if ESLint/Prettier fail
│   │   └── deploy.yml      ← One-click deploy to AWS EC2
│   └── dependabot.yml      ← Automated weekly dependency update PRs
│
├── backend/
│   ├── src/
│   │   ├── controllers/    ← Business logic (auth, menu, orders, store, upload)
│   │   ├── middleware/     ← JWT auth guard, vendor role guard
│   │   ├── routes/         ← Express routers (/api/*)
│   │   ├── utils/          ← Prisma client, Pusher helper, Cloudinary helper
│   │   ├── validations/    ← Zod request schemas
│   │   └── tests/
│   │       ├── unit/       ← Controller + middleware unit tests (Jest)
│   │       └── integration/← HTTP route tests (Supertest)
│   ├── prisma/
│   │   ├── schema.prisma   ← DB models: User, MenuItem, Order, OrderItem, StoreSetting
│   │   ├── migrations/     ← Versioned SQL migration history
│   │   └── seed.js         ← Idempotent seed data (upsert-based)
│   ├── server.js           ← Express app entry point
│   ├── Dockerfile          ← Node 20-slim image, Prisma generate
│   └── .eslintrc.js / .prettierrc
│
├── frontend/
│   ├── app/                ← Next.js App Router pages
│   ├── components/         ← Reusable UI components (MenuCard, CartDrawer, …)
│   ├── contexts/           ← AuthContext, CartContext, PusherContext
│   ├── lib/api.js          ← Centralized API client (typed fetch wrapper)
│   ├── __tests__/          ← Jest + React Testing Library unit tests
│   ├── e2e/                ← Playwright end-to-end test suite
│   ├── Dockerfile          ← Multi-stage Node 20-alpine image
│   └── eslint.config.mjs / .prettierrc
│
├── terraform/
│   ├── main.tf             ← EC2 instance + Security Group (ports 22, 3000, 3001)
│   └── providers.tf        ← AWS provider (us-east-1, Terraform ~> 5.0)
│
├── scripts/
│   ├── setup-ec2.sh        ← One-time idempotent server bootstrap (Nginx, Node, PM2)
│   ├── seed-db.sh          ← Idempotent DB migration + seed runner
│   └── rollback.sh         ← Roll back one git commit + restart Docker Compose
│
└── docker-compose.yml      ← Orchestrates backend (:3001) + frontend (:3000)
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** ≥ 20
- **Docker** and **Docker Compose** (v2)
- **MySQL** database (local, PlanetScale, or AWS RDS)
- **Pusher** account (free tier works)
- **Cloudinary** account (free tier works)

### Local Development

**1. Clone the repository**
```bash
git clone https://github.com/ashrith-07/campus-bites.git
cd campus-bites
```

**2. Set up environment variables**

Backend (`backend/.env`):
```env
DATABASE_URL=mysql://USER:PASSWORD@localhost:3306/campus_bites
JWT_SECRET=your-super-secret-jwt-key
PORT=3001
NODE_ENV=development

PUSHER_APP_ID=your_app_id
PUSHER_KEY=your_key
PUSHER_SECRET=your_secret
PUSHER_CLUSTER=your_cluster

CLOUDINARY_CLOUD_NAME=your_cloud
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

Frontend (`frontend/.env.local`):
```env
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_PUSHER_KEY=your_pusher_key
NEXT_PUBLIC_PUSHER_CLUSTER=your_pusher_cluster
```

**3. Run backend**
```bash
cd backend
npm ci
npx prisma migrate deploy
npx prisma db seed
npm run dev
```

**4. Run frontend**
```bash
cd frontend
npm ci
npm run dev
```

Visit **http://localhost:3000** 🎉

---

### Docker (Recommended)

Run the full stack with a single command:

```bash
# Build and start both services
docker compose up --build

# Run in detached mode
docker compose up --build -d

# Stop everything
docker compose down
```

| Service     | URL                              |
| ----------- | -------------------------------- |
| Frontend    | http://localhost:3000            |
| Backend API | http://localhost:3001/api        |
| API Status  | http://localhost:3001/api/status |

---

## ☁️ AWS Deployment (Terraform + Docker)

Deploy the entire application to AWS EC2 in just **3 commands**. The infrastructure is fully managed with Terraform — no manual console clicking required.

### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Terraform provisions:
- **EC2 instance** — Ubuntu 24.04 LTS, `t3.small`, 20 GB gp3 SSD
- **Security Group** — opens ports 22 (SSH), 3000 (frontend), 3001 (backend API)
- **Auto-fetched AMI** — always uses the latest Ubuntu noble image

After apply completes, note the public IP:
```
Outputs:
  ec2_public_ip = "x.x.x.x"
```

### 2. Bootstrap the Server (one time only)

```bash
scp -i labsuser.pem scripts/setup-ec2.sh ubuntu@<EC2_IP>:~/
ssh -i labsuser.pem ubuntu@<EC2_IP> "bash ~/setup-ec2.sh"
```

This idempotent script installs: `git`, `Docker`, `Docker Compose`, `Nginx` (reverse proxy), and creates the app directory. Safe to re-run at any time.

### 3. Deploy (via GitHub Actions — one click)

Set these **GitHub Secrets** in your repository settings:

| Secret                    | Description                            |
| ------------------------- | -------------------------------------- |
| `EC2_HOST`                | Public IP of your EC2 instance         |
| `EC2_USER`                | SSH user (default: `ubuntu`)           |
| `EC2_SSH_KEY`             | Contents of your `.pem` private key    |
| `CAMPUS_BITES_SERVER_ENV` | Full contents of `backend/.env`        |
| `CAMPUS_BITES_CLIENT_ENV` | Full contents of `frontend/.env.local` |

Then trigger deployment from GitHub → Actions → **"Deploy Campus Bites to AWS EC2"** → **Run workflow**.

The pipeline will:
1. SSH into EC2
2. Clone/update the repository
3. Write environment files securely
4. Prune old Docker images & set up swap space
5. Build and launch containers with `docker compose up -d`
6. Run `prisma migrate deploy` inside the backend container

> **That's it.** Infrastructure  + app deployment — 3 commands.

---

## 🔄 CI/CD Pipeline

Three GitHub Actions workflows handle the complete software delivery lifecycle:

### `ci.yml` — Quality Gate (every push & PR)

```
push / pull_request to main or devops
         │
   ┌─────▼──────┐        ┌────────────────┐
   │  backend   │        │    frontend    │
   │────────────│        │────────────────│
   │ npm ci     │        │ npm ci         │
   │ ESLint     │        │ ESLint         │
   │ Unit tests │        │ Unit tests     │
   │ Integration│        │ next build     │
   └─────┬──────┘        └───────┬────────┘
         └──────────┬────────────┘
               ┌────▼────┐
               │   E2E   │  (push to main only)
               │─────────│
               │Playwright│
               └─────────┘
```

### `pr-lint.yml` — PR Gate

Runs ESLint **and** Prettier on both frontend and backend. **PRs cannot be merged** unless this workflow passes — guaranteeing that all code in `main` is consistently formatted and lint-free.

### `deploy.yml` — AWS EC2 Deploy

Triggered manually via `workflow_dispatch`. Validates secrets, securely copies env files via SCP, and runs the full Docker Compose deployment over SSH. The SSH key is cleaned up immediately after the job completes.

---

## 🧪 Testing Strategy

### Backend Unit Tests (`src/tests/unit/`)

| Test File                 | What It Covers                                               |
| ------------------------- | ------------------------------------------------------------ |
| `authController.test.js`  | Signup/login validation, duplicate detection, JWT generation |
| `menuController.test.js`  | CRUD for menu items, Prisma error codes (P2002, P2025)       |
| `authMiddleware.test.js`  | JWT verification, missing/expired tokens, role enforcement   |
| `orderController.test.js` | Checkout flow, order confirmation, status transitions        |

All unit tests **mock Prisma and bcrypt** — no real database required. Fast, isolated, and CI-friendly.

### Backend Integration Tests (`src/tests/integration/`)

| Test File                  | What It Covers                                      |
| -------------------------- | --------------------------------------------------- |
| `auth.integration.test.js` | Full HTTP POST `/auth/signup` + `/auth/login` flows |
| `menu.integration.test.js` | GET/POST/DELETE `/menu/items` with auth middleware  |

Uses **Supertest** to spin up the real Express app. Validates that routes, middleware, and controllers are correctly wired end-to-end.

### Frontend Unit Tests (`__tests__/`)

| Test File              | What It Covers                                                |
| ---------------------- | ------------------------------------------------------------- |
| `MenuCard.test.jsx`    | Rendering, add-to-cart button, popular badge, price display   |
| `api.test.js`          | All API methods — request shape, auth headers, error handling |
| `CartContext.test.jsx` | Add/increment/updateQuantity/clear and total calculations     |

Uses **Jest + React Testing Library** in a jsdom environment with mocked contexts.

### E2E Tests (`e2e/userFlows.spec.js`)

**Playwright** simulates full user journeys in a real Chromium browser:
1. Home page loads and shows the menu (guest view)
2. Unauthenticated "Add to cart" redirects to login
3. Sign-up with a new account
4. Login with valid and invalid credentials
5. Add items to cart → proceed to checkout
6. Order tracking page loads and displays status

```bash
# Run all tests
cd backend && npm test
cd frontend && npm test

# Run Playwright E2E
cd frontend && npx playwright test

# Coverage reports
npm run test:coverage
```

---

## 🔐 Environment Variables

### Backend (`backend/.env`)

| Variable                | Required | Description                           |
| ----------------------- | -------- | ------------------------------------- |
| `DATABASE_URL`          | ✅        | MySQL connection string               |
| `JWT_SECRET`            | ✅        | Secret key for signing JWTs           |
| `PORT`                  | ✅        | Server port (default: `3001`)         |
| `NODE_ENV`              | ✅        | `development` / `production` / `test` |
| `PUSHER_APP_ID`         | ✅        | Pusher application ID                 |
| `PUSHER_KEY`            | ✅        | Pusher key                            |
| `PUSHER_SECRET`         | ✅        | Pusher secret                         |
| `PUSHER_CLUSTER`        | ✅        | Pusher cluster (e.g. `ap2`)           |
| `CLOUDINARY_CLOUD_NAME` | ✅        | Cloudinary cloud name                 |
| `CLOUDINARY_API_KEY`    | ✅        | Cloudinary API key                    |
| `CLOUDINARY_API_SECRET` | ✅        | Cloudinary API secret                 |

### Frontend (`frontend/.env.local`)

| Variable                     | Required | Description          |
| ---------------------------- | -------- | -------------------- |
| `NEXT_PUBLIC_API_URL`        | ✅        | Backend API base URL |
| `NEXT_PUBLIC_PUSHER_KEY`     | ✅        | Pusher public key    |
| `NEXT_PUBLIC_PUSHER_CLUSTER` | ✅        | Pusher cluster       |

---

## 🗄 Database Schema

```
User           MenuItem          Order            OrderItem
─────────      ────────────      ──────────       ───────────
id (PK)        id (PK)           id (PK)          id (PK)
email          name              userId (FK)      orderId (FK)
passwordHash   description       total            menuItemId (FK)
name           price             status           quantity
role           category          paymentIntentId
               imageUrl          createdAt
               stock             updatedAt
               isAvailable
               popular

StoreSetting
────────────
id (PK)
key (unique)
value
updatedAt

Enums: UserRole {CUSTOMER, VENDOR} · OrderStatus {PENDING, PROCESSING, READY, COMPLETED, CANCELLED}
```

---

## 📜 Scripts Reference

| Script                  | Location                  | Purpose                                       |
| ----------------------- | ------------------------- | --------------------------------------------- |
| `setup-ec2.sh`          | `scripts/`                | One-time bootstrap: Node, Docker, Nginx, PM2  |
| `seed-db.sh`            | `scripts/`                | Run Prisma migrations + seed idempotently     |
| `rollback.sh`           | `scripts/`                | Roll back one git commit and restart services |
| `npm run dev`           | `backend/` or `frontend/` | Start local dev server                        |
| `npm run lint`          | Both                      | Run ESLint                                    |
| `npm run format`        | Both                      | Run Prettier                                  |
| `npm test`              | Both                      | Run Jest test suite                           |
| `npm run test:coverage` | Both                      | Generate coverage report                      |
| `npx playwright test`   | `frontend/`               | Run E2E tests                                 |

---

## 💡 Design Decisions

| Decision                                  | Rationale                                                                                                          |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Pusher over self-hosted Socket.io**     | No infra to maintain; works through NAT/firewalls; built-in channel auth maps cleanly to customer/vendor roles     |
| **Prisma over raw SQL**                   | Type-safe queries, schema-first migrations, and readable models reduce runtime bugs                                |
| **Next.js App Router**                    | SSR improves initial load & SEO; file-system routing keeps pages organized                                         |
| **JWT over Sessions**                     | Stateless — scales horizontally; no session store required; clean for API clients                                  |
| **Mock Prisma in tests**                  | Tests run in CI without a live MySQL instance; faster execution; unit tests test logic, not the DB driver          |
| **Idempotent deploy scripts**             | Safe to re-run on network failure; `mkdir -p`, `pm2 describe                                                       |  | start`, `git reset --hard` prevent corruption |
| **Dependabot with major-version pinning** | Auto-PRs keep dependencies fresh; manual review gate prevents surprise breaking changes for Next.js, React, Prisma |
| **t3.small + 1 GB swap**                  | Balances cost vs. capacity for running two Node processes + Docker builds on a single instance                     |

---

## 📦 Dependabot

Automated dependency updates run on this schedule:

| Ecosystem      | Directory   | Schedule        |
| -------------- | ----------- | --------------- |
| npm (backend)  | `/backend`  | Weekly (Monday) |
| npm (frontend) | `/frontend` | Weekly (Monday) |
| GitHub Actions | `/`         | Monthly         |

Major version bumps for `next`, `react`, `react-dom`, and `prisma` are **blocked** — these require manual testing before upgrading.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes and ensure all tests pass: `npm test`
4. Ensure linting passes: `npm run lint && npm run format:check`
5. Open a Pull Request — the `pr-lint.yml` workflow will automatically validate your code

---

<div align="center">

Built with ❤️ · Deployed on [Vercel](https://campus-bites-web.vercel.app/) · Infra on AWS 

</div>
