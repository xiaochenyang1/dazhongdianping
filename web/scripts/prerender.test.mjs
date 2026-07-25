import { describe, expect, it } from 'vitest'
import { buildPrerenderHtml, canonicalUrl, normalizeRoutePath } from './prerender.mjs'

const template = `<!doctype html><html><head><meta name="description" content="old"><title>Old</title></head><body><div id="app"></div><script type="module" src="/assets/app.js"></script></body></html>`
const routes = [
  {
    path: '/',
    title: '首页',
    description: '首页描述',
    heading: '首页标题',
    summary: '首页摘要',
    schemaType: 'WebPage',
  },
  {
    path: '/shops',
    title: '商户列表',
    description: '商户描述',
    heading: '商户标题',
    summary: '商户摘要',
    schemaType: 'CollectionPage',
  },
]

describe('web prerender', () => {
  it('normalizes route paths and strips query/hash state', () => {
    expect(normalizeRoutePath('/shops/?page=2#results')).toBe('/shops')
    expect(normalizeRoutePath('topics/')).toBe('/topics')
    expect(() => normalizeRoutePath('/shops/../admin')).toThrow('Unsafe prerender route')
  })

  it('builds absolute canonical URLs only when a public site URL is configured', () => {
    expect(canonicalUrl('/shops')).toBe('/shops')
    expect(canonicalUrl('/shops', 'https://example.test')).toBe('https://example.test/shops')
  })

  it('renders crawlable route content and complete static metadata', () => {
    const html = buildPrerenderHtml(template, routes[1], routes, 'https://example.test')

    expect(html).toContain('<title>商户列表 | 大众点评(仿)</title>')
    expect(html).toContain('<link rel="canonical" href="https://example.test/shops">')
    expect(html).toContain('<meta property="og:url" content="https://example.test/shops">')
    expect(html).toContain('data-prerender-route="/shops"')
    expect(html).toContain('<h1>商户标题</h1>')
    expect(html).toContain('"@type":"CollectionPage"')
    expect(html).not.toContain('content="old"')
    expect(html).toContain('src="/assets/app.js"')
  })
})
