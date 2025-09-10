'use client'

import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'

export default function HomePage() {
  const router = useRouter()

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-6">
      <div className="text-center space-y-6">
        <h1 className="text-4xl font-bold text-blue-600">
          Asthma Buddy
        </h1>
        <p className="text-lg text-gray-600 max-w-md">
          Track your asthma symptoms, peak flow readings, and medications to better manage your health.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-4 justify-center mt-8">
          <Button onClick={() => router.push('/auth/signup')} size="lg">
            Get Started
          </Button>
          <Button onClick={() => router.push('/auth/login')} variant="outline" size="lg">
            Sign In
          </Button>
        </div>
        
        <div className="mt-8 space-y-2">
          <div className="text-sm text-green-600 font-medium">
            ✅ MVP Core Features Complete
          </div>
          <div className="text-xs text-gray-400">
            Mobile-first PWA • Secure • Offline-ready
          </div>
        </div>
      </div>
    </main>
  )
}