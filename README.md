# Asthma Buddy MVP

A production-ready digital health PWA application designed to help asthma patients log, track, and visualize daily health metrics.

## 🎯 Features

### ✅ Core MVP Features Complete

- **🔐 Secure Authentication** - Sign up/sign in with Supabase Auth
- **📝 Unified Log Entry** - Quick and comprehensive symptom, medication, trigger, and peak flow logging
- **📊 Interactive Dashboard** - Real-time charts and health insights with Recharts
- **📋 Action Plan Editor** - Customizable asthma action plan with print functionality
- **📱 PWA Support** - Installable app with offline-first functionality
- **🔒 HIPAA-Level Security** - Row Level Security (RLS) protecting all user data
- **📈 Data Visualizations** - Peak flow trends, symptom tracking, and weekly summaries

### 🏗️ Technical Architecture

- **Frontend**: Next.js 15 + React 19 + TypeScript
- **UI Components**: Shadcn/UI + Tailwind CSS + Radix UI
- **Database**: Supabase (PostgreSQL) with Prisma ORM
- **Authentication**: Supabase Auth with secure session management
- **PWA**: Service Worker with offline support and background sync
- **Charts**: Recharts for responsive data visualizations
- **Validation**: Zod schemas for type-safe form validation
- **State Management**: React hooks + localStorage for offline caching

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase account

### Installation

1. **Clone & Install**
   ```bash
   git clone <repository-url>
   cd asthma-buddy
   npm install
   ```

2. **Environment Setup**
   ```bash
   cp .env.example .env.local
   # Configure your Supabase credentials in .env.local
   ```

3. **Database Setup**
   ```bash
   # Generate Prisma client
   npm run db:generate
   
   # Run RLS setup (in Supabase SQL Editor)
   # Execute: prisma/migrations/001_enable_rls.sql
   
   # Seed reference data
   npm run db:seed
   ```

4. **Start Development**
   ```bash
   npm run dev
   ```

## 📱 PWA Features

- **Offline-First**: Works without internet connection
- **Background Sync**: Queues actions when offline, syncs when online
- **Installable**: Add to home screen on mobile devices
- **Push Notifications**: Ready for reminder notifications (Inngest integration prepared)

## 🔐 Security Features

- **Row Level Security**: Database-level data isolation per user
- **Secure Authentication**: Supabase Auth with HTTP-only cookies
- **Data Encryption**: End-to-end encrypted data storage
- **Input Validation**: Zod schemas prevent malicious input
- **CORS Protection**: Configured for production deployment

## 🗂️ Project Structure

```
asthma-buddy/
├── src/
│   ├── app/                    # Next.js 15 App Router
│   │   ├── (auth)/             # Authentication pages
│   │   ├── dashboard/          # Protected app routes
│   │   └── api/                # API endpoints
│   ├── components/
│   │   ├── ui/                 # Shadcn/UI base components
│   │   ├── auth/               # Authentication components
│   │   ├── logging/            # Log entry components
│   │   ├── charts/             # Data visualization components
│   │   └── layout/             # Layout components
│   ├── lib/
│   │   ├── supabase/           # Database client configuration
│   │   ├── auth/               # Authentication hooks
│   │   ├── validation/         # Zod validation schemas
│   │   └── hooks/              # Custom React hooks
│   └── types/                  # TypeScript type definitions
├── prisma/
│   ├── schema.prisma           # Database schema
│   └── migrations/             # SQL migration files
└── public/
    ├── manifest.json           # PWA manifest
    └── icons/                  # App icons
```

## 🎨 Design System

### Color Scheme
- **Primary**: Blue (#3b82f6) - Trust, medical, calm
- **Success**: Green (#22c55e) - Good control, positive metrics
- **Warning**: Yellow (#eab308) - Caution zone, attention needed
- **Danger**: Red (#ef4444) - Emergency, severe symptoms

### Typography
- **Font**: Inter (system font fallback)
- **Scales**: Mobile-first responsive typography
- **Accessibility**: High contrast, readable sizes

### Components
- **Touch Targets**: Minimum 44px for mobile accessibility
- **Spacing**: Consistent 4px grid system
- **Animations**: Reduced motion support

## 📊 Data Model

### Core Entities
- **User Profile**: Personal info, timezone, preferences
- **Log Entry**: Main tracking record with timestamp
- **Symptoms**: Rated 0-10 severity scale
- **Peak Flow**: Measurements with zone calculations
- **Medications**: Taken/not taken with dosage tracking  
- **Triggers**: Exposure tracking with intensity levels
- **Action Plan**: Rich text emergency instructions

### Key Relationships
- Users can only access their own data (RLS enforced)
- Log entries link to all symptom/medication/trigger records
- Reference tables (symptoms, triggers) are shared/read-only

## 🔧 Scripts

```bash
# Development
npm run dev              # Start development server
npm run build           # Build for production  
npm run start           # Start production server
npm run lint            # Lint codebase
npm run type-check      # TypeScript validation

# Database
npm run db:generate     # Generate Prisma client
npm run db:push         # Push schema to database
npm run db:migrate      # Run database migrations
npm run db:studio       # Open Prisma Studio
npm run db:seed         # Seed reference data
```

## 🚀 Deployment

### Vercel (Recommended)

1. **Connect Repository**
   - Link GitHub repo to Vercel
   - Auto-deploy on push to main

2. **Environment Variables**
   ```
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_service_key
   DATABASE_URL=your_postgres_url
   ```

3. **Build Configuration**
   - Build command: `npm run build`
   - Output directory: `.next`
   - Node.js version: 18.x

### Other Platforms

The app is compatible with any platform supporting Node.js applications:
- Netlify, Railway, Render, AWS, Google Cloud, etc.

## 🧪 Testing Strategy

### Planned Testing (Implementation Pending)

- **Unit Tests**: Component logic, utilities, validation
- **Integration Tests**: Authentication flows, database operations
- **E2E Tests**: Critical user journeys with Playwright
- **Performance Tests**: Core Web Vitals, load times

### Manual Testing Checklist

- [ ] User registration and login flow
- [ ] Complete log entry submission
- [ ] Dashboard chart rendering
- [ ] Action plan creation and editing
- [ ] Offline functionality
- [ ] PWA installation
- [ ] Cross-browser compatibility
- [ ] Mobile responsiveness

## 📈 Performance

### Optimization Features

- **Code Splitting**: Automatic route-based splitting
- **Image Optimization**: Next.js Image component
- **Caching**: Service Worker + localStorage
- **Bundle Analysis**: Webpack Bundle Analyzer ready
- **Core Web Vitals**: Optimized for Google's metrics

### Performance Targets

- **First Contentful Paint**: < 2.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3.8s

## 🔮 Future Roadmap

### Phase 2 - Advanced Features
- AI-powered symptom analysis and predictions
- Healthcare provider dashboard and sharing
- Environmental data integration (air quality, pollen)
- Advanced reporting and PDF exports

### Phase 3 - Integrations
- Smart inhaler device connectivity  
- Telehealth appointment scheduling
- Insurance and pharmacy integrations
- Multi-language support

### Phase 4 - Platform Expansion
- Native mobile apps (React Native)
- Wear OS / watchOS companion apps
- Voice logging with speech recognition
- Family/caregiver accounts

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Development Guidelines

- Follow TypeScript strict mode
- Use Prettier for code formatting
- Write tests for new features
- Update documentation for API changes
- Ensure accessibility compliance (WCAG 2.1 AA)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💡 Support

- **Documentation**: Check CLAUDE.md for development guidance
- **Issues**: Report bugs via GitHub Issues
- **Questions**: Use GitHub Discussions

---

**Built with ❤️ for the asthma community**

*Empowering patients to take control of their health through better data and insights.*