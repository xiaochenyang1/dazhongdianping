import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminSensitiveWords: vi.fn(),
  createAdminSensitiveWord: vi.fn(),
  updateAdminSensitiveWord: vi.fn(),
  updateAdminSensitiveWordStatus: vi.fn(),
  removeAdminSensitiveWord: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['operations:sensitive_word:read', 'operations:sensitive_word:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import SensitiveWordManagementView from './SensitiveWordManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const words = [
  {
    id: 1,
    region: 'CN' as const,
    word: '违禁演示词',
    matchMode: 1,
    enabled: true,
    remark: '演示',
  },
  {
    id: 2,
    region: 'CN' as const,
    word: '旧词',
    matchMode: 1,
    enabled: false,
    remark: '',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(SensitiveWordManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

describe('SensitiveWordManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['operations:sensitive_word:read', 'operations:sensitive_word:write']
    adminMocks.listAdminSensitiveWords.mockResolvedValue(words)
    adminMocks.createAdminSensitiveWord.mockResolvedValue({
      id: 3,
      region: 'CN',
      word: '新词',
      matchMode: 1,
      enabled: true,
      remark: '备注',
    })
    adminMocks.updateAdminSensitiveWordStatus.mockResolvedValue({ ...words[1], enabled: true })
    adminMocks.removeAdminSensitiveWord.mockResolvedValue(undefined)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads sensitive words for the current region', async () => {
    const { app, host } = mount()
    await flush()

    expect(adminMocks.listAdminSensitiveWords).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('违禁演示词')
    expect(host.textContent).toContain('旧词')
    expect(host.textContent).toContain('当前区域 CN')
    expect(host.textContent).toContain('新建敏感词')
    expect(host.textContent).toContain('—')
    app.unmount()
  })

  it('creates a new sensitive word from the editor form', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="create-sensitive-word"]')?.click()
    await nextTick()

    input(host, 'sensitive-word', '新词')
    input(host, 'sensitive-word-remark', '备注')
    host.querySelector<HTMLFormElement>('[data-testid="sensitive-word-editor"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(adminMocks.createAdminSensitiveWord).toHaveBeenCalledWith({
      word: '新词',
      remark: '备注',
    })
    app.unmount()
  })

  it('toggles and deletes configured sensitive words', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    expect(host.querySelector<HTMLButtonElement>('[data-testid="toggle-sensitive-word-2"]')?.textContent?.trim()).toBe('启用')
    host.querySelector<HTMLButtonElement>('[data-testid="toggle-sensitive-word-2"]')?.click()
    await flush()
    expect(adminMocks.updateAdminSensitiveWordStatus).toHaveBeenCalledWith(2, true)

    host.querySelector<HTMLButtonElement>('[data-testid="delete-sensitive-word-1"]')?.click()
    await flush()
    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('违禁演示词'))
    expect(adminMocks.removeAdminSensitiveWord).toHaveBeenCalledWith(1)
    app.unmount()
  })
})
