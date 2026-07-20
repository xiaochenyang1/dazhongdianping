export interface UserNotification {
  id: number
  type: string
  title: string
  content: string
  linkUrl: string
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
