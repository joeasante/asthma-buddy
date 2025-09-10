import { Prisma, PeakFlowZone, TriggerIntensity, TriggerCategory, MedicationType } from '@prisma/client'

// User/Profile types
export type Profile = Prisma.ProfileGetPayload<{}>
export type ProfileWithRelations = Prisma.ProfileGetPayload<{
  include: {
    log_entries: true
    medications: true
    action_plan: true
  }
}>

// Log Entry types
export type LogEntry = Prisma.LogEntryGetPayload<{}>
export type LogEntryWithDetails = Prisma.LogEntryGetPayload<{
  include: {
    peak_flow: true
    symptoms: {
      include: {
        symptom: true
      }
    }
    medications: {
      include: {
        medication: true
      }
    }
    triggers: {
      include: {
        trigger: true
      }
    }
  }
}>

// Symptom types
export type Symptom = Prisma.SymptomGetPayload<{}>
export type LogSymptom = Prisma.LogSymptomGetPayload<{}>
export type LogSymptomWithDetails = Prisma.LogSymptomGetPayload<{
  include: {
    symptom: true
  }
}>

// Medication types
export type UserMedication = Prisma.UserMedicationGetPayload<{}>
export type LogMedication = Prisma.LogMedicationGetPayload<{}>
export type LogMedicationWithDetails = Prisma.LogMedicationGetPayload<{
  include: {
    medication: true
  }
}>

// Trigger types
export type Trigger = Prisma.TriggerGetPayload<{}>
export type LogTrigger = Prisma.LogTriggerGetPayload<{}>
export type LogTriggerWithDetails = Prisma.LogTriggerGetPayload<{
  include: {
    trigger: true
  }
}>

// Peak Flow types
export type PeakFlowReading = Prisma.PeakFlowReadingGetPayload<{}>

// Action Plan types
export type ActionPlan = Prisma.ActionPlanGetPayload<{}>

// Re-export Enums
export { PeakFlowZone, TriggerIntensity, TriggerCategory, MedicationType }

// Form data types
export interface LogEntryFormData {
  symptoms: { id: string; severity: number }[]
  medications: { id: string; taken: boolean; time_taken?: Date; dosage?: string }[]
  triggers: { id: string; exposed: boolean; intensity?: TriggerIntensity }[]
  peak_flow?: {
    value: number
    personal_best?: number
  }
  notes?: string
  logged_at: Date
}

export interface CreateProfileData {
  id: string
  email: string
  full_name?: string
  timezone: string
  date_of_birth?: Date
}

export interface NotificationPreferences {
  daily_reminder: boolean
  reminder_time: string // "10:00"
  push_enabled: boolean
  email_enabled: boolean
  weekly_summary: boolean
}