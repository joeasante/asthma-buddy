import { z } from 'zod'

export const logEntrySchema = z.object({
  symptoms: z.array(z.object({
    id: z.string(),
    severity: z.number().min(0).max(10)
  })),
  medications: z.array(z.object({
    id: z.string(),
    taken: z.boolean(),
    time_taken: z.date().optional(),
    dosage: z.string().optional(),
    notes: z.string().optional()
  })),
  triggers: z.array(z.object({
    id: z.string(),
    exposed: z.boolean(),
    intensity: z.enum(['MILD', 'MODERATE', 'SEVERE']).optional(),
    notes: z.string().optional()
  })),
  peak_flow: z.object({
    value: z.number().min(50).max(800),
    personal_best: z.number().optional()
  }).optional(),
  notes: z.string().max(500).optional(),
  logged_at: z.date()
})

export const medicationSchema = z.object({
  name: z.string().min(1, 'Medication name is required').max(100),
  dosage: z.string().optional(),
  frequency: z.string().optional(),
  medication_type: z.enum(['CONTROLLER', 'RESCUE', 'PREVENTIVE', 'SUPPLEMENT']),
  color: z.string().optional()
})

export type LogEntryFormData = z.infer<typeof logEntrySchema>
export type MedicationFormData = z.infer<typeof medicationSchema>