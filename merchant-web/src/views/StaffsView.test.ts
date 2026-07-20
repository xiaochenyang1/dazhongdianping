import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchStaffs: vi.fn(),
  fetchRoles: vi.fn(),
  fetchShops: vi.fn(),
  createStaff: vi.fn(),
  updateStaff: vi.fn(),
  updateStaffStatus: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import StaffsView from './StaffsView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(StaffsView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string) {
  const button = [...host.querySelectorAll('button')].find((item) => item.textContent?.includes(text))
  if (!button) throw new Error(`missing button ${text}`)
  button.click()
}

describe('StaffsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchStaffs.mockResolvedValue({
      list: [{ id: 9, account: 'staff@example.com', name: 'Front Desk', status: 1, roles: [{ id: 12, code: 'coupon_operator', name: '核销员' }], shopScopeType: 2, shopIds: [20001] }],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.fetchRoles.mockResolvedValue({ list: [
      { id: 1, code: 'owner', name: '主账号', permissions: ['staff:manage'] },
      { id: 12, code: 'coupon_operator', name: '核销员', permissions: ['coupon:verify'] },
    ] })
    mocks.fetchShops.mockResolvedValue({ list: [{ id: 20001, name: '巴黎川味馆' }], total: 1, page: 1, pageSize: 50, hasMore: false })
    mocks.createStaff.mockResolvedValue({ id: 10 })
    mocks.updateStaffStatus.mockResolvedValue({ id: 9, status: 2 })
  })

  it('creates a scoped employee without exposing the owner role', async () => {
    const { app, host } = mountView()
    await flushView()
    expect(host.textContent).not.toContain('主账号')
    click(host, '新增员工')
    await nextTick()

    const values: Record<string, string> = {
      account: 'new-staff@example.com',
      password: 'Staff#123456',
      name: 'New Staff',
      phone: '+33111111111',
      email: 'new-staff@example.com',
    }
    Object.entries(values).forEach(([name, value]) => {
      const input = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
      if (!input) throw new Error(`missing ${name}`)
      input.value = value
      input.dispatchEvent(new Event('input'))
    })
    const scope = host.querySelector<HTMLSelectElement>('[name="shopScopeType"]')
    if (!scope) throw new Error('missing scope')
    scope.value = '2'
    scope.dispatchEvent(new Event('change'))
    await nextTick()
    const role = host.querySelector<HTMLInputElement>('[name="role-12"]')
    if (!role) throw new Error('missing role-12')
    role.checked = true
    role.dispatchEvent(new Event('change'))
    const shop = host.querySelector<HTMLInputElement>('[name="shop-20001"]')
    if (!shop) throw new Error('missing shop-20001')
    shop.checked = true
    shop.dispatchEvent(new Event('change'))
    await nextTick()
    expect(role.checked).toBe(true)
    expect(shop.checked).toBe(true)
    host.querySelector('form')?.dispatchEvent(new Event('submit'))
    await flushView()

    expect(mocks.createStaff).toHaveBeenCalledWith({
      ...values,
      roleIds: [12],
      shopScopeType: 2,
      shopIds: [20001],
    })
    app.unmount()
  })

  it('validates an empty shop scope and can disable an employee', async () => {
    const { app, host } = mountView()
    await flushView()
    click(host, '新增员工')
    await nextTick()
    const scope = host.querySelector<HTMLSelectElement>('[name="shopScopeType"]')
    if (!scope) throw new Error('missing scope')
    scope.value = '2'
    scope.dispatchEvent(new Event('change'))
    host.querySelector('form')?.dispatchEvent(new Event('submit'))
    await nextTick()
    expect(host.textContent).toContain('至少选择一家门店')
    expect(mocks.createStaff).not.toHaveBeenCalled()

    click(host, '关闭')
    click(host, '停用')
    await flushView()
    expect(mocks.updateStaffStatus).toHaveBeenCalledWith(9, 2)
    app.unmount()
  })
})
