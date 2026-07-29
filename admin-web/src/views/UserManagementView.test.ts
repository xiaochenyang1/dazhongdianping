import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminAppUsers: vi.fn(),
  getAdminAppUser: vi.fn(),
  updateAdminAppUserStatus: vi.fn(),
}))

const routerMocks = vi.hoisted(() => ({
  push: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { permissions: string[]; region: 'CN' | 'EU' },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    permissions: ['system:user:read', 'system:user:write'],
    region: 'EU' as const,
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})
vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: routerMocks.push,
  }),
}))

import UserManagementView from './UserManagementView.vue'

const users = [
  {
    id: 9001,
    nickname: '审评员阿木',
    avatar: '',
    email: 'demo.cn@example.com',
    phone: '',
    preferredRegion: 'CN',
    growthValue: 120,
    level: 4,
    points: 10,
    status: 1,
    statusText: '正常',
    lastLoginAt: '2026-07-23 10:00:00',
    createdAt: '2026-01-01 08:00:00',
  },
  {
    id: 9002,
    nickname: '欧洲咖啡客',
    avatar: '',
    email: '',
    phone: '+447700900999',
    preferredRegion: 'EU',
    growthValue: 80,
    level: 3,
    points: 5,
    status: 2,
    statusText: '已封禁',
    lastLoginAt: '',
    createdAt: '2026-01-02 08:00:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(UserManagementView)
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

describe('UserManagementView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    routerMocks.push.mockReset()
    sessionMock.state.permissions = ['system:user:read', 'system:user:write']
    sessionMock.state.region = 'EU'
    mocks.listAdminAppUsers.mockResolvedValue({ list: users, total: 2, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads users and applies filters', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminAppUsers).toHaveBeenCalledWith({
      keyword: undefined,
      userId: undefined,
      status: undefined,
      preferredRegion: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('User Management')
    expect(host.textContent).toContain('审评员阿木')
    expect(host.textContent).toContain('Banned')

    input(host, 'app-user-keyword', '咖啡')
    input(host, 'app-user-id', '9002')
    select(host, 'app-user-status', '2')
    select(host, 'app-user-region', 'EU')
    await nextTick()
    click(host, 'Apply filters')
    await flush()

    expect(mocks.listAdminAppUsers).toHaveBeenLastCalledWith({
      keyword: '咖啡',
      userId: 9002,
      status: 2,
      preferredRegion: 'EU',
      page: 1,
      pageSize: 20,
    })
    app.unmount()
  })

  it('shows user detail with content stats', async () => {
    mocks.getAdminAppUser.mockResolvedValue({
      ...users[0],
      gender: 1,
      signature: '本地演示用户',
      reviewCount: 3,
      postCount: 1,
      orderCount: 2,
      reservationCount: 1,
      favoriteCount: 4,
      activeSessionCount: 2,
      banReason: '',
      pendingAppealCount: 0,
      latestAppealStatusText: '',
    })
    const { app, host } = mount()
    await flush()

    click(host, 'Details')
    await flush()

    expect(mocks.getAdminAppUser).toHaveBeenCalledWith(9001)
    expect(host.textContent).toContain('Reviews')
    expect(host.textContent).toContain('Active sessions')
    expect(host.textContent).toContain('本地演示用户')
    app.unmount()
  })

  it('shows ban reason and pending appeal jump for banned user detail', async () => {
    mocks.getAdminAppUser.mockResolvedValue({
      ...users[1],
      gender: 0,
      signature: '',
      reviewCount: 0,
      postCount: 0,
      orderCount: 0,
      reservationCount: 0,
      favoriteCount: 0,
      activeSessionCount: 0,
      banReason: '发布垃圾广告',
      pendingAppealCount: 1,
      latestAppealStatusText: '待审核',
    })
    const { app, host } = mount()
    await flush()

    const detailButtons = [...host.querySelectorAll('button')].filter((item) => item.textContent?.includes('Details'))
    detailButtons[detailButtons.length - 1]?.click()
    await flush()

    expect(mocks.getAdminAppUser).toHaveBeenCalledWith(9002)
    expect(host.textContent).toContain('Ban reason')
    expect(host.textContent).toContain('发布垃圾广告')
    expect(host.textContent).toContain('1 pending ban appeal tasks.')

    click(host, 'Handle appeals')
    expect(routerMocks.push).toHaveBeenCalledWith('/audit/user-appeals')
    app.unmount()
  })

  it('bans a user with required reason and refreshes list', async () => {
    mocks.updateAdminAppUserStatus.mockResolvedValue({ ...users[0], status: 2, statusText: '已封禁' })
    const { app, host } = mount()
    await flush()

    click(host, 'Ban')
    await nextTick()
    click(host, 'Confirm ban')
    await flush()
    expect(mocks.updateAdminAppUserStatus).not.toHaveBeenCalled()
    expect(host.textContent).toContain('A ban reason is required.')

    const reasonBox = host.querySelector<HTMLTextAreaElement>('[name="banReason"]')
    if (!reasonBox) throw new Error('missing textarea: banReason')
    reasonBox.value = '发布垃圾广告'
    reasonBox.dispatchEvent(new Event('input'))
    await nextTick()
    click(host, 'Confirm ban')
    await flush()

    expect(mocks.updateAdminAppUserStatus).toHaveBeenCalledWith(9001, { action: 'ban', reason: '发布垃圾广告' })
    expect(mocks.listAdminAppUsers).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('has been banned. All sessions were revoked.')
    app.unmount()
  })

  it('unbans a banned user', async () => {
    mocks.updateAdminAppUserStatus.mockResolvedValue({ ...users[1], status: 1, statusText: '正常' })
    const { app, host } = mount()
    await flush()

    click(host, 'Unban')
    await flush()

    expect(mocks.updateAdminAppUserStatus).toHaveBeenCalledWith(9002, { action: 'unban', reason: '' })
    expect(mocks.listAdminAppUsers).toHaveBeenCalledTimes(2)
    app.unmount()
  })
})
