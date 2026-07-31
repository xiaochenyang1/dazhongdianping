import { describe, expect, it } from 'vitest'
import type { UserNotification } from '@/types/notification'
import {
  notificationDisplayContent,
  notificationDisplayTitle,
  notificationStringsForRegion,
} from './web_notification_localizations'

function notification(overrides: Partial<UserNotification>): UserNotification {
  return {
    id: 1,
    type: 'reservation.status',
    actorName: '',
    title: '预订已确认',
    content: '巴黎川菜馆 · 商户已确认你的预订',
    linkUrl: '/user/reservations/33?status=confirmed',
    aggregateCount: 1,
    read: false,
    readAt: '',
    createdAt: '2026-07-25 09:00:00',
    ...overrides,
  }
}

describe('web notification localizations', () => {
  const copy = notificationStringsForRegion('EU')

  it('uses notification type and route markers instead of backend Chinese templates', () => {
    const item = notification({})
    expect(notificationDisplayTitle(copy, item)).toBe('Booking confirmed')
    expect(notificationDisplayContent(copy, item)).toBe(
      'Your booking status changed. Open it for the latest details.',
    )
  })

  it('keeps user-authored direct-message content', () => {
    const item = notification({ type: 'message.direct', actorName: 'Lin', content: '周末见', title: '收到私信' })
    expect(notificationDisplayTitle(copy, item)).toBe('New direct message')
    expect(notificationDisplayContent(copy, item)).toBe('周末见')
  })

  it('localizes actor-driven social notifications', () => {
    const item = notification({ type: 'social.follow', actorName: 'Alex', title: '新增关注', content: 'Alex 关注了你' })
    expect(notificationDisplayTitle(copy, item)).toBe('New follower')
    expect(notificationDisplayContent(copy, item)).toBe('Alex followed you.')
  })
})
