'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth/hooks'
import { useOfflineSync } from '@/lib/hooks/useOfflineSync'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { SymptomScale } from '@/components/logging/symptom-scale'
import { PeakFlowInput } from '@/components/logging/peak-flow-input'
import { MedicationTracker } from '@/components/logging/medication-tracker'
import { TriggerTracker } from '@/components/logging/trigger-tracker'
import { ArrowLeft, Save, Clock, CheckCircle } from 'lucide-react'

// Mock data - will be replaced with real API calls
const mockSymptoms = [
  { id: '1', name: 'Wheezing', description: 'High-pitched whistling sound', icon: '🌪️' },
  { id: '2', name: 'Coughing', description: 'Persistent or recurring cough', icon: '🗣️' },
  { id: '3', name: 'Chest Tightness', description: 'Pressure in chest', icon: '🫁' },
  { id: '4', name: 'Shortness of Breath', description: 'Difficulty breathing', icon: '💨' }
]

const mockMedications = [
  { id: '1', name: 'Albuterol Inhaler', dosage: '2 puffs', frequency: 'As needed', medication_type: 'RESCUE' as const },
  { id: '2', name: 'Fluticasone', dosage: '1 puff', frequency: '2x daily', medication_type: 'CONTROLLER' as const }
]

const mockTriggers = [
  { id: '1', name: 'Pollen', category: 'ENVIRONMENTAL' as const, icon: '🌸' },
  { id: '2', name: 'Dust', category: 'ENVIRONMENTAL' as const, icon: '🏠' },
  { id: '3', name: 'Exercise', category: 'LIFESTYLE' as const, icon: '🏃' },
  { id: '4', name: 'Stress', category: 'LIFESTYLE' as const, icon: '😰' }
]

export default function LogEntryPage() {
  const { user, loading } = useAuth()
  const router = useRouter()
  const { addOfflineAction, isOnline } = useOfflineSync()
  
  // Form state
  const [symptoms, setSymptoms] = useState<Array<{ id: string; severity: number }>>([])
  const [medications, setMedications] = useState<Array<{ id: string; taken: boolean; time_taken?: Date; dosage?: string; notes?: string }>>([])
  const [triggers, setTriggers] = useState<Array<{ id: string; exposed: boolean; intensity?: 'MILD' | 'MODERATE' | 'SEVERE'; notes?: string }>>([])
  const [peakFlow, setPeakFlow] = useState<{ value: number; personal_best?: number } | undefined>()
  const [notes, setNotes] = useState('')
  const [activeTab, setActiveTab] = useState('symptoms')
  const [isSaving, setIsSaving] = useState(false)
  const [isSaved, setIsSaved] = useState(false)

  // Auto-save draft functionality (localStorage)
  useEffect(() => {
    const savedDraft = localStorage.getItem('log-entry-draft')
    if (savedDraft) {
      try {
        const draft = JSON.parse(savedDraft)
        setSymptoms(draft.symptoms || [])
        setMedications(draft.medications || [])
        setTriggers(draft.triggers || [])
        setPeakFlow(draft.peakFlow)
        setNotes(draft.notes || '')
      } catch (e) {
        console.error('Error loading draft:', e)
      }
    }
  }, [])

  // Save draft periodically
  useEffect(() => {
    const draft = {
      symptoms,
      medications,
      triggers,
      peakFlow,
      notes,
      timestamp: Date.now()
    }
    localStorage.setItem('log-entry-draft', JSON.stringify(draft))
  }, [symptoms, medications, triggers, peakFlow, notes])

  const handleSave = async () => {
    setIsSaving(true)
    
    try {
      const logEntryData = {
        symptoms,
        medications,
        triggers,
        peakFlow,
        notes,
        logged_at: new Date()
      }

      if (isOnline) {
        // Try to save directly if online
        await new Promise(resolve => setTimeout(resolve, 1000))
        console.log('Saved log entry online:', logEntryData)
      } else {
        // Add to offline queue if offline
        addOfflineAction({
          type: 'LOG_ENTRY',
          data: logEntryData
        })
      }
      
      // Clear draft after successful save
      localStorage.removeItem('log-entry-draft')
      setIsSaved(true)
      
      // Redirect back to dashboard after a moment
      setTimeout(() => {
        router.push('/dashboard')
      }, 1500)
    } catch (error) {
      console.error('Error saving log entry:', error)
    } finally {
      setIsSaving(false)
    }
  }

  const getProgress = () => {
    let completed = 0
    let total = 4 // symptoms, medications, triggers, notes (peak flow optional)
    
    if (symptoms.some(s => s.severity > 0)) completed++
    if (medications.some(m => m.taken)) completed++
    if (triggers.some(t => t.exposed)) completed++
    if (notes.trim()) completed++
    
    return { completed, total, percentage: (completed / total) * 100 }
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

  if (isSaved) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <Card className="w-full max-w-md">
          <CardContent className="text-center py-12">
            <CheckCircle className="w-16 h-16 text-green-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Entry Saved!</h2>
            <p className="text-gray-600 mb-4">Your health data has been logged successfully</p>
            <div className="text-sm text-gray-500">Redirecting to dashboard...</div>
          </CardContent>
        </Card>
      </div>
    )
  }

  const progress = getProgress()

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => router.back()}
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Log Entry</h1>
              <p className="text-sm text-gray-600">
                <Clock className="w-4 h-4 inline mr-1" />
                {new Date().toLocaleDateString('en-US', { 
                  weekday: 'long', 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </p>
            </div>
          </div>
          
          <div className="text-right">
            <div className="text-sm text-gray-600 mb-1">
              Progress: {progress.completed}/{progress.total}
            </div>
            <div className="w-32 bg-gray-200 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${progress.percentage}%` }}
              />
            </div>
          </div>
        </div>

        {/* Main Form */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="symptoms">Symptoms</TabsTrigger>
            <TabsTrigger value="medications">Medications</TabsTrigger>
            <TabsTrigger value="triggers">Triggers</TabsTrigger>
            <TabsTrigger value="notes">Notes & Flow</TabsTrigger>
          </TabsList>

          <TabsContent value="symptoms" className="space-y-6">
            <SymptomScale
              symptoms={mockSymptoms}
              values={symptoms}
              onChange={setSymptoms}
            />
          </TabsContent>

          <TabsContent value="medications" className="space-y-6">
            <MedicationTracker
              medications={mockMedications}
              values={medications}
              onChange={setMedications}
            />
          </TabsContent>

          <TabsContent value="triggers" className="space-y-6">
            <TriggerTracker
              triggers={mockTriggers}
              values={triggers}
              onChange={setTriggers}
            />
          </TabsContent>

          <TabsContent value="notes" className="space-y-6">
            <PeakFlowInput
              value={peakFlow}
              onChange={setPeakFlow}
            />
            
            <Card>
              <CardHeader>
                <CardTitle>Additional Notes</CardTitle>
                <p className="text-sm text-gray-600">
                  Add any additional details about your symptoms, triggers, or general health today
                </p>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label htmlFor="notes">Notes (Optional)</Label>
                  <Textarea
                    id="notes"
                    placeholder="How are you feeling today? Any other symptoms or observations?"
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="min-h-[120px]"
                    maxLength={500}
                  />
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>Be specific about timing, intensity, and context</span>
                    <span>{notes.length}/500</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Navigation & Save */}
        <div className="flex items-center justify-between mt-8 pt-6 border-t">
          <div className="text-sm text-gray-500">
            {progress.completed > 0 ? (
              <span>✓ Draft auto-saved</span>
            ) : (
              <span>Start filling out sections to auto-save</span>
            )}
          </div>
          
          <div className="flex space-x-3">
            <Button
              variant="outline"
              onClick={() => {
                const tabs = ['symptoms', 'medications', 'triggers', 'notes']
                const currentIndex = tabs.indexOf(activeTab)
                if (currentIndex > 0) {
                  setActiveTab(tabs[currentIndex - 1])
                }
              }}
              disabled={activeTab === 'symptoms'}
            >
              Previous
            </Button>
            
            {activeTab !== 'notes' ? (
              <Button
                onClick={() => {
                  const tabs = ['symptoms', 'medications', 'triggers', 'notes']
                  const currentIndex = tabs.indexOf(activeTab)
                  if (currentIndex < tabs.length - 1) {
                    setActiveTab(tabs[currentIndex + 1])
                  }
                }}
              >
                Next
              </Button>
            ) : (
              <Button
                onClick={handleSave}
                disabled={isSaving || progress.completed === 0}
                className="min-w-[100px]"
              >
                {isSaving ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4 mr-2" />
                    Save Entry
                  </>
                )}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}