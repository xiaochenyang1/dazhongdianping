import type { Region } from '@/types/browse'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebConsultStrings {
  tag: WebLocaleTag
  entry: string
  sessions: {
    eyebrow: string
    title: string
    summary: string
    loadFailed: string
    loading: string
    empty: string
    open: string
    unread: (count: number) => string
  }
  chat: {
    loadFailed: string
    sendFailed: string
    empty: string
    you: string
    merchant: string
    placeholder: string
    send: string
    back: string
  }
}

const zhCnStrings: WebConsultStrings = {
  tag: 'zh-CN',
  entry: '咨询商家',
  sessions: {
    eyebrow: '在线咨询',
    title: '与商家的咨询消息。',
    summary: '发起咨询后，商家回复会通过通知提醒你。',
    loadFailed: '咨询会话加载失败',
    loading: '加载中...',
    empty: '还没有咨询会话，去商户页发起咨询吧。',
    open: '进入会话',
    unread: (count) => `${count} 条未读`,
  },
  chat: {
    loadFailed: '消息加载失败',
    sendFailed: '发送失败',
    empty: '还没有消息，发条消息开始咨询吧。',
    you: '我',
    merchant: '商家',
    placeholder: '输入消息...',
    send: '发送',
    back: '返回',
  },
}

const enStrings: WebConsultStrings = {
  tag: 'en',
  entry: 'Chat with merchant',
  sessions: {
    eyebrow: 'Live chat',
    title: 'Your conversations with merchants.',
    summary: 'After you start a chat, merchant replies notify you.',
    loadFailed: 'Failed to load chat sessions',
    loading: 'Loading...',
    empty: 'No chats yet — start one from a shop page.',
    open: 'Open chat',
    unread: (count) => `${count} unread`,
  },
  chat: {
    loadFailed: 'Failed to load messages',
    sendFailed: 'Failed to send',
    empty: 'No messages yet — say hello to start.',
    you: 'You',
    merchant: 'Merchant',
    placeholder: 'Type a message...',
    send: 'Send',
    back: 'Back',
  },
}

const STRINGS: Record<Region, WebConsultStrings> = { CN: zhCnStrings, EU: enStrings }

export function consultStringsForRegion(region: Region) {
  return STRINGS[region]
}
