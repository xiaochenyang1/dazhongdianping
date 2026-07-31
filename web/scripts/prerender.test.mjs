import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { buildPrerenderHtml, canonicalUrl, normalizeRoutePath, prerender } from './prerender.mjs'

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

  it('selects the English route manifest and document chrome for EU builds', async () => {
    const distDir = await mkdtemp(path.join(os.tmpdir(), 'dzdp-prerender-eu-'))
    try {
      await writeFile(path.join(distDir, 'index.html'), template, 'utf8')
      const manifest = await prerender({ distDir, region: 'EU', siteUrl: 'https://eu.example.test' })
      const html = await readFile(path.join(distDir, 'shops', 'index.html'), 'utf8')

      expect(manifest).toMatchObject({ region: 'EU', sitemap: true })
      expect(manifest.routes).toHaveLength(7)
      expect(html).toContain('<html lang="en">')
      expect(html).toContain('<title>Places | Local Reviews (Demo)</title>')
      expect(html).toContain('aria-label="Public page links"')
      expect(html).not.toMatch(/[一-龥]/)
    } finally {
      await rm(distDir, { recursive: true, force: true })
    }
  })
})
