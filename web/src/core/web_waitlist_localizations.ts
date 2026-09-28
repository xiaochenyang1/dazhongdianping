import type { Region } from '@/types/browse'

export interface WebWaitlistStrings {
  entry: string
  join: {
    title: string
    tableType: string
    small: string
    medium: string
    large: string
    partySize: string
    submit: string
    submitting: string
    failed: string
    missingShop: string
  }
  mine: {
    eyebrow: string
    title: string
    summary: string
    loadFailed: string
    loading: string
    empty: string
    queueNo: string
    ahead: (count: number) => string
    cancel: string
    cancelFailed: string
    statusText: (status: number, fallback?: string) => string
    tableTypeText: (type: number, fallback?: string) => string
  }
}

const TABLE_ZH: Record<number, string> = { 1: '小桌', 2: '中桌', 3: '大桌' }
const TABLE_EN: Record<number, string> = { 1: 'Small', 2: 'Medium', 3: 'Large' }
const STATUS_ZH: Record<number, string> = { 1: '排队中', 2: '已叫号', 3: '已入座', 4: '已过号', 5: '已取消' }
const STATUS_EN: Record<number, string> = { 1: 'Waiting', 2: 'Called', 3: 'Seated', 4: 'Passed', 5: 'Cancelled' }

const zhCnStrings: WebWaitlistStrings = {
  entry: '排队取号',
  join: {
    title: '排队取号',
    tableType: '桌型',
    small: '小桌(1-2人)',
    medium: '中桌(3-4人)',
    large: '大桌(5人以上)',
    partySize: '就餐人数',
    submit: '取号',
    submitting: '取号中...',
    failed: '取号失败',
    missingShop: '缺少门店信息，无法取号。',
  },
  mine: {
    eyebrow: '我的排队',
    title: '实时查看排队进度。',
    summary: '轮到你时商家叫号会通过通知提醒。',
    loadFailed: '排队加载失败',
    loading: '加载中...',
    empty: '当前没有进行中的排队。',
    queueNo: '号码',
    ahead: (count) => `前面还有 ${count} 桌`,
    cancel: '取消排队',
    cancelFailed: '取消失败',
    statusText: (status, fallback = '') => STATUS_ZH[status] ?? fallback,
    tableTypeText: (type, fallback = '') => TABLE_ZH[type] ?? fallback,
  },
}

const enStrings: WebWaitlistStrings = {
  entry: 'Join the queue',
  join: {
    title: 'Join the queue',
    tableType: 'Table',
    small: 'Small (1-2)',
    medium: 'Medium (3-4)',
    large: 'Large (5+)',
    partySize: 'Party size',
    submit: 'Get a number',
    submitting: 'Joining...',
    failed: 'Failed to join the queue',
    missingShop: 'Missing shop info; cannot join.',
  },
  mine: {
    eyebrow: 'My queue',
    title: 'Track your place in line.',
    summary: 'You are notified when the merchant calls your number.',
    loadFailed: 'Failed to load the queue',
    loading: 'Loading...',
    empty: 'No active queue right now.',
    queueNo: 'No.',
    ahead: (count) => `${count} parties ahead`,
    cancel: 'Leave queue',
    cancelFailed: 'Failed to cancel',
    statusText: (status, fallback = '') => STATUS_EN[status] ?? fallback,
    tableTypeText: (type, fallback = '') => TABLE_EN[type] ?? fallback,
  },
}

const STRINGS: Record<Region, WebWaitlistStrings> = { CN: zhCnStrings, EU: enStrings }

export function waitlistStringsForRegion(region: Region) {
  return STRINGS[region]
}
