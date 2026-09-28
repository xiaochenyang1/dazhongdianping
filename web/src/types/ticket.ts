import type { PageResult } from './browse'

export interface TicketMessage {
  id: number
  senderType: number
  senderId: number
  content: string
  createdAt?: string
}

export interface SupportTicket {
  id: number
  requesterType: number
  requesterId: number
  shopId: number
  shopName: string
  subject: string
  content: string
  status: number
  statusText: string
  createdAt?: string
  updatedAt?: string
  messages?: TicketMessage[]
}

export type SupportTicketPage = PageResult<SupportTicket>
