import { apiGet, apiPost } from '@/lib/http'
import type { ConsultMessage, ConsultMessageQuery, ConsultSession, ConsultThread } from '@/types/consult'

/** 发起或复用与门店的咨询会话（需登录）。 */
export function startConsult(shopId: number) {
  return apiPost<ConsultSession>('/api/c/v1/consult/sessions', { shopId })
}

/** 我的咨询会话列表。 */
export function fetchConsultSessions() {
  return apiGet<ConsultSession[]>('/api/c/v1/consult/sessions')
}

/** 最近消息、历史分页或增量补收。 */
export function fetchConsultThread(sessionId: number, query?: ConsultMessageQuery) {
  return apiGet<ConsultThread>(`/api/c/v1/consult/sessions/${sessionId}/messages`, query)
}

/** 发送咨询消息。 */
export function sendConsultMessage(sessionId: number, content: string) {
  return apiPost<ConsultMessage>(`/api/c/v1/consult/sessions/${sessionId}/messages`, { content })
}
