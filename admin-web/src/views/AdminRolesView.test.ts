import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminPermissions: vi.fn(),
  listAdminRoles: vi.fn(),
  createAdminRole: vi.fn(),
  updateAdminRole: vi.fn(),
  updateAdminRoleStatus: vi.fn(),
  removeAdminRole: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({ state: { permissions: ['system:role:write'] } }),
}))

import AdminRolesView from './AdminRolesView.vue'

const permissions = [
  { id: 2, code: 'audit:review:read', name: '查看点评审核', category: 'audit', type: 1 },
  { id: 14, code: 'data:shop:read', name: '查看门店数据', category: 'data', type: 1 },
]

const roles = [
  { id: 1, code: 'super_admin', name: '超级管理员', description: '全量权限', status: 1, builtIn: true, permissionIds: [2, 14], adminCount: 1 },
  { id: 2, code: 'shop_reader', name: '门店只读员', description: '只读门店', status: 1, builtIn: false, permissionIds: [14], adminCount: 0 },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminRolesView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string) {
  const button = [...host.querySelectorAll('button')].find((item) => item.textContent?.includes(text))
  if (!button) throw new Error(`missing button: ${text}`)
  button.click()
}

function check(host: HTMLElement, name: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing checkbox: ${name}`)
  element.checked = true
  element.dispatchEvent(new Event('change'))
}

describe('AdminRolesView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.listAdminPermissions.mockResolvedValue(permissions)
    mocks.listAdminRoles.mockResolvedValue(roles)
    mocks.createAdminRole.mockResolvedValue({ ...roles[1], id: 3, code: 'eu_reader', name: 'EU 只读员' })
    mocks.updateAdminRole.mockResolvedValue(roles[1])
    mocks.updateAdminRoleStatus.mockResolvedValue({ ...roles[1], status: 2 })
    mocks.removeAdminRole.mockResolvedValue(undefined)
  })

  it('groups permissions, protects super admin controls, and creates a role', async () => {
    const { app, host } = mount()
    await flush()

    expect(host.querySelector<HTMLButtonElement>('[data-testid="role-status-1"]')?.disabled).toBe(true)

    click(host, '新建角色')
    await flush()
    expect(host.textContent).toContain('审核中心')
    expect(host.textContent).toContain('数据管理')
    const code = host.querySelector<HTMLInputElement>('[name="role-code"]')
    if (!code) throw new Error('missing role-code')
    code.value = 'eu_reader'
    code.dispatchEvent(new Event('input'))
    const name = host.querySelector<HTMLInputElement>('[name="role-name"]')
    if (!name) throw new Error('missing role-name')
    name.value = 'EU 只读员'
    name.dispatchEvent(new Event('input'))
    check(host, 'permission-14')
    await nextTick()
    host.querySelector<HTMLFormElement>('[data-testid="role-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createAdminRole).toHaveBeenCalledWith({
      code: 'eu_reader',
      name: 'EU 只读员',
      description: '',
      permissionIds: [14],
    })
    app.unmount()
  })

  it('keeps the role form open on a backend conflict', async () => {
    mocks.createAdminRole.mockRejectedValue(new Error('角色编码已存在'))
    const { app, host } = mount()
    await flush()
    click(host, '新建角色')
    await flush()
    const code = host.querySelector<HTMLInputElement>('[name="role-code"]')
    if (!code) throw new Error('missing role-code')
    code.value = 'taken_role'
    code.dispatchEvent(new Event('input'))
    const name = host.querySelector<HTMLInputElement>('[name="role-name"]')
    if (!name) throw new Error('missing role-name')
    name.value = '重复角色'
    name.dispatchEvent(new Event('input'))
    check(host, 'permission-14')
    await nextTick()
    host.querySelector<HTMLFormElement>('[data-testid="role-form"]')
      ?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(host.textContent).toContain('角色编码已存在')
    expect(host.querySelector<HTMLInputElement>('[name="role-code"]')?.value).toBe('taken_role')
    app.unmount()
  })
})
