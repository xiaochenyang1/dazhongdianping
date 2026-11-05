import { createApp, nextTick, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ fetchAdminInvoices: vi.fn(), fetchAdminTaxRates: vi.fn(), uploadAdminInvoice: vi.fn(), downloadAdminInvoice: vi.fn(), rejectAdminInvoice: vi.fn(), updateAdminTaxRate: vi.fn(), saveDownload: vi.fn() }))
vi.mock('@/services/ops', () => mocks)
vi.mock('@/lib/save-download', () => mocks)
const state = reactive({ region: 'CN', token: 'token', profile: { id: 1 }, permissions: ['finance:invoice:write'] })
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state }) }))
import InvoicesAdminView from './InvoicesAdminView.vue'
const item = () => ({ id: 10, userId: 1, orderId: 5, orderNo: 'ORDER-5', titleName: 'Test company', titleType: 2, taxNo: 'TAX-5', amount: 88, taxAmount: 5, currency: 'CNY', status: 1, invoiceNo: '', rejectReason: '' })
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(InvoicesAdminView); app.mount(host); return { host, app } }
function button(host: HTMLElement, text: string) { const b = [...host.querySelectorAll('button')].find(b => b.textContent?.includes(text)); if (!b) throw new Error(text); return b }
function choose(host: HTMLElement, name = 'invoice.pdf', size = 10) {
  const input = host.querySelector<HTMLInputElement>('[type=file]')!
  const file = new File(['x'.repeat(size)], name, { type: 'application/pdf' })
  Object.defineProperty(input, 'files', { value: [file], configurable: true })
  input.dispatchEvent(new Event('change'))
  return file
}
function number(host: HTMLElement) { const el = host.querySelector<HTMLInputElement>('[data-testid=invoice-number-10]')!; el.value = 'INV-10'; el.dispatchEvent(new Event('input')) }
function submit(host: HTMLElement) { host.querySelector('form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true })) }
describe('invoice PDF delivery admin', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(m => m.mockReset())
    state.region = 'CN'; state.token = 'token'; state.permissions = ['finance:invoice:write']
    mocks.fetchAdminInvoices.mockResolvedValue({ list: [item()], page: 1, hasMore: true })
    mocks.fetchAdminTaxRates.mockResolvedValue([])
  })
  it('preserves failed upload draft, prevents duplicate submit, and displays delivery', async () => {
    const { host, app } = mount(); await flush()
    expect(host.textContent).toContain('Test company'); expect(host.textContent).toContain('TAX-5')
    number(host); const file = choose(host); await flush()
    let reject!: (e: Error) => void
    mocks.uploadAdminInvoice.mockReturnValueOnce(new Promise((_, fail) => { reject = fail }))
    submit(host); submit(host); await flush()
    expect(mocks.uploadAdminInvoice).toHaveBeenCalledTimes(1)
    expect(mocks.uploadAdminInvoice).toHaveBeenCalledWith(10, 'INV-10', file)
    reject(new Error('upload offline')); await flush()
    expect(host.textContent).toContain('upload offline')
    expect(host.querySelector<HTMLInputElement>('[data-testid=invoice-number-10]')!.value).toBe('INV-10')
    mocks.uploadAdminInvoice.mockResolvedValue({ ...item(), status: 2, invoiceNo: 'INV-10', documentAvailable: true })
    submit(host); await flush()
    expect(host.textContent).toContain('已交付，待用户确认')
    expect(host.querySelector('[type=file]')).toBeNull()
    app.unmount()
  })
  it('rejects non-PDF choices and supports read-only downloads', async () => {
    const { host, app } = mount(); await flush()
    number(host); choose(host, 'photo.png'); submit(host); await flush()
    expect(mocks.uploadAdminInvoice).not.toHaveBeenCalled()
    expect(host.textContent).toContain('不超过 5 MB')
    state.permissions = []
    mocks.fetchAdminInvoices.mockResolvedValue({ list: [{ ...item(), status: 2, documentAvailable: true, receivedAt: '2026-11-05' }], page: 1, hasMore: false })
    button(host, '刷新').click(); await flush()
    expect(host.querySelector('[type=file]')).toBeNull()
    const blob = new Blob(['pdf']); mocks.downloadAdminInvoice.mockResolvedValue(blob)
    button(host, '下载 PDF').click(); await flush()
    expect(mocks.saveDownload).toHaveBeenCalledWith(blob, 'invoice-10.pdf')
    expect(host.textContent).toContain('用户已确认收到')
    app.unmount()
  })
  it('backfills the registered number and ignores late uploads after region switch', async () => {
    mocks.fetchAdminInvoices.mockResolvedValueOnce({ list: [{ ...item(), status: 2, invoiceNo: 'LEGACY' }], page: 1, hasMore: false })
    const { host, app } = mount(); await flush()
    choose(host); await flush()
    let complete!: (v: object) => void
    mocks.uploadAdminInvoice.mockReturnValueOnce(new Promise(resolve => { complete = resolve }))
    submit(host); await flush()
    expect(mocks.uploadAdminInvoice.mock.calls[0]?.[1]).toBe('LEGACY')
    mocks.fetchAdminInvoices.mockResolvedValue({ list: [], page: 1, hasMore: false })
    state.region = 'EU'; await flush()
    complete({ ...item(), status: 2, documentAvailable: true }); await flush()
    expect(host.textContent).toContain('No invoice requests')
    expect(host.textContent).not.toContain('PDF delivered')
    app.unmount()
  })
  it('pages through legacy requests', async () => {
    const { host, app } = mount(); await flush()
    mocks.fetchAdminInvoices.mockResolvedValue({ list: [], page: 2, hasMore: false })
    button(host, '下一页').click(); await flush()
    expect(mocks.fetchAdminInvoices).toHaveBeenLastCalledWith(2)
    app.unmount()
  })
})
