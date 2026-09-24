# 内容信任相关接口

消费者：

- `POST /api/c/v1/reviews/{id}/helpful` 切换「有用」，返回 `helpfulCount`、`voted`。`messageKey`: `review.helpful_toggled`
- `GET /api/c/v1/shops/{shopId}/reviews?sort=helpful` 按 `helpful_count` 降序，列表项含 `helpfulCount`
- `GET /api/c/v1/reviews/{id}/translations?lang=` 公开读取社区翻译，`lang` 可选（`zh` / `en`）
- `POST /api/c/v1/reviews/{id}/translations` 当前用户按目标语言 upsert。`messageKey`: `review.translation_saved`
- `GET /api/c/v1/shops/{shopId}/dishes/{dishId}/reviews` 菜品点评列表（公开）
- `POST /api/c/v1/shops/{shopId}/dishes/{dishId}/reviews` 发布菜品点评，`score` 1–5。`messageKey`: `dishreview.created`
- `GET /api/c/v1/user/level-privileges` 当前用户等级权益 `{level, levelName, growthValue, privileges}`
- `GET /api/c/v1/shops` 可选过滤：`chineseService`、`chineseMenu`、`acceptAlipay`、`acceptWechat`（为 true 时才过滤）
- `GET /api/c/v1/shops/{id}/amenities` 返回 `{chineseService, chineseMenu, acceptAlipay, acceptWechat}`

管理端：

- `GET /api/admin/v1/automod/hits?decision=&page=&pageSize=` 区域机审命中，权限 `audit:automod:read`
