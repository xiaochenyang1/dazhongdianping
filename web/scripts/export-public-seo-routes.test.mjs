import { describe, expect, it, vi } from 'vitest'
import { collectPublicSeoRoutes, createPublicApiClient } from './export-public-seo-routes.mjs'

describe('public SEO snapshot exporter', () => {
  it('adds region and query parameters to public API requests', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ code: 0, data: { ok: true } }),
    })
    const get = createPublicApiClient({ baseUrl: 'https://api.example.test', region: 'EU', fetchImpl })

    await get('/api/c/v1/shops', { page: 1, pageSize: 10 })

    expect(fetchImpl).toHaveBeenCalledWith(
      new URL('https://api.example.test/api/c/v1/shops?page=1&pageSize=10'),
      { headers: { Accept: 'application/json', 'X-Region': 'EU' } },
    )
  })

  it('turns public detail snapshots into crawlable shop, review, post and campaign routes', async () => {
    const get = vi.fn(async (endpoint) => {
      const fixtures = {
        '/api/c/v1/search/shops': { list: [{ id: 10001 }], total: 1 },
        '/api/c/v1/shops/10001': {
          id: 10001,
          name: '渝里火锅徐汇店',
          cityName: '上海',
          categoryName: '火锅',
          areaName: '徐汇',
          summary: '适合聚餐的川渝火锅。',
          address: '漕溪北路 88 号',
          phone: '021-61008888',
          businessHours: '10:00-22:00',
          score: 4.7,
          coverUrl: 'https://cdn.example.test/shop.jpg',
        },
        '/api/c/v1/shops/10001/reviews': { list: [{ id: 1 }], total: 1 },
        '/api/c/v1/reviews/1': {
          id: 1,
          shopId: 10001,
          shopName: '渝里火锅徐汇店',
          userName: '阿遥',
          content: '锅底香但不燥。',
          scoreOverall: 4.8,
          auditStatus: 1,
          status: 1,
          createdAt: '2026-07-01 18:30:00',
        },
        '/api/c/v1/posts': { list: [{ id: 7 }], total: 1 },
        '/api/c/v1/posts/7': {
          id: 7,
          userId: 9,
          userName: '伦敦小王',
          title: '周末市集指南',
          content: '本周六开放，适合慢慢逛。',
          topics: ['周末'],
          images: ['https://cdn.example.test/post.jpg'],
          likeCount: 2,
          commentCount: 1,
          createdAt: '2026-07-02 12:00:00',
        },
        '/api/c/v1/ranks': [{ id: 30001, name: '上海火锅必吃榜' }],
        '/api/c/v1/ranks/30001': {
          id: 30001,
          name: '上海火锅必吃榜',
          cityName: '上海',
          categoryName: '火锅',
          period: '2026-Q3',
          items: [{ position: 1, reason: '口碑稳定', shop: { id: 10001, name: '渝里火锅徐汇店' } }],
        },
        '/api/c/v1/activities': [{ id: 5001, name: '开学季聚餐专题' }],
        '/api/c/v1/activities/5001': {
          id: 5001,
          name: '开学季聚餐专题',
          cityName: '上海',
          channelText: '活动页',
          items: [{ title: '火锅局', subtitle: '一起吃饭', linkUrl: '/shops/10001' }],
        },
        '/api/c/v1/groups': { list: [], total: 0 },
        '/api/c/v1/topics': { list: [], total: 0 },
      }
      return fixtures[endpoint] ?? null
    })

    const result = await collectPublicSeoRoutes({ get, region: 'CN', siteUrl: 'https://www.example.test', pageSize: 10, maxReviews: 10 })
    const byPath = new Map(result.routes.map((route) => [route.path, route]))

    expect(result.warnings).toEqual([])
    expect(byPath.get('/shops/10001')).toMatchObject({
      title: '渝里火锅徐汇店 - 上海火锅',
      image: 'https://cdn.example.test/shop.jpg',
    })
    expect(byPath.get('/shops/10001').jsonLd.url).toBe('https://www.example.test/shops/10001')
    expect(byPath.get('/reviews/1').robots).toBe('index,follow')
    expect(byPath.get('/community/posts/7').jsonLd['@type']).toBe('Article')
    expect(byPath.get('/ranks/30001').contentHtml).toContain('渝里火锅徐汇店')
    expect(byPath.get('/activities/5001').contentHtml).toContain('火锅局')
    expect(get).toHaveBeenCalledWith('/api/c/v1/shops/10001/reviews', { page: 1, pageSize: 10 })
  })

  it('generates EU snapshot chrome and stable labels in English', async () => {
    const get = vi.fn(async (endpoint) => {
      const fixtures = {
        '/api/c/v1/search/shops': { list: [{ id: 20001 }], total: 1 },
        '/api/c/v1/shops/20001': {
          id: 20001,
          name: 'Maison Sichuan Paris',
          cityName: 'Paris',
          categoryName: 'Dining',
          areaName: 'Le Marais',
          summary: '',
          address: '',
          phone: '',
          businessHours: '',
          score: 4.7,
        },
        '/api/c/v1/shops/20001/reviews': { list: [{ id: 2 }], total: 1 },
        '/api/c/v1/reviews/2': {
          id: 2,
          shopId: 20001,
          shopName: 'Maison Sichuan Paris',
          userName: '',
          content: '',
          scoreOverall: 4.8,
          auditStatus: 1,
          status: 1,
          createdAt: '2026-07-01 18:30:00',
        },
        '/api/c/v1/posts': { list: [{ id: 8 }], total: 1 },
        '/api/c/v1/posts/8': {
          id: 8,
          userId: 10,
          userName: '',
          title: '',
          content: '',
          topics: [],
          images: [],
          createdAt: '2026-07-02 12:00:00',
        },
        '/api/c/v1/ranks': [{ id: 30002, name: 'Paris dining list' }],
        '/api/c/v1/ranks/30002': {
          id: 30002,
          name: 'Paris dining list',
          type: 1,
          typeText: '必吃榜',
          cityName: 'Paris',
          categoryName: 'Dining',
          period: '',
          updatedAt: '2026-07-03 09:15:00',
          items: [{ position: 1, reason: 'Consistently good', shop: { id: 20001, name: 'Maison Sichuan Paris' } }],
        },
        '/api/c/v1/activities': [{ id: 5002, name: 'Summer dining' }],
        '/api/c/v1/activities/5002': {
          id: 5002,
          name: 'Summer dining',
          cityName: 'Paris',
          channel: 4,
          channelText: '活动页',
          items: [{ title: '', subtitle: '', targetName: '', linkUrl: '/shops/20001' }],
        },
        '/api/c/v1/groups': { list: [{ id: 3 }], total: 1 },
        '/api/c/v1/groups/3': {
          id: 3,
          name: 'Paris community',
          description: '',
          memberCount: 12,
          postCount: 1,
        },
        '/api/c/v1/groups/3/posts': { list: [{ id: 8, title: '' }], total: 1 },
        '/api/c/v1/topics': { list: [{ id: 4 }], total: 1 },
        '/api/c/v1/topics/4': {
          id: 4,
          name: 'Paris weekends',
          followerCount: 9,
          postCount: 1,
          hotScore: 18,
        },
        '/api/c/v1/topics/4/posts': { list: [{ id: 8, title: '' }], total: 1 },
      }
      return fixtures[endpoint] ?? null
    })

    const result = await collectPublicSeoRoutes({
      get,
      region: 'EU',
      siteUrl: 'https://eu.example.test',
      pageSize: 10,
      maxReviews: 10,
      maxPosts: 10,
    })
    const byPath = new Map(result.routes.map((route) => [route.path, route]))

    expect(result.routes).toHaveLength(7)
    expect(JSON.stringify(result.routes)).not.toMatch(/[一-龥]/)
    expect(byPath.get('/shops/20001').contentHtml).toContain('View place reviews')
    expect(byPath.get('/reviews/2')).toMatchObject({
      title: 'Maison Sichuan Paris review - Anonymous user',
      summary: expect.stringContaining('4.8/5'),
    })
    expect(byPath.get('/reviews/2').contentHtml).toContain('01/07/2026 18:30')
    expect(byPath.get('/ranks/30002').description).toContain('Must-try ranking, updated 03/07/2026 09:15')
    expect(byPath.get('/activities/5002').summary).toContain('Activity page · 1 public resource')
    expect(byPath.get('/groups/3').contentHtml).toContain('12 members')
    expect(byPath.get('/topics/4').summary).toContain('9 followers · 1 public post')
  })
})
