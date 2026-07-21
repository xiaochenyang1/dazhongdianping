import { onBeforeUnmount, toValue, watchEffect, type MaybeRefOrGetter } from 'vue'

export interface SeoMetaInput {
  title: string
  description: string
  canonical: string
  robots?: string
  image?: string
  type?: 'website' | 'article' | 'restaurant'
  jsonLd?: Record<string, unknown> | null
}

let ownerSequence = 0

export function absoluteSeoUrl(value: string): string {
  const origin = typeof window === 'undefined' ? 'http://localhost' : window.location.origin
  return new URL(value, origin).href
}

function canonicalSeoUrl(value: string): string {
  const url = new URL(absoluteSeoUrl(value))
  url.search = ''
  url.hash = ''
  return url.href
}

export function toSeoDescription(value: string, maxLength = 160): string {
  const normalized = value.replace(/\s+/g, ' ').trim()
  if (normalized.length <= maxLength) return normalized
  return `${normalized.slice(0, Math.max(1, maxLength - 3))}...`
}

function findOrCreateMeta(attribute: 'name' | 'property', value: string, owner: string): HTMLMetaElement {
  const selector = `meta[${attribute}="${value}"]`
  const existing = document.head.querySelector<HTMLMetaElement>(selector)
  if (existing) {
    existing.dataset.seoOwner = owner
    return existing
  }

  const element = document.createElement('meta')
  element.setAttribute(attribute, value)
  element.dataset.seoOwner = owner
  element.dataset.seoCreated = 'true'
  document.head.appendChild(element)
  return element
}

function removeOwnedOptionalMeta(attribute: 'name' | 'property', value: string, owner: string) {
  document.head
    .querySelectorAll<HTMLMetaElement>(`meta[${attribute}="${value}"][data-seo-owner="${owner}"][data-seo-created="true"]`)
    .forEach((element) => element.remove())
}

function upsertCanonical(canonical: string, owner: string) {
  const existing = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]')
  const element = existing ?? document.createElement('link')
  element.setAttribute('rel', 'canonical')
  element.setAttribute('href', canonical)
  element.dataset.seoOwner = owner
  if (!existing) {
    element.dataset.seoCreated = 'true'
    document.head.appendChild(element)
  }
}

function upsertJsonLd(schema: Record<string, unknown> | null | undefined, owner: string) {
  document.head
    .querySelectorAll<HTMLScriptElement>(`script[type="application/ld+json"][data-seo-owner="${owner}"]`)
    .forEach((element) => element.remove())
  if (!schema) return

  const element = document.createElement('script')
  element.type = 'application/ld+json'
  element.dataset.seoOwner = owner
  element.dataset.seoCreated = 'true'
  element.textContent = JSON.stringify(schema).replace(/</g, '\\u003c')
  document.head.appendChild(element)
}

function applySeoMeta(meta: SeoMetaInput, owner: string) {
  const canonical = canonicalSeoUrl(meta.canonical)
  const title = meta.title.endsWith(' | 大众点评(仿)') ? meta.title : `${meta.title} | 大众点评(仿)`
  const description = toSeoDescription(meta.description)

  document.title = title
  findOrCreateMeta('name', 'description', owner).setAttribute('content', description)
  findOrCreateMeta('name', 'robots', owner).setAttribute('content', meta.robots ?? 'index,follow')
  findOrCreateMeta('property', 'og:title', owner).setAttribute('content', meta.title)
  findOrCreateMeta('property', 'og:description', owner).setAttribute('content', description)
  findOrCreateMeta('property', 'og:url', owner).setAttribute('content', canonical)
  findOrCreateMeta('property', 'og:type', owner).setAttribute('content', meta.type ?? 'website')
  findOrCreateMeta('name', 'twitter:card', owner).setAttribute('content', meta.image ? 'summary_large_image' : 'summary')

  if (meta.image) {
    findOrCreateMeta('property', 'og:image', owner).setAttribute('content', absoluteSeoUrl(meta.image))
  } else {
    removeOwnedOptionalMeta('property', 'og:image', owner)
  }

  upsertCanonical(canonical, owner)
  upsertJsonLd(meta.jsonLd, owner)
}

function cleanupSeoOwner(owner: string) {
  document.head.querySelectorAll<HTMLElement>(`[data-seo-owner="${owner}"]`).forEach((element) => {
    if (element.dataset.seoCreated === 'true') {
      element.remove()
    } else {
      delete element.dataset.seoOwner
    }
  })
}

export function useSeoMeta(source: MaybeRefOrGetter<SeoMetaInput>): void {
  const owner = `page-seo-${++ownerSequence}`
  watchEffect(() => applySeoMeta(toValue(source), owner))
  onBeforeUnmount(() => cleanupSeoOwner(owner))
}
