import type { PageResult } from './browse'

/** 投诉处理日志。 */
export interface ComplaintLog {
  id: number
  actorType: number
  actorTypeText: string
  action: number
  actionText: string
  remark: string
  createdAt?: string
}

/** 投诉工单。 */
export interface ComplaintTicket {
  id: number
  ticketNo: string
  userId: number
  userNickname: string
  shopId: number
  shopName: string
  orderId: number
  type: number
  typeText: string
  title: string
  content: string
  status: number
  statusText: string
  merchantReply: string
  merchantRepliedAt?: string
  resolution: string
  resolvedAt?: string
  createdAt?: string
  updatedAt?: string
  logs?: ComplaintLog[]
}

export interface ComplaintCreatePayload {
  shopId: number
  orderId?: number
  type: number
  title: string
  content: string
}

export type ComplaintPage = PageResult<ComplaintTicket>
