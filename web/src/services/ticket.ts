import { apiGet, apiPost } from '@/lib/http'
import type { SupportTicket, SupportTicketPage } from '@/types/ticket'

export function createTicket(payload: { subject: string; content: string; shopId?: number }) {
  return apiPost<SupportTicket>('/api/c/v1/tickets', payload)
}

export function fetchMyTickets(page = 1, pageSize = 12) {
  return apiGet<SupportTicketPage>('/api/c/v1/tickets', { page, pageSize })
}

export function fetchTicket(id: number) {
  return apiGet<SupportTicket>(`/api/c/v1/tickets/${id}`)
}

export function replyTicket(id: number, content: string) {
  return apiPost<SupportTicket>(`/api/c/v1/tickets/${id}/messages`, { content })
}
