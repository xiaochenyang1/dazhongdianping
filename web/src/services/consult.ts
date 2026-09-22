import { apiGet, apiPost } from '@/lib/http'
import type { ConsultMessage, ConsultSession, ConsultThread } from '@/types/consult'

/** 发起或复用与门店的咨询会话（需登录）。 */
export function startConsult(shopId: number) {
  return apiPost<ConsultSession>('/api/c/v1/consult/sessions', { shopId })
}

/** 我的咨询会话列表。 */
export function fetchConsultSessions() {
  return apiGet<ConsultSession[]>('/api/c/v1/consult/sessions')
}

/** 会话消息（读取后未读清零）。 */
export function fetchConsultThread(sessionId: number) {
  return apiGet<ConsultThread>(`/api/c/v1/consult/sessions/${sessionId}/messages`)
}

/** 发送咨询消息。 */
export function sendConsultMessage(sessionId: number, content: string) {
  return apiPost<ConsultMessage>(`/api/c/v1/consult/sessions/${sessionId}/messages`, { content })
}
