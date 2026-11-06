export interface CreatorTask {
  id: number
  title: string
  description: string
  rewardPoints: number
  status: number
  claimStatus: number
  claimId?: number | null
  reviewNote?: string | null
  evidenceType?: 'review' | 'post' | null
  evidenceId?: number | null
  submissionNote?: string | null
  submissionVersion?: number | null
  createdAt?: string
}

export interface CreatorClaimResult {
  taskId: number
  claimId: number
  claimStatus: number
  rewardPoints?: number
  points?: number
}

export interface CreatorEvidence { id: number; title: string; createdAt?: string }
export interface CreatorSubmission { evidenceType: 'review' | 'post'; evidenceId: number; note: string }
