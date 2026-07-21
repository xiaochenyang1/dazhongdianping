export interface UserNotification {
  id: number
  type: string
  actorUserId?: number | null
  actorName: string
  title: string
  content: string
  linkUrl: string
  aggregateCount: number
  read: boolean
  readAt: string
  createdAt: string
}

export interface NotificationPage {
  list: UserNotification[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}
