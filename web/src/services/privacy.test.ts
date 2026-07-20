import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiDelete, apiDownload, apiGet, apiPost } from '@/lib/http'
import {
  acceptPrivacyPolicy,
  cancelPrivacyDeleteTask,
  createPrivacyDeleteTask,
  createPrivacyExportTask,
  downloadPrivacyExport,
  fetchPrivacyExportTasks,
  fetchPrivacyOverview,
  fetchPrivacyPolicyLogs,
  fetchUserDevices,
  logoutUserDevice,
} from './privacy'

vi.mock('@/lib/http', () => ({
  apiDelete: vi.fn(),
  apiDownload: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('privacy service', () => {
  beforeEach(() => {
    vi.mocked(apiDownload).mockReset()
    vi.mocked(apiDelete).mockReset()
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('requests the privacy overview and export task list', () => {
    fetchPrivacyOverview()
    fetchPrivacyExportTasks({ page: 2, pageSize: 20 })

    expect(apiGet).toHaveBeenNthCalledWith(1, '/api/c/v1/privacy/overview')
    expect(apiGet).toHaveBeenNthCalledWith(2, '/api/c/v1/privacy/export-tasks', {
      page: 2,
      pageSize: 20,
    })
  })

  it('creates and downloads a privacy export task', () => {
    createPrivacyExportTask({ modules: ['account', 'reviews'], format: 'zip' })
    downloadPrivacyExport(8)

    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/privacy/export-tasks', {
      modules: ['account', 'reviews'],
      format: 'zip',
    })
    expect(apiDownload).toHaveBeenCalledWith('/api/c/v1/privacy/export-tasks/8/download')
  })

  it('creates and cancels a privacy delete task', () => {
    createPrivacyDeleteTask({
      verifyType: 'code',
      account: 'demo.cn@example.com',
      verifyCode: '123456',
      reason: '不再使用',
    })
    cancelPrivacyDeleteTask(9)

    expect(apiPost).toHaveBeenNthCalledWith(1, '/api/c/v1/privacy/delete-tasks', {
      verifyType: 'code',
      account: 'demo.cn@example.com',
      verifyCode: '123456',
      reason: '不再使用',
    })
    expect(apiPost).toHaveBeenNthCalledWith(2, '/api/c/v1/privacy/delete-tasks/9/cancel')
  })

  it('records policy acceptance and manages devices', () => {
    fetchPrivacyPolicyLogs()
    acceptPrivacyPolicy({
      policyType: 1,
      version: '2026.07',
      locale: 'zh-CN',
      source: 3,
    })
    fetchUserDevices()
    logoutUserDevice(7)

    expect(apiGet).toHaveBeenNthCalledWith(1, '/api/c/v1/privacy/policies')
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/privacy/policies/accept', {
      policyType: 1,
      version: '2026.07',
      locale: 'zh-CN',
      source: 3,
    })
    expect(apiGet).toHaveBeenNthCalledWith(2, '/api/c/v1/devices')
    expect(apiDelete).toHaveBeenCalledWith('/api/c/v1/devices/7')
  })
})
