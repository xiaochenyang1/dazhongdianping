import { access, mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const defaultDistDir = path.join(webRoot, 'dist')

const PRERENDER_LOCALES = {
  CN: { tag: 'zh-CN', brand: '大众点评(仿)', publicLinks: '公开页面入口' },
  EU: { tag: 'en', brand: 'Local Reviews (Demo)', publicLinks: 'Public page links' },
}

function prerenderLocale(region) {
  if (!PRERENDER_LOCALES[region]) throw new Error('PRERENDER_REGION must be CN or EU')
  return PRERENDER_LOCALES[region]
}

function defaultRouteManifestPath(region) {
  return path.join(webRoot, region === 'EU' ? 'seo-routes.eu.json' : 'seo-routes.json')
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

function escapeJsonForHtml(value) {
  return JSON.stringify(value).replaceAll('<', '\\u003c')
}

export function normalizeRoutePath(value) {
  const rawValue = String(value || '/').trim()
  const rawPath = rawValue.split(/[?#]/, 1)[0]
  const rawSegments = rawPath.split('/').filter(Boolean)
  const unsafeSegment = rawSegments.some((segment) => {
    let decoded = segment
    try {
      decoded = decodeURIComponent(segment)
    } catch {
      return true
    }
    return decoded === '.' || decoded === '..' || decoded.includes('\\') || decoded.includes('/')
  })
  if (unsafeSegment) {
    throw new Error(`Unsafe prerender route: ${value}`)
  }

  const parsed = new URL(rawValue, 'https://prerender.invalid')
  const normalized = parsed.pathname.replace(/\/{2,}/g, '/').replace(/\/$/, '') || '/'
  return normalized
}

export function canonicalUrl(routePath, siteUrl = '') {
  const normalizedRoute = normalizeRoutePath(routePath)
  if (!siteUrl) {
    return normalizedRoute
  }
  return new URL(normalizedRoute, siteUrl).href
}

function routeOutputPath(distDir, routePath) {
  const normalizedRoute = normalizeRoutePath(routePath)
  if (normalizedRoute === '/') {
    return path.join(distDir, 'index.html')
  }

  return path.join(distDir, ...normalizedRoute.slice(1).split('/'), 'index.html')
}

function removeGeneratedSeo(html) {
  return html
    .replace(/\s*<meta\s+name=["'](?:description|robots|twitter:card)["'][^>]*>/gi, '')
    .replace(/\s*<meta\s+property=["']og:(?:title|description|url|type|image)["'][^>]*>/gi, '')
    .replace(/\s*<link\s+rel=["']canonical["'][^>]*>/gi, '')
    .replace(/\s*<script\s+type=["']application\/ld\+json["'][^>]*data-prerender-seo[^>]*>[\s\S]*?<\/script>/gi, '')
}

function renderFallback(route, routes, locale) {
  const links = routes
    .filter((item) => item.path !== route.path && item.path.split('/').filter(Boolean).length <= 1)
    .slice(0, 12)
    .map((item) => `<a href="${escapeHtml(item.path)}">${escapeHtml(item.title)}</a>`)
    .join(' · ')

  return [
    `<main data-prerendered="true" data-prerender-route="${escapeHtml(route.path)}">`,
    `<h1>${escapeHtml(route.heading)}</h1>`,
    `<p>${escapeHtml(route.summary)}</p>`,
    route.contentHtml || '',
    links ? `<nav aria-label="${locale.publicLinks}">${links}</nav>` : '',
    '</main>',
  ].join('')
}

export function buildPrerenderHtml(template, route, routes, siteUrl = '', region = 'CN') {
  const locale = prerenderLocale(region)
  const normalizedRoute = { ...route, path: normalizeRoutePath(route.path) }
  const canonical = canonicalUrl(normalizedRoute.path, siteUrl)
  const pageTitle = `${normalizedRoute.title} | ${locale.brand}`
  const schema = normalizedRoute.jsonLd ?? {
    '@context': 'https://schema.org',
    '@type': normalizedRoute.schemaType || 'WebPage',
    name: normalizedRoute.title,
    description: normalizedRoute.description,
    url: canonical,
  }
  const seoTags = [
    `<meta name="description" content="${escapeHtml(normalizedRoute.description)}">`,
    `<meta name="robots" content="${escapeHtml(normalizedRoute.robots || 'index,follow')}">`,
    `<link rel="canonical" href="${escapeHtml(canonical)}">`,
    `<meta property="og:title" content="${escapeHtml(normalizedRoute.title)}">`,
    `<meta property="og:description" content="${escapeHtml(normalizedRoute.description)}">`,
    `<meta property="og:url" content="${escapeHtml(canonical)}">`,
    `<meta property="og:type" content="${escapeHtml(normalizedRoute.ogType || 'website')}">`,
    `<meta name="twitter:card" content="${normalizedRoute.image ? 'summary_large_image' : 'summary'}">`,
    normalizedRoute.image ? `<meta property="og:image" content="${escapeHtml(normalizedRoute.image)}">` : '',
    `<script type="application/ld+json" data-prerender-seo>${escapeJsonForHtml(schema)}</script>`,
  ].filter(Boolean).join('\n    ')

  let html = removeGeneratedSeo(template)
  html = html.replace(/<html(?:\s+lang=["'][^"']*["'])?/i, `<html lang="${locale.tag}"`)
  if (/<title>[\s\S]*?<\/title>/i.test(html)) {
    html = html.replace(/<title>[\s\S]*?<\/title>/i, `<title>${escapeHtml(pageTitle)}</title>`)
  } else {
    html = html.replace('</head>', `    <title>${escapeHtml(pageTitle)}</title>\n  </head>`)
  }
  html = html.replace('</head>', `    ${seoTags}\n  </head>`)

  const fallback = `<div id="app">${renderFallback(normalizedRoute, routes, locale)}</div>`
  if (!/<div\s+id=["']app["']\s*>\s*<\/div>/i.test(html)) {
    throw new Error('Built index.html must contain an empty #app element before prerendering')
  }
  return html.replace(/<div\s+id=["']app["']\s*>\s*<\/div>/i, fallback)
}

function parseSiteUrl(value) {
  const normalized = String(value || '').trim()
  if (!normalized) return ''
  const url = new URL(normalized)
  if (!['http:', 'https:'].includes(url.protocol)) {
    throw new Error('PUBLIC_SITE_URL must use http or https')
  }
  if (url.pathname !== '/' || url.search || url.hash) {
    throw new Error('PUBLIC_SITE_URL must be an origin without a path, query or hash')
  }
  url.hash = ''
  url.search = ''
  return url.href.replace(/\/$/, '')
}

async function loadRoutes(routeManifestPath, extraRouteManifestPath) {
  const routes = JSON.parse(await readFile(routeManifestPath, 'utf8'))
  if (!Array.isArray(routes) || routes.length === 0) {
    throw new Error('seo-routes.json must contain at least one route')
  }

  if (extraRouteManifestPath) {
    const extraRoutes = JSON.parse(await readFile(path.resolve(extraRouteManifestPath), 'utf8'))
    if (!Array.isArray(extraRoutes)) {
      throw new Error('PRERENDER_ROUTE_MANIFEST must contain a JSON array')
    }
    routes.push(...extraRoutes)
  }

  const uniqueRoutes = new Map()
  for (const route of routes) {
    const normalizedPath = normalizeRoutePath(route.path)
    if (!route.title || !route.description || !route.heading || !route.summary) {
      throw new Error(`Prerender route ${normalizedPath} is missing title, description, heading or summary`)
    }
    uniqueRoutes.set(normalizedPath, { ...route, path: normalizedPath })
  }
  return [...uniqueRoutes.values()]
}

async function fileExists(filePath) {
  try {
    await access(filePath)
    return true
  } catch {
    return false
  }
}

async function writeSitemap(distDir, routes, siteUrl) {
  if (!siteUrl) return false
  const urls = routes
    .filter((route) => !String(route.robots || '').includes('noindex'))
    .map((route) => `  <url><loc>${escapeHtml(canonicalUrl(route.path, siteUrl))}</loc></url>`)
    .join('\n')
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`
  await writeFile(path.join(distDir, 'sitemap.xml'), sitemap, 'utf8')
  await writeFile(path.join(distDir, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${canonicalUrl('/sitemap.xml', siteUrl)}\n`, 'utf8')
  return true
}

export async function prerender(options = {}) {
  const region = options.region ?? process.env.PRERENDER_REGION ?? 'CN'
  prerenderLocale(region)
  const distDir = path.resolve(options.distDir || defaultDistDir)
  const routeManifestPath = path.resolve(options.routeManifestPath || defaultRouteManifestPath(region))
  const siteUrl = parseSiteUrl(options.siteUrl ?? process.env.PUBLIC_SITE_URL)
  const configuredExtraRouteManifestPath = options.extraRouteManifestPath ?? process.env.PRERENDER_ROUTE_MANIFEST
  const defaultExtraRouteManifestPath = path.join(distDir, 'prerender-routes.json')
  const extraRouteManifestPath = configuredExtraRouteManifestPath
    || (await fileExists(defaultExtraRouteManifestPath) ? defaultExtraRouteManifestPath : undefined)
  const routes = await loadRoutes(routeManifestPath, extraRouteManifestPath)
  const indexPath = path.join(distDir, 'index.html')
  const template = await readFile(indexPath, 'utf8')
  const outputs = []

  for (const route of routes) {
    const outputPath = routeOutputPath(distDir, route.path)
    await mkdir(path.dirname(outputPath), { recursive: true })
    await writeFile(outputPath, buildPrerenderHtml(template, route, routes, siteUrl, region), 'utf8')
    outputs.push({ path: route.path, file: path.relative(distDir, outputPath), canonical: canonicalUrl(route.path, siteUrl) })
  }

  const sitemap = await writeSitemap(distDir, routes, siteUrl)
  const manifest = {
    generatedAt: new Date().toISOString(),
    region,
    siteUrl: siteUrl || null,
    sitemap,
    routes: outputs,
  }
  await writeFile(path.join(distDir, 'prerender-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8')
  return manifest
}

async function main() {
  const manifest = await prerender()
  const siteHint = manifest.siteUrl ? ` for ${manifest.siteUrl}` : ' with relative canonical URLs'
  process.stdout.write(`[prerender] generated ${manifest.routes.length} routes${siteHint}\n`)
}

if (import.meta.url === pathToFileURL(process.argv[1] || '').href) {
  main().catch((error) => {
    process.stderr.write(`[prerender] ${error instanceof Error ? error.message : String(error)}\n`)
    process.exitCode = 1
  })
}
