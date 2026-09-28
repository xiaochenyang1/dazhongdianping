import type { Region } from '@/types/browse'

export interface WebTicketStrings {
  eyebrow: string
  title: string
  summary: string
  subject: string
  content: string
  shopId: string
  submit: string
  submitting: string
  loading: string
  empty: string
  loadFailed: string
  reply: string
  send: string
  closed: string
  status: (status: number, fallback?: string) => string
}

const STATUS_ZH: Record<number, string> = { 1: '待处理', 2: '处理中', 3: '已解决', 4: '已关闭' }
const STATUS_EN: Record<number, string> = { 1: 'Open', 2: 'In progress', 3: 'Resolved', 4: 'Closed' }

const zh: WebTicketStrings = {
  eyebrow: '客服工单',
  title: '联系平台客服',
  summary: '描述问题后，客服会在工单里回复。已解决或已关闭的工单不能再回复。',
  subject: '主题',
  content: '内容',
  shopId: '相关门店（可选）',
  submit: '提交工单',
  submitting: '提交中...',
  loading: '加载中...',
  empty: '还没有工单。',
  loadFailed: '工单加载失败',
  reply: '回复',
  send: '发送',
  closed: '该工单已结束，不能继续回复。',
  status: (status, fallback) => STATUS_ZH[status] ?? fallback ?? '待处理',
}

const en: WebTicketStrings = {
  eyebrow: 'Support',
  title: 'Contact support',
  summary: 'Describe the issue and support will reply on the ticket. Resolved or closed tickets cannot be replied to.',
  subject: 'Subject',
  content: 'Message',
  shopId: 'Related place (optional)',
  submit: 'Submit ticket',
  submitting: 'Submitting...',
  loading: 'Loading...',
  empty: 'No tickets yet.',
  loadFailed: 'Could not load tickets',
  reply: 'Reply',
  send: 'Send',
  closed: 'This ticket is closed.',
  status: (status, fallback) => STATUS_EN[status] ?? fallback ?? 'Open',
}

export function ticketStringsForRegion(region: Region) {
  return region === 'EU' ? en : zh
}
