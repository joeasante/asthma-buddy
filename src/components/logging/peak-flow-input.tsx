'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'

interface PeakFlowReading {
  value: number
  personal_best?: number
}

interface PeakFlowInputProps {
  value?: PeakFlowReading
  onChange: (reading: PeakFlowReading | undefined) => void
}

export function PeakFlowInput({ value, onChange }: PeakFlowInputProps) {
  const [enabled, setEnabled] = useState(!!value)
  const [reading, setReading] = useState(value?.value || 0)
  const [personalBest, setPersonalBest] = useState(value?.personal_best || 0)

  const handleEnable = () => {
    setEnabled(true)
    const newReading = { value: reading || 300, personal_best: personalBest || 0 }
    setReading(newReading.value)
    onChange(newReading)
  }

  const handleDisable = () => {
    setEnabled(false)
    onChange(undefined)
  }

  const handleReadingChange = (newValue: number) => {
    setReading(newValue)
    onChange({
      value: newValue,
      personal_best: personalBest || undefined
    })
  }

  const handlePersonalBestChange = (newValue: number) => {
    setPersonalBest(newValue)
    onChange({
      value: reading,
      personal_best: newValue || undefined
    })
  }

  const getZoneInfo = () => {
    if (!enabled || !reading || !personalBest) return null

    const percentage = (reading / personalBest) * 100

    if (percentage >= 80) {
      return { zone: 'Green Zone', color: 'text-green-600 bg-green-50', description: 'Good control' }
    } else if (percentage >= 50) {
      return { zone: 'Yellow Zone', color: 'text-yellow-600 bg-yellow-50', description: 'Caution' }
    } else {
      return { zone: 'Red Zone', color: 'text-red-600 bg-red-50', description: 'Danger - seek help' }
    }
  }

  const zoneInfo = getZoneInfo()

  return (
    <Card>
      <CardHeader>
        <CardTitle>Peak Flow Reading</CardTitle>
        <p className="text-sm text-gray-600">
          Measure your peak expiratory flow rate (L/min)
        </p>
      </CardHeader>
      <CardContent className="space-y-4">
        {!enabled ? (
          <div className="text-center py-8">
            <p className="text-gray-500 mb-4">Skip peak flow measurement for now?</p>
            <Button onClick={handleEnable} variant="outline">
              📊 Add Peak Flow Reading
            </Button>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="peak-flow-reading">Today's Reading</Label>
                <div className="relative">
                  <Input
                    id="peak-flow-reading"
                    type="number"
                    min="50"
                    max="800"
                    placeholder="300"
                    value={reading || ''}
                    onChange={(e) => handleReadingChange(parseInt(e.target.value) || 0)}
                    className="pr-12"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">
                    L/min
                  </span>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="personal-best">Personal Best (Optional)</Label>
                <div className="relative">
                  <Input
                    id="personal-best"
                    type="number"
                    min="50"
                    max="800"
                    placeholder="400"
                    value={personalBest || ''}
                    onChange={(e) => handlePersonalBestChange(parseInt(e.target.value) || 0)}
                    className="pr-12"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">
                    L/min
                  </span>
                </div>
              </div>
            </div>

            {zoneInfo && (
              <div className={`p-3 rounded-lg ${zoneInfo.color} border`}>
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">{zoneInfo.zone}</div>
                    <div className="text-sm">{zoneInfo.description}</div>
                  </div>
                  <div className="text-lg font-bold">
                    {Math.round((reading / personalBest) * 100)}%
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-between items-center pt-2 border-t">
              <p className="text-xs text-gray-500">
                Typical adult range: 300-700 L/min
              </p>
              <Button 
                onClick={handleDisable} 
                variant="ghost" 
                size="sm"
                className="text-red-600 hover:text-red-700"
              >
                Remove
              </Button>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}