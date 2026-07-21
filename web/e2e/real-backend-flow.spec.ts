import { Buffer } from 'node:buffer'
import { expect, test, type APIRequestContext, type APIResponse, type Page } from '@playwright/test'

const adminPort = Number(process.env.PLAYWRIGHT_ADMIN_PORT ?? 16174)
const adminBaseURL = `http://127.0.0.1:${adminPort}`
const backendPort = Number(process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080)
const backendBaseURL = `http://127.0.0.1:${backendPort}`
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
  await expect(authDialog.getByRole('heading', { name: '先把登录链路跑顺' })).toBeVisible()
  await authDialog.getByLabel('邮箱 / 手机号').fill(account)
  await authDialog.getByLabel('密码').fill(password)
  await authDialog.getByRole('button', { name: '登录', exact: true }).click()
}

async function expectApiSuccess<T>(response: APIResponse) {
  expect(response.ok()).toBeTruthy()
  const body = (await response.json()) as {
    code: number
    message: string
    data: T
  }
  expect(body.code).toBe(0)
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

async function createApprovedPublicReview(request: APIRequestContext, content: string) {
  const reviewerSession = await expectApiSuccess<{
    accessToken: string
  }>(
    await request.post(`${backendBaseURL}/api/c/v1/auth/login/password`, {
      headers: {
        'Accept-Language': 'zh-CN',
        'X-Region': 'CN',
      },
      data: {
        account: 'demo.cn@example.com',
        password: 'Demo123456',
      },
    }),
  )

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
        account: 'admin',
        password: 'admin123456',
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

  return createdReview.id
}

test.describe.serial('real backend review flow', () => {
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
        data: { account: 'admin', password: 'admin123456' },
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
          data: { code: cityCode.toLowerCase(), name: cityName, sortNo: 9999 },
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

  test('submits an image review against H2 backend, approves it, and sees growth records', async ({ page, context }) => {
    const reviewContent = `真实后端 E2E 点评 ${Date.now()}`

    await page.goto('/')
    await page.getByRole('searchbox', { name: '搜索商户' }).fill('火锅')
    await page.getByRole('button', { name: '搜索' }).click()
    await expect(page).toHaveURL(/\/shops\?keyword=%E7%81%AB%E9%94%85/)
    await expect(page.getByLabel('关键词')).toHaveValue('火锅')
    await expect(page.getByText('渝里火锅徐汇店')).toBeVisible()

    await page.goto('/shops/10001/reviews/new')

    await loginFromAuthDialog(page, 'demo.cn@example.com', 'Demo123456')

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
    await adminPage.goto(`${adminBaseURL}/login`)
    await adminPage.getByRole('button', { name: '进入后台' }).click()
    await expect(adminPage).toHaveURL(/\/dashboard/)

    await adminPage.goto(`${adminBaseURL}/audit/reviews`)
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
    await expect(page.getByRole('heading', { name: /每一笔成长值和积分都摊开看/ })).toBeVisible()
    await expect(page.locator(`a[href="/user/reviews/${reviewId}"]`).first()).toBeVisible()
    await expect(page.getByText('发布点评奖励').first()).toBeVisible()
  })

  test('resumes guest like comment and report actions after login on a public review', async ({ browser, request }) => {
    const reviewContent = `游客续执行 E2E 点评 ${Date.now()}`
    const reviewId = await createApprovedPublicReview(request, reviewContent)

    const likeContext = await browser.newContext()
    try {
      const likePage = await likeContext.newPage()
      await likePage.goto(`/reviews/${reviewId}`)
      await expect(likePage.getByText(reviewContent)).toBeVisible()
      await likePage.getByRole('button', { name: /给个赞/ }).click()
      await loginFromAuthDialog(likePage, '+447700900999', 'Demo123456')
      await expect(likePage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(likePage.getByText('这次点赞真落下去了。')).toBeVisible()
      await expect(likePage.getByRole('button', { name: /取消点赞 · 1/ })).toBeVisible()
    } finally {
      await likeContext.close()
    }

    const commentText = `游客续执行评论 ${Date.now()}`
    const commentContext = await browser.newContext()
    try {
      const commentPage = await commentContext.newPage()
      await commentPage.goto(`/reviews/${reviewId}`)
      await expect(commentPage.getByText(reviewContent)).toBeVisible()
      await commentPage.getByLabel('写条评论').fill(commentText)
      await commentPage.getByRole('button', { name: '先登录再说' }).click()
      await loginFromAuthDialog(commentPage, '+447700900999', 'Demo123456')
      await expect(commentPage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(commentPage.getByText('评论已经发出去了。')).toBeVisible()
      await expect(commentPage.locator('.comment-card').filter({ hasText: commentText })).toHaveCount(1)
    } finally {
      await commentContext.close()
    }

    const reportReason = `游客续执行举报 ${Date.now()}`
    const reportContext = await browser.newContext()
    try {
      const reportPage = await reportContext.newPage()
      await reportPage.goto(`/reviews/${reviewId}`)
      await expect(reportPage.getByText(reviewContent)).toBeVisible()
      await reportPage.getByRole('button', { name: '举报这条点评' }).click()
      await reportPage.getByLabel('举报理由').fill(reportReason)
      await reportPage.getByRole('button', { name: '提交举报' }).click()
      await loginFromAuthDialog(reportPage, '+447700900999', 'Demo123456')
      await expect(reportPage).toHaveURL(new RegExp(`/reviews/${reviewId}$`))
      await expect(reportPage.getByText('举报已提交，后台会复核这条点评。')).toBeVisible()
    } finally {
      await reportContext.close()
    }
  })

  test('binds a phone, updates password, and completes a successful admin import', async ({ page, context, request }) => {
    const newPhone = `+4477009${Date.now().toString().slice(-6)}`
    const newPassword = 'Demo123456!'

    await page.goto('/user/profile')
    await loginFromAuthDialog(page, 'demo.cn@example.com', 'Demo123456')
    await expect(page).toHaveURL(/\/user\/profile/)
    await expect(page.getByRole('heading', { name: /资料、绑定、改密都得在这儿闭环/ })).toBeVisible()

    await page.getByLabel('绑定类型').selectOption('phone')
    await page.getByRole('textbox', { name: '手机号' }).fill(newPhone)
    await page.getByRole('button', { name: '发送验证码' }).click()
    await expect(page.getByText('手机号验证码已发送')).toBeVisible()
    await expect(page.getByText('本地 mock 验证码：123456')).toBeVisible()
    await page.getByPlaceholder('输入验证码').fill('123456')
    await page.getByRole('button', { name: '确认绑定' }).click()
    await expect(page.getByText('手机号已绑定成功。')).toBeVisible()
    await expect(page.getByText(newPhone)).toBeVisible()

    await page.getByPlaceholder('已有密码时填写').fill('Demo123456')
    await page.getByPlaceholder('设置新密码').fill(newPassword)
    await page.getByPlaceholder('再输一遍新密码').fill(newPassword)
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
          account: 'demo.cn@example.com',
          password: newPassword,
        },
      }),
    )

    const adminPage = await context.newPage()
    await adminPage.goto(`${adminBaseURL}/login`)
    await adminPage.getByRole('button', { name: '进入后台' }).click()
    await expect(adminPage).toHaveURL(/\/dashboard/)

    await adminPage.goto(`${adminBaseURL}/data/import`)
    await expect(adminPage.getByRole('heading', { name: /先让运营有办法造数/ })).toBeVisible()
    await adminPage.getByRole('button', { name: '开始导入' }).click()
    await expect(adminPage.getByText('导入完成：成功 1，失败 0。')).toBeVisible()
    await expect(adminPage.getByText('seed-cn-shops.json')).toBeVisible()
    await expect(adminPage.getByText('成功 1 / 失败 0')).toBeVisible()
  })

  test('exports privacy data and cancels an account deletion during the cooling-off period', async ({ page }) => {
    await page.goto('/user/privacy')
    await loginFromAuthDialog(page, '+447700900999', 'Demo123456')
    await expect(page).toHaveURL(/\/user\/privacy/)
    await expect(page.getByRole('heading', { name: /你的数据能带走/ })).toBeVisible()

    await page.getByRole('button', { name: '创建导出任务' }).click()
    await expect(page.getByText('数据导出任务已创建')).toBeVisible()
    const readyTask = page.locator('.privacy-task-card').filter({ hasText: '可下载' }).first()
    await expect(readyTask).toBeVisible()

    const downloadPromise = page.waitForEvent('download')
    await readyTask.getByRole('button', { name: '下载 ZIP' }).click()
    const download = await downloadPromise
    expect(download.suggestedFilename()).toMatch(/^privacy-export-\d+\.zip$/)

    await page.getByLabel('当前已绑定账号').selectOption('+447700900999')
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
      await adminPage.goto(`${adminBaseURL}/login`)
      await adminPage.getByLabel('账号').fill('admin')
      await adminPage.getByLabel('密码').fill('admin123456')
      await adminPage.getByRole('button', { name: '进入后台' }).click()
      await expect(adminPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const adminMenu = adminPage.getByRole('navigation', { name: '后台菜单' })
      await expect(adminMenu.getByRole('link', { name: '管理员账号', exact: true })).toBeVisible()

      await adminPage.goto(`${adminBaseURL}/system/roles`)
      await expect(adminPage.getByRole('main').getByRole('heading', { name: '角色与权限' })).toBeVisible()
      await adminPage.getByRole('button', { name: '新建角色' }).click()
      const roleForm = adminPage.getByTestId('role-form')
      await roleForm.getByLabel('角色编码').fill(roleCode)
      await roleForm.getByLabel('角色名称').fill(roleName)
      await roleForm.getByLabel('说明').fill('只允许处理 EU 点评审核的真实 H2 E2E 账号')
      await roleForm.getByRole('checkbox', { name: /查看点评审核.*audit:review:read/ }).check()
      await roleForm.getByRole('button', { name: '保存角色' }).click()
      const roleRow = adminPage.locator('tr').filter({ hasText: roleCode })
      await expect(roleRow).toContainText(roleName)
      await expect(roleRow).toContainText('启用')

      await adminPage.goto(`${adminBaseURL}/system/admins`)
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

      await reviewerPage.goto(`${adminBaseURL}/login`)
      await reviewerPage.getByLabel('账号').fill(account)
      await reviewerPage.getByLabel('密码').fill(password)
      await reviewerPage.getByRole('button', { name: '进入后台' }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      await expect(reviewerPage.getByLabel('区域')).toHaveValue('EU')

      const reviewerMenu = reviewerPage.getByRole('navigation', { name: '后台菜单' })
      await expect(reviewerMenu.getByRole('link', { name: '点评审核', exact: true })).toBeVisible()
      await expect(reviewerMenu).not.toContainText('商户管理')
      await expect(reviewerMenu).not.toContainText('管理员账号')
      await expect(reviewerMenu).not.toContainText('角色权限')

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
      const retainedReviewerMenu = retainedReviewerPage.getByRole('navigation', { name: '后台菜单' })
      await expect(retainedReviewerMenu.getByRole('link', { name: '点评审核', exact: true })).toBeVisible()

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

      await adminPage.goto(`${adminBaseURL}/system/roles`)
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
      await reviewerMenu.getByRole('link', { name: '点评审核', exact: true }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const revokedReviewerMenu = reviewerPage.getByRole('navigation', { name: '后台菜单' })
      await expect(revokedReviewerMenu).not.toContainText('点评审核')
      await expect(reviewerPage.getByText('当前账号暂无可查看的控制台数据。')).toBeVisible()
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
      const rehydratedReviewerMenu = retainedReviewerPage.getByRole('navigation', { name: '后台菜单' })
      await expect(rehydratedReviewerMenu).not.toContainText('点评审核')
      await expect(retainedReviewerPage.getByText('当前账号暂无可查看的控制台数据。')).toBeVisible()
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

      await adminPage.goto(`${adminBaseURL}/system/roles`)
      const reenabledRoleRow = adminPage.locator('tr').filter({ hasText: roleCode })
      await expect(reenabledRoleRow).toContainText('已停用')
      adminPage.once('dialog', (dialog) => dialog.accept())
      await reenabledRoleRow.getByRole('button', { name: '启用', exact: true }).click()
      await expect(reenabledRoleRow.locator('.status-pill')).toHaveText('启用')

      await reviewerPage.reload()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/dashboard$`))
      const restoredReviewerMenu = reviewerPage.getByRole('navigation', { name: '后台菜单' })
      await expect(restoredReviewerMenu.getByRole('link', { name: '点评审核', exact: true })).toBeVisible()
      const initialAuditTasksResponse = reviewerPage.waitForResponse((response) =>
        response.request().method() === 'GET'
        && response.status() === 200
        && response.url().includes('/api/admin/v1/audit/tasks'),
      )
      await restoredReviewerMenu.getByRole('link', { name: '点评审核', exact: true }).click()
      await expect(reviewerPage).toHaveURL(new RegExp(`${adminBaseURL}/audit/reviews$`))
      await initialAuditTasksResponse
      await expect(reviewerPage.getByText('点评审核任务加载中...')).not.toBeVisible()
      await expect(reviewerPage.getByRole('button', { name: '应用筛选', exact: true })).toBeVisible()

      await adminPage.goto(`${adminBaseURL}/system/admins`)
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
      await reviewerPage.getByLabel('状态').selectOption('1')
      await reviewerPage.getByRole('button', { name: '应用筛选', exact: true }).click()
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
