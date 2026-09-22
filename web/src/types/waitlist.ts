export interface WaitlistEntry {
  id: number
  shopId: number
  shopName: string
  tableType: number
  tableTypeText: string
  partySize: number
  queueNo: number
  status: number
  statusText: string
  aheadCount: number
  calledAt?: string
  seatedAt?: string
  createdAt?: string
}

export interface WaitlistJoinPayload {
  tableType: number
  partySize: number
}
