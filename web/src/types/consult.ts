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

export interface ConsultThread {
  session: ConsultSession
  messages: ConsultMessage[]
}
