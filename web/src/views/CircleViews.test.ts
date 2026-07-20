import { createApp, defineComponent, nextTick } from 'vue'
import { describe, expect, it, vi } from 'vitest'
const mocks=vi.hoisted(()=>({fetchCircles:vi.fn(),fetchCircle:vi.fn(),fetchCirclePosts:vi.fn()}))
vi.mock('@/services/circle',()=>mocks)
vi.mock('vue-router',()=>({RouterLink:{props:['to'],template:'<a><slot /></a>'}}))
import CircleListView from './CircleListView.vue'
import CircleDetailView from './CircleDetailView.vue'
const RouterLinkStub=defineComponent({props:['to'],template:'<a><slot /></a>'})
async function mount(component:any,props={}){const host=document.createElement('div'),app=createApp(component,props);app.component('RouterLink',RouterLinkStub);app.mount(host);await Promise.resolve();await Promise.resolve();await nextTick();return{host,app}}
const circle={id:3,region:'EU',name:'伦敦生活圈',description:'英国华人本地生活',coverUrl:'',memberCount:12,postCount:8,sort:20,status:1,joinedByCurrentUser:false}
describe('circle read-only views',()=>{it('renders list without write actions',async()=>{mocks.fetchCircles.mockResolvedValue({list:[circle],total:1,page:1,pageSize:20,hasMore:false});const{host,app}=await mount(CircleListView);expect(host.textContent).toContain('伦敦生活圈');expect(host.textContent).toContain('12 位成员');expect(host.textContent).not.toContain('加入圈子');app.unmount()});it('renders detail posts without publishing controls',async()=>{mocks.fetchCircle.mockResolvedValue(circle);mocks.fetchCirclePosts.mockResolvedValue({list:[{id:7,userId:9,userName:'伦敦小王',title:'周末市集指南',content:'本周六开放',likeCount:2,commentCount:1,topics:[],createdAt:'2026-07-17'}],total:1,page:1,pageSize:20,hasMore:false});const{host,app}=await mount(CircleDetailView,{circleId:3});expect(host.textContent).toContain('周末市集指南');expect(host.textContent).not.toContain('发布帖子');expect(host.textContent).not.toContain('退出圈子');app.unmount()})})
