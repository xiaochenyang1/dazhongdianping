export interface CreatorTask {
  id: number
  title: string
  description: string
  rewardPoints: number
  status: number
  claimStatus: number
  claimId?: number | null
  createdAt?: string
}

export interface CreatorClaimResult {
  taskId: number
  claimId: number
  claimStatus: number
  rewardPoints?: number
  points?: number
}
