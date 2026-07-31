import { describe, expect, it } from 'vitest'
import { authStringsForRegion } from './web_auth_localizations'
import {
  formatEnglishCount,
  isSingularEnglishCount,
} from './web_count_localizations'
import { discoveryStringsForRegion } from './web_discovery_localizations'
import { privacyStringsForRegion } from './web_privacy_localizations'
import { profileStringsForRegion } from './web_profile_localizations'
import { reviewStringsForRegion } from './web_review_localizations'
import { shopStringsForRegion } from './web_shop_localizations'
import { userStringsForRegion } from './web_user_localizations'

describe('English count localizations', () => {
  it('formats numeric and API string counts', () => {
    expect(formatEnglishCount(1, 'place')).toBe('1 place')
    expect(formatEnglishCount(2, 'place')).toBe('2 places')
    expect(formatEnglishCount('1.0', 'point')).toBe('1.0 point')
    expect(formatEnglishCount('—', 'hour')).toBe('— hours')
    expect(formatEnglishCount(undefined, 'point')).toBe('— points')
    expect(isSingularEnglishCount('')).toBe(false)
  })

  it('uses natural singular phrases across public and account pages', () => {
    const discovery = discoveryStringsForRegion('EU')
    expect(discovery.shopList.partialResults(1)).toBe(
      'Showing 1 place. Refine the filters to narrow the list.',
    )
    expect(discovery.shopList.allResults(1)).toBe(
      '1 matching place is shown.',
    )
    expect(discovery.shopList.allResults(2)).toBe('2 matching places are shown.')
    expect(discovery.shopList.contextCount(1)).toBe('1 active filter')

    const privacy = privacyStringsForRegion('EU')
    expect(privacy.dailyLimit(1)).toBe('Up to 1 time per day')
    expect(privacy.retention(1)).toBe('Files kept for 1 hour')
    expect(privacy.deleteCodeSent(1)).toContain('in 1 second.')

    const profile = profileStringsForRegion('EU')
    expect(profile.codeSent('Email', 1)).toContain('in 1 second.')
    expect(profile.stats(2, 1, 10)).toBe('Lv.2 · 1 point · 10 growth')
    expect(authStringsForRegion('EU').codeSent(1)).toContain('in 1 second.')
    expect(userStringsForRegion('EU').growth.rows(1)).toBe('1 row')

    const review = reviewStringsForRegion('EU')
    expect(review.detail.likes(1)).toBe('1 like')
    expect(review.detail.comments(1)).toBe('1 comment')
    expect(review.editor.remainingImages(1)).toContain('1 more image.')
    expect(review.editor.uploadedCount(1)).toBe('1 image uploaded · 9 maximum')

    const shop = shopStringsForRegion('EU')
    expect(shop.detail.likes(1)).toBe('1 like')
    expect(shop.reviews.comments(1)).toBe('1 comment')
    expect(shop.reviews.moreAvailable(1)).toBe(
      '1 more public review is available.',
    )
    expect(shop.reviews.moreAvailable(2)).toBe(
      '2 more public reviews are available.',
    )
    expect(shop.reviews.points('1.0')).toBe('1.0 point')
  })

  it('keeps Chinese count order unchanged', () => {
    expect(reviewStringsForRegion('CN').detail.likes(1)).toBe('点赞 1')
    expect(shopStringsForRegion('CN').reviews.comments(1)).toBe('评论 1')
  })
})
