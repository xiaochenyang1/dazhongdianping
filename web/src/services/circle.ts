import { apiGet } from '@/lib/http'
import type { CommunityPostPage } from '@/types/community'
export interface PublicCircle { id:number;region:string;name:string;description:string;coverUrl:string;memberCount:number;postCount:number;sort:number;status:number;joinedByCurrentUser:boolean }
export interface CirclePage { list:PublicCircle[];total:number;page:number;pageSize:number;hasMore:boolean }
export function fetchCircles(){return apiGet<CirclePage>('/api/c/v1/groups',{page:1,pageSize:30})}
export function fetchCircle(id:number){return apiGet<PublicCircle>(`/api/c/v1/groups/${id}`)}
export function fetchCirclePosts(id:number){return apiGet<CommunityPostPage>(`/api/c/v1/groups/${id}/posts`,{page:1,pageSize:30})}
