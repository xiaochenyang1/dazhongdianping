import { Buffer } from 'node:buffer'
import { expect, test, type APIResponse, type Response } from '@playwright/test'

const backend = `http://127.0.0.1:${process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080}`
const adminURL = `http://127.0.0.1:${process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174}`

// Run only against a dedicated feature-enabled local backend; normal launch tests keep rewards closed.
test.skip(process.env.PLAYWRIGHT_REAL_BACKEND !== '1' || process.env.PLAYWRIGHT_CREATOR_REVIEW !== '1',
  'requires PLAYWRIGHT_REAL_BACKEND=1, PLAYWRIGHT_CREATOR_REVIEW=1 and a feature-enabled test backend')

async function data<T>(response: APIResponse | Response): Promise<T> {
  const body = await response.json()
  expect(response.ok(), `${response.status()} ${body.message}`).toBeTruthy()
  expect(body.code).toBe(0)
  return body.data as T
}

for (const region of ['CN', 'EU'] as const) {
  test(`${region}: claim, reject, resubmit, approve and retain one frozen reward`, async ({ page, context, request }, testInfo) => {
    test.setTimeout(90_000)
    if (region === 'EU') await page.setViewportSize({ width: 390, height: 844 })
    const headers = { 'X-Region': region }
    const launch = await data<{ creatorRewards: boolean }>(await request.get(`${backend}/api/c/v1/launch-config`, { headers }))
    expect(launch.creatorRewards, 'Use an isolated backend with APP_LAUNCH_DEFERRED_FEATURES_ENABLED=true and APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED=true').toBe(true)
    const account = `creator-${region.toLowerCase()}-${Date.now()}@example.com`
    await data(await request.post(`${backend}/api/c/v1/auth/send-code`, {
      headers, data: { scene: 'register', type: 'email', account, deviceId: account },
    }))
    const session = await data<{ accessToken: string; refreshToken: string; user: { id: number } }>(
      await request.post(`${backend}/api/c/v1/auth/register`, {
        headers, data: { type: 'email', account, code: '123456', password: 'Passw0rd!', preferredRegion: region },
      }),
    )
    const userHeaders = { ...headers, Authorization: `Bearer ${session.accessToken}` }
    const admin = await data<{ accessToken: string }>(await request.post(`${backend}/api/admin/v1/auth/login`, {
      headers, data: { account: 'admin', password: 'admin123456' },
    }))
    const adminHeaders = { ...headers, Authorization: `Bearer ${admin.accessToken}` }
    const title = `Creator task ${region} ${Date.now()}`
    const task = await data<{ id: number }>(await request.post(`${backend}/api/admin/v1/creator/tasks`, {
      headers: adminHeaders, data: { title, description: 'Describe the visit and include a photo.', rewardPoints: 20, status: 1 },
    }))
    const upload = await data<{ url: string }>(await request.post(`${backend}/api/c/v1/files/upload`, {
      headers: userHeaders,
      multipart: { file: { name: 'creator-work.png', mimeType: 'image/png', buffer: Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR42mP8z8Dwn4GBgYGJAQoAHxcCAr7afKQAAAAASUVORK5CYII=', 'base64') } },
    }))
    const post = await data<{ id: number }>(await request.post(`${backend}/api/c/v1/posts`, {
      headers: userHeaders, data: { title: 'My restaurant visit', content: 'A detailed account of the menu and service.', contentType: 1, shopId: region === 'CN' ? 10001 : 20001, images: [upload.url], topics: [] },
    }))
    const auditTasks = await data<{ list: Array<{ id: number; bizId: number }> }>(await request.get(`${backend}/api/admin/v1/audit/tasks`, {
      headers: adminHeaders, params: { bizType: 4, status: 0, page: 1, pageSize: 50 },
    }))
    const audit = auditTasks.list.find(item => item.bizId === post.id)
    expect(audit).toBeTruthy()
    await data(await request.post(`${backend}/api/admin/v1/audit/tasks/${audit!.id}/pass`, {
      headers: adminHeaders, data: { remark: 'Published for creator review integration test' },
    }))
    const before = await data<{ points: number }>(await request.get(`${backend}/api/c/v1/user/me`, { headers: userHeaders }))
    await page.addInitScript(({ auth, region }) => {
      localStorage.setItem('dzdp:region', region)
      localStorage.setItem('dzdp:user-access-token', auth.accessToken)
      localStorage.setItem('dzdp:user-refresh-token', auth.refreshToken)
      localStorage.setItem('dzdp:user-profile', JSON.stringify(auth.user))
    }, { auth: session, region })
    await page.goto('/user/creator')
    const card = page.getByTestId(`creator-task-${task.id}`)
    await card.getByRole('button', { name: /^(领取|Claim)$/ }).click()
    await expect(card.getByRole('button', { name: /^(提交成果|Submit work)$/ })).toBeEnabled()
    await data(await request.put(`${backend}/api/admin/v1/creator/tasks/${task.id}`, {
      headers: adminHeaders, data: { title: 'Changed future requirements', description: 'New future terms', rewardPoints: 999, status: 0 },
    }))
    await page.getByTestId('creator-refresh').click()
    await expect(card).toContainText(title)
    await expect(card).toContainText('20')
    await expect(card).not.toContainText('999')
    await card.getByRole('button', { name: /^(提交成果|Submit work)$/ }).click()
    await page.getByTestId('evidence-type').selectOption('post')
    await expect(page.getByTestId('evidence-select')).toBeEnabled()
    await page.getByTestId('evidence-select').selectOption(String(post.id))
    await page.getByTestId('submission-note').fill('Original explanation')
    await page.getByTestId('submit-work').click()
    await expect(card).toContainText(region === 'CN' ? '待审核' : 'Awaiting review')
    await expect(card.locator('button')).toHaveCount(0)
    const pending = await data<{ list: Array<{ id: number; taskId: number; submissionVersion: number; evidenceHash: string }> }>(
      await request.get(`${backend}/api/admin/v1/creator/claims`, { headers: adminHeaders, params: { status: 3, pageSize: 50 } }),
    )
    const claim = pending.list.find(item => item.taskId === task.id)!
    expect(claim.submissionVersion).toBe(1)
    expect(claim.evidenceHash).toMatch(/^[a-f0-9]{64}$/)

    const adminPage = await context.newPage()
    await adminPage.setViewportSize({ width: 1280, height: 960 })
    await adminPage.addInitScript(region => localStorage.setItem('dzdp:admin-region', region), region)
    await adminPage.goto(`${adminURL}/login`)
    await adminPage.locator('input[autocomplete="username"]').fill('admin')
    await adminPage.locator('input[autocomplete="current-password"]').fill('admin123456')
    await adminPage.getByRole('button', { name: /进入后台|Enter console/ }).click()
    await expect(adminPage).toHaveURL(`${adminURL}/dashboard`)
    await adminPage.goto(`${adminURL}/operations/creator`)
    await adminPage.getByTestId(`creator-claim-${claim.id}`).getByRole('button').click()
    const detail = adminPage.getByTestId('creator-claim-detail')
    await expect(detail).toContainText('A detailed account of the menu and service.')
    await expect(detail).toContainText('Describe the visit and include a photo.')
    await expect(detail.locator('img')).toHaveCount(1)
    await expect.poll(() => detail.locator('img').evaluate((image: HTMLImageElement) => image.naturalWidth)).toBeGreaterThan(0)
    await adminPage.screenshot({ path: testInfo.outputPath(`creator-${region}-review.png`), fullPage: true })
    await adminPage.getByTestId('creator-reject').click()
    await expect(adminPage.getByRole('alert')).toContainText(region === 'CN' ? '请填写驳回原因' : 'Enter a reason for rejection')
    await adminPage.getByTestId('creator-review-note').fill('Explain the menu photo')
    await adminPage.getByTestId('creator-reject').click()
    await expect(detail).toContainText(region === 'CN' ? '已驳回' : 'Rejected')
    expect((await data<{ points: number }>(await request.get(`${backend}/api/c/v1/user/me`, { headers: userHeaders }))).points).toBe(before.points)

    await page.getByTestId('creator-refresh').click()
    await expect(card).toContainText('Explain the menu photo')
    await card.getByRole('button', { name: /^(提交成果|Submit work)$/ }).click()
    await expect(page.getByTestId('submission-note')).toHaveValue('Original explanation')
    await expect(page.getByTestId('evidence-select')).toBeEnabled()
    await page.getByTestId('evidence-select').selectOption(String(post.id))
    await page.getByTestId('submission-note').fill('The photo shows the full menu')
    await page.screenshot({ path: testInfo.outputPath(`creator-${region}-resubmit.png`), fullPage: true })
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.getByTestId('submit-work').click()
    await expect(card).toContainText(region === 'CN' ? '待审核' : 'Awaiting review')
    const stale = await request.post(`${backend}/api/admin/v1/creator/claims/${claim.id}/review`, {
      headers: adminHeaders, data: { approved: true, submissionVersion: 1, evidenceHash: claim.evidenceHash },
    })
    expect(stale.status()).toBe(409)

    await adminPage.getByRole('button', { name: /^(刷新|Refresh)$/ }).click()
    await adminPage.getByTestId(`creator-claim-${claim.id}`).getByRole('button').click()
    await expect(detail).toContainText('The photo shows the full menu')
    const approved = adminPage.waitForResponse(response => response.request().method() === 'POST' && response.url().endsWith(`/creator/claims/${claim.id}/review`))
    await adminPage.getByTestId('creator-approve').click()
    const award = await data<{ submissionVersion: number; evidenceHash: string }>(await approved)
    expect(award.submissionVersion).toBe(2)
    await expect(detail).toContainText(region === 'CN' ? '已发放积分' : 'Points awarded')
    await data(await request.post(`${backend}/api/admin/v1/creator/claims/${claim.id}/review`, {
      headers: adminHeaders, data: { approved: true, submissionVersion: 2, evidenceHash: award.evidenceHash },
    }))
    expect((await data<{ points: number }>(await request.get(`${backend}/api/c/v1/user/me`, { headers: userHeaders }))).points).toBe(before.points + 20)
    const ledger = await data<{ list: Array<{ action: string; changeAmount: number }> }>(await request.get(`${backend}/api/c/v1/user/growth/records`, { headers: userHeaders }))
    expect(ledger.list.filter(item => item.action === 'creator_task')).toEqual([expect.objectContaining({ changeAmount: 20 })])
    const legacy = await request.post(`${backend}/api/c/v1/creator/tasks/${task.id}/complete`, { headers: userHeaders })
    expect(legacy.status()).toBe(409)
    await page.getByTestId('creator-refresh').click()
    await expect(card).toContainText(region === 'CN' ? '已发放积分' : 'Points awarded')
    await expect(card.locator('button')).toHaveCount(0)
    await page.screenshot({ path: testInfo.outputPath(`creator-${region}-awarded.png`), fullPage: true })
    await adminPage.close()
  })
}
