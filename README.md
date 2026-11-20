# 🅿️ Parking SaaS – Multi-Tenant, White-Label

A multi-tenant parking platform: every customer (city, company, garage operator) gets its own
subdomain, branding and isolated data. **Laravel 11** API + **Next.js 15** (React 19) frontend.

## Features
- **Multi-tenancy (single DB):** tenant resolved from subdomain or `X-Tenant` header;
  `BelongsToTenant` trait adds a global scope + auto-fills `tenant_id` → no cross-tenant data leaks
- **White-label:** tenant name, colour and logo served by `/api/branding`, applied as CSS variable
- **Parking sessions:** check-in / check-out with **row locking** so the last spot can't be double-booked
- **Pricing engine:** free minutes, per started hour, daily cap – money stored in cents
- **Auth:** Laravel Sanctum tokens, roles (`driver`, `operator`, `admin`), user↔tenant check
- **Tests:** PHPUnit unit tests (pricing) and feature test (tenant isolation)

## Architecture
```
Browser ── berlin.parking.app ──► Next.js (SSR: branding, lots)
                                     │  X-Tenant: berlin
                                     ▼
                               Laravel API ──► ResolveTenant ──► Global scope (tenant_id)
                                     │
                                  MySQL / SQLite
```

## Setup
```bash
# Backend
composer create-project laravel/laravel backend-app
cd backend-app && php artisan install:api      # installs Sanctum + routes/api.php
# copy the files from ./backend over the new project, then register the provider:
#   bootstrap/providers.php -> App\Providers\TenancyServiceProvider::class
php artisan migrate --seed --seeder=DemoSeeder
php artisan serve

# Frontend
cd frontend && cp .env.example .env.local && npm install && npm run dev
```
Tests: `php artisan test`

## Skills
PHP · Laravel · REST API design · multi-tenant SaaS architecture · Next.js · React · TypeScript · testing
