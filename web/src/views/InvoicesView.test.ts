import { createApp, nextTick, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ fetchInvoices: vi.fn(), fetchInvoiceTitles: vi.fn(), createInvoiceTitle: vi.fn(), requestInvoice: vi.fn(), downloadInvoice: vi.fn(), confirmInvoiceReceipt: vi.fn(), saveDownload: vi.fn() }))
vi.mock('@/services/invoice', () => mocks)
vi.mock('@/lib/save-download', () => mocks)
vi.mock('vue-router', () => ({ useRoute: () => ({ query: {} }) }))
const state = reactive({ region: 'CN' })
const user = reactive({ currentUser: { id: 1 } })
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state }) }))
vi.mock('@/composables/useUserSession', () => ({ useUserSession: () => ({ state: user }) }))
import InvoicesView from './InvoicesView.vue'
const invoice = () => ({ id: 10, orderId: 5, status: 2, invoiceNo: 'INV-10', documentAvailable: true, documentSha256: 'a'.repeat(64), amount: 88, taxAmount: 5 })
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(InvoicesView); app.mount(host); return { host, app } }
function click(host: HTMLElement, id: string) { host.querySelector<HTMLButtonElement>(`[data-testid=${id}]`)!.click() }
describe('customer invoice documents', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(m => m.mockReset())
    state.region = 'CN'; user.currentUser = { id: 1 }
    mocks.fetchInvoices.mockResolvedValue({ list: [invoice()], page: 1, hasMore: false })
    mocks.fetchInvoiceTitles.mockResolvedValue([])
  })
  it('downloads without marking receipt and requires an explicit confirmation', async () => {
    const { host, app } = mount(); await flush()
    const blob = new Blob(['pdf']); mocks.downloadInvoice.mockResolvedValue(blob)
    click(host, 'invoice-download-10'); click(host, 'invoice-download-10'); await flush()
    expect(mocks.downloadInvoice).toHaveBeenCalledTimes(1)
    expect(mocks.saveDownload).toHaveBeenCalledWith(blob, 'invoice-10.pdf')
    expect(mocks.confirmInvoiceReceipt).not.toHaveBeenCalled()
    mocks.confirmInvoiceReceipt.mockResolvedValue({ ...invoice(), receivedAt: '2026-11-05' })
    click(host, 'invoice-receipt-10'); await flush()
    expect(mocks.confirmInvoiceReceipt).toHaveBeenCalledWith(10, 'a'.repeat(64))
    expect(host.textContent).toContain('已确认收到')
    expect(host.querySelector('[data-testid=invoice-receipt-10]')).toBeNull()
    app.unmount()
  })
  it('retains actions after download and receipt failures so users can retry', async () => {
    const { host, app } = mount(); await flush()
    mocks.downloadInvoice.mockRejectedValue(new Error('download offline'))
    click(host, 'invoice-download-10'); await flush()
    expect(host.textContent).toContain('download offline')
    expect(mocks.saveDownload).not.toHaveBeenCalled()
    mocks.confirmInvoiceReceipt.mockRejectedValueOnce(new Error('receipt offline'))
    click(host, 'invoice-receipt-10'); await flush()
    expect(host.textContent).toContain('receipt offline')
    expect(host.querySelector('[data-testid=invoice-receipt-10]')).not.toBeNull()
    app.unmount()
  })
  it('does not save another account’s late download or show stale invoice data', async () => {
    const { host, app } = mount(); await flush()
    let complete!: (v: Blob) => void
    mocks.downloadInvoice.mockReturnValue(new Promise(resolve => { complete = resolve }))
    click(host, 'invoice-download-10'); await flush()
    mocks.fetchInvoices.mockResolvedValue({ list: [], page: 1, hasMore: false })
    user.currentUser = { id: 2 }; await flush()
    complete(new Blob(['private'])); await flush()
    expect(mocks.saveDownload).not.toHaveBeenCalled()
    expect(host.textContent).not.toContain('INV-10')
    app.unmount()
  })
  it('shows legacy waiting state without a download button and pages history', async () => {
    mocks.fetchInvoices.mockResolvedValue({ list: [{ ...invoice(), documentAvailable: false }], page: 1, hasMore: true })
    const { host, app } = mount(); await flush()
    expect(host.textContent).toContain('待上传 PDF')
    expect(host.querySelector('[data-testid=invoice-download-10]')).toBeNull()
    const next = [...host.querySelectorAll('button')].find(b => b.textContent === '下一页')!
    next.click(); await flush()
    expect(mocks.fetchInvoices).toHaveBeenLastCalledWith(2)
    app.unmount()
  })
})
