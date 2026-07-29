import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminAccounts: vi.fn(),
  listAdminRoles: vi.fn(),
  listAdminScopeCities: vi.fn(),
  listAdminScopeShops: vi.fn(),
  createAdminAccount: vi.fn(),
  updateAdminAccount: vi.fn(),
  updateAdminAccountStatus: vi.fn(),
  resetAdminAccountPassword: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as {
    profile: { id: number; account: string; name: string }
    permissions: string[]
    region: 'CN' | 'EU'
  },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    profile: { id: 1, account: 'admin', name: '系统管理员' },
    permissions: ['system:admin:read', 'system:admin:write'],
    region: 'EU' as const,
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import AdminAccountsView from './AdminAccountsView.vue'

const roles = [
  { id: 1, code: 'super_admin', name: '超级管理员', description: '', status: 1, builtIn: true, permissionIds: [1], adminCount: 1 },
  { id: 2, code: 'shop_reader', name: '门店只读员', description: '', status: 1, builtIn: false, permissionIds: [14], adminCount: 0 },
]

const scopeCities = [
  { id: 1, region: 'CN', name: '上海' },
  { id: 2, region: 'CN', name: '北京' },
  { id: 101, region: 'EU', name: 'Paris' },
  { id: 102, region: 'EU', name: 'Berlin' },
]

const scopeShops = [
  { id: 20001, region: 'EU', cityId: 101, cityName: 'Paris', name: 'Maison Sichuan Paris' },
  { id: 20002, region: 'EU', cityId: 102, cityName: 'Berlin', name: 'Spree Sichuan' },
]

const accounts = [
  {
    id: 1,
    account: 'admin',
    name: '系统管理员',
    status: 1,
    roleIds: [1],
    roleNames: ['超级管理员'],
    regions: ['CN', 'EU'],
    cityScopes: [
      { region: 'CN', allCities: true, cityIds: [], shopIds: [] },
      { region: 'EU', allCities: true, cityIds: [], shopIds: [] },
    ],
    lastLoginAt: '2026-07-18 09:00:00',
  },
  {
    id: 7,
    account: 'eu.reader',
    name: 'EU 只读员',
    status: 1,
    roleIds: [2],
    roleNames: ['门店只读员'],
    regions: ['EU'],
    cityScopes: [{ region: 'EU', allCities: false, cityIds: [101], shopIds: [] }],
    lastLoginAt: '',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await new Promise((resolve) => setTimeout(resolve, 0))
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
    sessionMock.state.permissions = ['system:admin:read', 'system:admin:write']
    sessionMock.state.region = 'EU'
    mocks.listAdminAccounts.mockResolvedValue({ list: accounts, total: 2, page: 1, pageSize: 20, hasMore: false })
    mocks.listAdminRoles.mockResolvedValue(roles)
    mocks.listAdminScopeCities.mockResolvedValue(scopeCities)
    mocks.listAdminScopeShops.mockResolvedValue(scopeShops)
    mocks.createAdminAccount.mockResolvedValue({ ...accounts[1], id: 8, account: 'eu.new' })
    mocks.updateAdminAccount.mockResolvedValue(accounts[1])
    mocks.updateAdminAccountStatus.mockResolvedValue({ ...accounts[1], status: 2 })
    mocks.resetAdminAccountPassword.mockResolvedValue(undefined)
  })

  it('loads accounts and creates an account with an explicit all-cities scope', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminAccounts).toHaveBeenCalledWith({ page: 1, pageSize: 20 })
    expect(mocks.listAdminRoles).toHaveBeenCalledTimes(1)
    expect(mocks.listAdminScopeCities).toHaveBeenCalledTimes(1)
    expect(mocks.listAdminScopeShops).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('Admin accounts')
    expect(host.textContent).toContain('New admin')
    expect(host.textContent).toContain('系统管理员')
    expect(host.textContent).toContain('CN: All cities')
    expect(host.textContent).toContain('EU: Paris')
    expect(host.textContent).toContain('Never signed in')
    const selfStatusButton = host.querySelector<HTMLButtonElement>('[data-testid="status-admin-1"]')
    expect(selfStatusButton?.disabled).toBe(true)

    click(host, 'New admin')
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
      cityScopes: [{ region: 'EU', allCities: true, cityIds: [], shopIds: [] }],
    })
    app.unmount()
  })

  it('keeps the form open with user input when the backend rejects a create request', async () => {
    mocks.createAdminAccount.mockRejectedValue(new Error('管理员账号已存在'))
    const { app, host } = mount()
    await flush()

    click(host, 'New admin')
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

  it('requires a city in selected mode and submits a selected-city scope', async () => {
    const { app, host } = mount()
    await flush()

    click(host, 'New admin')
    await nextTick()
    input(host, 'admin-account', 'paris.reader')
    input(host, 'admin-password', 'Reader#123456')
    input(host, 'admin-name', 'Paris 只读员')
    check(host, 'role-2')
    check(host, 'region-EU')
    await nextTick()
    const selectedScope = host.querySelector<HTMLInputElement>('[data-testid="city-scope-selected-EU"]')
    if (!selectedScope) throw new Error('missing EU selected-city scope option')
    selectedScope.checked = true
    selectedScope.dispatchEvent(new Event('change'))
    await nextTick()
    expect(host.querySelector('[name="city-EU-101"]')).not.toBeNull()
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await nextTick()

    expect(host.textContent).toContain('Select at least one city or shop for EU.')
    expect(mocks.createAdminAccount).not.toHaveBeenCalled()

    check(host, 'city-EU-101')
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createAdminAccount).toHaveBeenCalledWith({
      account: 'paris.reader',
      password: 'Reader#123456',
      name: 'Paris 只读员',
      roleIds: [2],
      regions: ['EU'],
      cityScopes: [{ region: 'EU', allCities: false, cityIds: [101], shopIds: [] }],
    })
    app.unmount()
  })

  it('restores and updates a selected-city scope when editing an account', async () => {
    const { app, host } = mount()
    await flush()

    const accountRow = [...host.querySelectorAll('tbody tr')]
      .find((row) => row.textContent?.includes('eu.reader'))
    const editButton = [...(accountRow?.querySelectorAll<HTMLButtonElement>('button') ?? [])]
      .find((button) => button.textContent?.trim() === 'Edit')
    if (!editButton) throw new Error('missing EU reader edit button')
    editButton.click()
    await nextTick()

    expect(host.querySelector<HTMLInputElement>('[name="city-EU-101"]')?.checked).toBe(true)
    expect(host.querySelector<HTMLInputElement>('[name="city-EU-102"]')?.checked).toBe(false)
    check(host, 'city-EU-102')
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.updateAdminAccount).toHaveBeenCalledWith(7, {
      name: 'EU 只读员',
      roleIds: [2],
      regions: ['EU'],
      cityScopes: [{ region: 'EU', allCities: false, cityIds: [101, 102], shopIds: [] }],
    })
    app.unmount()
  })

  it('submits a selected-shop whitelist', async () => {
    const { app, host } = mount()
    await flush()

    click(host, 'New admin')
    await nextTick()
    input(host, 'admin-account', 'shop.reader')
    input(host, 'admin-password', 'Reader#123456')
    input(host, 'admin-name', '门店只读员')
    check(host, 'role-2')
    check(host, 'region-EU')
    await nextTick()
    const shopScope = host.querySelector<HTMLInputElement>('[data-testid="city-scope-shops-EU"]')
    if (!shopScope) throw new Error('missing EU selected-shop scope option')
    shopScope.checked = true
    shopScope.dispatchEvent(new Event('change'))
    await nextTick()
    check(host, 'shop-EU-20001')
    host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createAdminAccount).toHaveBeenCalledWith({
      account: 'shop.reader',
      password: 'Reader#123456',
      name: '门店只读员',
      roleIds: [2],
      regions: ['EU'],
      cityScopes: [{ region: 'EU', allCities: false, cityIds: [], shopIds: [20001] }],
    })
    app.unmount()
  })

  it('keeps account scopes readable and blocks stale writes after permission revocation', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    const createButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('New admin'))
    const accountRow = [...host.querySelectorAll('tbody tr')]
      .find((row) => row.textContent?.includes('eu.reader'))
    const statusButton = accountRow?.querySelector<HTMLButtonElement>('[data-testid="status-admin-7"]')
    const resetButton = [...(accountRow?.querySelectorAll<HTMLButtonElement>('button') ?? [])]
      .find((button) => button.textContent?.includes('Reset password'))
    if (!createButton || !statusButton || !resetButton) throw new Error('missing admin mutation controls')

    resetButton.click()
    createButton.click()
    await nextTick()
    const accountForm = host.querySelector<HTMLFormElement>('[data-testid="admin-form"]')
    const resetForm = [...host.querySelectorAll<HTMLFormElement>('form')]
      .find((form) => form.querySelector('[name="reset-password"]'))
    if (!accountForm || !resetForm) throw new Error('missing opened admin mutation forms')

    sessionMock.state.permissions = ['system:admin:read']
    accountForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    resetForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    statusButton.click()
    createButton.click()
    resetButton.click()
    await flush()

    expect(host.textContent).toContain('EU: Paris')
    expect(confirm).not.toHaveBeenCalled()
    expect(mocks.createAdminAccount).not.toHaveBeenCalled()
    expect(mocks.updateAdminAccount).not.toHaveBeenCalled()
    expect(mocks.updateAdminAccountStatus).not.toHaveBeenCalled()
    expect(mocks.resetAdminAccountPassword).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="admin-form"]')).toBeNull()
    expect(host.querySelector('[data-testid^="status-admin-"]')).toBeNull()
    app.unmount()
  })
})
