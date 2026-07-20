import { apiGet, apiPost } from '@/lib/http'
import type { NotificationPage, UserNotification } from '@/types/notification'

export function fetchNotifications(page = 1, pageSize = 20) {
  return apiGet<NotificationPage>('/api/c/v1/notifications', { page, pageSize })
}

export function fetchUnreadNotificationCount() {
  return apiGet<{ count: number }>('/api/c/v1/notifications/unread-count')
}

export function ackNotification(id: number) {
  return apiPost<UserNotification>(`/api/c/v1/notifications/${id}/ack`)
}

export function issueWebSocketTicket() {
  return apiPost<{ ticket: string; expiresInSeconds: number }>('/api/c/v1/ws/ticket')
}
