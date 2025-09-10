'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

interface Medication {
  id: string
  name: string
  dosage?: string
  frequency?: string
  medication_type: 'CONTROLLER' | 'RESCUE' | 'PREVENTIVE' | 'SUPPLEMENT'
  color?: string
}

interface MedicationLog {
  id: string
  taken: boolean
  time_taken?: Date
  dosage?: string
  notes?: string
}

interface MedicationTrackerProps {
  medications: Medication[]
  values: MedicationLog[]
  onChange: (medications: MedicationLog[]) => void
}

const medicationTypeColors = {
  CONTROLLER: 'bg-blue-100 border-blue-300 text-blue-800',
  RESCUE: 'bg-red-100 border-red-300 text-red-800', 
  PREVENTIVE: 'bg-green-100 border-green-300 text-green-800',
  SUPPLEMENT: 'bg-purple-100 border-purple-300 text-purple-800'
}

const medicationTypeLabels = {
  CONTROLLER: 'Daily Controller',
  RESCUE: 'Quick Relief',
  PREVENTIVE: 'Preventive',
  SUPPLEMENT: 'Supplement'
}

export function MedicationTracker({ medications, values, onChange }: MedicationTrackerProps) {
  const [expandedMed, setExpandedMed] = useState<string | null>(null)

  const updateMedication = (medicationId: string, updates: Partial<MedicationLog>) => {
    const existingIndex = values.findIndex(v => v.id === medicationId)
    const newValues = [...values]
    
    if (existingIndex >= 0) {
      newValues[existingIndex] = { ...newValues[existingIndex], ...updates }
    } else {
      newValues.push({ id: medicationId, taken: false, ...updates })
    }
    
    onChange(newValues)
  }

  const getMedicationLog = (medicationId: string): MedicationLog => {
    return values.find(v => v.id === medicationId) || { id: medicationId, taken: false }
  }

  const toggleTaken = (medicationId: string) => {
    const current = getMedicationLog(medicationId)
    updateMedication(medicationId, { 
      taken: !current.taken,
      time_taken: !current.taken ? new Date() : undefined
    })
  }

  const groupedMedications = medications.reduce((groups, med) => {
    const type = med.medication_type
    if (!groups[type]) groups[type] = []
    groups[type].push(med)
    return groups
  }, {} as Record<string, Medication[]>)

  if (medications.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Medications</CardTitle>
        </CardHeader>
        <CardContent className="text-center py-8">
          <p className="text-gray-500 mb-4">No medications added yet</p>
          <Button variant="outline">
            💊 Add Your Medications
          </Button>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Medication Tracking</CardTitle>
        <p className="text-sm text-gray-600">
          Track which medications you've taken today
        </p>
      </CardHeader>
      <CardContent className="space-y-4">
        {Object.entries(groupedMedications).map(([type, meds]) => (
          <div key={type} className="space-y-2">
            <div className={`px-3 py-1 rounded-full text-xs font-medium inline-block ${medicationTypeColors[type as keyof typeof medicationTypeColors]}`}>
              {medicationTypeLabels[type as keyof typeof medicationTypeLabels]}
            </div>
            
            <div className="space-y-2 ml-2">
              {meds.map((medication) => {
                const log = getMedicationLog(medication.id)
                const isExpanded = expandedMed === medication.id
                
                return (
                  <div key={medication.id} className="border rounded-lg p-3">
                    <div className="flex items-center space-x-3">
                      <Checkbox
                        id={`med-${medication.id}`}
                        checked={log.taken}
                        onCheckedChange={() => toggleTaken(medication.id)}
                      />
                      
                      <div className="flex-1 min-w-0">
                        <Label 
                          htmlFor={`med-${medication.id}`}
                          className="text-base font-medium cursor-pointer"
                        >
                          {medication.name}
                        </Label>
                        {medication.dosage && (
                          <p className="text-sm text-gray-500">{medication.dosage}</p>
                        )}
                        {medication.frequency && (
                          <p className="text-xs text-gray-400">{medication.frequency}</p>
                        )}
                      </div>

                      <div className="text-right">
                        {log.taken && log.time_taken && (
                          <p className="text-xs text-green-600">
                            ✓ {log.time_taken.toLocaleTimeString('en-US', { 
                              hour: 'numeric', 
                              minute: '2-digit'
                            })}
                          </p>
                        )}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setExpandedMed(isExpanded ? null : medication.id)}
                          className="text-xs h-6 px-2"
                        >
                          {isExpanded ? 'Less' : 'Details'}
                        </Button>
                      </div>
                    </div>

                    {isExpanded && (
                      <div className="mt-3 pt-3 border-t space-y-3">
                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <Label className="text-xs">Dosage Taken</Label>
                            <Input
                              placeholder={medication.dosage || "Enter dosage"}
                              value={log.dosage || ''}
                              onChange={(e) => updateMedication(medication.id, { dosage: e.target.value })}
                              className="h-8 text-sm"
                            />
                          </div>
                          
                          <div className="space-y-1">
                            <Label className="text-xs">Time</Label>
                            <Input
                              type="time"
                              value={log.time_taken ? log.time_taken.toTimeString().slice(0, 5) : ''}
                              onChange={(e) => {
                                if (e.target.value) {
                                  const [hours, minutes] = e.target.value.split(':')
                                  const newTime = new Date()
                                  newTime.setHours(parseInt(hours), parseInt(minutes))
                                  updateMedication(medication.id, { time_taken: newTime })
                                }
                              }}
                              className="h-8 text-sm"
                            />
                          </div>
                        </div>

                        <div className="space-y-1">
                          <Label className="text-xs">Notes</Label>
                          <Input
                            placeholder="Any notes about this medication"
                            value={log.notes || ''}
                            onChange={(e) => updateMedication(medication.id, { notes: e.target.value })}
                            className="h-8 text-sm"
                          />
                        </div>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}