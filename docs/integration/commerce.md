# Commerce endpoints

## Invoice

- GET /api/c/v1/invoices/titles
- POST /api/c/v1/invoices/titles
- GET /api/c/v1/invoices
- POST /api/c/v1/invoices
- GET /api/admin/v1/invoices
- POST /api/admin/v1/invoices/{id}/issue
- POST /api/admin/v1/invoices/{id}/reject
- GET /api/admin/v1/tax-rates
- PUT /api/admin/v1/tax-rates/{id}

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
