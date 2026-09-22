import type { Region } from '@/types/browse'

export interface WebQaStrings {
  title: string
  empty: string
  loadFailed: string
  askPlaceholder: string
  ask: string
  askFailed: string
  answerCount: (count: number) => string
  viewAnswers: string
  hideAnswers: string
  answerPlaceholder: string
  answer: string
  answerFailed: string
  noAnswers: string
  loginToAsk: string
}

const zhCnStrings: WebQaStrings = {
  title: '问大家',
  empty: '还没有人提问，来问第一个问题吧。',
  loadFailed: '问答加载失败',
  askPlaceholder: '想问点什么？例如营业时间、停车、是否需要预约',
  ask: '提问',
  askFailed: '提问失败',
  answerCount: (count) => `${count} 个回答`,
  viewAnswers: '查看回答',
  hideAnswers: '收起',
  answerPlaceholder: '写下你的回答',
  answer: '回答',
  answerFailed: '回答失败',
  noAnswers: '还没有回答，来回答一下吧。',
  loginToAsk: '登录后即可提问',
}

const enStrings: WebQaStrings = {
  title: 'Ask the community',
  empty: 'No questions yet — be the first to ask.',
  loadFailed: 'Failed to load Q&A',
  askPlaceholder: 'Ask anything — hours, parking, reservations…',
  ask: 'Ask',
  askFailed: 'Failed to post the question',
  answerCount: (count) => `${count} answers`,
  viewAnswers: 'View answers',
  hideAnswers: 'Hide',
  answerPlaceholder: 'Write your answer',
  answer: 'Answer',
  answerFailed: 'Failed to post the answer',
  noAnswers: 'No answers yet — share what you know.',
  loginToAsk: 'Log in to ask a question',
}

const STRINGS: Record<Region, WebQaStrings> = { CN: zhCnStrings, EU: enStrings }

export function qaStringsForRegion(region: Region) {
  return STRINGS[region]
}
