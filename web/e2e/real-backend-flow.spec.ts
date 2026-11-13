import { Buffer } from 'node:buffer'
import { expect, test, type APIRequestContext, type APIResponse, type BrowserContext, type Page, type Response } from '@playwright/test'

const adminPort = Number(process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174)
const normalizeBaseURL = (value: string | undefined, fallback: string) => (value?.trim() || fallback).replace(/\/+$/, '')
const adminBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_ADMIN_BASE_URL, `http://127.0.0.1:${adminPort}`)
const merchantPort = Number(process.env.PLAYWRIGHT_MERCHANT_PORT ?? 15175)
const merchantBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_MERCHANT_BASE_URL, `http://127.0.0.1:${merchantPort}`)
const backendPort = Number(process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080)
const backendBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_BACKEND_BASE_URL, `http://127.0.0.1:${backendPort}`)
const webPort = Number(process.env.PLAYWRIGHT_WEB_PORT ?? 15173)
const webBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_WEB_BASE_URL, `http://127.0.0.1:${webPort}`)
const remoteAcceptance = process.env.PLAYWRIGHT_REMOTE_ACCEPTANCE === '1'
const expectedCommitSha = process.env.PLAYWRIGHT_EXPECTED_COMMIT_SHA?.trim() ?? ''
const adminAccount = process.env.PLAYWRIGHT_E2E_ADMIN_ACCOUNT?.trim() || 'admin'
const adminPassword = process.env.PLAYWRIGHT_E2E_ADMIN_PASSWORD?.trim() || 'admin123456'
const merchantAccount = process.env.PLAYWRIGHT_E2E_MERCHANT_ACCOUNT?.trim() || 'merchant_eu_sichuan@example.com'
const merchantPassword = process.env.PLAYWRIGHT_E2E_MERCHANT_PASSWORD?.trim() || 'merchant123456'
const applicationOrigins = new Set([webBaseURL, adminBaseURL, merchantBaseURL, backendBaseURL].map((value) => new URL(value).origin))
let syntheticAccountSequence = 0
const reviewUploadPng = {
  name: 'real-backend-review-upload.png',
  mimeType: 'image/png',
  buffer: Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR42mP8z8Dwn4GBgYGJAQoAHxcCAr7afKQAAAAASUVORK5CYII=',
    'base64',
  ),
}

test.skip(process.env.PLAYWRIGHT_REAL_BACKEND !== '1', 'requires PLAYWRIGHT_REAL_BACKEND=1')

async function loginFromAuthDialog(page: Page, account: string, password: string) {
  const authDialog = page.locator('.auth-dialog')
  await expect(authDialog).toBeVisible()
  await authDialog.getByLabel('邮箱 / 手机号').fill(account)
  await authDialog.getByLabel('密码').fill(password)
  await authDialog.getByRole('button', { name: '登录', exact: true }).click()
}

async function setUserRegion(context: BrowserContext, region: 'CN' | 'EU') {
  await context.addInitScript((selectedRegion) => {
    localStorage.setItem('dzdp:region', selectedRegion)
  }, region)
}

async function loginToAdminConsole(page: Page, account = adminAccount, password = adminPassword) {
  await page.goto(`${adminBaseURL}/login`)
  // Login fields deliberately start empty; never rely on demo credentials being prefilled.
  await page.locator('input[autocomplete="username"]').fill(account)
  await page.locator('input[autocomplete="current-password"]').fill(password)
  const loginResponse = page.waitForResponse((response) =>
    response.request().method() === 'POST'
    && new URL(response.url()).pathname === '/api/admin/v1/auth/login',
  )
  await page.getByRole('button', { name: /进入后台|Enter console/ }).click()
  await expectApiSuccess(await loginResponse)
  await expect(page).toHaveURL(`${adminBaseURL}/dashboard`)
}

async function registerSyntheticUser(
  request: APIRequestContext,
  prefix: string,
  region: 'CN' | 'EU' = 'CN',
) {
  syntheticAccountSequence += 1
  const account = `${prefix}-${Date.now()}-${syntheticAccountSequence}@example.com`
  const password = 'Passw0rd!'
  const headers = { 'Accept-Language': 'zh-CN', 'X-Region': region }
  await expectApiSuccess(await request.post(`${backendBaseURL}/api/c/v1/auth/send-code`, {
    headers,
    data: { scene: 'register', type: 'email', account, deviceId: account },
  }))
  const session = await expectApiSuccess<{ accessToken: string; refreshToken: string; user: object }>(
    await request.post(`${backendBaseURL}/api/c/v1/auth/register`, {
      headers,
      data: { type: 'email', account, code: '123456', password, preferredRegion: region },
    }),
  )
  return { account, password, ...session }
}

let sharedEuUser: Awaited<ReturnType<typeof registerSyntheticUser>> | undefined

async function getSharedEuUser(request: APIRequestContext) {
  sharedEuUser ??= await registerSyntheticUser(request, 'shared-eu-flow', 'EU')
  return sharedEuUser
}

async function navigateAdmin(page: Page, path: string) {
  // Keep pending requests alive by navigating through the app instead of reloading the document.
  const menu = page.getByRole('navigation', { name: /^(后台菜单|Admin navigation)$/ })
  const link = menu.locator(`a[href="${path}"]`)
  await expect(link).toBeVisible()
  await link.click()
  await expect(page).toHaveURL(`${adminBaseURL}${path}`)
}

async function expectApiSuccess<T>(response: APIResponse | Response) {
  const body = (await response.json()) as {
    code: number
    message: string
    data: T
  }
  const diagnostic = `${response.status()} ${body.message}`
  expect(response.ok(), diagnostic).toBeTruthy()
  expect(body.code, diagnostic).toBe(0)
  return body.data
}

async function expectApiFailure(response: APIResponse, status: number) {
  const body = (await response.json()) as {
    code: number
    message: string
  }
  expect(response.status(), JSON.stringify(body)).toBe(status)
  expect(body.code).not.toBe(0)
  expect(body.message).not.toBe('')
}

function collectBrowserErrors(page: Page) {
  const errors: string[] = []
  const failedResponses: string[] = []
  const failedRequests: string[] = []
  const requests: string[] = []
  const startedAt = Date.now()
  const elapsed = () => `${Date.now() - startedAt}ms`
  page.on('pageerror', (error) => {
    errors.push(`${elapsed()} pageerror: ${error.message}`)
  })
  page.on('console', (message) => {
    if (message.type() === 'error') {
      errors.push(`${elapsed()} console.error: ${message.text()}`)
    }
  })
  page.on('request', (request) => {
    requests.push(`${elapsed()} ${request.method()} ${request.url()}`)
  })
  page.on('response', (response) => {
    if (response.status() >= 400) {
      failedResponses.push(`${elapsed()} ${response.status()} ${response.request().method()} ${response.url()}`)
    }
  })
  page.on('requestfailed', (request) => {
    failedRequests.push(`${elapsed()} ${request.method()} ${request.url()} ${request.failure()?.errorText ?? ''}`)
  })
  return { errors, failedResponses, failedRequests, requests }
}

function expectNoBrowserFailures(
  diagnostics: ReturnType<typeof collectBrowserErrors>,
  from = { errors: 0, failedResponses: 0, failedRequests: 0 },
) {
  const errors = diagnostics.errors.slice(from.errors)
  const failedResponses = diagnostics.failedResponses.slice(from.failedResponses)
  const failedRequests = diagnostics.failedRequests.slice(from.failedRequests)
  expect(errors, errors.join('\n')).toEqual([])
  expect(failedResponses, failedResponses.join('\n')).toEqual([])
  expect(failedRequests, failedRequests.join('\n')).toEqual([])
}

function expectBrowserAuthInvalidation(
  diagnostics: ReturnType<typeof collectBrowserErrors>,
  from: { errors: number; failedResponses: number; failedRequests: number },
  endpoint: string,
) {
  const errors = diagnostics.errors.slice(from.errors)
  const failedResponses = diagnostics.failedResponses.slice(from.failedResponses)
  const failedRequests = diagnostics.failedRequests.slice(from.failedRequests)
  expect(errors).toEqual([
    expect.stringMatching(/console\.error: Failed to load resource: the server responded with a status of 401 \(Unauthorized\)/),
  ])
  expect(failedResponses).toHaveLength(1)
  expect(failedResponses[0]).toContain('401 GET')
  expect(failedResponses[0]).toContain(endpoint)
  expect(failedRequests).toEqual([])
}

function adminHeaders(token: string, region: 'CN' | 'EU') {
  return {
    'Accept-Language': 'zh-CN',
    'Authorization': `Bearer ${token}`,
    'X-Region': region,
  }
}

function containsCategoryId(categories: Array<{ id: number; children?: unknown[] }>, categoryId: number): boolean {
  return categories.some((category) =>
    category.id === categoryId
    || containsCategoryId((category.children ?? []) as Array<{ id: number; children?: unknown[] }>, categoryId),
  )
}

test.describe('Paris launch', () => {
  test.use({ timezoneId: 'Asia/Shanghai' })

  test('books Paris in shop time and blocks deferred entry points across regions', async ({ page, context, request }) => {
    const headers = { 'X-Region': 'EU' }
    const account = `paris-launch-${Date.now()}@example.com`
    await expectApiSuccess(await request.post(`${backendBaseURL}/api/c/v1/auth/send-code`, {
      headers, data: { scene: 'register', type: 'email', account, deviceId: account },
    }))
    const session = await expectApiSuccess<{ accessToken: string; refreshToken: string; user: object }>(
      await request.post(`${backendBaseURL}/api/c/v1/auth/register`, {
        headers, data: { type: 'email', account, code: '123456', password: 'Passw0rd!', preferredRegion: 'EU' },
      }),
    )
    const userHeaders = { ...headers, Authorization: `Bearer ${session.accessToken}` }
    const availability = await expectApiSuccess<{ date: string; today: string; timeZone: string }>(
      await request.get(`${backendBaseURL}/api/c/v1/shops/20001/reservation-slots`, {
        headers, params: { peopleCount: 2 },
      }),
    )
    expect(availability.timeZone).toBe('Europe/Paris')
    const merchant = await expectApiSuccess<{ accessToken: string }>(
      await request.post(`${backendBaseURL}/api/b/v1/auth/login`, {
        headers, data: { account: merchantAccount, password: merchantPassword },
      }),
    )
    await expectApiSuccess(await request.post(`${backendBaseURL}/api/b/v1/reservation-slots`, {
      headers: { ...headers, Authorization: `Bearer ${merchant.accessToken}` },
      data: { shopId: 20001, bizDate: availability.date, startTime: '18:30:00', endTime: '20:30:00',
        capacity: 8, confirmMode: 2, cancelBeforeMinutes: 120, enabled: true },
    }))
    await context.addInitScript((auth) => {
      if (!localStorage.getItem('dzdp:region')) localStorage.setItem('dzdp:region', 'EU')
      localStorage.setItem('dzdp:user-access-token', auth.accessToken)
      localStorage.setItem('dzdp:user-refresh-token', auth.refreshToken)
      localStorage.setItem('dzdp:user-profile', JSON.stringify(auth.user))
    }, session)

    await page.goto('/shops/20001/reserve')
    await expect(page.getByLabel('Date', { exact: true })).toHaveValue(availability.date)
    await expect(page.getByLabel('Date', { exact: true })).toHaveAttribute('min', availability.today)
    await expect(page.getByTestId('reservation-time-zone')).toHaveText('Europe/Paris')
    await expect(page.locator('.top-nav')).not.toContainText('Creator')
    await expect(page.locator('.top-nav')).not.toContainText('Flash sale')
    await page.getByRole('button', { name: /18:30:00-20:30:00/ }).click()
    await page.getByLabel('Contact name', { exact: true }).fill('Paris visitor')
    await page.getByLabel('Phone number', { exact: true }).fill('+33123456789')
    await page.getByRole('button', { name: 'Book now', exact: true }).click()
    await expect(page).toHaveURL(/\/user\/reservations\/\d+$/)
    const reservationId = page.url().split('/').pop()
    await expect(page.locator('.page-header')).toContainText('18:30 Europe/Paris')
    await page.getByRole('button', { name: 'Cancel booking', exact: true }).click()
    await expect(page.getByText('Booking cancelled.', { exact: true })).toBeVisible()
    const cancelled = await expectApiSuccess<{ status: number; timeZone: string; reserveAt: string }>(
      await request.get(`${backendBaseURL}/api/c/v1/reservations/${reservationId}`, { headers: userHeaders }),
    )
    expect(cancelled.status).toBe(3)
    expect(cancelled.timeZone).toBe('Europe/Paris')
    expect(cancelled.reserveAt).toMatch(/Z$/)

    await expectApiFailure(await request.post(`${backendBaseURL}/api/c/v1/reservations`, {
      headers: userHeaders, data: { shopId: 20002, reserveTime: `${availability.date} 18:30:00`,
        peopleCount: 2, contactName: 'Paris visitor', contactPhone: '+33123456789' },
    }), 404)
    for (const region of ['EU', 'CN', '']) {
      const probeHeaders: Record<string, string> = { Authorization: `Bearer ${session.accessToken}` }
      if (region) probeHeaders['X-Region'] = region
      const launch = await expectApiSuccess(await request.get(`${backendBaseURL}/api/c/v1/launch-config`, {
        headers: probeHeaders,
      }))
      expect(launch).toEqual({ region: region || 'CN', creatorRewards: false, seckill: false, groupBuy: false })
      const taskId = region === 'EU' ? 9102 : 9101
      for (const action of ['claim', 'complete']) {
        await expectApiFailure(await request.post(`${backendBaseURL}/api/c/v1/creator/tasks/${taskId}/${action}`, {
          headers: probeHeaders,
        }), 403)
      }
    }
    const profile = await expectApiSuccess<{ preferredRegion: string; points: number }>(
      await request.get(`${backendBaseURL}/api/c/v1/user/me`, { headers: userHeaders }),
    )
    expect(profile.preferredRegion).toBe('EU')
    expect(profile.points).toBe(0)

    for (const region of ['EU', 'CN']) {
      await page.locator('.region-switch').getByRole('button', { name: region, exact: true }).click()
      for (const path of ['/user/creator', '/marketing/seckill', '/marketing/groupbuy']) {
        await page.goto(path)
        await expect(page).toHaveURL(/\/$/)
        await expect(page.locator('.region-switch').getByRole('button', { name: region, exact: true })).toHaveClass(/is-active/)
        await expect(page.locator(`.top-nav a[href="${path}"]`)).toHaveCount(0)
        await expect(page.locator('.auth-dialog')).toHaveCount(0)
      }
    }
  })
})

async function createApprovedPublicReview(request: APIRequestContext, content: string) {
  const reviewerSession = await registerSyntheticUser(request, 'review-author')

  const createdReview = await expectApiSuccess<{ id: number }>(
    await request.post(`${backendBaseURL}/api/c/v1/reviews`, {
      headers: {
        'Accept-Language': 'zh-CN',
        'Authorization': `Bearer ${reviewerSession.accessToken}`,
        'Idempotency-Key': `pw-review-${Date.now()}`,
        'X-Region': 'CN',
      },
      data: {
        shopId: 10001,
        content,
        scoreOverall: 5,
        scoreTaste: 5,
        scoreEnv: 4,
        scoreService: 5,
        cost: 128,
        currency: 'CNY',
        tags: ['真实E2E', '游客续执行'],
        images: [],
      },
    }),
  )

  const adminSession = await expectApiSuccess<{
    accessToken: string
  }>(
    await request.post(`${backendBaseURL}/api/admin/v1/auth/login`, {
      headers: {
        'Accept-Language': 'zh-CN',
        'X-Region': 'CN',
      },
      data: {
        account: adminAccount,
        password: adminPassword,
      },
    }),
  )

  const tasks = await expectApiSuccess<{
    list: Array<{ id: number; bizId: number }>
  }>(
    await request.get(`${backendBaseURL}/api/admin/v1/audit/tasks`, {
      headers: {
        'Accept-Language': 'zh-CN',
        'Authorization': `Bearer ${adminSession.accessToken}`,
        'X-Region': 'CN',
      },
      params: {
        bizType: 3,
        status: 0,
        page: 1,
        pageSize: 20,
      },
    }),
  )

  const auditTask = tasks.list.find((item) => item.bizId === createdReview.id)
  expect(auditTask).toBeTruthy()

  await expectApiSuccess(
    await request.post(`${backendBaseURL}/api/admin/v1/audit/tasks/${auditTask?.id}/pass`, {
      headers: {
        'Accept-Language': 'zh-CN',
        'Authorization': `Bearer ${adminSession.accessToken}`,
        'X-Region': 'CN',
      },
      data: {
        remark: 'Playwright 自动放行游客互动续执行用例',
      },
    }),
  )

  return { reviewId: createdReview.id, reviewerSession }
}

test('renders a redeemable coupon QR without contacting an external image service', async ({ page, context, request }) => {
  const headers = { 'X-Region': 'EU' }
  const session = await getSharedEuUser(request)
  const userHeaders = { ...headers, Authorization: `Bearer ${session.accessToken}` }
  const order = await expectApiSuccess<{ id: number }>(await request.post(`${backendBaseURL}/api/c/v1/orders`, {
    headers: userHeaders, data: { dealId: 41001, quantity: 1 },
  }))
  const paid = await expectApiSuccess<{ coupons: Array<{ code: string }> }>(
    await request.post(`${backendBaseURL}/api/c/v1/orders/${order.id}/pay/mock-complete`, { headers: userHeaders }),
  )
  const code = paid.coupons[0].code
  const externalImageRequests: string[] = []
  await page.route('**/*', async (route) => {
    const resource = route.request()
    const url = new URL(resource.url())
    if (resource.resourceType() === 'image' && !applicationOrigins.has(url.origin)) {
      externalImageRequests.push(resource.url())
      await route.abort()
    } else {
      await route.continue()
    }
  })
  await context.addInitScript((auth) => {
    localStorage.setItem('dzdp:region', 'EU')
    localStorage.setItem('dzdp:user-access-token', auth.accessToken)
    localStorage.setItem('dzdp:user-refresh-token', auth.refreshToken)
    localStorage.setItem('dzdp:user-profile', JSON.stringify(auth.user))
  }, session)
  await page.goto(`/user/coupons/${encodeURIComponent(code)}`)
  await expect(page.getByTestId('coupon-detail-code')).toHaveText(code)
  const qr = page.getByTestId('coupon-qr-image')
  await expect(qr).toHaveAttribute('src', /^data:image\/png;base64,/)
  await expect.poll(() => qr.evaluate((element) => (element as HTMLImageElement).naturalWidth)).toBe(240)
  expect(externalImageRequests).toEqual([])
})

test('scans an issued coupon from video frames, confirms verification and rejects a second redemption', async ({ page, request }) => {
  const headers = { 'X-Region': 'EU' }
  const session = await getSharedEuUser(request)
  const userHeaders = { ...headers, Authorization: `Bearer ${session.accessToken}` }
  const order = await expectApiSuccess<{ id: number }>(await request.post(`${backendBaseURL}/api/c/v1/orders`, {
    headers: userHeaders, data: { dealId: 41001, quantity: 1 },
  }))
  const paid = await expectApiSuccess<{ coupons: Array<{ code: string }> }>(
    await request.post(`${backendBaseURL}/api/c/v1/orders/${order.id}/pay/mock-complete`, { headers: userHeaders }),
  )
  const code = paid.coupons[0].code
  const detail = await expectApiSuccess<{ qrImageUrl: string }>(await request.get(
    `${backendBaseURL}/api/c/v1/coupons/${code}`, { headers: userHeaders },
  ))
  const merchant = await expectApiSuccess<{ accessToken: string; merchantId: number }>(
    await request.post(`${backendBaseURL}/api/b/v1/auth/login`, {
      headers, data: { account: merchantAccount, password: merchantPassword },
    }),
  )
  await page.addInitScript((auth) => {
    localStorage.setItem('dzdp:merchant-token', auth.accessToken)
    localStorage.setItem('dzdp:merchant-id', String(auth.merchantId))
    localStorage.setItem('dzdp:merchant-account', auth.account)
    localStorage.setItem('dzdp:merchant-region', 'EU')
  }, { ...merchant, account: merchantAccount })
  await page.goto(`${merchantBaseURL}/coupons`)
  await expect(page.getByTestId('coupon-scan-start')).toBeEnabled()

  // Replace the physical camera with a browser MediaStream, keeping video/canvas and QR decoding real.
  await page.evaluate((source) => {
    Object.defineProperty(navigator.mediaDevices, 'getUserMedia', {
      configurable: true,
      value: async () => {
        const image = new Image()
        image.src = source
        await image.decode()
        const canvas = document.createElement('canvas')
        canvas.width = 320
        canvas.height = 320
        const context = canvas.getContext('2d')!
        const draw = () => {
          context.fillStyle = '#fff'
          context.fillRect(0, 0, 320, 320)
          context.drawImage(image, 40, 40, 240, 240)
        }
        draw()
        const stream = canvas.captureStream(10)
        const interval = window.setInterval(draw, 100)
        for (const track of stream.getTracks()) {
          const stop = track.stop.bind(track)
          track.stop = () => { window.clearInterval(interval); stop() }
        }
        ;(window as unknown as { couponCameraStream: MediaStream }).couponCameraStream = stream
        return stream
      },
    })
  }, detail.qrImageUrl)
  const verificationRequests: string[] = []
  const externalRequests: string[] = []
  page.on('request', (request) => {
    if (request.method() === 'POST' && request.url().includes(`/coupons/${code}/verify`)) verificationRequests.push(request.url())
    if (!applicationOrigins.has(new URL(request.url()).origin)) externalRequests.push(request.url())
  })
  await page.getByTestId('coupon-scan-start').click()
  await expect(page.getByTestId('coupon-code-input')).toHaveValue(code)
  await expect(page.getByTestId('coupon-camera-panel')).toHaveCount(0)
  expect(verificationRequests).toEqual([])
  expect(await page.evaluate(() => (window as unknown as { couponCameraStream: MediaStream }).couponCameraStream.getTracks().map((track) => track.readyState))).toEqual(['ended'])
  const verifyResponse = page.waitForResponse((response) => response.url().includes(`/coupons/${code}/verify`))
  await page.getByTestId('coupon-verify-submit').click()
  await expectApiSuccess(await verifyResponse)
  await expect(page.getByTestId('coupon-verify-result')).toContainText('Used')
  await page.getByTestId('coupon-code-input').fill(code)
  const duplicate = page.waitForResponse((response) => response.url().includes(`/coupons/${code}/verify`))
  await page.getByTestId('coupon-verify-submit').click()
  const duplicateResponse = await duplicate
  expect(duplicateResponse.status()).toBe(400)
  await expect(page.getByRole('alert')).toBeVisible()
  expect(verificationRequests).toHaveLength(2)
  expect(externalRequests).toEqual([])
})

test.describe.serial('real backend review flow', () => {
  test('shows safe system health and reflects the active search provider', async ({ browser }) => {
    const adminContext = await browser.newContext()
    const adminPage = await adminContext.newPage()
    const diagnostics = collectBrowserErrors(adminPage)

    try {
      // Keep identity/dashboard requests in flight long enough to catch navigation races seen in CI.
      const network = await adminContext.newCDPSession(adminPage)
      await network.send('Network.enable')
      await network.send('Network.emulateNetworkConditions', {
        offline: false,
        latency: 150,
        downloadThroughput: -1,
        uploadThroughput: -1,
      })
      await loginToAdminConsole(adminPage)

      const healthResponsePromise = adminPage.waitForResponse((response) =>
        response.request().method() === 'GET'
        && response.status() === 200
        && response.url().includes('/api/admin/v1/system/health'),
      )
      await navigateAdmin(adminPage, '/system/health')
      const healthResponse = await healthResponsePromise
      const health = await expectApiSuccess<{
        status: string
        checkedAt: string
        uptimeSeconds: number
        runtimeMode: string
        applicationVersion: string
        release: {
          version: string
          commitSha: string
          buildEnvironment: string
          buildRegion: string
          migrationVersion: number
          runtimeMode: string
          builtAtUtc: string
        }
        activeProfiles: string[]
        components: Array<{
          key: string
          status: string
          checkType: string
          critical: boolean
          latencyMillis: number
          detail: string
        }>
      }>(healthResponse)

      expect(Object.keys(health).sort()).toEqual([
        'activeProfiles',
        'applicationVersion',
        'checkedAt',
        'components',
        'release',
        'runtimeMode',
        'status',
        'uptimeSeconds',
      ])
      expect(['up', 'degraded']).toContain(health.status)
      expect(Object.keys(health.release).sort()).toEqual([
        'buildEnvironment',
        'buildRegion',
        'builtAtUtc',
        'commitSha',
        'migrationVersion',
        'runtimeMode',
        'version',
      ])
      if (remoteAcceptance) {
        expect(expectedCommitSha).toMatch(/^[0-9a-f]{40}$/)
        expect(health.runtimeMode).toBe('test')
        expect(health.release).toMatchObject({
          commitSha: expectedCommitSha,
          buildEnvironment: 'test',
          buildRegion: 'EU',
          runtimeMode: 'test',
        })
        expect(health.release.migrationVersion).toBeGreaterThanOrEqual(3)
        expect(health.activeProfiles).not.toContain('local')
        expect(health.activeProfiles).not.toContain('h2')
      } else {
        expect(health.runtimeMode).toBe('local')
        expect(health.release).toMatchObject({
          version: 'development',
          commitSha: 'unknown',
          buildEnvironment: 'local',
          buildRegion: 'EU',
          migrationVersion: 0,
          runtimeMode: 'local',
        })
        expect(health.activeProfiles).toEqual(['h2', 'local'])
      }
      expect(health.components).toHaveLength(7)
      expect(health.components.map((component) => component.key)).toEqual([
        'database',
        'stateStore',
        'search',
        'fileStorage',
        'payment',
        'verificationCode',
        'push',
      ])
      for (const component of health.components) {
        expect(Object.keys(component).sort()).toEqual([
          'checkType',
          'critical',
          'detail',
          'key',
          'latencyMillis',
          'status',
        ])
      }
      const serializedHealth = JSON.stringify(health).toLowerCase()
      for (const sensitiveMarker of ['jdbc:', 'password', 'secret', 'token']) {
        expect(serializedHealth).not.toContain(sensitiveMarker)
      }

      const healthMain = adminPage.getByRole('main')
      await expect(healthMain.getByRole('heading', { name: '系统健康' })).toBeVisible()
      await expect(healthMain.locator('.system-health-table tbody tr')).toHaveCount(7)
      await expect(healthMain.getByText('MySQL 数据库')).toBeVisible()
      if (remoteAcceptance) {
        await expect(healthMain.getByText('构建目标: test/EU')).toBeVisible()
        await expect(healthMain).toContainText(expectedCommitSha)
      } else {
        await expect(healthMain.getByText('当前由 MySQL 提供搜索，Elasticsearch 未启用')).toBeVisible()
        await expect(healthMain.getByText('构建目标: local/EU')).toBeVisible()
        await expect(healthMain.getByText('提交: unknown · 迁移版本: 0')).toBeVisible()
      }
      await expect(healthMain).not.toContainText('jdbc:h2:')
      await expect(healthMain).not.toContainText('admin123456')
      await expect(healthMain).not.toContainText('Demo123456')

      const overviewResponsePromise = adminPage.waitForResponse((response) =>
        response.request().method() === 'GET'
        && response.status() === 200
        && response.url().includes('/api/admin/v1/search/sync-tasks/overview'),
      )
      const tasksResponsePromise = adminPage.waitForResponse((response) =>
        response.request().method() === 'GET'
        && response.status() === 200
        && /\/api\/admin\/v1\/search\/sync-tasks(?:\?|$)/.test(response.url()),
      )
      await navigateAdmin(adminPage, '/data/search-sync')
      const [overviewResponse, tasksResponse] = await Promise.all([
        overviewResponsePromise,
        tasksResponsePromise,
      ])
      const overview = await expectApiSuccess<{
        provider: string
        enabled: boolean
        indexName: string
        total: number
      }>(overviewResponse)
      const tasks = await expectApiSuccess<{ list: unknown[]; total: number }>(tasksResponse)

      expect(['mysql', 'elasticsearch']).toContain(overview.provider)
      expect(overview.indexName).not.toBe('')
      expect(overview.total).toBeGreaterThanOrEqual(0)
      expect(tasks.total).toBeGreaterThanOrEqual(tasks.list.length)
      const searchMain = adminPage.getByRole('main')
      await expect(searchMain.getByRole('heading', { name: '搜索索引同步' })).toBeVisible()
      await expect(searchMain.getByRole('heading', { name: overview.provider, exact: true })).toBeVisible()
      if (overview.enabled) {
        expect(overview.provider).toBe('elasticsearch')
        await expect(searchMain.getByText('增量同步运行中', { exact: true })).toBeVisible()
        await expect(searchMain.getByRole('button', { name: '重试异常任务' })).toBeEnabled()
        await expect(searchMain.getByRole('button', { name: '全量重建索引' })).toBeEnabled()
      } else {
        expect(overview.provider).toBe('mysql')
        await expect(searchMain.getByText('增量同步已暂停', { exact: true })).toBeVisible()
        await expect(searchMain.getByText('当前 APP_SEARCH_PROVIDER 不是 elasticsearch，任务不会被投递。')).toBeVisible()
        await expect(searchMain.getByRole('button', { name: '重试异常任务' })).toBeDisabled()
        await expect(searchMain.getByRole('button', { name: '全量重建索引' })).toBeDisabled()
      }

      expectNoBrowserFailures(diagnostics)
    } finally {
      await adminContext.close()
    }
  })

  test('governs EU categories cities and areas against the real backend', async ({ request }) => {
    const suffix = Date.now().toString()
    const categoryName = `E2E 分类 ${suffix}`
    const cityCode = `E2E${suffix.slice(-10)}`
    const cityName = `E2E 城市 ${suffix}`
    const areaName = `E2E 商圈 ${suffix}`
    let categoryId: number | undefined
    let cityId: number | undefined
    let areaId: number | undefined

    const adminSession = await expectApiSuccess<{ accessToken: string }>(
      await request.post(`${backendBaseURL}/api/admin/v1/auth/login`, {
        headers: { 'Accept-Language': 'zh-CN', 'X-Region': 'EU' },
        data: { account: adminAccount, password: adminPassword },
      }),
    )
    const headers = adminHeaders(adminSession.accessToken, 'EU')
    const publicHeaders = { 'Accept-Language': 'zh-CN', 'X-Region': 'EU' }

    try {
      const category = await expectApiSuccess<{ id: number; status: number }>(
        await request.post(`${backendBaseURL}/api/admin/v1/categories`, {
          headers,
          data: { parentId: 0, name: categoryName, sortNo: 9999 },
        }),
      )
      categoryId = category.id
      expect(category.status).toBe(1)

      const city = await expectApiSuccess<{ id: number; code: string; status: number }>(
        await request.post(`${backendBaseURL}/api/admin/v1/cities`, {
          headers,
          data: { code: cityCode.toLowerCase(), name: cityName, timeZone: 'Europe/Paris', sortNo: 9999 },
        }),
      )
      cityId = city.id
      expect(city.code).toBe(cityCode)
      expect(city.status).toBe(1)

      const area = await expectApiSuccess<{ id: number; cityId: number; status: number }>(
        await request.post(`${backendBaseURL}/api/admin/v1/areas`, {
          headers,
          data: { cityId, name: areaName, sortNo: 9999 },
        }),
      )
      areaId = area.id
      expect(area.cityId).toBe(cityId)
      expect(area.status).toBe(1)

      const publicCategories = await expectApiSuccess<Array<{ id: number; children: unknown[] }>>(
        await request.get(`${backendBaseURL}/api/c/v1/categories`, { headers: publicHeaders }),
      )
      expect(containsCategoryId(publicCategories, categoryId)).toBeTruthy()

      const publicCities = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities`, { headers: publicHeaders }),
      )
      expect(publicCities.some((item) => item.id === cityId)).toBeTruthy()

      const publicAreas = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities/${cityId}/areas`, { headers: publicHeaders }),
      )
      expect(publicAreas.some((item) => item.id === areaId)).toBeTruthy()

      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/categories/${categoryId}/status`, {
          headers,
          data: { status: 0 },
        }),
      )
      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/areas/${areaId}/status`, {
          headers,
          data: { status: 0 },
        }),
      )
      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/cities/${cityId}/status`, {
          headers,
          data: { status: 0 },
        }),
      )

      const hiddenCategories = await expectApiSuccess<Array<{ id: number; children: unknown[] }>>(
        await request.get(`${backendBaseURL}/api/c/v1/categories`, { headers: publicHeaders }),
      )
      expect(containsCategoryId(hiddenCategories, categoryId)).toBeFalsy()
      const hiddenCities = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities`, { headers: publicHeaders }),
      )
      expect(hiddenCities.some((item) => item.id === cityId)).toBeFalsy()
      const hiddenAreas = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities/${cityId}/areas`, { headers: publicHeaders }),
      )
      expect(hiddenAreas).toEqual([])

      for (const params of [{ categoryId }, { cityId }, { areaId }]) {
        const shops = await expectApiSuccess<{ total: number }>(
          await request.get(`${backendBaseURL}/api/c/v1/search/shops`, { headers: publicHeaders, params }),
        )
        expect(shops.total).toBe(0)
      }

      await expectApiFailure(
        await request.delete(`${backendBaseURL}/api/admin/v1/categories/201`, { headers }),
        409,
      )
      await expectApiFailure(
        await request.delete(`${backendBaseURL}/api/admin/v1/cities/101`, { headers }),
        409,
      )
      await expectApiFailure(
        await request.delete(`${backendBaseURL}/api/admin/v1/areas/1011`, { headers }),
        409,
      )

      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/categories/${categoryId}/status`, {
          headers,
          data: { status: 1 },
        }),
      )
      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/cities/${cityId}/status`, {
          headers,
          data: { status: 1 },
        }),
      )
      await expectApiSuccess(
        await request.put(`${backendBaseURL}/api/admin/v1/areas/${areaId}/status`, {
          headers,
          data: { status: 1 },
        }),
      )

      const restoredCategories = await expectApiSuccess<Array<{ id: number; children: unknown[] }>>(
        await request.get(`${backendBaseURL}/api/c/v1/categories`, { headers: publicHeaders }),
      )
      expect(containsCategoryId(restoredCategories, categoryId)).toBeTruthy()
      const restoredCities = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities`, { headers: publicHeaders }),
      )
      expect(restoredCities.some((item) => item.id === cityId)).toBeTruthy()
      const restoredAreas = await expectApiSuccess<Array<{ id: number }>>(
        await request.get(`${backendBaseURL}/api/c/v1/cities/${cityId}/areas`, { headers: publicHeaders }),
      )
      expect(restoredAreas.some((item) => item.id === areaId)).toBeTruthy()
    } finally {
      if (areaId !== undefined) {
        await request.delete(`${backendBaseURL}/api/admin/v1/areas/${areaId}`, { headers })
      }
      if (cityId !== undefined) {
        await request.delete(`${backendBaseURL}/api/admin/v1/cities/${cityId}`, { headers })
      }
      if (categoryId !== undefined) {
        await request.delete(`${backendBaseURL}/api/admin/v1/categories/${categoryId}`, { headers })
      }
    }
  })

  test('submits an image review against the real backend, approves it, and sees growth records', async ({ page, context, request }) => {
    const reviewContent = `真实后端 E2E 点评 ${Date.now()}`
    const reviewer = await registerSyntheticUser(request, 'image-review')
    await setUserRegion(context, 'CN')

    await page.goto('/')
    await page.getByRole('searchbox', { name: '搜索商户' }).fill('火锅')
    await page.getByRole('button', { name: '搜索' }).click()
    await expect(page).toHaveURL(/\/shops\?keyword=%E7%81%AB%E9%94%85/)
    await expect(page.getByLabel('关键词')).toHaveValue('火锅')
    await expect(page.getByRole('heading', { name: '渝里火锅徐汇店' })).toBeVisible()

    await page.goto('/shops/10001/reviews/new')

    await loginFromAuthDialog(page, reviewer.account, reviewer.password)

    await expect(page).toHaveURL(/\/shops\/10001\/reviews\/new/)
    await expect(page.getByRole('heading', { name: '渝里火锅徐汇店' })).toBeVisible()

    await page.getByLabel('消费金额').fill('128')
    await page.getByLabel('标签').fill('真实E2E,自动回归')
    await page.getByLabel('点评正文').fill(reviewContent)
    await page.locator('input[type="file"]').setInputFiles(reviewUploadPng)
    await expect(page.getByText('已上传 1 张图片。')).toBeVisible()
    await expect(page.locator('.uploaded-image-card')).toHaveCount(1)
    await page.getByRole('button', { name: '提交点评' }).click()

    await expect(page).toHaveURL(/\/user\/reviews\/\d+/)
    await expect(page.getByText(reviewContent)).toBeVisible()
    await expect(page.locator('.status-pill', { hasText: '待审' })).toBeVisible()
    const reviewId = page.url().match(/\/user\/reviews\/(\d+)/)?.[1]
    expect(reviewId).toBeTruthy()

    const adminPage = await context.newPage()
    await loginToAdminConsole(adminPage)

    await navigateAdmin(adminPage, '/audit/reviews')
    await expect(adminPage.getByText(reviewContent)).toBeVisible()
    await adminPage.getByRole('button', { name: '通过点评' }).click()
    await expect(adminPage.getByText(/已审核通过/)).toBeVisible()

    await page.reload()
    await expect(page.locator('.status-pill', { hasText: '通过' })).toBeVisible()

    await page.goto(`/reviews/${reviewId}`)
    await expect(page.getByText(reviewContent)).toBeVisible()
    await expect(page.locator('.photo-grid img')).toHaveCount(1)
    await page.getByRole('button', { name: /给个赞/ }).click()
    await expect(page.getByText('这次点赞真落下去了。')).toBeVisible()
    await expect(page.getByRole('button', { name: /取消点赞 · 1/ })).toBeVisible()

    const commentContent = `真实后端 E2E 评论 ${Date.now()}`
    await page.getByLabel('写条评论').fill(commentContent)
    await page.getByRole('button', { name: '发布评论' }).click()
    await expect(page.getByText('评论已经发出去了。')).toBeVisible()
    await expect(page.getByText(commentContent)).toBeVisible()

    await page.getByRole('button', { name: '举报这条点评' }).click()
    await page.getByLabel('举报理由').fill('真实后端 E2E 举报复核路径')
    await page.getByRole('button', { name: '提交举报' }).click()
    await expect(page.getByText('举报已提交，后台会复核这条点评。')).toBeVisible()

    await page.goto('/user/growth-records')
    await expect(page.getByRole('heading', { name: '每一笔成长值和积分都清晰可查。' })).toBeVisible()
    await expect(page.locator(`a[href="/user/reviews/${reviewId}"]`).first()).toBeVisible()
    await expect(page.getByText('发布点评奖励').first()).toBeVisible()
  })

  test('resumes guest like comment and report actions after login on a public review', async ({ browser, request }) => {
    const reviewContent = `游客续执行 E2E 点评 ${Date.now()}`
    const { reviewId, reviewerSession } = await createApprovedPublicReview(request, reviewContent)
    const actor = await registerSyntheticUser(request, 'guest-resume')

    const likeContext = await browser.newContext()
    try {
      await setUserRegion(likeContext, 'CN')
      const likePage = await likeContext.newPage()
      await likePage.goto(`/reviews/${reviewId}`)
      await expect(likePage.getByText(reviewContent)).toBeVisible()
      await likePage.getByRole('button', { name: /给个赞/ }).click()
      await loginFromAuthDialog(likePage, actor.account, actor.password)
      await expect(likePage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(likePage.getByText('这次点赞真落下去了。')).toBeVisible()
      await expect(likePage.getByRole('button', { name: /取消点赞 · 1/ })).toBeVisible()
    } finally {
      await likeContext.close()
    }

    const commentText = `游客续执行评论 ${Date.now()}`
    const commentContext = await browser.newContext()
    try {
      await setUserRegion(commentContext, 'CN')
      const commentPage = await commentContext.newPage()
      await commentPage.goto(`/reviews/${reviewId}`)
      await expect(commentPage.getByText(reviewContent)).toBeVisible()
      await commentPage.getByLabel('写条评论').fill(commentText)
      await commentPage.getByRole('button', { name: '先登录再说' }).click()
      await loginFromAuthDialog(commentPage, actor.account, actor.password)
      await expect(commentPage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(commentPage.getByText('评论已经发出去了。')).toBeVisible()
      await expect(commentPage.locator('.comment-card').filter({ hasText: commentText })).toHaveCount(1)
    } finally {
      await commentContext.close()
    }

    const reportReason = `游客续执行举报 ${Date.now()}`
    const reportContext = await browser.newContext()
    try {
      await setUserRegion(reportContext, 'CN')
      const reportPage = await reportContext.newPage()
      await reportPage.goto(`/reviews/${reviewId}`)
      await expect(reportPage.getByText(reviewContent)).toBeVisible()
      await reportPage.getByRole('button', { name: '举报这条点评' }).click()
      await reportPage.getByLabel('举报理由').fill(reportReason)
      await reportPage.getByRole('button', { name: '提交举报' }).click()
      await loginFromAuthDialog(reportPage, actor.account, actor.password)
      await expect(reportPage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(reportPage.getByText('举报已提交，后台会复核这条点评。')).toBeVisible()
    } finally {
      await reportContext.close()
    }

    const commentReportReason = `评论举报 E2E ${Date.now()}`
    const seededComment = await expectApiSuccess<{ id: number; content: string }>(
      await request.post(`${backendBaseURL}/api/c/v1/reviews/${reviewId}/comments`, {
        headers: {
          'Accept-Language': 'zh-CN',
          'Authorization': `Bearer ${reviewerSession.accessToken}`,
          'Idempotency-Key': `pw-cmt-${Date.now()}`,
          'X-Region': 'CN',
        },
        data: {
          content: `待举报评论 ${Date.now()}`,
        },
      }),
    )

    const commentReportContext = await browser.newContext()
    try {
      await setUserRegion(commentReportContext, 'CN')
      const commentReportPage = await commentReportContext.newPage()
      await commentReportPage.goto(`/reviews/${reviewId}`)
      await expect(commentReportPage.getByText(seededComment.content)).toBeVisible()
      // Guest report opens auth first; panel appears after login resume.
      await commentReportPage.getByTestId(`comment-report-${seededComment.id}`).click()
      await loginFromAuthDialog(commentReportPage, actor.account, actor.password)
      await expect(commentReportPage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(commentReportPage.getByTestId(`comment-report-reason-${seededComment.id}`)).toBeVisible()
      await commentReportPage.getByTestId(`comment-report-reason-${seededComment.id}`).fill(commentReportReason)
      await commentReportPage.getByTestId(`comment-report-submit-${seededComment.id}`).click()
      await expect(commentReportPage.getByText('评论举报已提交，后台会复核。')).toBeVisible()
    } finally {
      await commentReportContext.close()
    }
  })

  test('completes daily check-in and points mall exchange against the real backend', async ({ page, context, request }) => {
    const shopper = await registerSyntheticUser(request, 'points-shopper')
    await setUserRegion(context, 'CN')
    const adminSession = await expectApiSuccess<{ accessToken: string }>(
      await request.post(`${backendBaseURL}/api/admin/v1/auth/login`, {
        headers: {
          'Accept-Language': 'zh-CN',
          'X-Region': 'CN',
        },
        data: {
          account: adminAccount,
          password: adminPassword,
        },
      }),
    )

    const productName = `E2E 低价积分商品 ${Date.now()}`
    const product = await expectApiSuccess<{ id: number; name: string; pointsPrice: number }>(
      await request.post(`${backendBaseURL}/api/admin/v1/points/products`, {
        headers: adminHeaders(adminSession.accessToken, 'CN'),
        data: {
          name: productName,
          coverImage: '',
          description: 'Playwright 低价兑换样例',
          pointsPrice: 1,
          stock: 20,
          exchangeLimitPerUser: 5,
          fulfillType: 1,
          sort: 0,
        },
      }),
    )
    expect(product.pointsPrice).toBe(1)

    try {
      await page.goto('/user/check-in')
      await loginFromAuthDialog(page, shopper.account, shopper.password)
      await expect(page).toHaveURL(/\/user\/check-in/)
      await expect(page.getByTestId('check-in-status')).toBeVisible()
      await page.getByTestId('check-in-submit').click()
      await expect(page.getByText('签到成功，奖励已入账。')).toBeVisible()
      await expect(page.getByTestId('check-in-status')).toContainText('已签到')
      await expect(page.getByTestId('check-in-submit')).toBeDisabled()

      await page.goto('/user/points-mall')
      await expect(page).toHaveURL(/\/user\/points-mall/)
      await expect(page.getByTestId('points-balance')).toBeVisible()
      await expect(page.getByTestId(`points-product-${product.id}`)).toBeVisible()

      page.once('dialog', async (dialog) => {
        await dialog.accept()
      })
      await page.getByTestId(`points-product-${product.id}`).getByRole('button', { name: '立即兑换' }).click()
      await expect(page.getByTestId('points-success')).toContainText(/兑换成功/)

      await page.getByTestId('points-tab-exchanges').click()
      await expect(page.getByText(productName)).toBeVisible()
    } finally {
      await request.delete(`${backendBaseURL}/api/admin/v1/points/products/${product.id}`, {
        headers: adminHeaders(adminSession.accessToken, 'CN'),
      })
    }
  })

  test('binds a phone, updates password, and completes a successful admin import', async ({ page, context, request }) => {
    const user = await registerSyntheticUser(request, 'profile-password')
    const newPhone = `+4477009${Date.now().toString().slice(-6)}`
    const newPassword = 'ChangedPassw0rd!'
    await setUserRegion(context, 'CN')

    await page.goto('/user/profile')
    await loginFromAuthDialog(page, user.account, user.password)
    await expect(page).toHaveURL(/\/user\/profile/)
    await expect(page.getByRole('heading', { name: '管理个人资料、账号绑定和登录密码。' })).toBeVisible()

    await page.getByLabel('绑定类型').selectOption('phone')
    await page.getByRole('textbox', { name: '手机号' }).fill(newPhone)
    await page.getByRole('button', { name: '发送验证码' }).click()
    await expect(page.getByText('手机号验证码已发送')).toBeVisible()
    await expect(page.getByText('本地 mock 验证码：123456')).toBeVisible()
    await page.getByPlaceholder('输入验证码').fill('123456')
    await page.getByRole('button', { name: '确认绑定' }).click()
    await expect(page.getByText('手机号已绑定成功。')).toBeVisible()
    await expect(page.getByText(newPhone)).toBeVisible()

    await page.getByPlaceholder('已有密码时填写').fill(user.password)
    await page.getByPlaceholder('设置新密码').fill(newPassword)
    await page.getByPlaceholder('再次输入新密码').fill(newPassword)
    await page.getByRole('button', { name: '更新密码' }).click()
    await expect(page.getByText('密码已经更新。')).toBeVisible()

    await expectApiSuccess<{
      accessToken: string
    }>(
      await request.post(`${backendBaseURL}/api/c/v1/auth/login/password`, {
        headers: {
          'Accept-Language': 'zh-CN',
          'X-Region': 'CN',
        },
        data: {
          account: user.account,
          password: newPassword,
        },
      }),
    )

    const adminPage = await context.newPage()
    await loginToAdminConsole(adminPage)

    await navigateAdmin(adminPage, '/data/import')
    await expect(adminPage.getByRole('heading', { name: /先让运营有办法造数/ })).toBeVisible()
    await adminPage.getByRole('button', { name: '开始导入' }).click()
    await expect(adminPage.getByText('导入完成：成功 1，失败 0。')).toBeVisible()
    await expect(adminPage.getByText('seed-cn-shops.json')).toBeVisible()
    await expect(adminPage.getByText('成功 1 / 失败 0')).toBeVisible()
  })

  test('exports privacy data and cancels an account deletion during the cooling-off period', async ({ page, context, request }) => {
    const user = await registerSyntheticUser(request, 'privacy-center')
    await setUserRegion(context, 'CN')
    await page.goto('/user/privacy')
    await loginFromAuthDialog(page, user.account, user.password)
    await expect(page).toHaveURL(/\/user\/privacy/)
    await expect(page.getByRole('heading', { name: '管理数据导出、协议记录、设备和账号删除。' })).toBeVisible()

    await page.getByRole('button', { name: '创建导出任务' }).click()
    await expect(page.getByText('数据导出任务已创建')).toBeVisible()
    const readyTask = page.locator('.privacy-task-card').filter({ hasText: '可下载' }).first()
    await expect(readyTask).toBeVisible()

    const downloadPromise = page.waitForEvent('download')
    await readyTask.getByRole('button', { name: '下载 ZIP' }).click()
    const download = await downloadPromise
    expect(download.suggestedFilename()).toMatch(/^privacy-export-\d+\.zip$/)

    await page.getByLabel('当前已绑定账号').selectOption(user.account)
    await page.getByLabel('删除原因').fill('真实后端 E2E 验证冷静期撤销')
    await page.getByRole('button', { name: '发送注销验证码' }).click()
    await expect(page.getByText('本地 mock 验证码：123456')).toBeVisible()
    await page.getByLabel('验证码').fill('123456')
    await page.getByRole('button', { name: '提交删除申请' }).click()
    await expect(page.getByText('删除申请已进入冷静期')).toBeVisible()
    await expect(page.getByRole('heading', { name: '冷静期中' })).toBeVisible()

    await page.getByRole('button', { name: '撤销删除申请' }).click()
    await expect(page.getByText('删除申请已撤销')).toBeVisible()
    await expect(page.getByRole('heading', { name: '已取消' })).toBeVisible()
  })

  test('enforces EU-only reviewer permissions, route guards, and immediate session revocation', async ({ browser, request }) => {
    const suffix = Date.now().toString()
    const roleCode = `e2e_review_${suffix.slice(-10)}`
    const roleName = `E2E EU 审核员 ${suffix}`
    const account = `e2e.eu.${suffix}`
    const password = 'E2eEuAudit!123'
    const adminContext = await browser.newContext()
    const reviewerContext = await browser.newContext()
    const retainedReviewerContext = await browser.newContext()
    const adminPage = await adminContext.newPage()
    const reviewerPage = await reviewerContext.newPage()
    const retainedReviewerPage = await retainedReviewerContext.newPage()
    const adminDiagnostics = collectBrowserErrors(adminPage)
    const reviewerDiagnostics = collectBrowserErrors(reviewerPage)
    const retainedReviewerDiagnostics = collectBrowserErrors(retainedReviewerPage)

    try {
      await loginToAdminConsole(adminPage)
      const adminMenu = adminPage.getByRole('navigation', { name: '后台菜单' })
      await expect(adminMenu.getByRole('link', { name: '管理员账号', exact: true })).toBeVisible()

      await navigateAdmin(adminPage, '/system/roles')
      await expect(adminPage.getByRole('main').getByRole('heading', { name: '角色与权限' })).toBeVisible()
      await adminPage.getByRole('button', { name: '新建角色' }).click()
      const roleForm = adminPage.getByTestId('role-form')
      await roleForm.getByLabel('角色编码').fill(roleCode)
      await roleForm.getByLabel('角色名称').fill(roleName)
      await roleForm.getByLabel('说明').fill('只允许处理 EU 点评审核的真实 E2E 账号')
      await roleForm.getByRole('checkbox', { name: /查看点评审核.*audit:review:read/ }).check()
      await roleForm.getByRole('button', { name: '保存角色' }).click()
      const roleRow = adminPage.locator('tr').filter({ hasText: roleCode })
      await expect(roleRow).toContainText(roleName)
      await expect(roleRow).toContainText('启用')

      await navigateAdmin(adminPage, '/system/admins')
      await expect(adminPage.getByRole('main').getByRole('heading', { name: '管理员账号' })).toBeVisible()
      await adminPage.getByRole('button', { name: '新建管理员' }).click()
      const accountForm = adminPage.getByTestId('admin-form')
      await accountForm.getByLabel('登录账号').fill(account)
      await accountForm.getByLabel('初始密码').fill(password)
      await accountForm.getByLabel('显示名称').fill(roleName)
      await accountForm.getByRole('checkbox', { name: new RegExp(`${roleName}.*${roleCode}`) }).check()
      await accountForm.getByRole('checkbox', { name: 'EU', exact: true }).check()
      await accountForm.getByRole('button', { name: '保存管理员' }).click()
      const accountRow = adminPage.locator('tr').filter({ hasText: account })
      await expect(accountRow).toContainText(roleName)
      await expect(accountRow).toContainText('EU')
      await expect(accountRow).toContainText('启用')

      await loginToAdminConsole(reviewerPage, account, password)
      await expect(reviewerPage.getByLabel('Region')).toHaveValue('EU')

      const reviewerMenu = reviewerPage.getByRole('navigation', { name: 'Admin navigation' })
      await expect(reviewerMenu.getByRole('link', { name: 'Review Audit', exact: true })).toBeVisible()
      await expect(reviewerMenu).not.toContainText('Merchant Accounts')
      await expect(reviewerMenu).not.toContainText('Admin Accounts')
      await expect(reviewerMenu).not.toContainText('Roles & Permissions')

      await reviewerPage.goto(`${adminBaseURL}/system/admins`)
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))

      const reviewerToken = await reviewerPage.evaluate(() => localStorage.getItem('dzdp:admin-token'))
      expect(reviewerToken).toBeTruthy()
      if (!reviewerToken) {
        throw new Error('受限审核员登录后未保存管理员 token')
      }

      const retainedReviewerStorage = await reviewerPage.evaluate(() => ({
        token: localStorage.getItem('dzdp:admin-token'),
        profile: localStorage.getItem('dzdp:admin-profile'),
        permissions: localStorage.getItem('dzdp:admin-permissions'),
        regions: localStorage.getItem('dzdp:admin-regions'),
        region: localStorage.getItem('dzdp:admin-region'),
      }))
      await retainedReviewerPage.goto(`${adminBaseURL}/login`)
      await retainedReviewerPage.evaluate((storage) => {
        const entries = [
          ['dzdp:admin-token', storage.token],
          ['dzdp:admin-profile', storage.profile],
          ['dzdp:admin-permissions', storage.permissions],
          ['dzdp:admin-regions', storage.regions],
          ['dzdp:admin-region', storage.region],
        ]
        entries.forEach(([key, value]) => {
          if (value !== null) {
            localStorage.setItem(key, value)
          }
        })
      }, retainedReviewerStorage)
      await retainedReviewerPage.goto(`${adminBaseURL}/dashboard`)
      const retainedReviewerMenu = retainedReviewerPage.getByRole('navigation', { name: 'Admin navigation' })
      await expect(retainedReviewerMenu.getByRole('link', { name: 'Review Audit', exact: true })).toBeVisible()

      await expectApiSuccess(
        await request.get(`${backendBaseURL}/api/admin/v1/audit/tasks`, {
          headers: adminHeaders(reviewerToken, 'EU'),
          params: { bizType: 3, page: 1, pageSize: 20 },
        }),
      )
      await expectApiFailure(
        await request.get(`${backendBaseURL}/api/admin/v1/audit/tasks`, {
          headers: adminHeaders(reviewerToken, 'CN'),
          params: { bizType: 3, page: 1, pageSize: 20 },
        }),
        403,
      )
      await expectApiFailure(
        await request.get(`${backendBaseURL}/api/admin/v1/rbac/admins`, {
          headers: adminHeaders(reviewerToken, 'EU'),
        }),
        403,
      )

      await navigateAdmin(adminPage, '/system/roles')
      const refreshedRoleRow = adminPage.locator('tr').filter({ hasText: roleCode })
      await expect(refreshedRoleRow).toContainText(roleName)
      adminPage.once('dialog', (dialog) => dialog.accept())
      await refreshedRoleRow.getByRole('button', { name: '停用', exact: true }).click()
      await expect(refreshedRoleRow).toContainText('已停用')

      const reviewerBeforeNavigation = {
        errors: reviewerDiagnostics.errors.length,
        failedResponses: reviewerDiagnostics.failedResponses.length,
        failedRequests: reviewerDiagnostics.failedRequests.length,
        requests: reviewerDiagnostics.requests.length,
      }
      await reviewerMenu.getByRole('link', { name: 'Review Audit', exact: true }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const revokedReviewerMenu = reviewerPage.getByRole('navigation', { name: 'Admin navigation' })
      await expect(revokedReviewerMenu).not.toContainText('Review Audit')
      await expect(reviewerPage.getByText('This account does not have any dashboard data to view.')).toBeVisible()
      expectNoBrowserFailures(reviewerDiagnostics, reviewerBeforeNavigation)
      expect(
        reviewerDiagnostics.requests.slice(reviewerBeforeNavigation.requests)
          .some((entry) => entry.includes('/api/admin/v1/audit/tasks')),
      ).toBe(false)

      const retainedReviewerBeforeReload = {
        errors: retainedReviewerDiagnostics.errors.length,
        failedResponses: retainedReviewerDiagnostics.failedResponses.length,
        failedRequests: retainedReviewerDiagnostics.failedRequests.length,
      }
      await retainedReviewerPage.reload()
      await expect(retainedReviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const rehydratedReviewerMenu = retainedReviewerPage.getByRole('navigation', { name: 'Admin navigation' })
      await expect(rehydratedReviewerMenu).not.toContainText('Review Audit')
      await expect(retainedReviewerPage.getByText('This account does not have any dashboard data to view.')).toBeVisible()
      expectNoBrowserFailures(retainedReviewerDiagnostics, retainedReviewerBeforeReload)

      const revokedIdentity = await expectApiSuccess<{ permissions: string[] }>(
        await request.get(`${backendBaseURL}/api/admin/v1/auth/me`, {
          headers: adminHeaders(reviewerToken, 'EU'),
        }),
      )
      expect(revokedIdentity.permissions).not.toContain('audit:review:read')
      const revokedTasks = await expectApiSuccess<{ list: unknown[]; total: number }>(
        await request.get(`${backendBaseURL}/api/admin/v1/audit/tasks`, {
          headers: adminHeaders(reviewerToken, 'EU'),
          params: { bizType: 3, page: 1, pageSize: 20 },
        }),
      )
      expect(revokedTasks.list).toEqual([])
      expect(revokedTasks.total).toBe(0)

      await navigateAdmin(adminPage, '/system/roles')
      const reenabledRoleRow = adminPage.locator('tr').filter({ hasText: roleCode })
      await expect(reenabledRoleRow).toContainText('已停用')
      adminPage.once('dialog', (dialog) => dialog.accept())
      await reenabledRoleRow.getByRole('button', { name: '启用', exact: true }).click()
      await expect(reenabledRoleRow.locator('.status-pill')).toHaveText('启用')

      await reviewerPage.reload()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const restoredReviewerMenu = reviewerPage.getByRole('navigation', { name: 'Admin navigation' })
      await expect(restoredReviewerMenu.getByRole('link', { name: 'Review Audit', exact: true })).toBeVisible()
      const initialAuditTasksResponse = reviewerPage.waitForResponse((response) =>
        response.request().method() === 'GET'
        && new URL(response.url()).pathname === '/api/admin/v1/audit/tasks',
      )
      await restoredReviewerMenu.getByRole('link', { name: 'Review Audit', exact: true }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/audit/reviews$`))
      await expectApiSuccess(await initialAuditTasksResponse)
      await expect(reviewerPage.getByText('Loading review audit tasks...')).not.toBeVisible()
      await expect(reviewerPage.getByRole('button', { name: 'Apply filters', exact: true })).toBeVisible()

      await navigateAdmin(adminPage, '/system/admins')
      const refreshedAccountRow = adminPage.locator('tr').filter({ hasText: account })
      await expect(refreshedAccountRow).toContainText(roleName)
      adminPage.once('dialog', (dialog) => dialog.accept())
      await refreshedAccountRow.getByRole('button', { name: '停用', exact: true }).click()
      await expect(refreshedAccountRow).toContainText('已停用')

      const reviewerBeforeAccountRequest = {
        errors: reviewerDiagnostics.errors.length,
        failedResponses: reviewerDiagnostics.failedResponses.length,
        failedRequests: reviewerDiagnostics.failedRequests.length,
      }
      expectNoBrowserFailures(reviewerDiagnostics)
      await reviewerPage.getByLabel('Status').selectOption('1')
      await reviewerPage.getByRole('button', { name: 'Apply filters', exact: true }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/login$`))
      expect(await reviewerPage.evaluate(() => localStorage.getItem('dzdp:admin-token'))).toBeNull()
      expectBrowserAuthInvalidation(reviewerDiagnostics, reviewerBeforeAccountRequest, '/api/admin/v1/audit/tasks')

      const retainedReviewerBeforeAccountReload = {
        errors: retainedReviewerDiagnostics.errors.length,
        failedResponses: retainedReviewerDiagnostics.failedResponses.length,
        failedRequests: retainedReviewerDiagnostics.failedRequests.length,
      }
      await retainedReviewerPage.reload()
      await expect(retainedReviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/login$`))
      expect(await retainedReviewerPage.evaluate(() => localStorage.getItem('dzdp:admin-token'))).toBeNull()
      expectBrowserAuthInvalidation(retainedReviewerDiagnostics, retainedReviewerBeforeAccountReload, '/api/admin/v1/auth/me')

      await expectApiFailure(
        await request.get(`${backendBaseURL}/api/admin/v1/auth/me`, {
          headers: adminHeaders(reviewerToken, 'EU'),
        }),
        401,
      )

      expectNoBrowserFailures(adminDiagnostics)
    } finally {
      await retainedReviewerContext.close()
      await reviewerContext.close()
      await adminContext.close()
    }
  })
})

test('customer and merchant exchange live consultation replies and support closes a ticket', async ({ page, context, browser, request }) => {
  test.setTimeout(60_000)
  const headers = { 'X-Region': 'EU' }
  const auth = await getSharedEuUser(request)
  const userHeaders = { ...headers, Authorization: `Bearer ${auth.accessToken}` }
  await context.addInitScript((session) => {
    localStorage.setItem('dzdp:region', 'EU')
    localStorage.setItem('dzdp:user-access-token', session.accessToken)
    localStorage.setItem('dzdp:user-refresh-token', session.refreshToken)
    localStorage.setItem('dzdp:user-profile', JSON.stringify(session.user))
  }, auth)
  const otherConsultation = await expectApiSuccess<{ id: number }>(
    await request.post(`${backendBaseURL}/api/c/v1/consult/sessions`, {
      headers: userHeaders, data: { shopId: 20002 },
    }),
  )
  const consultation = await expectApiSuccess<{ id: number }>(
    await request.post(`${backendBaseURL}/api/c/v1/consult/sessions`, {
      headers: userHeaders, data: { shopId: 20001 },
    }),
  )
  const merchantContext = await browser.newContext()
  const merchantPage = await merchantContext.newPage()
  const userDiagnostics = collectBrowserErrors(page)
  const merchantDiagnostics = collectBrowserErrors(merchantPage)
  try {
    for (let i = 0; i < 55; i++) {
      await expectApiSuccess(await request.post(`${backendBaseURL}/api/c/v1/consult/sessions/${consultation.id}/messages`, {
        headers: userHeaders, data: { content: `Earlier question ${i}` },
      }))
    }
    // Smaller real API pages exercise navigation with two real shops; response data is never mocked.
    await page.route('**/api/c/v1/consult/sessions?*', async (route) => {
      const url = new URL(route.request().url())
      url.searchParams.set('pageSize', '1')
      await route.continue({ url: url.toString() })
    })
    await page.goto('/user/consult')
    await expect(page.locator(`.session-list a[href="/user/consult/${consultation.id}"]`)).toBeVisible()
    await page.getByTestId('sessions-next').click()
    await expect(page.locator(`.session-list a[href="/user/consult/${otherConsultation.id}"]`)).toBeVisible()
    await expect(page.getByTestId('sessions-next')).toBeDisabled()
    await page.getByTestId('sessions-unread').check()
    await expect(page.getByText('No unread chats.', { exact: true })).toBeVisible()
    await page.getByTestId('sessions-unread').uncheck()
    await page.screenshot({ path: test.info().outputPath('consult-session-list.png'), fullPage: true })
    await page.locator(`.session-list a[href="/user/consult/${consultation.id}"]`).click()
    await expect(page.getByText('Earlier question 54', { exact: true })).toBeVisible()
    await expect(page.getByText('Earlier question 0', { exact: true })).toHaveCount(0)
    await page.getByTestId('consult-load-older').click()
    await expect(page.getByText('Earlier question 0', { exact: true })).toHaveCount(1)
    await expect(page.getByTestId('consult-load-older')).toHaveCount(0)
    await page.locator('.chat-messages').evaluate((list) => { list.scrollTop = 0 })
    await expect(page.getByText('Earlier question 0', { exact: true })).toBeInViewport()
    await page.screenshot({ path: test.info().outputPath('consult-customer-history.png'), fullPage: true })
    await page.getByTestId('consult-input').fill('Is a table available tonight?')
    await page.getByTestId('consult-send').click()
    await expect(page.getByText('Is a table available tonight?', { exact: true })).toBeInViewport()
    await merchantPage.goto(`${merchantBaseURL}/login`)
    await merchantPage.locator('input[autocomplete="username"]').fill(merchantAccount)
    await merchantPage.locator('input[autocomplete="current-password"]').fill(merchantPassword)
    const merchantAccountResponse = merchantPage.waitForResponse((response) =>
      response.request().method() === 'GET'
      && new URL(response.url()).pathname === '/api/b/v1/account/me',
    )
    const merchantDashboardResponse = merchantPage.waitForResponse((response) =>
      response.request().method() === 'GET'
      && new URL(response.url()).pathname === '/api/b/v1/dashboard',
    )
    await merchantPage.locator('form button').click()
    await expect(merchantPage).toHaveURL(`${merchantBaseURL}/dashboard`)
    await expectApiSuccess(await merchantAccountResponse)
    await expectApiSuccess(await merchantDashboardResponse)
    await merchantPage.goto(`${merchantBaseURL}/consult`)
    await merchantPage.getByTestId(`session-${consultation.id}`).click()
    await expect(merchantPage.getByTestId('consult-load-older')).toBeVisible()
    await merchantPage.getByTestId('consult-load-older').click()
    await expect(merchantPage.getByText('Earlier question 0', { exact: true })).toHaveCount(1)
    await expect(merchantPage.getByTestId('consult-load-older')).toHaveCount(0)
    await merchantPage.locator('.messages').evaluate((list) => { list.scrollTop = 0 })
    await expect(merchantPage.getByText('Earlier question 0', { exact: true })).toBeInViewport()
    await merchantPage.screenshot({ path: test.info().outputPath('consult-merchant-history.png'), fullPage: true })
    await expect(merchantPage.locator('.messages')).toContainText('Is a table available tonight?')
    await merchantPage.getByTestId('consult-input').fill('Yes, we have a table at seven.')
    await merchantPage.getByTestId('sessions-unread').check()
    await expect(merchantPage.getByTestId(`session-${consultation.id}`)).toHaveCount(0)
    await expect(merchantPage.getByTestId('consult-input')).toHaveValue('Yes, we have a table at seven.')
    await merchantPage.getByTestId('consult-send').click()
    await expect(merchantPage.getByText('Yes, we have a table at seven.', { exact: true })).toBeInViewport()
    await expect(page.locator('.chat-messages')).toContainText('Yes, we have a table at seven.')
    await page.getByTestId('consult-input').fill('Thank you, see you then.')
    await page.getByTestId('consult-send').click()
    await expect(merchantPage.locator('.messages')).toContainText('Thank you, see you then.')

    await page.goto('/user/tickets')
    await page.getByTestId('ticket-subject').fill('Invoice delivery question')
    await page.getByTestId('ticket-content').fill('Please check my invoice delivery.')
    const createdResponse = page.waitForResponse(r => r.request().method() === 'POST' && new URL(r.url()).pathname === '/api/c/v1/tickets')
    await page.getByTestId('ticket-submit').click()
    const ticket = await expectApiSuccess<{ id: number }>(await createdResponse)
    const detail = page.getByTestId(`ticket-detail-${ticket.id}`)
    await expect(detail).toBeVisible()
    const admin = await expectApiSuccess<{ accessToken: string }>(await request.post(`${backendBaseURL}/api/admin/v1/auth/login`, {
      data: { account: adminAccount, password: adminPassword },
    }))
    await expectApiSuccess(await request.post(`${backendBaseURL}/api/admin/v1/tickets/${ticket.id}/reply`, {
      headers: adminHeaders(admin.accessToken, 'EU'), data: { content: 'Please confirm your invoice title.' },
    }))
    await page.getByTestId(`ticket-${ticket.id}`).click()
    await expect(detail).toContainText('Please confirm your invoice title.')
    await page.getByTestId('ticket-reply').fill('The title is correct.')
    await detail.locator('form button').click()
    await expect(detail).toContainText('The title is correct.')
    await expectApiSuccess(await request.post(`${backendBaseURL}/api/admin/v1/tickets/${ticket.id}/status`, {
      headers: adminHeaders(admin.accessToken, 'EU'), data: { status: 4 },
    }))
    await page.getByTestId(`ticket-${ticket.id}`).click()
    await expect(page.getByTestId('ticket-reply')).toHaveCount(0)
    await expectApiFailure(await request.post(`${backendBaseURL}/api/c/v1/tickets/${ticket.id}/messages`, {
      headers: userHeaders, data: { content: 'Not allowed after close' },
    }), 409)
    expectNoBrowserFailures(userDiagnostics)
    expectNoBrowserFailures(merchantDiagnostics)
  } finally {
    await merchantContext.close()
  }
})

test('admin delivers a private invoice PDF and customer explicitly confirms receipt', async ({ page, context, browser, request }) => {
  const headers = { 'X-Region': 'EU' }
  const auth = await getSharedEuUser(request)
  const account = auth.account
  const userHeaders = { ...headers, Authorization: `Bearer ${auth.accessToken}` }
  const order = await expectApiSuccess<{ id: number }>(await request.post(`${backendBaseURL}/api/c/v1/orders`, {
    headers: userHeaders, data: { dealId: 41001, quantity: 1 },
  }))
  await expectApiSuccess(await request.post(`${backendBaseURL}/api/c/v1/orders/${order.id}/pay/mock-complete`, { headers: userHeaders }))
  const title = await expectApiSuccess<{ id: number }>(await request.post(`${backendBaseURL}/api/c/v1/invoices/titles`, {
    headers: userHeaders, data: { titleType: 2, name: 'Synthetic test company', taxNo: 'SYNTHETIC-TAX', email: account },
  }))
  await context.addInitScript((session) => {
    localStorage.setItem('dzdp:region', 'EU')
    localStorage.setItem('dzdp:user-access-token', session.accessToken)
    localStorage.setItem('dzdp:user-refresh-token', session.refreshToken)
    localStorage.setItem('dzdp:user-profile', JSON.stringify(session.user))
  }, auth)
  await page.goto(`/user/invoices?orderId=${order.id}`)
  await page.getByTestId('invoice-title').selectOption(String(title.id))
  const applied = page.waitForResponse(r => r.request().method() === 'POST' && new URL(r.url()).pathname === '/api/c/v1/invoices')
  await page.getByTestId('invoice-request').click()
  const invoice = await expectApiSuccess<{ id: number }>(await applied)
  const adminContext = await browser.newContext()
  const adminPage = await adminContext.newPage()
  const userDiagnostics = collectBrowserErrors(page)
  const adminDiagnostics = collectBrowserErrors(adminPage)
  try {
    await loginToAdminConsole(adminPage)
    await adminPage.locator('.admin-topbar select').selectOption('EU')
    await navigateAdmin(adminPage, '/data/invoices')
    const row = adminPage.getByTestId(`admin-invoice-${invoice.id}`)
    await expect(row).toContainText('Synthetic test company')
    await adminPage.getByTestId(`invoice-number-${invoice.id}`).fill(`TEST-PDF-${invoice.id}`)
    await adminPage.getByTestId(`invoice-file-${invoice.id}`).setInputFiles('../scripts/ci/fixtures/invoice.pdf')
    await adminPage.getByTestId(`invoice-upload-${invoice.id}`).click()
    await expect(row).toContainText('Delivered, awaiting confirmation')
    await page.getByRole('button', { name: 'Refresh', exact: true }).click()
    const downloadEvent = page.waitForEvent('download')
    await page.getByTestId(`invoice-download-${invoice.id}`).click()
    const download = await downloadEvent
    expect(download.suggestedFilename()).toBe(`invoice-${invoice.id}.pdf`)
    const stream = await download.createReadStream()
    const chunks: Buffer[] = []
    for await (const chunk of stream!) chunks.push(Buffer.from(chunk))
    expect(Buffer.concat(chunks).toString()).toContain('Synthetic test invoice')
    const before = await expectApiSuccess<{ list: Array<{ id: number; receivedAt?: string }> }>(await request.get(`${backendBaseURL}/api/c/v1/invoices`, { headers: userHeaders }))
    expect(before.list.find(i => i.id === invoice.id)?.receivedAt).toBeFalsy()
    await page.getByTestId(`invoice-receipt-${invoice.id}`).click()
    await expect(page.getByTestId(`invoice-${invoice.id}`)).toContainText('Receipt confirmed')
    await adminPage.getByRole('button', { name: 'Refresh', exact: true }).click()
    await expect(row).toContainText('Customer confirmed receipt')
    await page.screenshot({ path: test.info().outputPath('invoice-customer.png'), fullPage: true })
    await adminPage.screenshot({ path: test.info().outputPath('invoice-admin.png'), fullPage: true })
    expectNoBrowserFailures(userDiagnostics)
    expectNoBrowserFailures(adminDiagnostics)
  } finally { await adminContext.close() }
  await expectApiFailure(await request.get(`${backendBaseURL}/api/c/v1/invoices/${invoice.id}/document`), 401)
})
