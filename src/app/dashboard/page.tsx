'use client'

import { useAuth } from '@/lib/auth/hooks'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { authActions } from '@/lib/auth/hooks'
import { useRouter } from 'next/navigation'
import { PeakFlowChart } from '@/components/charts/peak-flow-chart'
import { SymptomChart } from '@/components/charts/symptom-chart'
import { RecentLogsList } from '@/components/charts/recent-logs-list'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function DashboardPage() {
  const { user, loading } = useAuth()
  const router = useRouter()

  const handleSignOut = async () => {
    await authActions.signOut()
    router.push('/auth/login')
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-2 text-sm text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    router.push('/auth/login')
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="px-4 py-6 sm:px-0">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Welcome back{user.user_metadata?.full_name ? `, ${user.user_metadata.full_name}` : ''}!
              </h1>
              <p className="mt-1 text-sm text-gray-600">
                Track your asthma and manage your health
              </p>
            </div>
            <Button variant="outline" onClick={handleSignOut}>
              Sign Out
            </Button>
          </div>
        </div>

        {/* Main Content */}
        <div className="px-4 py-6 sm:px-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Quick Log Entry */}
            <Card>
              <CardHeader>
                <CardTitle>Quick Log Entry</CardTitle>
                <CardDescription>
                  Log your current symptoms and medications
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="w-full" onClick={() => router.push('/dashboard/log')}>
                  📝 Start Logging
                </Button>
              </CardContent>
            </Card>

            {/* Today's Status */}
            <Card>
              <CardHeader>
                <CardTitle>Today's Status</CardTitle>
                <CardDescription>
                  Your health summary for today
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-4">
                  <Badge className="bg-green-100 text-green-800 text-base px-4 py-2">
                    🟢 Good Control
                  </Badge>
                  <p className="text-sm text-gray-600 mt-2">Demo data showing</p>
                </div>
              </CardContent>
            </Card>

            {/* Action Plan */}
            <Card>
              <CardHeader>
                <CardTitle>Action Plan</CardTitle>
                <CardDescription>
                  Quick access to your asthma action plan
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button variant="outline" className="w-full" onClick={() => router.push('/dashboard/action-plan')}>
                  📋 View Action Plan
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Charts and Data */}
          <div className="mt-8 space-y-8">
            <Tabs defaultValue="charts" className="w-full">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="charts">Charts</TabsTrigger>
                <TabsTrigger value="history">Recent Logs</TabsTrigger>
              </TabsList>
              
              <TabsContent value="charts" className="space-y-6">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {/* Peak Flow Chart */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Peak Flow Trend</CardTitle>
                      <CardDescription>
                        Your peak flow readings over the past week
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <PeakFlowChart data={[]} />
                    </CardContent>
                  </Card>

                  {/* Symptom Chart */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Symptom Severity</CardTitle>
                      <CardDescription>
                        Overall symptom levels over the past week
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <SymptomChart data={[]} />
                    </CardContent>
                  </Card>
                </div>

                {/* Weekly Summary */}
                <Card>
                  <CardHeader>
                    <CardTitle>Weekly Summary</CardTitle>
                    <CardDescription>
                      Key insights from your health data this week
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="text-center p-4 bg-green-50 rounded-lg">
                        <div className="text-2xl font-bold text-green-600">4.2</div>
                        <div className="text-sm text-gray-600">Avg Symptoms (0-10)</div>
                        <div className="text-xs text-green-600 mt-1">↓ Better than last week</div>
                      </div>
                      <div className="text-center p-4 bg-blue-50 rounded-lg">
                        <div className="text-2xl font-bold text-blue-600">420</div>
                        <div className="text-sm text-gray-600">Avg Peak Flow</div>
                        <div className="text-xs text-blue-600 mt-1">→ Stable</div>
                      </div>
                      <div className="text-center p-4 bg-orange-50 rounded-lg">
                        <div className="text-2xl font-bold text-orange-600">2</div>
                        <div className="text-sm text-gray-600">Rescue Inhaler Uses</div>
                        <div className="text-xs text-orange-600 mt-1">↓ Reduced</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </TabsContent>

              <TabsContent value="history">
                <RecentLogsList logs={[]} />
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </div>
  )
}