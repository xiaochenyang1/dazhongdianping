import { createApp, defineComponent, nextTick, ref } from 'vue'
import { describe, expect, it } from 'vitest'
import { absoluteSeoUrl, useSeoMeta } from './useSeoMeta'

async function flush() {
  await Promise.resolve()
  await nextTick()
}

describe('useSeoMeta', () => {
  it('keeps asset query strings while canonical URLs drop query and hash', () => {
    expect(absoluteSeoUrl('/shops/1?preview=1#details')).toBe(`${window.location.origin}/shops/1?preview=1#details`)

    const state = ref({
      title: '门店',
      description: '描述',
      canonical: '/shops/1?preview=1#details',
      image: 'https://cdn.example.test/cover.jpg?token=abc',
      jsonLd: { '@context': 'https://schema.org', '@type': 'Restaurant' },
    })
    const View = defineComponent({ setup: () => { useSeoMeta(state); return () => null } })
    const host = document.createElement('div')
    const app = createApp(View)
    app.mount(host)

    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href')).toBe(`${window.location.origin}/shops/1`)
    expect(document.head.querySelector('meta[property="og:image"]')?.getAttribute('content')).toBe('https://cdn.example.test/cover.jpg?token=abc')
    state.value = { ...state.value, jsonLd: { '@context': 'https://schema.org', '@type': 'LocalBusiness' } }
    return flush().then(() => {
      expect(document.head.querySelectorAll('script[type="application/ld+json"]')).toHaveLength(1)
      expect(document.head.querySelector('script[type="application/ld+json"]')?.textContent).toContain('LocalBusiness')
      app.unmount()
      expect(document.head.querySelector('link[rel="canonical"]')).toBeNull()
      expect(document.head.querySelector('script[type="application/ld+json"]')).toBeNull()
    })
  })
})
