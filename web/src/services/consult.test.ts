import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { fetchConsultSessions, fetchConsultThread, sendConsultMessage, startConsult } from './consult'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('consult service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('starts a session for a shop', () => {
    startConsult(10001)
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/consult/sessions', { shopId: 10001 })
  })

  it('lists my sessions', () => {
    fetchConsultSessions()
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/consult/sessions')
  })

  it('loads a thread and sends a message', () => {
    fetchConsultThread(5)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/consult/sessions/5/messages')
    sendConsultMessage(5, '你好')
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/consult/sessions/5/messages', { content: '你好' })
  })
})
