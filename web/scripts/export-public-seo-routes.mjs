import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { prerender } from './prerender.mjs'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const webRoot = path.resolve(scriptDir, '..')
const defaultOutputPath = path.join(webRoot, 'dist', 'prerender-routes.json')

function text(value, fallback = '') {
  if (value == null) return fallback
  const normalized = String(value).replace(/\s+/g, ' ').trim()
  return normalized || fallback
}

function truncate(value, maxLength = 160) {
  const normalized = text(value)
  if (normalized.length <= maxLength) return normalized
  return `${normalized.slice(0, Math.max(1, maxLength - 3))}...`
}

function regional(region, cn, eu) {
  return region === 'EU' ? eu : cn
}

function englishCount(count, singular, plural = `${singular}s`) {
  return `${count} ${count === 1 ? singular : plural}`
}

function formatSnapshotDate(value, region) {
  const raw = text(value)
  const match = raw.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2}))?/)
  if (!match) return raw
  const [, year, month, day, hour = '00', minute = '00'] = match
  return region === 'EU'
    ? `${day}/${month}/${year} ${hour}:${minute}`
    : `${year}/${Number(month)}/${Number(day)} ${hour}:${minute}`
}

function rankTypeLabel(rank, region) {
  const labels = region === 'EU'
    ? { 1: 'Must-try', 2: 'Top-rated', 3: 'Popular' }
    : { 1: '必吃榜', 2: '好评榜', 3: '热门榜' }
  return labels[Number(rank.type)] || text(rank.typeText, regional(region, '城市榜单', 'city ranking'))
}

function activityChannelLabel(activity, region) {
  const labels = region === 'EU'
    ? { 1: 'Home', 2: 'Search', 3: 'Channel', 4: 'Activity page', 5: 'Community' }
    : { 1: '首页', 2: '搜索', 3: '频道', 4: '活动页', 5: '社区' }
  return labels[Number(activity.channel)] || text(activity.channelText, regional(region, '活动页', 'Activity page'))
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

function routeUrl(routePath, siteUrl = '') {
  return siteUrl ? new URL(routePath, siteUrl).href : routePath
}

function asList(value) {
  return Array.isArray(value) ? value : []
}

function boundedInteger(value, fallback, minimum, maximum) {
  const parsed = Number(value)
  if (!Number.isFinite(parsed)) return fallback
  return Math.min(maximum, Math.max(minimum, Math.trunc(parsed)))
}

function pageList(value) {
  return asList(value?.list)
}

function htmlList(items, renderItem) {
  const rows = items.map(renderItem).join('')
  return rows ? `<ul>${rows}</ul>` : ''
}

function internalLink(pathValue, label) {
  const target = text(pathValue)
  if (!target.startsWith('/')) return ''
  return `<a href="${escapeHtml(target)}">${escapeHtml(label || target)}</a>`
}

function shopRoute(shop, siteUrl, region) {
  const routePath = `/shops/${shop.id}`
  const name = text(shop.name, regional(region, `门店 ${shop.id}`, `Place ${shop.id}`))
  const city = text(shop.cityName)
  const category = text(shop.categoryName)
  const address = text(shop.address, regional(region, '地址待补充', 'Address not available'))
  const placeScope = [city, category].filter(Boolean).join(' · ')
  const publicInfo = region === 'EU'
    ? `${placeScope ? `${placeScope} public` : 'Public'} place information.`
    : `${city}${category ? ` · ${category}` : ''}公开门店信息。`
  const summary = text(shop.summary, publicInfo)
  const description = truncate(region === 'EU' ? `${summary} Address: ${address}.` : `${summary} 地址：${address}。`)
  const score = Number.isFinite(Number(shop.score)) ? Number(shop.score).toFixed(1) : '—'
  const canonical = routeUrl(routePath, siteUrl)
  return {
    path: routePath,
    title: region === 'EU'
      ? `${name}${city ? ` - ${city}` : ''}${category ? ` · ${category}` : ''}`
      : `${name}${city ? ` - ${city}` : ''}${category ? `${category}` : ''}`,
    description,
    heading: name,
    summary: `${[city, category, `${regional(region, '评分', 'Rating')} ${score}`].filter(Boolean).join(' · ')} · ${address}`,
    image: text(shop.coverUrl) || undefined,
    schemaType: 'Restaurant',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'Restaurant',
      name,
      description: summary,
      url: canonical,
      image: text(shop.coverUrl) || undefined,
      telephone: text(shop.phone) || undefined,
      servesCuisine: category || undefined,
      openingHours: text(shop.businessHours) || undefined,
      address: {
        '@type': 'PostalAddress',
        streetAddress: address,
        addressLocality: city || undefined,
        addressRegion: text(shop.areaName) || undefined,
      },
      aggregateRating: Number.isFinite(Number(shop.score))
        ? { '@type': 'AggregateRating', ratingValue: Number(shop.score), bestRating: 5, worstRating: 1 }
        : undefined,
    },
    contentHtml: [
      `<dl data-snapshot-kind="shop">`,
      `<div><dt>${regional(region, '评分', 'Rating')}</dt><dd>${escapeHtml(score)}</dd></div>`,
      `<div><dt>${regional(region, '地址', 'Address')}</dt><dd>${escapeHtml(address)}</dd></div>`,
      `<div><dt>${regional(region, '营业时间', 'Opening hours')}</dt><dd>${escapeHtml(text(shop.businessHours, '—'))}</dd></div>`,
      `<div><dt>${regional(region, '电话', 'Phone')}</dt><dd>${escapeHtml(text(shop.phone, '—'))}</dd></div>`,
      '</dl>',
      `<p>${escapeHtml(summary)}</p>`,
      `<p>${internalLink(`/shops/${shop.id}/reviews`, regional(region, '查看门店点评', 'View place reviews'))}</p>`,
    ].join(''),
  }
}

function reviewRoute(review, siteUrl, region) {
  const routePath = `/reviews/${review.id}`
  const shopName = text(review.shopName, regional(region, `门店 ${review.shopId}`, `Place ${review.shopId}`))
  const userName = text(review.userName, regional(region, '匿名用户', 'Anonymous user'))
  const content = text(review.content, regional(region, '公开点评内容待补充。', 'Public review content is not available.'))
  const visible = Number(review.auditStatus) === 1 && Number(review.status) === 1
  const canonical = routeUrl(routePath, siteUrl)
  const rating = Number.isFinite(Number(review.scoreOverall)) ? Number(review.scoreOverall).toFixed(1) : '—'
  const route = {
    path: routePath,
    title: region === 'EU' ? `${shopName} review - ${userName}` : `${shopName}点评 - ${userName}`,
    description: truncate(region === 'EU' ? `Public review of ${shopName}: ${content}` : `${shopName} 的公开点评：${content}`),
    heading: region === 'EU' ? `${shopName} review` : `${shopName}点评`,
    summary: `${userName} · ${region === 'EU' ? `${rating}/5` : `${rating} 分`} · ${truncate(content, 110)}`,
    robots: visible ? 'index,follow' : 'noindex,nofollow',
    schemaType: 'Review',
    ogType: 'article',
    contentHtml: [
      `<article data-snapshot-kind="review">`,
      `<p><strong>${escapeHtml(userName)}</strong> · ${escapeHtml(formatSnapshotDate(review.createdAt, region))}</p>`,
      `<p>${escapeHtml(content)}</p>`,
      `<p>${internalLink(`/shops/${review.shopId}`, regional(region, `返回${shopName}`, `Back to ${shopName}`))}</p>`,
      '</article>',
    ].join(''),
  }
  if (visible) {
    route.jsonLd = {
      '@context': 'https://schema.org',
      '@type': 'Review',
      url: canonical,
      author: { '@type': 'Person', name: userName },
      datePublished: text(review.createdAt) || undefined,
      reviewBody: content,
      reviewRating: {
        '@type': 'Rating',
        ratingValue: Number(review.scoreOverall),
        bestRating: 5,
        worstRating: 1,
      },
      itemReviewed: { '@type': 'Restaurant', name: shopName, url: routeUrl(`/shops/${review.shopId}`, siteUrl) },
    }
  }
  return route
}

function postRoute(post, siteUrl, region) {
  const routePath = `/community/posts/${post.id}`
  const title = text(post.title, regional(region, `社区帖子 ${post.id}`, `Community post ${post.id}`))
  const content = text(post.content, regional(region, '公开社区帖子内容待补充。', 'Public post content is not available.'))
  const userName = text(post.userName, regional(region, '社区用户', 'Community user'))
  const images = asList(post.images).filter(Boolean)
  const canonical = routeUrl(routePath, siteUrl)
  return {
    path: routePath,
    title,
    description: truncate(content),
    heading: title,
    summary: `${userName} · ${truncate(content, 120)}`,
    image: text(images[0]) || undefined,
    schemaType: 'Article',
    ogType: 'article',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: title,
      description: truncate(content),
      articleBody: content,
      articleSection: asList(post.topics),
      url: canonical,
      image: images.map((image) => routeUrl(image, siteUrl)),
      author: { '@type': 'Person', name: userName, url: routeUrl(`/users/${post.userId}`, siteUrl) },
      datePublished: text(post.createdAt) || undefined,
      interactionStatistic: [
        { '@type': 'InteractionCounter', interactionType: 'https://schema.org/LikeAction', userInteractionCount: Number(post.likeCount) || 0 },
        { '@type': 'InteractionCounter', interactionType: 'https://schema.org/CommentAction', userInteractionCount: Number(post.commentCount) || 0 },
      ],
    },
    contentHtml: [
      `<article data-snapshot-kind="post">`,
      `<p><strong>${escapeHtml(userName)}</strong> · ${escapeHtml(formatSnapshotDate(post.createdAt, region))}</p>`,
      `<p>${escapeHtml(content)}</p>`,
      images.map((image) => `<img src="${escapeHtml(image)}" alt="${escapeHtml(title)}">`).join(''),
      '</article>',
    ].join(''),
  }
}

function rankRoute(rank, siteUrl, region) {
  const routePath = `/ranks/${rank.id}`
  const name = text(rank.name, regional(region, `城市榜单 ${rank.id}`, `City ranking ${rank.id}`))
  const city = text(rank.cityName)
  const category = text(rank.categoryName)
  const items = asList(rank.items)
  const canonical = routeUrl(routePath, siteUrl)
  const type = rankTypeLabel(rank, region)
  const updatedAt = formatSnapshotDate(rank.updatedAt, region) || regional(region, '近期', 'recently')
  const description = region === 'EU'
    ? `${[city, category].filter(Boolean).join(' ')} ${type} ranking, updated ${updatedAt}.`
    : `${city}${category ? ` ${category}` : ''}的${type}，更新于 ${updatedAt}。`
  return {
    path: routePath,
    title: name,
    description: truncate(description),
    heading: name,
    summary: `${city} · ${category} · ${text(rank.period, regional(region, '当前周期', 'Current period'))} · ${regional(region, `共 ${items.length} 家上榜门店`, englishCount(items.length, 'ranked place'))}`,
    image: text(rank.coverUrl) || text(items[0]?.shop?.coverUrl) || undefined,
    schemaType: 'CollectionPage',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name,
      description: truncate(region === 'EU' ? `${[city, category].filter(Boolean).join(' ')} city ranking.` : `${city}${category ? ` ${category}` : ''}的城市榜单。`),
      url: canonical,
      mainEntity: {
        '@type': 'ItemList',
        itemListElement: items.map((item, index) => ({
          '@type': 'ListItem',
          position: Number(item.position) || index + 1,
          name: text(item.shop?.name, regional(region, `上榜门店 ${index + 1}`, `Ranked place ${index + 1}`)),
          url: routeUrl(`/shops/${item.shop?.id}`, siteUrl),
          description: truncate(item.reason),
        })),
      },
    },
    contentHtml: [
      `<ol data-snapshot-kind="rank">`,
      items.map((item, index) => `<li><strong>${escapeHtml(text(item.shop?.name, regional(region, `上榜门店 ${index + 1}`, `Ranked place ${index + 1}`)))}</strong> · ${escapeHtml(truncate(item.reason, 120))} ${internalLink(`/shops/${item.shop?.id}`, regional(region, '查看门店', 'View place'))}</li>`).join(''),
      '</ol>',
    ].join(''),
  }
}

function activityRoute(activity, siteUrl, region) {
  const routePath = `/activities/${activity.id}`
  const name = text(activity.name, regional(region, `运营活动 ${activity.id}`, `Activity ${activity.id}`))
  const items = asList(activity.items)
  const canonical = routeUrl(routePath, siteUrl)
  const city = text(activity.cityName)
  const channel = activityChannelLabel(activity, region)
  return {
    path: routePath,
    title: name,
    description: truncate(region === 'EU' ? `${city} ${channel} activity with ${englishCount(items.length, 'public resource')}.` : `${city} ${channel}活动，${items.length} 个公开资源。`),
    heading: name,
    summary: `${city} · ${channel} · ${regional(region, `${items.length} 个公开资源`, englishCount(items.length, 'public resource'))}`,
    image: text(activity.cover) || undefined,
    schemaType: 'CollectionPage',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name,
      description: truncate(region === 'EU' ? `${city} ${channel} activity.` : `${city} ${channel}活动。`),
      url: canonical,
      mainEntity: {
        '@type': 'ItemList',
        itemListElement: items.map((item, index) => ({
          '@type': 'ListItem',
          position: index + 1,
          name: text(item.title, text(item.targetName, regional(region, `活动资源 ${index + 1}`, `Activity resource ${index + 1}`))),
          url: routeUrl(text(item.linkUrl, routePath), siteUrl),
          description: truncate(item.subtitle || item.targetName),
        })),
      },
    },
    contentHtml: [
      `<ul data-snapshot-kind="activity">`,
      items.map((item, index) => `<li><strong>${escapeHtml(text(item.title, text(item.targetName, regional(region, `活动资源 ${index + 1}`, `Activity resource ${index + 1}`))))}</strong> · ${escapeHtml(text(item.subtitle, text(item.targetName, regional(region, '公开资源', 'Public resource'))))} ${internalLink(item.linkUrl, regional(region, '查看', 'View'))}</li>`).join(''),
      '</ul>',
    ].join(''),
  }
}

function circleRoute(circle, posts, siteUrl, region) {
  const routePath = `/groups/${circle.id}`
  const name = text(circle.name, regional(region, `官方圈子 ${circle.id}`, `Official group ${circle.id}`))
  const description = text(circle.description, regional(region, '当前区域官方社区圈子。', 'Official community group for the current region.'))
  const canonical = routeUrl(routePath, siteUrl)
  const members = Number(circle.memberCount) || 0
  const postCount = Number(circle.postCount) || 0
  return {
    path: routePath,
    title: name,
    description: truncate(description),
    heading: name,
    summary: `${description} ${regional(region, `${members} 位成员 · ${postCount} 篇帖子`, `${englishCount(members, 'member')} · ${englishCount(postCount, 'post')}`)}`,
    image: text(circle.coverUrl) || undefined,
    schemaType: 'CollectionPage',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name,
      description: truncate(description),
      url: canonical,
      about: { '@type': 'Organization', name },
      mainEntity: {
        '@type': 'ItemList',
        itemListElement: posts.map((post, index) => ({
          '@type': 'ListItem', position: index + 1, name: text(post.title), url: routeUrl(`/community/posts/${post.id}`, siteUrl),
        })),
      },
    },
    contentHtml: [
      `<p data-snapshot-kind="circle"><strong>${regional(region, `${escapeHtml(members)} 位成员`, englishCount(members, 'member'))}</strong> · ${regional(region, `${escapeHtml(postCount)} 篇帖子`, englishCount(postCount, 'post'))}</p>`,
      htmlList(posts, (post) => `<li>${internalLink(`/community/posts/${post.id}`, text(post.title, regional(region, '公开帖子', 'Public post')))}</li>`),
    ].join(''),
  }
}

function topicRoute(topic, posts, siteUrl, region) {
  const routePath = `/topics/${topic.id}`
  const name = text(topic.name, regional(region, `话题 ${topic.id}`, `Topic ${topic.id}`))
  const followers = Number(topic.followerCount) || 0
  const postCount = Number(topic.postCount) || 0
  const hotScore = Number(topic.hotScore) || 0
  const description = region === 'EU'
    ? `${englishCount(followers, 'follower')} and ${englishCount(postCount, 'public post')}. Local discussions and shared experiences about ${name}.`
    : `${followers} 人关注，${postCount} 篇公开帖子。${name} 的城市生活讨论与经验分享。`
  const canonical = routeUrl(routePath, siteUrl)
  return {
    path: routePath,
    title: `#${name}`,
    description: truncate(description),
    heading: `#${name}`,
    summary: regional(region, `${followers} 人关注 · ${postCount} 篇公开帖子 · 热度 ${hotScore}`, `${englishCount(followers, 'follower')} · ${englishCount(postCount, 'public post')} · Popularity ${hotScore}`),
    schemaType: 'CollectionPage',
    jsonLd: {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name,
      description: truncate(description),
      url: canonical,
      about: { '@type': 'Thing', name },
      mainEntity: {
        '@type': 'ItemList',
        itemListElement: posts.map((post, index) => ({
          '@type': 'ListItem', position: index + 1, name: text(post.title), url: routeUrl(`/community/posts/${post.id}`, siteUrl),
        })),
      },
    },
    contentHtml: [
      `<p data-snapshot-kind="topic"><strong>${regional(region, `${escapeHtml(followers)} 人关注`, englishCount(followers, 'follower'))}</strong> · ${regional(region, `${escapeHtml(postCount)} 篇公开帖子`, englishCount(postCount, 'public post'))} · ${regional(region, '热度', 'Popularity')} ${escapeHtml(hotScore)}</p>`,
      htmlList(posts, (post) => `<li>${internalLink(`/community/posts/${post.id}`, text(post.title, regional(region, '公开帖子', 'Public post')))}</li>`),
    ].join(''),
  }
}

export function createPublicApiClient({ baseUrl, region, fetchImpl = globalThis.fetch } = {}) {
  if (!baseUrl) throw new Error('PRERENDER_API_BASE_URL is required')
  if (typeof fetchImpl !== 'function') throw new Error('global fetch is unavailable')
  const base = new URL(baseUrl)
  return async (endpoint, params = {}) => {
    const url = new URL(endpoint, base)
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value))
    }
    const response = await fetchImpl(url, { headers: { Accept: 'application/json', 'X-Region': region } })
    if (!response.ok) throw new Error(`${endpoint} returned HTTP ${response.status}`)
    const envelope = await response.json()
    if (!envelope || envelope.code !== 0) throw new Error(`${endpoint} returned ${envelope?.message || 'an API error'}`)
    return envelope.data
  }
}

async function mapLimit(items, limit, worker) {
  const results = new Array(items.length)
  let cursor = 0
  async function consume() {
    while (cursor < items.length) {
      const index = cursor++
      results[index] = await worker(items[index], index)
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, Math.max(items.length, 1)) }, consume))
  return results
}

function uniqueRoutes(routes) {
  const map = new Map()
  for (const route of routes) {
    if (route?.path) map.set(route.path, route)
  }
  return [...map.values()]
}

export async function collectPublicSeoRoutes(options = {}) {
  const region = options.region || process.env.PRERENDER_REGION || 'CN'
  if (!['CN', 'EU'].includes(region)) throw new Error('PRERENDER_REGION must be CN or EU')
  const siteUrl = options.siteUrl ?? process.env.PUBLIC_SITE_URL ?? ''
  const pageSize = boundedInteger(options.pageSize || process.env.PRERENDER_PAGE_SIZE, 50, 1, 50)
  const maxReviews = boundedInteger(options.maxReviews || process.env.PRERENDER_MAX_REVIEWS, 100, 0, 500)
  const maxPosts = boundedInteger(options.maxPosts || process.env.PRERENDER_MAX_POSTS, 50, 0, 50)
  const strict = options.strict ?? process.env.PRERENDER_STRICT !== '0'
  const get = options.get || createPublicApiClient({ baseUrl: options.baseUrl || process.env.PRERENDER_API_BASE_URL, region, fetchImpl: options.fetchImpl })
  const warnings = []
  const routes = []
  const seenReviews = new Set()

  async function optional(label, action) {
    try {
      return await action()
    } catch (error) {
      if (strict) throw error
      warnings.push(`${label}: ${error instanceof Error ? error.message : String(error)}`)
      return null
    }
  }

  const shopsPage = await optional('shops', () => get('/api/c/v1/search/shops', { page: 1, pageSize }))
  const shops = pageList(shopsPage)
  const shopDetails = await mapLimit(shops, 6, (shop) => optional(`shop ${shop.id}`, () => get(`/api/c/v1/shops/${shop.id}`)))
  for (let index = 0; index < shopDetails.length; index += 1) {
    const detail = shopDetails[index]
    if (!detail) continue
    routes.push(shopRoute(detail, siteUrl, region))
    if (maxReviews > 0) {
      const reviewPage = await optional(`reviews for shop ${detail.id}`, () => get(`/api/c/v1/shops/${detail.id}/reviews`, { page: 1, pageSize: Math.min(50, maxReviews) }))
      for (const preview of pageList(reviewPage)) {
        if (seenReviews.has(preview.id) || seenReviews.size >= maxReviews) continue
        seenReviews.add(preview.id)
        const review = await optional(`review ${preview.id}`, () => get(`/api/c/v1/reviews/${preview.id}`))
        if (review) routes.push(reviewRoute(review, siteUrl, region))
      }
    }
  }

  if (maxPosts > 0) {
    const postPage = await optional('posts', () => get('/api/c/v1/posts', { page: 1, pageSize: maxPosts }))
    for (const preview of pageList(postPage)) {
      const post = await optional(`post ${preview.id}`, () => get(`/api/c/v1/posts/${preview.id}`))
      if (post) routes.push(postRoute(post, siteUrl, region))
    }
  }

  const rankList = await optional('ranks', () => get('/api/c/v1/ranks'))
  for (const summary of asList(rankList)) {
    const detail = await optional(`rank ${summary.id}`, () => get(`/api/c/v1/ranks/${summary.id}`))
    if (detail) routes.push(rankRoute({ ...summary, ...detail }, siteUrl, region))
  }

  const activityList = await optional('activities', () => get('/api/c/v1/activities', { limit: pageSize }))
  for (const summary of asList(activityList)) {
    const detail = await optional(`activity ${summary.id}`, () => get(`/api/c/v1/activities/${summary.id}`))
    if (detail) routes.push(activityRoute({ ...summary, ...detail }, siteUrl, region))
  }

  const circlePage = await optional('circles', () => get('/api/c/v1/groups', { page: 1, pageSize }))
  for (const summary of pageList(circlePage)) {
    const detail = await optional(`circle ${summary.id}`, () => get(`/api/c/v1/groups/${summary.id}`))
    const postPageForCircle = maxPosts > 0
      ? await optional(`circle posts ${summary.id}`, () => get(`/api/c/v1/groups/${summary.id}/posts`, { page: 1, pageSize: Math.min(30, maxPosts) }))
      : { list: [] }
    if (detail) routes.push(circleRoute(detail, pageList(postPageForCircle), siteUrl, region))
  }

  const topicPage = await optional('topics', () => get('/api/c/v1/topics', { sort: 'latest', page: 1, pageSize }))
  for (const summary of pageList(topicPage)) {
    const detail = await optional(`topic ${summary.id}`, () => get(`/api/c/v1/topics/${summary.id}`))
    const postPageForTopic = maxPosts > 0
      ? await optional(`topic posts ${summary.id}`, () => get(`/api/c/v1/topics/${summary.id}/posts`, { page: 1, pageSize: Math.min(30, maxPosts) }))
      : { list: [] }
    if (detail) routes.push(topicRoute(detail, pageList(postPageForTopic), siteUrl, region))
  }

  return { region, routes: uniqueRoutes(routes), warnings }
}

export async function writePublicSeoRouteManifest(options = {}) {
  const outputPath = path.resolve(options.outputPath || defaultOutputPath)
  const result = await collectPublicSeoRoutes(options)
  await mkdir(path.dirname(outputPath), { recursive: true })
  const payload = {
    generatedAt: new Date().toISOString(),
    region: result.region,
    source: options.baseUrl || process.env.PRERENDER_API_BASE_URL,
    routes: result.routes,
    warnings: result.warnings,
  }
  await writeFile(outputPath, `${JSON.stringify(payload.routes, null, 2)}\n`, 'utf8')
  return { ...result, outputPath, payload }
}

function optionValue(name) {
  const index = process.argv.indexOf(name)
  return index >= 0 ? process.argv[index + 1] : undefined
}

async function main() {
  const outputPath = optionValue('--output') || defaultOutputPath
  const result = await writePublicSeoRouteManifest({ outputPath })
  process.stdout.write(`[seo-snapshot] generated ${result.routes.length} routes for ${result.region} -> ${result.outputPath}\n`)
  for (const warning of result.warnings) process.stdout.write(`[seo-snapshot] warning: ${warning}\n`)
  if (process.argv.includes('--and-prerender')) {
    const manifest = await prerender({ extraRouteManifestPath: result.outputPath, region: result.region })
    process.stdout.write(`[seo-snapshot] prerendered ${manifest.routes.length} total routes\n`)
  }
}

if (import.meta.url === pathToFileURL(process.argv[1] || '').href) {
  main().catch((error) => {
    process.stderr.write(`[seo-snapshot] ${error instanceof Error ? error.message : String(error)}\n`)
    process.exitCode = 1
  })
}
