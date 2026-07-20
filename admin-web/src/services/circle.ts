import { apiGet, apiPost, apiPut } from '@/lib/http'
import type { PageResult } from '@/types/admin'

export interface AdminCircle { id:number; region:'CN'|'EU'; name:string; description:string; coverUrl:string; memberCount:number; postCount:number; sort:number; status:number; joinedByCurrentUser:boolean }
export interface CirclePayload { name:string; description:string; coverUrl:string; sort:number }
export function listCircles(query:{status?:number;keyword:string;page:number;pageSize:number}) { return apiGet<PageResult<AdminCircle>>('/api/admin/v1/circles',query) }
export function createCircle(payload:CirclePayload) { return apiPost<AdminCircle>('/api/admin/v1/circles',payload) }
export function updateCircle(id:number,payload:CirclePayload) { return apiPut<AdminCircle>(`/api/admin/v1/circles/${id}`,payload) }
export function updateCircleStatus(id:number,status:number) { return apiPut<AdminCircle>(`/api/admin/v1/circles/${id}/status`,{status}) }
