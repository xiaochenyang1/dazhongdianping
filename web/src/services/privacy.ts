import { apiDelete, apiDownload, apiGet, apiPost } from '@/lib/http'
import type {
  PrivacyDeleteTask,
  PrivacyDeleteTaskCreatePayload,
  PrivacyExportTask,
  PrivacyExportTaskCreatePayload,
  PrivacyExportTaskPage,
  PrivacyOverview,
  PrivacyPolicyAcceptLog,
  PrivacyPolicyAcceptPayload,
  UserDevice,
} from '@/types/privacy'

export function fetchPrivacyOverview() {
  return apiGet<PrivacyOverview>('/api/c/v1/privacy/overview')
}

export function fetchPrivacyExportTasks(query?: { page?: number; pageSize?: number }) {
  return apiGet<PrivacyExportTaskPage>('/api/c/v1/privacy/export-tasks', query)
}

export function createPrivacyExportTask(payload: PrivacyExportTaskCreatePayload) {
  return apiPost<PrivacyExportTask>('/api/c/v1/privacy/export-tasks', payload)
}

export function downloadPrivacyExport(taskId: number) {
  return apiDownload(`/api/c/v1/privacy/export-tasks/${taskId}/download`)
}

export function createPrivacyDeleteTask(payload: PrivacyDeleteTaskCreatePayload) {
  return apiPost<PrivacyDeleteTask>('/api/c/v1/privacy/delete-tasks', payload)
}

export function cancelPrivacyDeleteTask(taskId: number) {
  return apiPost<PrivacyDeleteTask>(`/api/c/v1/privacy/delete-tasks/${taskId}/cancel`)
}

export function fetchPrivacyPolicyLogs() {
  return apiGet<PrivacyPolicyAcceptLog[]>('/api/c/v1/privacy/policies')
}

export function acceptPrivacyPolicy(payload: PrivacyPolicyAcceptPayload) {
  return apiPost<PrivacyPolicyAcceptLog>('/api/c/v1/privacy/policies/accept', payload)
}

export function fetchUserDevices() {
  return apiGet<UserDevice[]>('/api/c/v1/devices')
}

export function logoutUserDevice(deviceId: number) {
  return apiDelete<UserDevice>(`/api/c/v1/devices/${deviceId}`)
}
