import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listTopics: vi.fn(),
  updateTopic: vi.fn(),
  updateTopicRecommendation: vi.fn(),
  updateTopicStatus: vi.fn(),
  mergeTopic: vi.fn(),
  recalculateTopicHot: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/topic', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:topic:read', 'operations:topic:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import TopicManagementView from './TopicManagementView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(TopicManagementView)
  app.mount(host)
  return { host, app }
}

const source = {
  id: 31,
  region: 'EU' as const,
  name: '伦敦咖啡',
  postCount: 12,
  followerCount: 88,
  recommended: false,
  pinnedSort: 20,
  status: 1,
  mergedToId: null,
  hotScore: 169,
  postCount7d: 2,
  likeCount7d: 3,
  commentCount7d: 4,
  calculatedAt: '2026-07-17 19:00:00',
}

const target = {
  ...source,
  id: 32,
  name: '英国咖啡',
  recommended: true,
  pinnedSort: 50,
}

describe('TopicManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:topic:read', 'operations:topic:write']
    mocks.listTopics.mockResolvedValue({ list: [source, target], total: 2, page: 1, pageSize: 20, hasMore: false })
    mocks.updateTopic.mockResolvedValue({ ...source, name: '伦敦咖啡馆' })
    mocks.updateTopicRecommendation.mockResolvedValue({ ...source, recommended: true, pinnedSort: 60 })
    mocks.updateTopicStatus.mockResolvedValue({ ...source, status: 2 })
    mocks.mergeTopic.mockResolvedValue(target)
    mocks.recalculateTopicHot.mockResolvedValue({ region: 'EU', calculatedAt: '2026-07-17 20:00:00' })
  })

  it('loads filters and performs rename recommendation pin and block actions', async () => {
    const { host, app } = mount()
    await flush()

    expect(mocks.listTopics).toHaveBeenCalledWith({
      status: undefined,
      recommended: undefined,
      keyword: '',
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('伦敦咖啡')
    expect(host.textContent).toContain('热度169')
    expect(host.textContent).toContain('2 帖 · 3 赞 · 4 评论')

    const editButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('编辑名称'))
    if (!editButton) throw new Error('缺少编辑名称按钮')
    editButton.click()
    await flush()
    const nameInput = host.querySelector<HTMLInputElement>('input[name="topic-name"]')
    if (!nameInput) throw new Error('缺少话题名称输入框')
    nameInput.value = '伦敦咖啡馆'
    nameInput.dispatchEvent(new Event('input'))
    host.querySelector<HTMLFormElement>('form[data-testid="rename-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()
    expect(mocks.updateTopic).toHaveBeenCalledWith(31, { name: '伦敦咖啡馆' })

    const pinInput = host.querySelector<HTMLInputElement>('input[name="pin-31"]')
    if (!pinInput) throw new Error('缺少置顶排序输入框')
    pinInput.value = '60'
    pinInput.dispatchEvent(new Event('input'))
    const recommendButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('推荐并置顶'))
    if (!recommendButton) throw new Error('缺少推荐按钮')
    recommendButton.click()
    await flush()
    expect(mocks.updateTopicRecommendation).toHaveBeenCalledWith(31, { recommended: true, pinnedSort: 60 })

    const blockButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('屏蔽'))
    if (!blockButton) throw new Error('缺少屏蔽按钮')
    blockButton.click()
    await flush()
    expect(mocks.updateTopicStatus).toHaveBeenCalledWith(31, 2)
    app.unmount()
  })

  it('requires irreversible confirmation before merging source into target', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { host, app } = mount()
    await flush()

    const mergeButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('合并话题'))
    if (!mergeButton) throw new Error('缺少合并按钮')
    mergeButton.click()
    await flush()
    const targetSelect = host.querySelector<HTMLSelectElement>('select[name="merge-target"]')
    if (!targetSelect) throw new Error('缺少合并目标选择器')
    targetSelect.value = '32'
    targetSelect.dispatchEvent(new Event('change'))
    const confirmButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('确认不可逆合并'))
    if (!confirmButton) throw new Error('缺少合并确认按钮')
    confirmButton.click()
    await flush()

    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('将「伦敦咖啡」合并到「英国咖啡」'))
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('不可逆'))
    expect(mocks.mergeTopic).toHaveBeenCalledWith(31, 32)
    app.unmount()
  })

  it('recalculates hot ranking and renders real backend errors', async () => {
    mocks.recalculateTopicHot.mockRejectedValue(new Error('热榜重算失败，旧快照已保留'))
    const { host, app } = mount()
    await flush()

    const recalculateButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('重算热榜'))
    if (!recalculateButton) throw new Error('缺少重算按钮')
    recalculateButton.click()
    await flush()

    expect(mocks.recalculateTopicHot).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('热榜重算失败，旧快照已保留')
    app.unmount()
  })

  it('keeps topic browsing available while hiding every write control from read-only users', async () => {
    sessionMock.state.permissions = ['operations:topic:read']
    const { host, app } = mount()
    await flush()

    expect(mocks.listTopics).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('伦敦咖啡')
    expect(host.querySelector('input[name="pin-31"]')).toBeNull()
    expect(host.querySelector('[data-testid="rename-form"]')).toBeNull()
    expect(host.querySelector('select[name="merge-target"]')).toBeNull()
    expect([...host.querySelectorAll('button')].map((button) => button.textContent?.trim())).toEqual([
      '执行筛选',
    ])
    app.unmount()
  })

  it('blocks every mutation when write permission is revoked after controls are opened', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { host, app } = mount()
    await flush()

    const buttons = [...host.querySelectorAll<HTMLButtonElement>('button')]
    const findButton = (text: string) => buttons.find((button) => button.textContent?.includes(text))
    findButton('编辑名称')?.click()
    findButton('合并话题')?.click()
    await nextTick()

    const renameForm = host.querySelector<HTMLFormElement>('[data-testid="rename-form"]')
    const mergeTarget = host.querySelector<HTMLSelectElement>('select[name="merge-target"]')
    const mergeButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('确认不可逆合并'))
    if (!renameForm || !mergeTarget || !mergeButton) throw new Error('缺少已打开的话题写入控件')
    mergeTarget.value = '32'
    mergeTarget.dispatchEvent(new Event('change'))

    sessionMock.state.permissions = ['operations:topic:read']
    renameForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    mergeButton.click()
    findButton('推荐并置顶')?.click()
    findButton('屏蔽')?.click()
    findButton('重算热榜')?.click()
    await flush()

    expect(confirm).not.toHaveBeenCalled()
    expect(mocks.updateTopic).not.toHaveBeenCalled()
    expect(mocks.updateTopicRecommendation).not.toHaveBeenCalled()
    expect(mocks.updateTopicStatus).not.toHaveBeenCalled()
    expect(mocks.mergeTopic).not.toHaveBeenCalled()
    expect(mocks.recalculateTopicHot).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="rename-form"]')).toBeNull()
    expect(host.querySelector('select[name="merge-target"]')).toBeNull()
    app.unmount()
  })
})
