export interface ShopQuestion {
  id: number
  shopId: number
  userId: number
  userNickname: string
  content: string
  answerCount: number
  latestAnswer: string
  createdAt?: string
}

export interface ShopAnswer {
  id: number
  questionId: number
  userId: number
  userNickname: string
  content: string
  createdAt?: string
}
