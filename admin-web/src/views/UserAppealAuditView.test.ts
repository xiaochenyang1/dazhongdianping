import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: {
      region: 'CN',
      permissions: ['audit:user_appeal:read', 'audit:user_appeal:write'],
    },
  }),
}))

import UserAppealAuditView from './UserAppealAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(UserAppealAuditView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 88,
    bizType: 8,
    bizTypeText: '用户封禁申诉',
    bizId: 5,
    region: 'CN',
    status: 0,
    statusText: '待人审',
    shopId: null,
    shopName: '',
    submittedBy: '被封禁的测试用户',
    summary: '账号被误封，我没有发布任何违规内容，请复核。',
    remark: '',
    createdAt: '2026-07-24 10:00:00',
    updatedAt: '2026-07-24 10:00:00',
  }
}

describe('UserAppealAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
  })

  it('按 bizType=8 拉取申诉任务并展示申诉用户与理由', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'CN',
      bizType: 8,
      status: 0,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('被封禁的测试用户')
    expect(host.textContent).toContain('账号被误封，我没有发布任何违规内容，请复核。')
    app.unmount()
  })

  it('通过申诉后提示已解封并刷新列表', async () => {
    adminMocks.passAuditTask.mockResolvedValue({ ...pendingTask(), status: 1, statusText: '通过' })
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('通过并解封'),
    )
    if (!passButton) throw new Error('找不到通过按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(88, { remark: undefined })
    expect(host.textContent).toContain('用户已自动解封')
    app.unmount()
  })

  it('驳回申诉必须填原因', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({ ...pendingTask(), status: 2, statusText: '驳回' })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('驳回申诉'),
    )
    if (!rejectButton) throw new Error('找不到驳回按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    const textareas = host.querySelectorAll('textarea')
    const reason = textareas[textareas.length - 1]
    if (!reason) throw new Error('找不到驳回原因输入框')
    reason.value = '证据充分，维持封禁'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(88, { reason: '证据充分，维持封禁' })
    expect(host.textContent).toContain('用户保持封禁')
    app.unmount()
  })
})
