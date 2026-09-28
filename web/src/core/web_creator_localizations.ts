import type { Region } from '@/types/browse'

export interface WebCreatorStrings {
  eyebrow: string
  title: string
  summary: string
  loading: string
  empty: string
  loadFailed: string
  points: string
  claim: string
  complete: string
  claimed: string
  done: string
}

const zh: WebCreatorStrings = {
  eyebrow: '创作者',
  title: '创作者任务',
  summary: '领取任务并完成后，积分只发放一次。',
  loading: '加载中...',
  empty: '当前没有进行中的任务。',
  loadFailed: '任务加载失败',
  points: '积分',
  claim: '领取',
  complete: '完成并领积分',
  claimed: '已领取',
  done: '已完成',
}

const en: WebCreatorStrings = {
  eyebrow: 'Creator',
  title: 'Creator tasks',
  summary: 'Points are awarded once when a claimed task is completed.',
  loading: 'Loading...',
  empty: 'No active tasks.',
  loadFailed: 'Could not load tasks',
  points: 'points',
  claim: 'Claim',
  complete: 'Complete',
  claimed: 'Claimed',
  done: 'Done',
}

export function creatorStringsForRegion(region: Region) {
  return region === 'EU' ? en : zh
}
