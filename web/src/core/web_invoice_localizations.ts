import type { Region } from '@/types/browse'

export interface WebInvoiceStrings {
  eyebrow: string
  title: string
  summary: string
  titleType: string
  personal: string
  company: string
  name: string
  taxNo: string
  email: string
  saveTitle: string
  orderId: string
  titleId: string
  request: string
  loading: string
  empty: string
  loadFailed: string
  amount: string
  tax: string
  download: string
  confirmReceipt: string
  receiptHelp: string
  received: string
  awaiting: string
  downloadStarted: string
  previous: string
  next: string
  refresh: string
  pending: string
  issued: string
  rejected: string
}

const zh: WebInvoiceStrings = {
  eyebrow: '发票',
  title: '发票抬头与开票申请',
  summary: '只有已支付订单可以申请。企业抬头必须填写税号。同一订单不能重复申请。',
  titleType: '抬头类型',
  personal: '个人',
  company: '企业',
  name: '抬头名称',
  taxNo: '税号',
  email: '邮箱',
  saveTitle: '保存抬头',
  orderId: '订单号',
  titleId: '抬头',
  request: '申请开票',
  loading: '加载中...',
  empty: '还没有开票申请。',
  loadFailed: '发票加载失败',
  amount: '金额',
  tax: '税额',
  download: '下载 PDF',
  confirmReceipt: '确认收到',
  receiptHelp: '请打开并核对下载的发票，再确认收到。',
  received: '已确认收到',
  awaiting: '待上传 PDF',
  downloadStarted: '已开始下载，请打开文件核对后确认收到。',
  previous: '上一页',
  next: '下一页',
  refresh: '刷新',
  pending: '待开票',
  issued: '已登记开票',
  rejected: '已驳回',

}

const en: WebInvoiceStrings = {
  eyebrow: 'Invoices',
  title: 'Invoice titles and requests',
  summary: 'Only paid orders can be invoiced. A company title needs a tax number. Each order can be requested once.',
  titleType: 'Title type',
  personal: 'Personal',
  company: 'Company',
  name: 'Name',
  taxNo: 'Tax number',
  email: 'Email',
  saveTitle: 'Save title',
  orderId: 'Order',
  titleId: 'Title',
  request: 'Request invoice',
  loading: 'Loading...',
  empty: 'No invoice requests yet.',
  loadFailed: 'Could not load invoices',
  amount: 'Amount',
  tax: 'Tax',
  download: 'Download PDF',
  confirmReceipt: 'Confirm receipt',
  receiptHelp: 'Open and review the downloaded invoice before confirming receipt.',
  received: 'Receipt confirmed',
  awaiting: 'Awaiting PDF',
  downloadStarted: 'Download started. Review the file before confirming receipt.',
  previous: 'Previous',
  next: 'Next',
  refresh: 'Refresh',
  pending: 'Pending',
  issued: 'Invoice registered',
  rejected: 'Rejected',

}

export function invoiceStringsForRegion(region: Region) {
  return region === 'EU' ? en : zh
}
