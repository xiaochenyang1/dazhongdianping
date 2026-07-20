import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ listCircles: vi.fn(), createCircle: vi.fn(), updateCircle: vi.fn(), updateCircleStatus: vi.fn() }))
vi.mock('@/services/circle', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state: { region: 'EU' } }) }))

import CircleManagementView from './CircleManagementView.vue'

async function flush() { await Promise.resolve(); await Promise.resolve(); await nextTick() }
function mount() { const host=document.createElement('div'); const app=createApp(CircleManagementView); app.mount(host); return {host,app} }
const circle={id:3,region:'EU',name:'伦敦生活圈',description:'英国华人本地生活',coverUrl:'',memberCount:12,postCount:8,sort:20,status:1,joinedByCurrentUser:false}

describe('CircleManagementView', () => {
  beforeEach(() => { Object.values(mocks).forEach((mock) => mock.mockReset()); mocks.listCircles.mockResolvedValue({list:[circle],total:1,page:1,pageSize:20,hasMore:false}) })
  it('loads current-region circles and disables one', async () => {
    mocks.updateCircleStatus.mockResolvedValue({...circle,status:2})
    const {host,app}=mount(); await flush()
    expect(mocks.listCircles).toHaveBeenCalledWith({status:undefined,keyword:'',page:1,pageSize:20})
    expect(host.textContent).toContain('伦敦生活圈')
    const button=[...host.querySelectorAll('button')].find((node)=>node.textContent?.includes('停用'))
    if(!button) throw new Error('找不到停用按钮'); button.click(); await flush()
    expect(mocks.updateCircleStatus).toHaveBeenCalledWith(3,2)
    app.unmount()
  })
  it('creates a circle and renders real errors', async () => {
    mocks.createCircle.mockRejectedValue(new Error('当前区域已存在同名圈子'))
    const {host,app}=mount(); await flush()
    const name=host.querySelector<HTMLInputElement>('input[name="circle-name"]'); if(!name) throw new Error('缺少名称输入框')
    name.value='巴黎生活圈'; name.dispatchEvent(new Event('input'))
    const form=host.querySelector('form'); if(!form) throw new Error('缺少创建表单')
    form.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true})); await flush()
    expect(mocks.createCircle).toHaveBeenCalledWith({name:'巴黎生活圈',description:'',coverUrl:'',sort:0})
    expect(host.textContent).toContain('当前区域已存在同名圈子')
    app.unmount()
  })
})
