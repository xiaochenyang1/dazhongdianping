import type { Region } from '@/types/browse'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebComplaintStrings {
  tag: WebLocaleTag
  list: {
    eyebrow: string
    title: string
    summary: string
    loadFailed: string
    loading: string
    empty: string
    all: string
    newComplaint: string
    statusText: (status: number, fallback?: string) => string
    typeText: (type: number, fallback?: string) => string
    submittedAt: string
    view: string
    merchantReply: string
    resolution: string
    noReply: string
  }
  create: {
    eyebrow: string
    title: string
    summary: string
    shopLabel: string
    orderLabel: string
    typeLabel: string
    titleLabel: string
    titlePlaceholder: string
    contentLabel: string
    contentPlaceholder: string
    submit: string
    submitting: string
    submitFailed: string
    submitSuccess: string
    missingShop: string
  }
  errorTranslations: Record<string, string>
}

const TYPES_ZH: Record<number, string> = {
  1: '商品/服务质量', 2: '虚假宣传', 3: '退款纠纷', 4: '服务态度', 5: '其他',
}
const TYPES_EN: Record<number, string> = {
  1: 'Product/service quality', 2: 'False advertising', 3: 'Refund dispute', 4: 'Service attitude', 5: 'Other',
}
const STATUS_ZH: Record<number, string> = { 1: '待受理', 2: '处理中', 3: '已解决', 4: '已驳回' }
const STATUS_EN: Record<number, string> = { 1: 'Pending', 2: 'Processing', 3: 'Resolved', 4: 'Rejected' }

const zhCnStrings: WebComplaintStrings = {
  tag: 'zh-CN',
  list: {
    eyebrow: '我的投诉',
    title: '查看投诉进度与处理结果。',
    summary: '发起后由平台受理、商家申辩，最终由平台仲裁解决或驳回。',
    loadFailed: '投诉列表加载失败',
    loading: '加载中...',
    empty: '你还没有发起过投诉。',
    all: '全部',
    newComplaint: '发起投诉',
    statusText: (status, fallback = '') => STATUS_ZH[status] ?? fallback,
    typeText: (type, fallback = '') => TYPES_ZH[type] ?? fallback,
    submittedAt: '提交时间',
    view: '查看详情',
    merchantReply: '商家申辩',
    resolution: '仲裁结论',
    noReply: '商家暂未申辩',
  },
  create: {
    eyebrow: '发起投诉',
    title: '描述你遇到的问题，平台会尽快受理。',
    summary: '请如实填写，商家将收到申辩通知，平台介入仲裁。',
    shopLabel: '投诉门店',
    orderLabel: '关联订单',
    typeLabel: '投诉类型',
    titleLabel: '标题',
    titlePlaceholder: '一句话概括问题',
    contentLabel: '详细描述',
    contentPlaceholder: '请描述具体情况、时间与诉求',
    submit: '提交投诉',
    submitting: '提交中...',
    submitFailed: '提交失败',
    submitSuccess: '投诉已提交',
    missingShop: '缺少门店信息，无法发起投诉。',
  },
  errorTranslations: {
    'complaint.created': '投诉已提交',
  },
}

const enStrings: WebComplaintStrings = {
  tag: 'en',
  list: {
    eyebrow: 'My complaints',
    title: 'Track complaint progress and outcomes.',
    summary: 'The platform accepts it, the merchant may rebut, and the platform rules to resolve or reject.',
    loadFailed: 'Failed to load complaints',
    loading: 'Loading...',
    empty: 'You have not filed any complaints yet.',
    all: 'All',
    newComplaint: 'File a complaint',
    statusText: (status, fallback = '') => STATUS_EN[status] ?? fallback,
    typeText: (type, fallback = '') => TYPES_EN[type] ?? fallback,
    submittedAt: 'Submitted',
    view: 'View detail',
    merchantReply: 'Merchant rebuttal',
    resolution: 'Ruling',
    noReply: 'No merchant rebuttal yet',
  },
  create: {
    eyebrow: 'File a complaint',
    title: 'Describe the problem and the platform will follow up.',
    summary: 'Please be accurate. The merchant is notified to rebut and the platform arbitrates.',
    shopLabel: 'Shop',
    orderLabel: 'Related order',
    typeLabel: 'Type',
    titleLabel: 'Title',
    titlePlaceholder: 'Summarise the issue in one line',
    contentLabel: 'Details',
    contentPlaceholder: 'Describe what happened, when, and what you want',
    submit: 'Submit complaint',
    submitting: 'Submitting...',
    submitFailed: 'Submit failed',
    submitSuccess: 'Complaint submitted',
    missingShop: 'Missing shop info; cannot file a complaint.',
  },
  errorTranslations: {
    'complaint.created': 'Complaint submitted',
  },
}

const STRINGS: Record<Region, WebComplaintStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function complaintStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebComplaintError(strings: WebComplaintStrings, error: unknown, fallback: string) {
  const messageKey = (error as { messageKey?: string })?.messageKey
  if (messageKey && strings.errorTranslations[messageKey]) return strings.errorTranslations[messageKey]
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN' || !HAN_TEXT.test(error.message)) return error.message || fallback
  return fallback
}
