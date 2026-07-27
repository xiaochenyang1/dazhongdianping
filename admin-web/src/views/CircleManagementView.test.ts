import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ listCircles: vi.fn(), createCircle: vi.fn(), updateCircle: vi.fn(), updateCircleStatus: vi.fn() }))
const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))
vi.mock('@/services/circle', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:circle:read', 'operations:circle:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import CircleManagementView from './CircleManagementView.vue'

async function flush() { await Promise.resolve(); await Promise.resolve(); await nextTick() }
function mount() { const host=document.createElement('div'); const app=createApp(CircleManagementView); app.mount(host); return {host,app} }
const circle={id:3,region:'EU',name:'伦敦生活圈',description:'英国华人本地生活',coverUrl:'',memberCount:12,postCount:8,sort:20,status:1,joinedByCurrentUser:false}

describe('CircleManagementView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:circle:read', 'operations:circle:write']
    mocks.listCircles.mockResolvedValue({list:[circle],total:1,page:1,pageSize:20,hasMore:false})
  })
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

  it('updates an existing circle when write permission is available', async () => {
    mocks.updateCircle.mockResolvedValue({...circle,name:'伦敦华人生活圈'})
    const {host,app}=mount(); await flush()
    const editButton=[...host.querySelectorAll('button')].find((node)=>node.textContent?.trim()==='编辑')
    if(!editButton) throw new Error('找不到编辑按钮'); editButton.click(); await nextTick()
    const name=host.querySelector<HTMLInputElement>('input[name="circle-name"]'); if(!name) throw new Error('缺少名称输入框')
    name.value='伦敦华人生活圈'; name.dispatchEvent(new Event('input'))
    host.querySelector<HTMLFormElement>('[data-testid="circle-editor"]')?.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true})); await flush()
    expect(mocks.updateCircle).toHaveBeenCalledWith(3,{name:'伦敦华人生活圈',description:'英国华人本地生活',coverUrl:'',sort:20})
    app.unmount()
  })

  it('keeps circle browsing available while hiding every write control from read-only users', async () => {
    sessionMock.state.permissions = ['operations:circle:read']
    const {host,app}=mount(); await flush()
    expect(mocks.listCircles).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('伦敦生活圈')
    expect(host.textContent).toContain('成员 12 · 帖子 8 · 排序 20')
    expect(host.querySelector('[data-testid="circle-editor"]')).toBeNull()
    expect([...host.querySelectorAll('button')].map((button)=>button.textContent?.trim())).toEqual(['查询'])
    expect(mocks.createCircle).not.toHaveBeenCalled()
    expect(mocks.updateCircle).not.toHaveBeenCalled()
    expect(mocks.updateCircleStatus).not.toHaveBeenCalled()
    app.unmount()
  })

  it('blocks stale mutation handlers after write permission is revoked', async () => {
    const {host,app}=mount(); await flush()
    const editButton=[...host.querySelectorAll<HTMLButtonElement>('button')].find((node)=>node.textContent?.trim()==='编辑')
    const toggleButton=[...host.querySelectorAll<HTMLButtonElement>('button')].find((node)=>node.textContent?.trim()==='停用')
    if(!editButton||!toggleButton) throw new Error('缺少圈子写入按钮')
    editButton.click(); await nextTick()
    const form=host.querySelector<HTMLFormElement>('[data-testid="circle-editor"]')
    if(!form) throw new Error('缺少圈子编辑表单')

    sessionMock.state.permissions = ['operations:circle:read']
    form.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}))
    toggleButton.click()
    editButton.click()
    await flush()

    expect(mocks.createCircle).not.toHaveBeenCalled()
    expect(mocks.updateCircle).not.toHaveBeenCalled()
    expect(mocks.updateCircleStatus).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="circle-editor"]')).toBeNull()
    expect([...host.querySelectorAll('button')].map((button)=>button.textContent?.trim())).toEqual(['查询'])
    app.unmount()
  })
})
