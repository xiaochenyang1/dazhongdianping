import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  createRankConfig: vi.fn(),
  listRankConfigs: vi.fn(),
  publishRankConfig: vi.fn(),
  rollbackRankConfig: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:rank:read', 'operations:rank:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import RankConfigView from './RankConfigView.vue'

const draftConfig = {
  id: 31,
  rankType: 1,
  rankTypeText: '必吃榜',
  region: 'EU' as const,
  cityId: 101,
  categoryId: 201,
  version: 3,
  calcCycle: 4,
  weight: { score: 0.7, reviewCount: 0.2, hasDeal: 0.1 },
  minReviewCount: 1,
  minScore: 4,
  manualIntervene: true,
  status: 0,
  statusText: '草稿',
  effectiveFrom: '',
  updatedAt: '2026-07-24 13:00:00',
}

const publishedConfig = {
  ...draftConfig,
  id: 30,
  version: 2,
  status: 1,
  statusText: '已发布',
  effectiveFrom: '2026-07-20 09:00:00',
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(RankConfigView)
  app.mount(host)
  return { app, host }
}

describe('RankConfigView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:rank:read', 'operations:rank:write']
    adminMocks.listRankConfigs.mockResolvedValue([draftConfig, publishedConfig])
    adminMocks.createRankConfig.mockResolvedValue(draftConfig)
    adminMocks.publishRankConfig.mockResolvedValue({
      config: publishedConfig,
      rankId: 81,
      itemCount: 12,
    })
    adminMocks.rollbackRankConfig.mockResolvedValue({
      config: publishedConfig,
      rankId: 82,
      itemCount: 10,
    })
  })

  it('creates drafts and publishes or rolls back rank configurations with write permission', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listRankConfigs).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('必吃榜')
    expect(host.textContent).toContain('城市 101 / 分类 201')

    const form = host.querySelector<HTMLFormElement>('[data-testid="rank-draft-form"]')
    const publishButton = host.querySelector<HTMLButtonElement>('[data-testid="rank-publish-31"]')
    const rollbackButton = host.querySelector<HTMLButtonElement>('[data-testid="rank-rollback-30"]')
    if (!form || !publishButton || !rollbackButton) throw new Error('找不到榜单配置写入控件')

    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flushView()
    expect(adminMocks.createRankConfig).toHaveBeenCalledWith({
      rankType: 1,
      region: 'EU',
      cityId: 101,
      categoryId: 201,
      calcCycle: 4,
      weight: { score: 0.7, reviewCount: 0.2, hasDeal: 0.1 },
      minReviewCount: 1,
      minScore: 4,
      manualIntervene: true,
    })

    publishButton.click()
    await flushView()
    expect(adminMocks.publishRankConfig).toHaveBeenCalledWith(31)

    rollbackButton.click()
    await flushView()
    expect(adminMocks.rollbackRankConfig).toHaveBeenCalledWith(30)
    app.unmount()
  })

  it('keeps rank history visible while hiding all write controls from read-only users', async () => {
    sessionMock.state.permissions = ['operations:rank:read']
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listRankConfigs).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('必吃榜')
    expect(host.textContent).toContain('城市 101 / 分类 201')
    expect(host.textContent).toContain('当前账号仅可查看，无榜单配置权限。')
    expect(host.querySelector('[data-testid="rank-draft-form"]')).toBeNull()
    expect(host.querySelector('[data-testid="rank-publish-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="rank-rollback-30"]')).toBeNull()
    expect([...host.querySelectorAll('th')].map((cell) => cell.textContent?.trim())).toEqual([
      '类型',
      '作用域',
      '版本',
      '状态',
    ])
    app.unmount()
  })

  it('blocks stale draft publish and rollback controls after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const form = host.querySelector<HTMLFormElement>('[data-testid="rank-draft-form"]')
    const publishButton = host.querySelector<HTMLButtonElement>('[data-testid="rank-publish-31"]')
    const rollbackButton = host.querySelector<HTMLButtonElement>('[data-testid="rank-rollback-30"]')
    if (!form || !publishButton || !rollbackButton) throw new Error('找不到榜单配置写入控件')

    sessionMock.state.permissions = ['operations:rank:read']
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    publishButton.click()
    rollbackButton.click()
    await flushView()

    expect(adminMocks.createRankConfig).not.toHaveBeenCalled()
    expect(adminMocks.publishRankConfig).not.toHaveBeenCalled()
    expect(adminMocks.rollbackRankConfig).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="rank-draft-form"]')).toBeNull()
    expect(host.querySelector('[data-testid="rank-publish-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="rank-rollback-30"]')).toBeNull()
    app.unmount()
  })
})
