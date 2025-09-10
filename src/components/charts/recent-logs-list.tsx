'use client'

import { format, subDays, startOfDay } from 'date-fns'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface LogEntry {
  id: string
  date: Date
  overallSymptoms: number
  peakFlow?: number
  medicationsTaken: number
  totalMedications: number
  triggersExposed: string[]
  notes?: string
}

interface RecentLogsListProps {
  logs: LogEntry[]
}

// Generate mock data for demo
const generateMockLogs = (days: number = 7): LogEntry[] => {
  const logs: LogEntry[] = []
  const triggers = ['Pollen', 'Dust', 'Exercise', 'Stress', 'Cold Air']
  
  for (let i = days - 1; i >= 0; i--) {
    const date = startOfDay(subDays(new Date(), i))
    const overallSymptoms = Math.floor(Math.random() * 8)
    const peakFlow = Math.random() > 0.3 ? 350 + Math.floor(Math.random() * 150) : undefined
    const medicationsTaken = Math.floor(Math.random() * 3)
    const totalMedications = 2
    const triggersExposed = triggers.slice(0, Math.floor(Math.random() * 3))
    
    const noteOptions = [
      "Feeling good today, no major issues",
      "Slight tightness after morning walk",
      "Used rescue inhaler once during the day",
      "Symptoms worse in the afternoon",
      "Good control overall",
      undefined
    ]
    const notes = noteOptions[Math.floor(Math.random() * noteOptions.length)]
    
    logs.push({
      id: `log-${i}`,
      date,
      overallSymptoms,
      peakFlow,
      medicationsTaken,
      totalMedications,
      triggersExposed,
      notes
    })
  }
  
  return logs.reverse() // Most recent first
}

export function RecentLogsList({ logs }: RecentLogsListProps) {
  const logData = logs.length > 0 ? logs : generateMockLogs()
  
  const getSeverityColor = (severity: number) => {
    if (severity <= 2) return 'bg-green-100 text-green-800'
    if (severity <= 4) return 'bg-yellow-100 text-yellow-800'
    if (severity <= 6) return 'bg-orange-100 text-orange-800'
    return 'bg-red-100 text-red-800'
  }
  
  const getSeverityLabel = (severity: number) => {
    if (severity === 0) return 'No symptoms'
    if (severity <= 2) return 'Mild'
    if (severity <= 4) return 'Moderate'
    if (severity <= 6) return 'Severe'
    return 'Very severe'
  }

  const getPeakFlowColor = (value?: number) => {
    if (!value) return ''
    if (value >= 400) return 'text-green-600'
    if (value >= 300) return 'text-yellow-600'
    return 'text-red-600'
  }

  if (logData.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Entries</CardTitle>
        </CardHeader>
        <CardContent className="text-center py-8">
          <p className="text-gray-500">No log entries yet</p>
          <p className="text-sm text-gray-400 mt-1">Start logging to see your history here</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Entries</CardTitle>
        <p className="text-sm text-gray-600">Your last {logData.length} log entries</p>
      </CardHeader>
      <CardContent className="space-y-4">
        {logData.map((log, index) => (
          <div key={log.id} className="border rounded-lg p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="text-sm font-medium">
                  {format(log.date, 'MMM dd')}
                </div>
                <Badge className={getSeverityColor(log.overallSymptoms)}>
                  {getSeverityLabel(log.overallSymptoms)}
                </Badge>
              </div>
              
              <div className="text-xs text-gray-500">
                {index === 0 ? 'Today' : 
                 index === 1 ? 'Yesterday' : 
                 `${index} days ago`}
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 text-sm">
              {log.peakFlow && (
                <div>
                  <div className="text-gray-500 text-xs">Peak Flow</div>
                  <div className={`font-medium ${getPeakFlowColor(log.peakFlow)}`}>
                    {log.peakFlow} L/min
                  </div>
                </div>
              )}
              
              <div>
                <div className="text-gray-500 text-xs">Medications</div>
                <div className="font-medium">
                  {log.medicationsTaken}/{log.totalMedications} taken
                </div>
              </div>
              
              <div>
                <div className="text-gray-500 text-xs">Triggers</div>
                <div className="font-medium">
                  {log.triggersExposed.length === 0 ? (
                    <span className="text-green-600">None</span>
                  ) : (
                    <span className="text-orange-600">{log.triggersExposed.length} exposed</span>
                  )}
                </div>
              </div>
            </div>

            {log.triggersExposed.length > 0 && (
              <div className="flex flex-wrap gap-1">
                {log.triggersExposed.map((trigger) => (
                  <Badge key={trigger} variant="outline" className="text-xs">
                    {trigger}
                  </Badge>
                ))}
              </div>
            )}

            {log.notes && (
              <div className="text-sm text-gray-600 italic border-l-2 border-gray-200 pl-3">
                "{log.notes}"
              </div>
            )}
          </div>
        ))}
        
        <div className="text-center pt-4">
          <button className="text-sm text-blue-600 hover:text-blue-700">
            View all entries →
          </button>
        </div>
      </CardContent>
    </Card>
  )
}