export interface ConsultSession {
  id: number
  shopId: number
  shopName: string
  userId: number
  userNickname: string
  lastMessage: string
  lastMessageAt?: string
  unread: number
  updatedAt?: string
}

export interface ConsultMessage {
  id: number
  sessionId: number
  senderType: number
  senderId: number
  content: string
  createdAt?: string
}

export interface ConsultMessageQuery {
  beforeId?: number
  afterId?: number
  pageSize?: number
}

export interface ConsultThread {
  hasMore: boolean
  nextBeforeId: number | null
  nextAfterId: number
  session: ConsultSession
  messages: ConsultMessage[]
}
