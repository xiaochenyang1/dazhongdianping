import { reactive } from 'vue'
import { ackNotification, fetchNotifications, fetchUnreadNotificationCount, issueWebSocketTicket } from '@/services/notification'
import type { UserNotification } from '@/types/notification'

const state = reactive({ items: [] as UserNotification[], unreadCount: 0, connected: false, loading: false })
let socket: WebSocket | undefined
let reconnectTimer: number | undefined
let shouldReconnect = false

async function refresh() {
  state.loading = true
  try {
    const [page, unread] = await Promise.all([fetchNotifications(), fetchUnreadNotificationCount()])
    state.items = page.list
    state.unreadCount = unread.count
  } finally {
    state.loading = false
  }
}

async function connect() {
  disconnect()
  shouldReconnect = true
  const { ticket } = await issueWebSocketTicket()
  const configuredBase = import.meta.env.VITE_WS_BASE_URL as string | undefined
  const base = configuredBase || `${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}`
  socket = new WebSocket(`${base}/ws/notifications?ticket=${encodeURIComponent(ticket)}`)
  socket.onopen = () => { state.connected = true }
  socket.onmessage = (event) => {
    const payload = JSON.parse(String(event.data)) as { type?: string; data?: UserNotification }
    if (payload.type === 'notification.new' && payload.data) {
      state.items.unshift(payload.data)
      state.unreadCount += 1
    }
  }
  socket.onclose = () => {
    state.connected = false
    if (shouldReconnect) reconnectTimer = window.setTimeout(() => void connect().catch(() => undefined), 3000)
  }
}

function disconnect() {
  shouldReconnect = false
  if (reconnectTimer) window.clearTimeout(reconnectTimer)
  socket?.close()
  socket = undefined
  state.connected = false
}

async function markRead(notification: UserNotification) {
  if (!notification.read) {
    const updated = await ackNotification(notification.id)
    Object.assign(notification, updated)
    state.unreadCount = Math.max(0, state.unreadCount - 1)
  }
}

export function useNotifications() { return { state, refresh, connect, disconnect, markRead } }
