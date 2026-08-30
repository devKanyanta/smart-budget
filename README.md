# Smart Budget ZM 💰

A full-stack mobile budgeting application for the Zambian market. Track transactions, manage budgets, set savings goals, and receive personalized financial insights.

## Tech Stack

| Component | Technology |
|---|---|
| **Mobile App** | Flutter (Android) |
| **Backend API** | Node.js + Express |
| **Database** | PostgreSQL 16 |
| **ML Service** | Python + FastAPI |
| **Admin Dashboard** | React + Vite + Tailwind |
| **Auth** | JWT (access + refresh tokens) |
| **Offline Storage** | Hive (Flutter) |
| **Notifications** | Push (FCM) + Email |
| **Orchestration** | Docker Compose |

## Quick Start

### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker & Docker Compose
- Flutter SDK (for mobile app)
- PostgreSQL (if running locally)

### 1. Start All Services

```bash
# Clone the repo
git clone <repo-url>
cd smart-budget-zm

# Copy environment file
cp .env.example .env

# Start with Docker Compose
cd docker
docker-compose up -d
```

### 2. Seed the Database

```bash
# Install backend dependencies
cd apps/backend-api
npm install

# Run seed script
node scripts/seed.js
```

This creates:
- 3 sample users + 1 admin
- 11 spending categories
- 6 months of realistic Zambian transactions per user
- Sample budgets, savings goals, mobile money accounts
- Sample notifications and financial insights

### 3. Access the Services

| Service | URL |
|---|---|
| **Backend API** | http://localhost:3000 |
| **Admin Dashboard** | http://localhost:5173 |
| **ML Service** | http://localhost:5001 |
| **API Health Check** | http://localhost:3000/api/v1/health |

### Login Credentials

| Role | Email | Password |
|---|---|---|
| User | khadijah@example.com | password123 |
| User | james@example.com | password123 |
| User | grace@example.com | password123 |
| Admin | admin@smartbudgetzm.com | admin123 |

## Project Structure

```
smart-budget-zm/
├── apps/
│   ├── flutter-app/          # Flutter mobile app (Android)
│   ├── backend-api/          # Node.js Express REST API
│   ├── ml-service/           # Python FastAPI ML microservice
│   └── admin-dashboard/      # React + Vite admin panel
├── docker/
│   └── docker-compose.yml    # Service orchestration
├── Smart_Budget_ZM_URD.md    # User Requirements Document
├── Smart_Budget_ZM-spec.md   # System Specification
└── README.md
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` — Register a new user
- `POST /api/v1/auth/login` — Login
- `POST /api/v1/auth/refresh` — Refresh access token
- `POST /api/v1/auth/logout` — Logout
- `PUT /api/v1/auth/change-password` — Change password

### Transactions
- `GET /api/v1/transactions` — List (paginated, filterable)
- `POST /api/v1/transactions` — Create manual transaction
- `GET /api/v1/transactions/summary` — Spending summary

### Budgets
- `GET /api/v1/budgets` — List budgets with spent amounts
- `POST /api/v1/budgets` — Create budget
- `GET /api/v1/budgets/:id/spending` — Spending breakdown

### Savings Goals
- `GET /api/v1/savings` — List savings goals
- `POST /api/v1/savings` — Create savings goal
- `POST /api/v1/savings/:id/entries` — Add savings entry
- `GET /api/v1/savings/:id/predictions` — Get savings prediction

### Analytics
- `GET /api/v1/analytics/dashboard` — Dashboard summary
- `GET /api/v1/analytics/monthly-comparison` — Month-over-month
- `GET /api/v1/analytics/category-breakdown` — Spending by category
- `GET /api/v1/analytics/trends` — Spending trends

### ML Service
- `POST /ml/v1/categorize` — Auto-categorize transaction
- `POST /ml/v1/predictions/savings/:user_id` — Savings prediction

## Currency

All amounts are in **Zambian Kwacha (ZMW)**, displayed as `K`.

## Running Locally (Without Docker)

```bash
# Backend API
cd apps/backend-api
npm install
cp .env.example .env
node src/app.js

# ML Service
cd apps/ml-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 5001

# Admin Dashboard
cd apps/admin-dashboard
npm install
npm run dev

# Flutter App
cd apps/flutter-app
flutter pub get
flutter run
```

## License

This project is for academic purposes.
