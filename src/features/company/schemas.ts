import { z } from 'zod'

export const companyFormSchema = z.object({
  legal_name: z.string().min(1, 'Legal name is required'),
  trade_name: z.string().optional(),
  business_type: z.enum([
    'proprietorship',
    'partnership',
    'llp',
    'private_limited',
    'public_limited',
    'other',
  ]),
  gstin: z
    .string()
    .optional()
    .refine(
      (v) =>
        !v ||
        /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(v),
      'Invalid GSTIN format',
    ),
  pan: z
    .string()
    .optional()
    .refine((v) => !v || /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(v), 'Invalid PAN'),
  tan: z.string().optional(),
  email: z.string().email().optional().or(z.literal('')),
  phone: z.string().optional(),
  website: z.string().optional(),
  address_line1: z.string().optional(),
  address_line2: z.string().optional(),
  city: z.string().optional(),
  district: z.string().optional(),
  state_code: z.string().optional(),
  pincode: z.string().optional(),
  invoice_prefix: z.string().min(1, 'Invoice prefix is required'),
  invoice_terms: z.string().optional(),
  invoice_notes: z.string().optional(),
  default_payment_terms_days: z.number().int().min(0).max(365),
  enable_gst: z.boolean(),
})

export type CompanyFormValues = z.infer<typeof companyFormSchema>

export const bankFormSchema = z.object({
  account_name: z.string().min(1, 'Account name is required'),
  bank_name: z.string().min(1, 'Bank name is required'),
  branch_name: z.string().optional(),
  account_number: z.string().min(1, 'Account number is required'),
  ifsc_code: z.string().optional(),
  upi_id: z.string().optional(),
  is_primary: z.boolean(),
  is_active: z.boolean(),
  notes: z.string().optional(),
})

export type BankFormValues = z.infer<typeof bankFormSchema>

export const partnerFormSchema = z.object({
  full_name: z.string().min(1, 'Name is required'),
  pan: z
    .string()
    .optional()
    .refine((v) => !v || /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(v), 'Invalid PAN'),
  email: z.string().email().optional().or(z.literal('')),
  phone: z.string().optional(),
  share_percent: z.number().min(0).max(100).nullable().optional(),
  status: z.enum(['active', 'inactive']),
  address: z.string().optional(),
  notes: z.string().optional(),
})

export type PartnerFormValues = z.infer<typeof partnerFormSchema>
