# PAI: Personal Assistant for Trades

PAI is a mobile and web application built with Flutter and Supabase, specifically designed for the UK trade industry. It connects Tradespeople (Contractors) with clients (Customers) and provides a comprehensive suite of tools for job discovery, AI-assisted quoting, automated invoicing, and financial management.

## Core Features

### For Contractors
- **Find Work:** Browse a public marketplace of job posts filtered by trade and location.
- **AI-Assisted Quoting:** Generate detailed, itemized quotes (scope of work, materials, labor) using the built-in OpenAI proxy.
- **Private Ledger:** Automatically track won jobs in a private dashboard separate from the public marketplace.
- **Tax Pot:** Automatically calculate UK tax liability (Self-Employed 30% or CIS 20%) from PAI earnings and manual external income.
- **Digital Invoicing:** Generate professional PDF-style estimates and invoices that can be shared via WhatsApp or email.

### For Customers
- **Post Jobs:** Easily describe requirements and receive structured quotes from verified tradespeople.
- **Trade Network:** Access a directory of contractors for direct hiring or contractor-to-contractor collaboration.
- **Reliability Scoring:** View verified ratings and reliability scores based on past job performance.

## Tech Stack

- **Frontend:** Flutter (Dart 3)
- **State Management:** Riverpod 2.0
- **Navigation:** GoRouter 14
- **Backend-as-a-Service:** Supabase (Auth, Postgres, Realtime, Storage)
- **AI Engine:** OpenAI gpt-4o-mini (mediated via Supabase Edge Function)
- **Payments:** Stripe Connect & RevenueCat
- **Invoicing:** Shared as generated views within the app.

## Project Structure

```text
lib/
├── config/             # Environment variables and global constants
├── models/             # Data models (user_profiles, job_posts, private_jobs, etc.)
├── services/           # Supabase, OpenAI, and Stripe adapters
├── providers/          # Riverpod state management and StreamProviders
├── widgets/            # Shared UI components (StatCards, ReliabilityBadges)
├── screens/            # Feature-specific screens (Dashboard, JobDetail, TaxPot)
├── routes/             # GoRouter navigation logic and guards
└── main.dart           # Application entry point
```

## Setup & Configuration

### Prerequisites
- Flutter SDK `^3.2.0`
- Supabase Project with the database schema defined in `dataModels`.

### Environment Variables
Create a `.env` file or use `lib/config/env.dart` with the following:
- `SUPABASE_URL`: Your Supabase Project URL.
- `SUPABASE_ANON_KEY`: Your Supabase Anonymous Public Key.

### AI Integration
The AI Quoting feature requires a Supabase Edge Function named `openai-proxy` deployed.
- The app sends requests to `${SUPABASE_URL}/functions/v1/openai-proxy`.
- Access tokens are passed in the `Authorization` header.
- The Edge Function holds the `OPENAI_API_KEY` secret.

### Database Tables (PostgreSQL)
Ensure the following tables exist in the `public` schema of your Supabase instance:
- `user_profiles` (authenticated users with roles)
- `job_posts` (public marketplace listings)
- `job_applications` (contractor quotes for marketplace jobs)
- `private_jobs` (contractor job ledger)
- `manual_income` (external earnings for tax tracking)
- `reviews` (two-way rating system)
- `disputes` (admin-moderated conflict resolution)

## Role-Based Redirection
The app uses a custom routing logic:
1. **Unauthenticated:** Directed to `AuthScreen`.
2. **Authenticated (New):** Redirected to `OnboardingScreen` to select role and trades.
3. **Authenticated (Complete):** Redirected to the relevant role-based `DashboardScreen`.

## Support & Admin
Administrative users (designated via the `is_admin` flag in a metadata claim or profile) can access the `AdminDisputesScreen` to moderate content and resolve user conflicts.