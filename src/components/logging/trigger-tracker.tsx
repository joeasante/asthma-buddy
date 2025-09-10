'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'

interface Trigger {
  id: string
  name: string
  description?: string
  category: 'ENVIRONMENTAL' | 'LIFESTYLE' | 'WEATHER' | 'CHEMICAL' | 'MEDICAL' | 'FOOD' | 'OTHER'
  icon?: string
}

interface TriggerLog {
  id: string
  exposed: boolean
  intensity?: 'MILD' | 'MODERATE' | 'SEVERE'
  notes?: string
}

interface TriggerTrackerProps {
  triggers: Trigger[]
  values: TriggerLog[]
  onChange: (triggers: TriggerLog[]) => void
}

const triggerCategoryColors = {
  ENVIRONMENTAL: 'bg-green-100 text-green-800',
  LIFESTYLE: 'bg-blue-100 text-blue-800',
  WEATHER: 'bg-cyan-100 text-cyan-800',
  CHEMICAL: 'bg-orange-100 text-orange-800',
  MEDICAL: 'bg-red-100 text-red-800',
  FOOD: 'bg-purple-100 text-purple-800',
  OTHER: 'bg-gray-100 text-gray-800'
}

const intensityColors = {
  MILD: 'bg-yellow-100 text-yellow-800 border-yellow-300',
  MODERATE: 'bg-orange-100 text-orange-800 border-orange-300',
  SEVERE: 'bg-red-100 text-red-800 border-red-300'
}

export function TriggerTracker({ triggers, values, onChange }: TriggerTrackerProps) {
  const updateTrigger = (triggerId: string, updates: Partial<TriggerLog>) => {
    const existingIndex = values.findIndex(v => v.id === triggerId)
    const newValues = [...values]
    
    if (existingIndex >= 0) {
      newValues[existingIndex] = { ...newValues[existingIndex], ...updates }
    } else {
      newValues.push({ id: triggerId, exposed: false, ...updates })
    }
    
    onChange(newValues)
  }

  const getTriggerLog = (triggerId: string): TriggerLog => {
    return values.find(v => v.id === triggerId) || { id: triggerId, exposed: false }
  }

  const toggleExposed = (triggerId: string) => {
    const current = getTriggerLog(triggerId)
    updateTrigger(triggerId, { 
      exposed: !current.exposed,
      intensity: !current.exposed ? 'MILD' : undefined
    })
  }

  const setIntensity = (triggerId: string, intensity: 'MILD' | 'MODERATE' | 'SEVERE') => {
    updateTrigger(triggerId, { intensity })
  }

  const groupedTriggers = triggers.reduce((groups, trigger) => {
    const category = trigger.category
    if (!groups[category]) groups[category] = []
    groups[category].push(trigger)
    return groups
  }, {} as Record<string, Trigger[]>)

  const exposedTriggers = values.filter(v => v.exposed)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Trigger Exposure</CardTitle>
        <p className="text-sm text-gray-600">
          Track what triggers you were exposed to today
        </p>
      </CardHeader>
      <CardContent className="space-y-6">
        {exposedTriggers.length > 0 && (
          <div className="p-3 bg-orange-50 border border-orange-200 rounded-lg">
            <h4 className="font-medium text-orange-800 mb-2">Exposed Today ({exposedTriggers.length})</h4>
            <div className="flex flex-wrap gap-2">
              {exposedTriggers.map((triggerLog) => {
                const trigger = triggers.find(t => t.id === triggerLog.id)
                if (!trigger) return null
                
                return (
                  <div 
                    key={triggerLog.id} 
                    className={`px-2 py-1 rounded-full text-xs font-medium border ${
                      triggerLog.intensity ? intensityColors[triggerLog.intensity] : 'bg-gray-100 text-gray-800 border-gray-300'
                    }`}
                  >
                    {trigger.icon && <span className="mr-1">{trigger.icon}</span>}
                    {trigger.name}
                    {triggerLog.intensity && (
                      <span className="ml-1 text-xs">({triggerLog.intensity.toLowerCase()})</span>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        )}

        {Object.entries(groupedTriggers).map(([category, categoryTriggers]) => (
          <div key={category} className="space-y-3">
            <div className={`px-2 py-1 rounded-full text-xs font-medium inline-block ${triggerCategoryColors[category as keyof typeof triggerCategoryColors]}`}>
              {category.charAt(0).toUpperCase() + category.slice(1).toLowerCase()}
            </div>
            
            <div className="grid grid-cols-1 gap-2">
              {categoryTriggers.map((trigger) => {
                const log = getTriggerLog(trigger.id)
                
                return (
                  <div key={trigger.id} className="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-50">
                    <Checkbox
                      id={`trigger-${trigger.id}`}
                      checked={log.exposed}
                      onCheckedChange={() => toggleExposed(trigger.id)}
                    />
                    
                    <div className="flex-1 min-w-0">
                      <Label 
                        htmlFor={`trigger-${trigger.id}`}
                        className="cursor-pointer flex items-center"
                      >
                        {trigger.icon && <span className="mr-2">{trigger.icon}</span>}
                        <div>
                          <div className="font-medium">{trigger.name}</div>
                          {trigger.description && (
                            <div className="text-xs text-gray-500">{trigger.description}</div>
                          )}
                        </div>
                      </Label>
                    </div>

                    {log.exposed && (
                      <div className="flex space-x-1">
                        {(['MILD', 'MODERATE', 'SEVERE'] as const).map((intensity) => (
                          <Button
                            key={intensity}
                            variant={log.intensity === intensity ? 'default' : 'outline'}
                            size="sm"
                            className={`h-6 px-2 text-xs ${
                              log.intensity === intensity ? intensityColors[intensity] : ''
                            }`}
                            onClick={() => setIntensity(trigger.id, intensity)}
                          >
                            {intensity.charAt(0).toUpperCase() + intensity.slice(1).toLowerCase()}
                          </Button>
                        ))}
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        ))}

        {exposedTriggers.length === 0 && (
          <div className="text-center py-4 text-gray-500">
            <p>✅ No triggers exposed today - great job!</p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}