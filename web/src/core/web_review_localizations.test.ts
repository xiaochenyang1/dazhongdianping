import { describe, expect, it } from 'vitest'
import { localizeWebReviewError, reviewStringsForRegion } from './web_review_localizations'

class FakeApiError extends Error {
  messageKey?: string
  constructor(message: string, messageKey?: string) {
    super(message)
    this.messageKey = messageKey
  }
}

describe('web review localizations', () => {
  it('maps the risk block messageKey to the friendly copy for both regions', () => {
    const zh = reviewStringsForRegion('CN')
    const en = reviewStringsForRegion('EU')
    const error = new FakeApiError('点评被风控拦截：相似度过高', 'riskcontrol.review_blocked')

    expect(localizeWebReviewError(zh, error, 'fallback')).toBe(zh.editor.riskBlocked)
    expect(localizeWebReviewError(en, error, 'fallback')).toBe(en.editor.riskBlocked)
  })

  it('falls back to normal localization when no risk messageKey is present', () => {
    const en = reviewStringsForRegion('EU')
    expect(localizeWebReviewError(en, new Error('Unexpected failure'), 'fallback')).toBe('Unexpected failure')
  })
})
