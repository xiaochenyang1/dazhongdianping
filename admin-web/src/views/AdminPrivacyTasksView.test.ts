import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminPrivacyTasks: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: { permissions: ['system:privacy_task:read'] },
  }),
}))

import AdminPrivacyTasksView from './AdminPrivacyTasksView.vue'

const tasks = [
  {
    id: 9201,
    taskType: 2,
    taskTypeText: '账号删除',
    userId: 9001,
    userNickname: '审评员阿木',
    account: 'demo.cn@example.com',
    status: 1,
    statusText: '冷静期中',
    modules: [],
    format: '',
    fileName: '',
    failReason: '',
    verifyType: 'code',
    reason: '不再使用',
    expireAt: '',
    coolingOffExpireAt: '2026-07-26 12:00:00',
    completedAt: '',
    cancelledAt: '',
    createdAt: '2026-07-19 11:00:00',
    updatedAt: '2026-07-19 11:10:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminPrivacyTasksView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string) {
  const button = [...host.querySelectorAll('button')].find((item) => item.textContent?.includes(text))
  if (!button) throw new Error(`missing button: ${text}`)
  button.click()
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

function select(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLSelectElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing select: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('change'))
}

describe('AdminPrivacyTasksView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.listAdminPrivacyTasks.mockResolvedValue({ list: tasks, total: 1, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads privacy tasks and applies filters', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminPrivacyTasks).toHaveBeenCalledWith({
      userId: undefined,
      taskType: undefined,
      status: undefined,
      keyword: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('账号删除')
    expect(host.textContent).toContain('审评员阿木')

    input(host, 'privacy-task-user-id', '9001')
    select(host, 'privacy-task-type', '2')
    select(host, 'privacy-task-status', '1')
    input(host, 'privacy-task-keyword', 'demo.cn')
    await nextTick()
    click(host, '应用筛选')
    await flush()

    expect(mocks.listAdminPrivacyTasks).toHaveBeenLastCalledWith({
      userId: 9001,
      taskType: 2,
      status: 1,
      keyword: 'demo.cn',
      page: 1,
      pageSize: 20,
    })
    app.unmount()
  })
})
