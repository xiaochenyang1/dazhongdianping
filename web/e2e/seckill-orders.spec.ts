import { expect, test, type APIRequestContext, type APIResponse, type Page, type Response } from '@playwright/test'
import type { TradeOrder } from '../src/types/trade'

const backend = `http://127.0.0.1:${process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080}`
const adminURL = `http://127.0.0.1:${process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174}`
const merchantURL = `http://127.0.0.1:${process.env.PLAYWRIGHT_MERCHANT_PORT ?? 15175}`
test.skip(process.env.PLAYWRIGHT_REAL_BACKEND !== '1' || process.env.PLAYWRIGHT_SECKILL_ORDERS !== '1',
  'requires a disposable MySQL/backend with the flash-sale test gates enabled')

async function data<T>(response: APIResponse | Response): Promise<T> {
  const body = await response.json()
  expect(response.ok(), `${response.status()} ${body.message}`).toBeTruthy()
  expect(body.code).toBe(0)
  return body.data as T
}

async function customer(request: APIRequestContext, page: Page, region: 'CN' | 'EU') {
  const account = `seckill-${region}-${Date.now()}-${Math.random().toString(36).slice(2)}@example.com`
  const headers = { 'X-Region': region }
  await data(await request.post(`${backend}/api/c/v1/auth/send-code`, {
    headers, data: { scene: 'register', type: 'email', account, deviceId: account },
  }))
  const auth = await data<{ accessToken: string; refreshToken: string; user: object }>(
    await request.post(`${backend}/api/c/v1/auth/register`, {
      headers, data: { type: 'email', account, code: '123456', password: 'Passw0rd!', preferredRegion: region },
    }),
  )
  await page.addInitScript(({ auth, region }) => {
    localStorage.setItem('dzdp:region', region)
    localStorage.setItem('dzdp:user-access-token', auth.accessToken)
    localStorage.setItem('dzdp:user-refresh-token', auth.refreshToken)
    localStorage.setItem('dzdp:user-profile', JSON.stringify(auth.user))
  }, { auth, region })
  return { ...headers, Authorization: `Bearer ${auth.accessToken}` }
}

for (const region of ['CN', 'EU'] as const) {
  test(`${region}: merchant creates, admin approves, customer buys, refunds and redeems`, async ({ page, context, request }, info) => {
    test.setTimeout(120_000)
    const errors: string[] = []
    page.on('pageerror', error => errors.push(error.message))
    if (region === 'EU') await page.setViewportSize({ width: 390, height: 844 })
    const capabilities = await data<{ seckill: boolean }>(await request.get(`${backend}/api/c/v1/launch-config`, { headers: { 'X-Region': region } }))
    expect(capabilities.seckill).toBe(true)
    const title = `Lunch flash sale ${region} ${Date.now()}`
    const shop = region === 'CN' ? 10001 : 20001
    const deal = region === 'CN' ? 40001 : 41001

    const merchant = await context.newPage()
    merchant.on('pageerror', error => errors.push(error.message))
    await merchant.goto(`${merchantURL}/login`)
    await merchant.locator('input[autocomplete="username"]').fill(region === 'CN' ? 'merchant_cn_hotpot@example.com' : 'merchant_eu_sichuan@example.com')
    await merchant.locator('input[autocomplete="current-password"]').fill('merchant123456')
    await merchant.locator('form button').click()
    await expect(merchant).toHaveURL(`${merchantURL}/dashboard`)
    await merchant.goto(`${merchantURL}/marketing`)
    await merchant.getByTestId('marketing-shop').selectOption(String(shop))
    await expect(merchant.getByTestId('seckill-deal').locator(`option[value="${deal}"]`)).toHaveCount(1)
    await merchant.getByTestId('seckill-deal').selectOption(String(deal))
    await merchant.getByTestId('seckill-title').fill(title)
    await merchant.getByTestId('seckill-price').fill('9.90')
    await merchant.getByTestId('seckill-stock').fill('2')
    await merchant.getByTestId('seckill-start').fill(new Date(Date.now() - 86400_000).toISOString().slice(0, 16))
    await merchant.getByTestId('seckill-end').fill(new Date(Date.now() + 86400_000).toISOString().slice(0, 16))
    const created = merchant.waitForResponse(response => response.request().method() === 'POST' && response.url().endsWith('/marketing/seckill'))
    await merchant.getByTestId('seckill-create').getByRole('button').click()
    const event = await data<{ id: number; auditStatus: number }>(await created)
    expect(event.auditStatus).toBe(1)

    const admin = await context.newPage()
    admin.on('pageerror', error => errors.push(error.message))
    await admin.addInitScript(region => localStorage.setItem('dzdp:admin-region', region), region)
    await admin.goto(`${adminURL}/login`)
    await admin.locator('input[autocomplete="username"]').fill('admin')
    await admin.locator('input[autocomplete="current-password"]').fill('admin123456')
    await admin.getByRole('button', { name: /进入后台|Enter console/ }).click()
    await expect(admin).toHaveURL(`${adminURL}/dashboard`)
    await admin.goto(`${adminURL}/operations/campaign-audit`)
    const row = admin.getByRole('row').filter({ hasText: title })
    const approval = admin.waitForResponse(response => response.request().method() === 'POST' && response.url().endsWith(`/seckill/${event.id}/audit`))
    await row.getByRole('button', { name: '通过', exact: true }).click()
    await data(await approval)

    const headers = await customer(request, page, region)
    page.on('dialog', dialog => dialog.accept(dialog.type() === 'prompt' ? 'Plans changed' : undefined))
    await page.bringToFront()
    await page.goto('/marketing/seckill')
    const card = page.getByTestId(`seckill-${event.id}`)
    await expect(card).toContainText('9.9')
    await expect(card).toContainText(region === 'CN' ? 'CNY' : 'EUR')
    const clippedControls = await page.locator('.app-header a, .header-search input, .region-switch, .session-chip')
      .evaluateAll(controls => controls.filter(control => {
        const bounds = control.getBoundingClientRect()
        return bounds.left < 0 || bounds.right > window.innerWidth
      }).map(control => control.textContent?.trim() || control.tagName))
    expect(clippedControls, 'navigation, search and account controls must remain inside the viewport').toEqual([])
    await page.screenshot({ path: info.outputPath(`seckill-${region}-sale.png`), fullPage: true })
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    const purchase = page.waitForResponse(response => response.request().method() === 'POST' && response.url().endsWith(`/seckill/${event.id}/orders`))
    await page.getByTestId(`seckill-buy-${event.id}`).click()
    const initial = await data<{ orderId: number }>(await purchase)
    await expect(page).toHaveURL(new RegExp(`/user/orders/${initial.orderId}$`))
    await expect(page.getByTestId('order-source')).toContainText(title)
    await expect(page.getByTestId('order-deadline')).toBeVisible()
    await page.getByTestId('order-cancel').click()
    await expect(page.getByTestId('order-pay')).toHaveCount(0)

    await page.goto('/marketing/seckill')
    const retry = page.waitForResponse(response => response.request().method() === 'POST' && response.url().endsWith(`/seckill/${event.id}/orders`))
    await page.getByTestId(`seckill-buy-${event.id}`).click()
    const replacement = await data<{ orderId: number }>(await retry)
    expect(replacement.orderId).not.toBe(initial.orderId)
    const duplicate = await data<{ orderId: number }>(await request.post(`${backend}/api/c/v1/marketing/seckill/${event.id}/claim`, { headers }))
    expect(duplicate.orderId).toBe(replacement.orderId)
    await page.getByTestId('order-pay').click()
    await page.getByTestId('mock-pay-complete').click()
    await expect(page.locator('[data-testid^="order-coupon-link-"]')).toHaveCount(1)
    const paid = await data<TradeOrder>(await request.get(`${backend}/api/c/v1/orders/${replacement.orderId}`, { headers }))
    expect(paid.amount).toBe(9.9)
    expect(paid.orderSource).toBe('seckill')
    expect(paid.coupons).toHaveLength(1)
    await page.screenshot({ path: info.outputPath(`seckill-${region}-paid.png`), fullPage: true })

    await page.getByTestId('order-refund').click()
    await expect(page.getByTestId('order-refund-card')).toBeVisible()
    await merchant.bringToFront()
    await merchant.goto(`${merchantURL}/orders`)
    const refundRow = merchant.getByRole('row').filter({ hasText: paid.orderNo })
    await expect(refundRow).toContainText(title)
    await expect(refundRow).toContainText('9.9')
    await merchant.locator(`input[name="refund-reason-${paid.id}"]`).fill('Approved for integration test')
    const refund = merchant.waitForResponse(response => response.request().method() === 'POST' && response.url().includes(`/orders/${paid.id}/refund`))
    await merchant.getByTestId(`approve-refund-${paid.id}`).click()
    await data(await refund)
    await page.bringToFront()
    await page.reload()
    await expect(page.getByTestId('order-refund-card')).toContainText(region === 'CN' ? '退款成功' : 'Refunded')
    expect((await data<TradeOrder>(await request.get(`${backend}/api/c/v1/orders/${paid.id}`, { headers }))).payStatus).toBe(2)
    await page.screenshot({ path: info.outputPath(`seckill-${region}-refunded.png`), fullPage: true })
    await page.goto('/marketing/seckill')
    await expect(page.getByTestId(`seckill-buy-${event.id}`)).toHaveCount(0)
    await expect(card.getByRole('link', { name: /查看订单|View order/ })).toBeVisible()

    const second = await context.newPage()
    const secondHeaders = await customer(request, second, region)
    await second.goto('/marketing/seckill')
    await second.getByTestId(`seckill-buy-${event.id}`).click()
    await second.getByTestId('order-pay').click()
    await second.getByTestId('mock-pay-complete').click()
    await expect(second.locator('[data-testid^="order-coupon-link-"]')).toHaveCount(1)
    const secondId = second.url().split('/').pop()
    const secondOrder = await data<TradeOrder>(await request.get(`${backend}/api/c/v1/orders/${secondId}`, { headers: secondHeaders }))
    const code = secondOrder.coupons![0]!.code
    await merchant.bringToFront()
    await merchant.goto(`${merchantURL}/coupons`)
    await merchant.getByTestId('coupon-code-input').fill(code)
    await merchant.getByTestId('coupon-verify-submit').click()
    await expect(merchant.getByTestId('coupon-verify-result')).toContainText(region === 'CN' ? '已使用' : 'Used')
    await merchant.screenshot({ path: info.outputPath(`seckill-${region}-redeemed.png`), fullPage: true })
    expect((await data<TradeOrder>(await request.get(`${backend}/api/c/v1/orders/${secondId}`, { headers: secondHeaders }))).coupons![0]!.status).toBe(2)
    expect(errors).toEqual([])
    await second.close(); await admin.close(); await merchant.close()
  })
}
