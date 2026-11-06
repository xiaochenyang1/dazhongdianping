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
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/consult/sessions', undefined)
  })

  it('sends history and incremental cursors separately', () => {
    fetchConsultThread(5, { beforeId: 40, pageSize: 20 })
    expect(apiGet).toHaveBeenLastCalledWith('/api/c/v1/consult/sessions/5/messages', { beforeId: 40, pageSize: 20 })
    fetchConsultThread(5, { afterId: 80 })
    expect(apiGet).toHaveBeenLastCalledWith('/api/c/v1/consult/sessions/5/messages', { afterId: 80 })
  })

  it('loads a thread and sends a message', () => {
    fetchConsultThread(5)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/consult/sessions/5/messages', undefined)
    sendConsultMessage(5, '你好')
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/consult/sessions/5/messages', { content: '你好' })
  })
})
