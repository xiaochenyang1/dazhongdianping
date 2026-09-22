import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type { ShopAnswer, ShopQuestion } from '@/types/qa'

/** 门店问题列表（游客可读）。 */
export function fetchQuestions(shopId: number, page = 1, pageSize = 10) {
  return apiGet<PageResult<ShopQuestion>>(`/api/c/v1/shops/${shopId}/questions`, { page, pageSize })
}

/** 提问（需登录）。 */
export function askQuestion(shopId: number, content: string) {
  return apiPost<ShopQuestion>(`/api/c/v1/shops/${shopId}/questions`, { content })
}

/** 某问题的回答列表（游客可读）。 */
export function fetchAnswers(shopId: number, questionId: number) {
  return apiGet<ShopAnswer[]>(`/api/c/v1/shops/${shopId}/questions/${questionId}/answers`)
}

/** 回答（需登录）。 */
export function answerQuestion(shopId: number, questionId: number, content: string) {
  return apiPost<ShopAnswer>(`/api/c/v1/shops/${shopId}/questions/${questionId}/answers`, { content })
}
