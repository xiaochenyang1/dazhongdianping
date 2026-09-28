import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type { InvoiceRequest, InvoiceTitle } from '@/types/invoice'

export function fetchInvoiceTitles() {
  return apiGet<InvoiceTitle[]>('/api/c/v1/invoices/titles')
}

export function createInvoiceTitle(payload: {
  titleType: number
  name: string
  taxNo?: string
  email?: string
  isDefault?: boolean
}) {
  return apiPost<InvoiceTitle>('/api/c/v1/invoices/titles', payload)
}

export function fetchInvoices(page = 1, pageSize = 12) {
  return apiGet<PageResult<InvoiceRequest>>('/api/c/v1/invoices', { page, pageSize })
}

export function requestInvoice(payload: { orderId: number; titleId: number }) {
  return apiPost<InvoiceRequest>('/api/c/v1/invoices', payload)
}
