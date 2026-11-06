export interface InvoiceTitle {
  id: number
  titleType: number
  name: string
  taxNo: string
  email: string
  isDefault: boolean
}

export interface InvoiceRequest {
  documentAvailable?: boolean
  documentFileName?: string
  documentSha256?: string
  documentSize?: number
  documentUploadedAt?: string
  receivedAt?: string

  id: number
  orderId: number
  titleId: number
  amount: number
  taxAmount: number
  currency: string
  status: number
  statusText: string
  invoiceNo: string
  rejectReason: string
  createdAt?: string
}
