import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { answerQuestion, askQuestion, fetchAnswers, fetchQuestions } from './qa'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('qa service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('lists questions for a shop', () => {
    fetchQuestions(10001, 1, 10)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/questions', { page: 1, pageSize: 10 })
  })

  it('posts a question', () => {
    askQuestion(10001, '需要预约吗')
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/shops/10001/questions', { content: '需要预约吗' })
  })

  it('lists and posts answers', () => {
    fetchAnswers(10001, 7)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/questions/7/answers')
    answerQuestion(10001, 7, '需要')
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/shops/10001/questions/7/answers', { content: '需要' })
  })
})
