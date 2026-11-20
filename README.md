# 🅿️ Parking SaaS – Multi-Tenant, White-Label

[![ci](https://github.com/muhammedfidann06/parking-saas/actions/workflows/ci.yml/badge.svg)](https://github.com/muhammedfidann06/parking-saas/actions/workflows/ci.yml)

A multi-tenant parking platform: every customer (city, company, garage operator) gets its own
subdomain, branding and isolated data. One backend, two clients:

| Part | Tech | Folder |
|---|---|---|
| REST API | **Laravel** · Sanctum · SQLite/MySQL | [`backend/`](backend) |
| Web app | **Next.js 15** · React 19 · TypeScript | [`frontend/`](frontend) |
| Mobile app | **Flutter** (Android · iOS · Web) | [`mobile/`](mobile) |

> 🇩🇪 **Kurzbeschreibung:** Eine Parkplatz-Plattform für mehrere Kunden (Mandanten). Jeder Kunde hat eigene
> Farben, ein eigenes Logo und streng getrennte Daten. Fahrer können per Web oder Flutter-App parken,
> die App berechnet den Preis automatisch. Backend-, Web- und Mobile-Tests laufen bei jedem Push.

## Features
- **Multi-tenancy (single DB):** tenant resolved from subdomain or `X-Tenant` header;
  `BelongsToTenant` trait adds a global scope + auto-fills `tenant_id` → no cross-tenant data leaks
- **White-label:** tenant name, colour and logo from `/api/branding` – used as CSS variable (web)
  and as Material 3 seed colour (Flutter)
- **Parking sessions:** check-in / check-out with **row locking** so the last spot can't be double-booked
- **Pricing engine:** free minutes, per started hour, daily cap – money stored in cents
- **Auth:** token login per tenant (Laravel Sanctum), roles (`driver`, `operator`, `admin`), rate-limited login
- **Mobile app:** login, live occupancy, start/stop parking, running timer, price on checkout, dark mode

## Architecture
```
 Flutter app ─┐
              ├── X-Tenant: linz ──► Laravel API ──► ResolveTenant ──► Global scope (tenant_id)
 Next.js web ─┘                          │
                                     MySQL / SQLite
```

## API
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/branding` | – | Tenant name, colour, logo |
| GET | `/api/lots` | – | Lots with free spots and prices |
| POST | `/api/login` | – | Returns a Sanctum token |
| GET | `/api/sessions/active` | ✓ | Running sessions of the user |
| POST | `/api/sessions` | ✓ | Start parking |
| POST | `/api/sessions/{id}/stop` | ✓ | Stop parking, calculate price |

## Setup
```bash
# Backend (PHP 8.3+)
composer create-project laravel/laravel backend-app
cd backend-app && php artisan install:api
# copy ./backend over the new project and add App\Providers\TenancyServiceProvider::class to bootstrap/providers.php
php artisan migrate --seed --seeder=DemoSeeder
php artisan serve                      # demo login: operator@berlin.test / password

# Web
cd frontend && cp .env.example .env.local && npm install && npm run dev

# Mobile
cd mobile && flutter create . --platforms=android,ios,web   # generates platform folders once
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api --dart-define=TENANT=berlin
```

## Tests
- Backend: pricing unit tests, tenant isolation, login and full parking flow (`php artisan test`)
- Mobile: model/formatting unit tests, API client with `MockClient`, widget tests (`flutter test`)
- Web: production build with type checking (`npm run build`)

## Skills
PHP · Laravel · REST API design · multi-tenant SaaS architecture · Flutter · Dart · Next.js · React · TypeScript · CI/CD
