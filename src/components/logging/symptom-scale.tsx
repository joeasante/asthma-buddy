'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Slider } from '@/components/ui/slider'
import { Label } from '@/components/ui/label'

interface Symptom {
  id: string
  name: string
  description?: string
  icon?: string
}

interface SymptomRating {
  id: string
  severity: number
}

interface SymptomScaleProps {
  symptoms: Symptom[]
  values: SymptomRating[]
  onChange: (symptoms: SymptomRating[]) => void
}

const severityLabels = [
  { value: 0, label: 'None', color: 'text-green-600' },
  { value: 1, label: 'Very Mild', color: 'text-green-500' },
  { value: 2, label: 'Mild', color: 'text-yellow-500' },
  { value: 3, label: 'Mild-Moderate', color: 'text-yellow-600' },
  { value: 4, label: 'Moderate', color: 'text-orange-500' },
  { value: 5, label: 'Moderate-Severe', color: 'text-orange-600' },
  { value: 6, label: 'Severe', color: 'text-red-500' },
  { value: 7, label: 'Very Severe', color: 'text-red-600' },
  { value: 8, label: 'Extremely Severe', color: 'text-red-700' },
  { value: 9, label: 'Near Maximum', color: 'text-red-800' },
  { value: 10, label: 'Maximum', color: 'text-red-900' }
]

export function SymptomScale({ symptoms, values, onChange }: SymptomScaleProps) {
  const updateSymptom = (symptomId: string, severity: number) => {
    const existingIndex = values.findIndex(v => v.id === symptomId)
    const newValues = [...values]
    
    if (existingIndex >= 0) {
      newValues[existingIndex] = { id: symptomId, severity }
    } else {
      newValues.push({ id: symptomId, severity })
    }
    
    onChange(newValues)
  }

  const getSymptomSeverity = (symptomId: string): number => {
    return values.find(v => v.id === symptomId)?.severity || 0
  }

  const getSeverityLabel = (severity: number) => {
    return severityLabels.find(l => l.value === severity) || severityLabels[0]
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Rate Your Symptoms</CardTitle>
        <p className="text-sm text-gray-600">
          Rate each symptom from 0 (none) to 10 (maximum severity)
        </p>
      </CardHeader>
      <CardContent className="space-y-6">
        {symptoms.map((symptom) => {
          const severity = getSymptomSeverity(symptom.id)
          const severityLabel = getSeverityLabel(severity)
          
          return (
            <div key={symptom.id} className="space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <Label className="text-base font-medium">
                    {symptom.icon && <span className="mr-2">{symptom.icon}</span>}
                    {symptom.name}
                  </Label>
                  {symptom.description && (
                    <p className="text-sm text-gray-500 mt-1">{symptom.description}</p>
                  )}
                </div>
                <div className="text-right">
                  <div className="text-2xl font-bold">{severity}</div>
                  <div className={`text-xs font-medium ${severityLabel.color}`}>
                    {severityLabel.label}
                  </div>
                </div>
              </div>
              
              <div className="px-3">
                <Slider
                  value={[severity]}
                  onValueChange={(values) => updateSymptom(symptom.id, values[0])}
                  max={10}
                  min={0}
                  step={1}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-gray-400 mt-1">
                  <span>0 - None</span>
                  <span>5 - Moderate</span>
                  <span>10 - Maximum</span>
                </div>
              </div>
            </div>
          )
        })}
      </CardContent>
    </Card>
  )
}