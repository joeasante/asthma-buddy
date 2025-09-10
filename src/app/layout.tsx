import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import '../styles/globals.css'
import { OfflineStatus } from '@/components/layout/offline-status'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Asthma Buddy - Track Your Asthma',
  description: 'A digital health application to help asthma patients log, track, and visualize daily health metrics.',
  manifest: '/manifest.json',
  keywords: ['asthma', 'health', 'tracking', 'medical', 'wellness'],
  authors: [{ name: 'Asthma Buddy Team' }],
  creator: 'Asthma Buddy',
  publisher: 'Asthma Buddy',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  icons: {
    icon: '/icons/icon-192x192.png',
    apple: '/icons/icon-192x192.png',
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Asthma Buddy',
  },
  viewport: {
    width: 'device-width',
    initialScale: 1,
    maximumScale: 1,
    userScalable: false,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="icon" href="/icons/icon-192x192.png" />
        <link rel="apple-touch-icon" href="/icons/icon-192x192.png" />
        <meta name="theme-color" content="#3b82f6" />
      </head>
      <body className={inter.className}>
        <div id="root">
          {children}
          <OfflineStatus />
        </div>
      </body>
    </html>
  )
}