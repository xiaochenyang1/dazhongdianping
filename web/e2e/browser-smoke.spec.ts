import { expect, test } from '@playwright/test'

const adminPort = Number(process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174)
const adminBaseURL = `http://127.0.0.1:${adminPort}`

function envelope(data: unknown) {
  return {
    code: 0,
    message: 'OK',
    messageKey: 'ok',
    data,
    traceId: 'pw-smoke',
  }
}

test.beforeEach(async ({ page }) => {
  await page.route('**/api/c/v1/auth/login/password', async (route) => {
    await route.fulfill({
      json: envelope({
        accessToken: 'smoke-access-token',
        refreshToken: 'smoke-refresh-token',
        user: {
          id: 9527,
          nickname: '冒烟用户',
          avatar: 'https://example.test/avatar.jpg',
          preferredRegion: 'CN',
        },
      }),
    })
  })

  await page.route('**/api/c/v1/user/me', async (route) => {
    await route.fulfill({
      json: envelope({
        id: 9527,
        nickname: '冒烟用户',
        avatar: 'https://example.test/avatar.jpg',
        email: 'smoke@example.test',
        phone: null,
        hasPassword: true,
        gender: 0,
        signature: '冒烟测试账号',
        preferredRegion: 'CN',
        level: 2,
        points: 15,
        growthValue: 30,
      }),
    })
  })

  await page.route('**/api/c/v1/categories', async (route) => {
    await route.fulfill({
      json: envelope([
        {
          id: 1,
          name: '美食',
          children: [{ id: 11, name: '火锅' }],
        },
      ]),
    })
  })

  await page.route('**/api/c/v1/cities', async (route) => {
    await route.fulfill({
      json: envelope([{ id: 1, name: '上海' }]),
    })
  })

  await page.route('**/api/c/v1/cities/1/areas', async (route) => {
    await route.fulfill({
      json: envelope([{ id: 101, name: '人民广场' }]),
    })
  })

  await page.route('**/api/c/v1/home/banners**', async (route) => {
    await route.fulfill({
      json: envelope([
        {
          id: 1,
          title: '本地精选',
          subtitle: '冒烟测试运营位',
          imageUrl: 'https://example.test/banner.jpg',
          linkUrl: '/shops',
        },
      ]),
    })
  })

  await page.route('**/api/c/v1/home/feed**', async (route) => {
    await route.fulfill({
      json: envelope([
        {
          id: 1,
          type: 'shop',
          title: '冒烟推荐门店',
          subtitle: '测试数据',
          coverUrl: 'https://example.test/shop.jpg',
          shopId: 1,
        },
      ]),
    })
  })

  await page.route('**/api/c/v1/search/suggest**', async (route) => {
    await route.fulfill({
      json: envelope([
        {
          term: '冒烟火锅',
          type: 'shop',
          refId: 1,
        },
      ]),
    })
  })

  await page.route('**/api/c/v1/search/hot**', async (route) => {
    await route.fulfill({
      json: envelope([
        {
          term: '火锅',
          score: 3,
        },
      ]),
    })
  })

  await page.route('**/api/c/v1/search/shops?**', async (route) => {
    await route.fulfill({
      json: envelope({
        list: [
          {
            id: 1,
            name: '冒烟火锅',
            cityName: '上海',
            areaName: '人民广场',
            categoryName: '火锅',
            coverUrl: 'https://example.test/shop.jpg',
            score: 4.6,
            avgCost: 88,
            currency: 'CNY',
            reviewCount: 12,
            tags: ['冒烟'],
            summary: 'Playwright mock shop',
          },
        ],
        page: 1,
        pageSize: 12,
        total: 1,
      }),
    })
  })

  await page.route('**/api/c/v1/shops/1', async (route) => {
    await route.fulfill({
      json: envelope({
        id: 1,
        name: '冒烟火锅',
        cityName: '上海',
        areaName: '人民广场',
        categoryName: '火锅',
        coverUrl: 'https://example.test/shop.jpg',
        score: 4.6,
        avgCost: 88,
        currency: 'CNY',
        reviewCount: 12,
        tags: ['冒烟'],
        summary: 'Playwright mock shop',
        address: '测试路 1 号',
        phone: '021-00000000',
        openingHours: '10:00-22:00',
        images: [],
        dishes: [],
      }),
    })
  })
})

test.describe('browser smoke', () => {
  test('opens web public routes', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('heading', { name: /先把首页、列表、详情跑通/ })).toBeVisible()

    await page.goto('/shops')
    await expect(page.getByRole('heading', { name: /当前区域 .*先把可浏览链路做扎实/ })).toBeVisible()
  })

  test('submits header keyword search to shop list', async ({ page }) => {
    await page.goto('/')

    await page.getByRole('searchbox', { name: '搜索商户' }).fill('火锅')
    await page.getByRole('button', { name: '搜索' }).click()

    await expect(page).toHaveURL(/\/shops\?keyword=%E7%81%AB%E9%94%85/)
    await expect(page.getByLabel('关键词')).toHaveValue('火锅')
    await expect(page.getByText('冒烟火锅')).toBeVisible()
  })

  test('opens search suggestions from header keyword input', async ({ page }) => {
    await page.goto('/')

    await page.getByRole('searchbox', { name: '搜索商户' }).fill('火')
    await page.getByRole('button', { name: '冒烟火锅' }).click()

    await expect(page).toHaveURL(/\/shops\?keyword=%E5%86%92%E7%83%9F%E7%81%AB%E9%94%85/)
    await expect(page.getByLabel('关键词')).toHaveValue('冒烟火锅')
  })

  test('opens login dialog when guest visits guarded review route', async ({ page }) => {
    await page.goto('/shops/1/reviews/new')

    const authDialog = page.locator('.auth-dialog')
    await expect(authDialog.getByRole('heading', { name: '先把登录链路跑顺' })).toBeVisible()
    await expect(authDialog.getByRole('button', { name: '登录', exact: true })).toBeVisible()
  })

  test('logs in from auth dialog and resumes the guarded review page', async ({ page }) => {
    await page.goto('/shops/1/reviews/new')

    const authDialog = page.locator('.auth-dialog')
    await expect(authDialog.getByRole('heading', { name: '先把登录链路跑顺' })).toBeVisible()

    await authDialog.getByLabel('邮箱 / 手机号').fill('smoke@example.test')
    await authDialog.getByLabel('密码').fill('Smoke123456')
    await authDialog.getByRole('button', { name: '登录', exact: true }).click()

    await expect(page).toHaveURL(/\/shops\/1\/reviews\/new/)
    await expect(page.locator('.auth-dialog')).toHaveCount(0)
    await expect(page.getByRole('heading', { name: '冒烟火锅' })).toBeVisible()
    await expect(page.getByRole('button', { name: '提交点评' })).toBeVisible()
  })

  test('opens admin login route', async ({ page }) => {
    await page.goto(`${adminBaseURL}/login`)

    await expect(page.getByLabel('账号')).toBeVisible()
    await expect(page.getByLabel('密码')).toBeVisible()
    await expect(page.getByRole('button', { name: '进入后台' })).toBeVisible()
  })

  test('opens the authorized administrator account page and its create dialog', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('dzdp:admin-token', 'admin-smoke-token')
      localStorage.setItem('dzdp:admin-profile', JSON.stringify({ id: 1, account: 'admin', name: '系统管理员' }))
      localStorage.setItem('dzdp:admin-permissions', JSON.stringify(['system:admin:read', 'system:admin:write']))
      localStorage.setItem('dzdp:admin-regions', JSON.stringify(['CN', 'EU']))
      localStorage.setItem('dzdp:admin-region', 'CN')
    })
    await page.route('**/api/admin/v1/auth/me', async (route) => {
      await route.fulfill({
        json: envelope({
          profile: { id: 1, account: 'admin', name: '系统管理员' },
          permissions: ['system:admin:read', 'system:admin:write'],
          regions: ['CN', 'EU'],
        }),
      })
    })
    await page.route('**/api/admin/v1/menus', async (route) => {
      await route.fulfill({
        json: envelope([
          {
            code: 'system',
            name: '系统管理',
            path: '/system',
            children: [{ code: 'system.admins', name: '管理员账号', path: '/system/admins', children: [] }],
          },
        ]),
      })
    })
    await page.route('**/api/admin/v1/rbac/admins?**', async (route) => {
      await route.fulfill({
        json: envelope({
          list: [{
            id: 1,
            account: 'admin',
            name: '系统管理员',
            status: 1,
            roleIds: [1],
            roleNames: ['超级管理员'],
            regions: ['CN', 'EU'],
            lastLoginAt: '2026-07-18 09:00:00',
          }],
          total: 1,
          page: 1,
          pageSize: 20,
          hasMore: false,
        }),
      })
    })
    await page.route('**/api/admin/v1/rbac/roles', async (route) => {
      await route.fulfill({
        json: envelope([{ id: 1, code: 'super_admin', name: '超级管理员', description: '', status: 1, builtIn: true, permissionIds: [1], adminCount: 1 }]),
      })
    })

    await page.goto(`${adminBaseURL}/system/admins`)

    await expect(page.getByRole('main').getByRole('heading', { name: '管理员账号' })).toBeVisible()
    await expect(page.getByText('系统管理员', { exact: true }).first()).toBeVisible()
    await page.getByRole('button', { name: '新建管理员' }).click()
    await expect(page.getByRole('heading', { name: '新建管理员' })).toBeVisible()
    await expect(page.getByLabel('登录账号')).toBeVisible()
  })

  test('opens basic data management with read-only region metadata', async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('dzdp:admin-token', 'geo-read-token')
      localStorage.setItem('dzdp:admin-profile', JSON.stringify({ id: 2, account: 'geo.reader', name: '基础数据查看员' }))
      localStorage.setItem('dzdp:admin-permissions', JSON.stringify(['data:geo:read']))
      localStorage.setItem('dzdp:admin-regions', JSON.stringify(['EU']))
      localStorage.setItem('dzdp:admin-region', 'EU')
    })
    await page.route('**/api/admin/v1/auth/me', async (route) => {
      await route.fulfill({
        json: envelope({
          profile: { id: 2, account: 'geo.reader', name: '基础数据查看员' },
          permissions: ['data:geo:read'],
          regions: ['EU'],
        }),
      })
    })
    await page.route('**/api/admin/v1/menus', async (route) => {
      await route.fulfill({
        json: envelope([{
          code: 'data',
          name: '数据管理',
          path: '/data',
          children: [{ code: 'data.meta', name: '基础数据', path: '/data/meta', children: [] }],
        }]),
      })
    })
    await page.route('**/api/admin/v1/categories', async (route) => {
      await route.fulfill({
        json: envelope([{ id: 200, parentId: 0, name: 'Dining', sortNo: 1, status: 1 }]),
      })
    })
    await page.route('**/api/admin/v1/cities', async (route) => {
      await route.fulfill({
        json: envelope([{ id: 101, code: 'PAR', name: 'Paris', sortNo: 1, status: 1 }]),
      })
    })
    await page.route('**/api/admin/v1/areas**', async (route) => {
      await route.fulfill({
        json: envelope([{ id: 1011, cityId: 101, name: 'Le Marais', sortNo: 1, status: 1 }]),
      })
    })

    await page.goto(`${adminBaseURL}/data/meta`)
    await expect(page.getByRole('main').getByRole('heading', { name: '基础数据' })).toBeVisible()
    await expect(page.getByText('Dining', { exact: true })).toBeVisible()
    await expect(page.getByTestId('create-category')).toHaveCount(0)

    await page.getByTestId('tab-areas').click()
    await page.getByTestId('area-city-select').selectOption('101')
    await expect(page.getByText('Le Marais', { exact: true })).toBeVisible()
    await expect(page.getByTestId('create-area')).toHaveCount(0)
  })
})
