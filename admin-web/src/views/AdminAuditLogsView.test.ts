import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminAuditLogs: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: { permissions: ['system:audit_log:read'] },
  }),
}))

import AdminAuditLogsView from './AdminAuditLogsView.vue'

const logs = [
  {
    id: 9002,
    adminId: 1,
    adminAccount: 'admin',
    adminName: '系统管理员',
    action: 'system.role_update',
    target: 'role:7',
    detail: '更新 EU 只读员权限',
    ip: '127.0.0.2',
    createdAt: '2026-07-19 10:00:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminAuditLogsView)
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

describe('AdminAuditLogsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.listAdminAuditLogs.mockResolvedValue({ list: logs, total: 1, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads audit logs and applies filters', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminAuditLogs).toHaveBeenCalledWith({
      adminId: undefined,
      action: undefined,
      target: undefined,
      keyword: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('system.role_update')
    expect(host.textContent).toContain('更新 EU 只读员权限')

    input(host, 'audit-log-admin-id', '1')
    input(host, 'audit-log-action', 'system.role_update')
    input(host, 'audit-log-keyword', '只读员')
    await nextTick()
    click(host, '应用筛选')
    await flush()

    expect(mocks.listAdminAuditLogs).toHaveBeenLastCalledWith({
      adminId: 1,
      action: 'system.role_update',
      target: undefined,
      keyword: '只读员',
      page: 1,
      pageSize: 20,
    })
    app.unmount()
  })
})
