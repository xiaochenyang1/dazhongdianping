# Commerce endpoints

## Invoice

- GET /api/c/v1/invoices/orders
- GET /api/c/v1/invoices/titles
- POST /api/c/v1/invoices/titles
- GET /api/c/v1/invoices
- POST /api/c/v1/invoices
- GET /api/admin/v1/invoices
- POST /api/admin/v1/invoices/{id}/issue
- POST /api/admin/v1/invoices/{id}/reject
- POST /api/admin/v1/invoices/{id}/document (multipart: `invoiceNo`, `file`)
- GET /api/admin/v1/invoices/{id}/document
- GET /api/c/v1/invoices/{id}/document
- POST /api/c/v1/invoices/{id}/receipt (JSON: `sha256`)
- GET /api/admin/v1/tax-rates
- PUT /api/admin/v1/tax-rates/{id}

`GET /api/c/v1/invoices/orders` requires a user session. It lists only the current
user's orders in `X-Region` with `pay_status=1` and no invoice request (including
pending, registered or rejected requests). Parameters: `page=1`, `pageSize=12`
(maximum 50), optional positive `orderId` for entry from an order detail page.
Foreign, wrong-region and ineligible IDs return an empty page, without disclosing
whether the order exists. Response data is `{list,total,page,pageSize,hasMore}`;
each item contains `id,orderNo,dealTitle,shopName,amount,currency`. Order selection
is advisory: `POST /invoices` still rechecks ownership, region, payment status,
title ownership and duplicate requests before writing.

Flutter now opens invoicing from a paid order detail or the user centre. Users
select an eligible order and an existing title, or create a personal/company title
with optional email. Company titles require a tax number. Saves select the ID
returned by the server; submissions prevent repeated taps, preserve failed input,
and distinguish a successful request from a subsequent refresh failure. Eligible
orders and request history both paginate. Registered invoice numbers and rejection
reasons are displayed. The existing issue endpoint records a number/status for
compatibility; an actual PDF requires the document endpoint below.

An administrator with `finance:invoice:write` uploads an already issued PDF
(maximum 5 MiB). Pending requests become issued atomically with publication;
registered requests accept a backfill only with their existing invoice number.
PDFBox 3.0.8 parses the bytes in strict mode and rejects malformed, encrypted or
zero-page documents. Same-number, same-SHA-256 retries are idempotent. A different
number or replacement PDF returns 409. This integration does not generate legal
invoices, contact a tax provider, send email, or verify tax signatures/content.

Downloads require the owning user's session and matching `X-Region`, or an admin
with `finance:invoice:read` in that region. They return an attachment named
`invoice-{id}.pdf`, `application/pdf`, `Cache-Control: no-store` and `nosniff`.
No public URL is created. Lists omit binary data and add `documentAvailable`,
`documentFileName`, `documentSha256`, `documentSize`, `documentUploadedAt` and
`receivedAt`. Authorized lists also include order number and invoice title details.
A successful GET never sets receipt: the customer explicitly confirms the expected
SHA-256, returning 409 if it differs. Repeated confirmations preserve the first
receipt timestamp. Admin publication/downloads produce audit records without PDF
bytes or tax details.

Migration `27_invoice_document_delivery_migration.sql` adds a private
`invoice_document` table with bounded MEDIUMBLOB content, SHA-256 and receipt
metadata. Existing migrations and the baseline-14 snapshot are unchanged. Apply
through migration 27 before starting the backend. Include this table in database
backup/restore, use binary-safe dumps (for example `mysqldump --hex-blob`) and a
`max_allowed_packet` comfortably above 5 MiB (16 MiB or higher). Size capacity and
backup time for accumulated PDFs; this implementation does not use public object
storage or deployment-local uploads.

Account export includes document metadata and `invoices/invoice-{id}.pdf` ZIP
entries only when the `invoices` module is selected, across the user's regions.
The account lock serializes publication, export, receipt and deletion; current
locking reads avoid stale snapshots when concurrent MySQL uploads retry. PDFs and
receipt metadata are deleted transactionally during account erasure, while the
existing minimum financial request records remain. Inactive/deleted owners cannot
receive a new PDF. No cleanup version bump is needed because the new table starts
empty and historical deleted owners cannot acquire documents.

## Marketing

- GET /api/b/v1/marketing/coupons
- POST /api/b/v1/marketing/coupons
- GET /api/b/v1/marketing/seckill
- POST /api/b/v1/marketing/seckill
- GET /api/b/v1/marketing/groupbuy
- POST /api/b/v1/marketing/groupbuy
- POST /api/admin/v1/marketing/coupon-templates/{id}/audit
- POST /api/admin/v1/marketing/seckill/{id}/audit
- POST /api/admin/v1/marketing/groupbuy/{id}/audit
- GET /api/c/v1/marketing/seckill
- POST /api/c/v1/marketing/seckill/{id}/claim
- GET /api/c/v1/marketing/groupbuy
- POST /api/c/v1/marketing/groupbuy/{id}/teams
- POST /api/c/v1/marketing/groupbuy/teams/{teamId}/join

## Ads

- GET /api/b/v1/ads/report

## Analytics

- GET /api/b/v1/analytics/trend
- GET /api/b/v1/analytics/export
