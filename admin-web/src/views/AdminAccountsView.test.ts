import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminAccounts: vi.fn(),
  listAdminRoles: vi.fn(),
  createAdminAccount: vi.fn(),
  updateAdminAccount: vi.fn(),
  updateAdminAccountStatus: vi.fn(),
  resetAdminAccountPassword: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: { profile: { id: 1, account: 'admin', name: '系统管理员' }, permissions: ['system:admin:write'] },
  }),
}))

import AdminAccountsView from './AdminAccountsView.vue'

const roles = [
  { id: 1, code: 'super_admin', name: '超级管理员', description: '', status: 1, builtIn: true, permissionIds: [1], adminCount: 1 },
  { id: 2, code: 'shop_reader', name: '门店只读员', description: '', status: 1, builtIn: false, permissionIds: [14], adminCount: 0 },
]

const accounts = [
  { id: 1, account: 'admin', name: '系统管理员', status: 1, roleIds: [1], roleNames: ['超级管理员'], regions: ['CN', 'EU'], lastLoginAt: '2026-07-18 09:00:00' },
  { id: 7, account: 'eu.reader', name: 'EU 只读员', status: 1, roleIds: [2], roleNames: ['门店只读员'], regions: ['EU'], lastLoginAt: '' },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminAccountsView)
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

function check(host: HTMLElement, name: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing checkbox: ${name}`)
  element.checked = true
  element.dispatchEvent(new Event('change'))
}

describe('AdminAccountsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.listAdminAccounts.mockResolvedValue({ list: accounts, total: 2, page: 1, pageSize: 20, hasMore: false })
    mocks.listAdminRoles.mockResolvedValue(roles)
    mocks.createAdminAccount.mockResolvedValue({ ...accounts[1], id: 8, account: 'eu.new' })
    mocks.updateAdminAccount.mockResolvedValue(accounts[1])
    mocks.updateAdminAccountStatus.mockResolvedValue({ ...accounts[1], status: 2 })
    mocks.resetAdminAccountPassword.mockResolvedValue(undefined)
  })

  it('loads accounts, prevents self disable, and creates an account with roles and regions', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminAccounts).toHaveBeenCalledWith({ page: 1, pageSize: 20 })
    expect(mocks.listAdminRoles).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('系统管理员')
    const selfStatusButton = host.querySelector<HTMLButtonElement>('[data-testid="status-admin-1"]')
    expect(selfStatusButton?.disabled).toBe(true)

    click(host, '新建管理员')
    await nextTick()
    input(host, 'admin-account', 'eu.new')
    input(host, 'admin-password', 'Reader#123456')
    input(host, 'admin-name', 'EU 新管理员')
    check(host, 'role-2')
    check(host, 'region-EU')
    await nextTick()
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createAdminAccount).toHaveBeenCalledWith({
      account: 'eu.new',
      password: 'Reader#123456',
      name: 'EU 新管理员',
      roleIds: [2],
      regions: ['EU'],
    })
    app.unmount()
  })

  it('keeps the form open with user input when the backend rejects a create request', async () => {
    mocks.createAdminAccount.mockRejectedValue(new Error('管理员账号已存在'))
    const { app, host } = mount()
    await flush()

    click(host, '新建管理员')
    await nextTick()
    input(host, 'admin-account', 'taken.account')
    input(host, 'admin-password', 'Reader#123456')
    input(host, 'admin-name', '重复账号')
    check(host, 'role-2')
    check(host, 'region-EU')
    await nextTick()
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(host.textContent).toContain('管理员账号已存在')
    expect(host.querySelector<HTMLInputElement>('[name="admin-account"]')?.value).toBe('taken.account')
    app.unmount()
  })
})
