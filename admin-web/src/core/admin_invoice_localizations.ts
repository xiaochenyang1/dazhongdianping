import type { Region } from '@/types/admin'
const zh = {
  title: '发票与税率', summary: '上传已开具的 PDF 发票交付用户。支持为已登记的发票补传文件。',
  refresh: '刷新', empty: '暂无开票申请', amount: '金额 / 税额', customer: '订单与抬头', delivery: '开票与交付', actions: '操作',
  number: '发票号', file: 'PDF 发票（最大 5 MB）', upload: '上传并交付', rejectReason: '驳回原因', reject: '驳回',
  download: '下载 PDF', delivered: '已交付，待用户确认', received: '用户已确认收到', awaiting: '待上传 PDF',
  pending: '待开票', issued: '已登记开票', rejected: '已驳回', previous: '上一页', next: '下一页',
  rates: '税率', rateHelp: '税额使用当前区域已启用税率中 id 最大的一条计算。', rateName: '税率名称', rateBp: '税率（基点）',
  enabled: '启用', disabled: '停用', save: '保存', saved: '已保存', published: 'PDF 已交付', failed: '操作失败，请重试',
  invalid: '请填写发票号并选择不超过 5 MB 的 PDF 文件', reasonRequired: '请填写驳回原因', personal: '个人', company: '企业',
}
const en: typeof zh = {
  title: 'Invoices and tax rates', summary: 'Deliver issued PDF invoices to customers. Registered invoices can also receive a PDF.',
  refresh: 'Refresh', empty: 'No invoice requests', amount: 'Amount / Tax', customer: 'Order and title', delivery: 'Invoice delivery', actions: 'Actions',
  number: 'Invoice number', file: 'PDF invoice (up to 5 MB)', upload: 'Upload and deliver', rejectReason: 'Rejection reason', reject: 'Reject',
  download: 'Download PDF', delivered: 'Delivered, awaiting confirmation', received: 'Customer confirmed receipt', awaiting: 'Awaiting PDF',
  pending: 'Pending', issued: 'Invoice registered', rejected: 'Rejected', previous: 'Previous', next: 'Next',
  rates: 'Tax rates', rateHelp: 'Tax uses the enabled rate with the highest ID in this region.', rateName: 'Rate name', rateBp: 'Rate (basis points)',
  enabled: 'Enabled', disabled: 'Disabled', save: 'Save', saved: 'Saved', published: 'PDF delivered', failed: 'Action failed. Please retry.',
  invalid: 'Enter the invoice number and choose a PDF up to 5 MB', reasonRequired: 'Enter a rejection reason', personal: 'Personal', company: 'Company',
}
export const adminInvoiceStrings = (region: Region) => region === 'EU' ? en : zh
