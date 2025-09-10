# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Asthma Buddy MVP** - A production-ready digital health PWA application built with Next.js 15, TypeScript, Supabase, and modern tooling. Helps asthma patients log, track, and visualize daily health metrics with offline-first functionality.

## Development Commands

### Essential Commands
```bash
# Development
npm run dev              # Start development server (uses Turbo)
npm run build           # Production build
npm run lint            # ESLint validation
npm run type-check      # TypeScript validation

# Database (Prisma + Supabase)
npm run db:generate     # Generate Prisma client
npm run db:push         # Push schema to database  
npm run db:migrate      # Run migrations
npm run db:studio       # Open Prisma Studio
npm run db:seed         # Seed reference data (symptoms/triggers)
```

### Testing Commands (When Implemented)
```bash
npm test                # Jest unit tests
npm run test:watch      # Jest in watch mode
npm run test:e2e        # Playwright E2E tests
```

## Architecture Overview

### Tech Stack
- **Framework**: Next.js 15 with App Router + React 19 + TypeScript
- **Database**: Supabase (PostgreSQL) with Prisma ORM
- **UI**: Shadcn/UI + Tailwind CSS + Radix UI primitives
- **Auth**: Supabase Auth with Row Level Security (RLS)
- **PWA**: next-pwa with offline-first architecture (NetworkFirst caching strategy)
- **Charts**: Recharts for data visualizations
- **Validation**: Zod schemas throughout
- **Forms**: React Hook Form with Zod resolvers

### Key Features
- **Secure**: RLS policies isolate user data completely
- **Mobile-First**: Touch-optimized UI with PWA capabilities  
- **Offline-Ready**: Background sync queue with localStorage
- **Accessible**: WCAG 2.1 AA compliant components

## Project Structure

```
src/
├── app/                    # Next.js 15 App Router
│   ├── (auth)/             # Auth pages (login/signup)  
│   ├── dashboard/          # Protected routes
│   │   ├── page.tsx        # Main dashboard
│   │   ├── log/            # Unified log entry form
│   │   └── action-plan/    # Action plan editor
│   ├── api/                # API routes (future)
│   └── layout.tsx          # Root layout with providers

├── components/
│   ├── ui/                 # Shadcn base components
│   ├── auth/               # Auth forms and flows
│   ├── logging/            # Log entry components
│   │   ├── symptom-scale.tsx      # 0-10 symptom rating
│   │   ├── peak-flow-input.tsx    # Peak flow with zones
│   │   ├── medication-tracker.tsx # Med adherence tracking
│   │   └── trigger-tracker.tsx    # Trigger exposure
│   ├── charts/             # Data visualizations
│   │   ├── peak-flow-chart.tsx    # Line chart with zones
│   │   ├── symptom-chart.tsx      # Bar chart with severity
│   │   └── recent-logs-list.tsx   # History component
│   └── layout/             # Layout components
│       └── offline-status.tsx     # Offline sync indicator

├── lib/
│   ├── supabase/           # Database clients (client/server)
│   ├── auth/               # Auth hooks and actions
│   ├── validation/         # Zod schemas (auth + logging)
│   ├── hooks/              # Custom hooks (useOfflineSync)
│   └── utils.ts            # Utilities (cn helper)

└── types/                  # TypeScript definitions
    └── database.ts         # Prisma-generated types
```

## Database Schema

### Core Models
- **Profile**: User metadata, timezone, onboarding status
- **LogEntry**: Main logging table with user_id + timestamp
- **Symptoms/Medications/Triggers**: Tracked with severity/adherence/exposure
- **PeakFlowReading**: Values with personal best + zone calculation
- **ActionPlan**: Rich text emergency instructions per user

### Security Model
- **RLS Enabled**: All user-data tables have Row Level Security
- **User Isolation**: Users can ONLY access their own data via auth.uid()
- **Reference Tables**: Symptoms/Triggers are public read-only for authenticated users

## Key Implementation Patterns

### Authentication
- Supabase Auth with server/client components
- Middleware protects routes automatically
- Profile creation on first sign-up

### Form Handling
- React Hook Form + Zod validation
- Optimistic updates with error handling
- Auto-save drafts to localStorage

### Offline Support
- Service Worker caches app shell + data
- `useOfflineSync` hook queues actions when offline
- Background sync when connection restored

### Mobile-First Design
- Touch targets minimum 44px
- Bottom navigation for thumb reach
- Responsive breakpoints for all screen sizes

## Development Guidelines

### Code Style
- TypeScript strict mode enabled
- Prettier for consistent formatting
- ESLint with Next.js recommended rules
- Import aliases via `@/*` paths

### Component Conventions
- Server Components by default (add 'use client' only when needed)
- Props interfaces defined inline or exported
- Consistent error boundaries and loading states

### Database Operations
- Always use Prisma client via `@/lib/prisma/client`
- Server Components for database reads
- API routes for mutations (when needed)
- RLS handles authorization automatically

### Security Requirements
- Never log sensitive data to console
- Validate all inputs with Zod schemas
- Use parameterized queries (Prisma handles this)
- Environment variables for all secrets

## Common Tasks

### Adding New UI Components
1. Check if Shadcn component exists first
2. Add to `src/components/ui/` if creating custom
3. Follow Radix UI patterns for accessibility
4. Include proper TypeScript interfaces

### Database Schema Changes
1. Update `prisma/schema.prisma`
2. Run `npm run db:generate` to update client
3. Create migration with `npm run db:migrate`
4. Update RLS policies if needed

### Adding New Pages
1. Create in appropriate `src/app/` directory
2. Use Server Components for data fetching
3. Add to middleware matcher if authentication required
4. Update navigation components

## Deployment Notes

### Environment Variables Required
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_URL` (Prisma connection string)
- `DIRECT_URL` (Prisma direct connection for migrations)

### Vercel Deployment
- Auto-deploys from GitHub main branch
- Build command: `npm run build`
- Node.js 18.x runtime
- PWA manifest and service worker included in build
- `DIRECT_URL` environment variable may be needed for Prisma migrations

This is a production-ready MVP with a solid foundation for healthcare applications. All core features are implemented and the architecture supports future scaling.