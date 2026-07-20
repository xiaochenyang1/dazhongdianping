import { apiPost } from '@/lib/http'
import type { FileUploadResponse } from '@/types/file'

export function uploadImage(file: File) {
  const formData = new FormData()
  formData.append('file', file)
  return apiPost<FileUploadResponse>('/api/c/v1/files/upload', formData)
}
