import { createApp } from 'vue'
import { beforeEach, describe, expect, it } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'
import ShopCard from './ShopCard.vue'

describe('ShopCard', () => {
  beforeEach(() => {
    localStorage.clear()
    useAppContext().setRegion('CN')
  })

  it('renders an EUR shop price from the response currency', () => {
    useAppContext().setRegion('EU')
    const host = document.createElement('div')
    const app = createApp(ShopCard, {
      shop: {
        id: 20001,
        name: 'Maison Sichuan Paris',
        coverUrl: '/shop.jpg',
        score: 4.6,
        pricePerCapita: 36,
        currency: 'EUR',
        address: '12 Rue du Temple, Paris',
        areaName: 'Le Marais',
        cityName: 'Paris',
        hasDeal: true,
        openNow: true,
        tags: ['Chinese'],
      },
    })

    app.mount(host)

    expect(host.textContent).toContain('Average €36 EUR')
    expect(host.textContent).toContain('Open now')
    expect(host.textContent).toContain('Offer available')
    expect(host.textContent).not.toContain('¥')
    app.unmount()
  })

  it('renders a CNY shop price with its matching symbol and code', () => {
    const host = document.createElement('div')
    const app = createApp(ShopCard, {
      shop: {
        id: 10001,
        name: '渝里火锅徐汇店',
        coverUrl: '/shop.jpg',
        score: 4.7,
        pricePerCapita: 138,
        currency: 'CNY',
        address: '上海市徐汇区漕溪北路88号',
        areaName: '徐汇',
        cityName: '上海',
        hasDeal: true,
        openNow: true,
        tags: ['火锅'],
      },
    })

    app.mount(host)

    expect(host.textContent).toContain('人均 ¥138 CNY')
    expect(host.textContent).not.toContain('€')
    app.unmount()
  })

  it('renders verified merchant badge next to the shop name', () => {
    useAppContext().setRegion('EU')
    const host = document.createElement('div')
    const app = createApp(ShopCard, {
      shop: {
        id: 20001,
        name: 'Maison Sichuan Paris',
        coverUrl: '/shop.jpg',
        score: 4.6,
        pricePerCapita: 36,
        currency: 'EUR',
        address: '12 Rue du Temple, Paris',
        areaName: 'Le Marais',
        cityName: 'Paris',
        hasDeal: true,
        openNow: true,
        tags: ['Chinese'],
        distanceMeters: null,
        merchantCertification: { code: 'verified_merchant', label: '认证商户' },
      },
    })

    app.mount(host)

    expect(host.textContent).toContain('Maison Sichuan Paris')
    expect(host.textContent).toContain('Verified merchant')
    expect(host.textContent).not.toContain('认证商户')
    app.unmount()
  })
})
