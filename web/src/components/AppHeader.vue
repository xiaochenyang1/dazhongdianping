<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { logoutUser } from '@/services/auth'
import {
  clearSearchHistory,
  fetchHotSearchWords,
  fetchSearchHistory,
  fetchSearchSuggestions,
  removeSearchHistoryItem,
} from '@/services/browse'
import type { SearchHistoryItem, SearchHotWord, SearchSuggestion } from '@/types/browse'
import { useNotifications } from '@/composables/useNotifications'
import type { UserNotification } from '@/types/notification'
import { applyWebDocumentMeta, formatWebDateTime, webStringsForRegion } from '@/core/web_localizations'
import {
  notificationDisplayContent,
  notificationDisplayTitle,
  notificationHint as localizedNotificationHint,
  notificationStringsForRegion,
} from '@/core/web_notification_localizations'

interface SearchPanelItem {
  key: string
  term: string
  meta: string
  historyId?: number
}

interface SearchPanelSection {
  label: string
  items: SearchPanelItem[]
  actionLabel?: string
}

const route = useRoute()
const router = useRouter()
const { state, setRegion } = useAppContext()
const { state: sessionState, openAuthDialog, clearSession } = useUserSession()
const { state: notificationState, refresh: refreshNotifications, connect: connectNotifications, disconnect: disconnectNotifications, markRead, markAllRead } = useNotifications()
const notificationOpen = ref(false)
const logoutLoading = ref(false)
const searchKeyword = ref(typeof route.query.keyword === 'string' ? route.query.keyword : '')
const searchFocused = ref(false)
const suggestions = ref<SearchSuggestion[]>([])
const hotWords = ref<SearchHotWord[]>([])
const searchHistory = ref<SearchHistoryItem[]>([])
const searchLoading = ref(false)
const searchHistoryLoading = ref(false)
const clearingSearchHistory = ref(false)
let suggestionRequestId = 0
let hotWordsRequestId = 0
let searchHistoryRequestId = 0

const strings = computed(() => webStringsForRegion(state.region))
const notificationStrings = computed(() => notificationStringsForRegion(state.region))
const navItems = computed(() => strings.value.nav)
applyWebDocumentMeta(state.region, route.name)
const userInitial = computed(() => (
  sessionState.currentUser?.nickname?.slice(0, 1) || strings.value.session.userInitial
).toUpperCase())
const searchPanelSections = computed<SearchPanelSection[]>(() => {
  const keyword = searchKeyword.value.trim()
  if (keyword) {
    return [
      {
        label: strings.value.search.suggested,
        items: suggestions.value.map((item) => ({
          key: `${item.type}-${item.refId}-${item.term}`,
          term: item.term,
          meta: item.type === 'shop' ? strings.value.search.shop : strings.value.search.category,
        })),
      },
    ].filter((section) => section.items.length > 0)
  }

  const sections: SearchPanelSection[] = []

  if (sessionState.currentUser && searchHistory.value.length > 0) {
    sections.push({
      label: strings.value.search.recent,
      actionLabel: strings.value.search.clear,
      items: searchHistory.value.map((item) => ({
        key: `history-${item.id}`,
        term: item.keyword,
        meta: item.updatedAt,
        historyId: item.id,
      })),
    })
  }

  if (hotWords.value.length > 0) {
    sections.push({
      label: strings.value.search.hot,
      items: hotWords.value.map((item) => ({
        key: `hot-${item.term}`,
        term: item.term,
        meta: strings.value.search.heat(item.score),
      })),
    })
  }

  return sections
})
const showSearchPanel = computed(() => searchFocused.value && searchPanelSections.value.length > 0)

function isActive(to: string, matchPrefix?: string) {
  if (matchPrefix) {
    return route.path.startsWith(matchPrefix)
  }
  return route.path === to
}

function handleLogin() {
  openAuthDialog({
    mode: 'password',
    redirectTo: route.fullPath,
  })
}

function switchRegion(nextRegion: 'CN' | 'EU') {
  if (state.region === nextRegion) {
    return
  }
  setRegion(nextRegion)
}

function submitSearch() {
  const keyword = searchKeyword.value.trim()
  runSearch(keyword)
}

function runSearch(keyword: string) {
  searchKeyword.value = keyword
  searchFocused.value = false
  void router.push({
    path: '/shops',
    query: keyword ? { keyword } : {},
  })
}

async function handleSearchFocus() {
  searchFocused.value = true
  const keyword = searchKeyword.value.trim()
  if (keyword) {
    if (suggestions.value.length === 0) {
      await loadSuggestions(keyword)
    }
    return
  }

  await Promise.all([loadHotWords(), loadSearchHistory()])
}

function handleSearchBlur() {
  window.setTimeout(() => {
    searchFocused.value = false
  }, 120)
}

function notificationRoute(item: UserNotification) {
  if (item.type === 'message.direct') {
    return null
  }
  if (!item.linkUrl) {
    return null
  }
  // Coupon reminders need status/code query so the coupons page can highlight the target code.
  if (item.type === 'coupon.reminder' || item.type === 'coupon.expired') {
    const [path, search = ''] = item.linkUrl.split('?')
    const query: Record<string, string> = {}
    new URLSearchParams(search).forEach((value, key) => {
      query[key] = value
    })
    return { path: path || '/user/coupons', query }
  }
  // Strip query markers like ?remind=30 so Vue Router lands on the reservation page.
  const path = item.linkUrl.split('?')[0]
  return path || null
}

function notificationHint(item: UserNotification) {
  return ` · ${localizedNotificationHint(notificationStrings.value, item)}`
}

async function handleMarkAllNotificationsRead() {
  try {
    await markAllRead()
  } catch {
    // ignore
  }
}

async function handleNotificationClick(item: UserNotification) {
  await markRead(item)
  notificationOpen.value = false
  const target = notificationRoute(item)
  if (target) {
    await router.push(target)
  }
}

async function handleLogout() {
  logoutLoading.value = true
  try {
    await logoutUser()
  } catch {
    // 本地开发阶段以清理前端会话为准，后端若已失效不影响继续收口。
  } finally {
    disconnectNotifications()
    clearSession()
    logoutLoading.value = false
    if (route.meta.requiresAuth) {
      void router.push('/')
    }
  }
}

async function loadHotWords() {
  if (hotWords.value.length > 0) {
    return
  }

  const requestId = ++hotWordsRequestId
  try {
    const result = await fetchHotSearchWords()
    if (requestId === hotWordsRequestId) {
      hotWords.value = result
    }
  } catch {
    if (requestId === hotWordsRequestId) {
      hotWords.value = []
    }
  }
}

async function loadSearchHistory() {
  if (!sessionState.currentUser) {
    searchHistory.value = []
    return
  }

  const requestId = ++searchHistoryRequestId
  searchHistoryLoading.value = true
  try {
    const result = await fetchSearchHistory(1, 6)
    if (requestId === searchHistoryRequestId) {
      searchHistory.value = result.list
    }
  } catch {
    if (requestId === searchHistoryRequestId) {
      searchHistory.value = []
    }
  } finally {
    if (requestId === searchHistoryRequestId) {
      searchHistoryLoading.value = false
    }
  }
}

async function handleClearSearchHistory() {
  if (clearingSearchHistory.value) {
    return
  }

  clearingSearchHistory.value = true
  try {
    await clearSearchHistory()
    searchHistory.value = []
  } catch {
    // 清空失败别把整个头部面板搞崩，用户下次再试。
  } finally {
    clearingSearchHistory.value = false
  }
}

async function handleRemoveSearchHistoryItem(historyId: number) {
  try {
    await removeSearchHistoryItem(historyId)
    searchHistory.value = searchHistory.value.filter((item) => item.id !== historyId)
  } catch {
    // 单条删除失败不阻塞面板，用户可刷新后重试。
  }
}

async function loadSuggestions(keyword: string) {
  const normalized = keyword.trim()
  suggestions.value = []
  if (!normalized) {
    searchLoading.value = false
    return
  }

  const requestId = ++suggestionRequestId
  searchLoading.value = true
  try {
    const result = await fetchSearchSuggestions(normalized)
    if (requestId === suggestionRequestId) {
      suggestions.value = result
    }
  } catch {
    if (requestId === suggestionRequestId) {
      suggestions.value = []
    }
  } finally {
    if (requestId === suggestionRequestId) {
      searchLoading.value = false
    }
  }
}

watch(
  () => searchKeyword.value,
  (keyword) => {
    void loadSuggestions(keyword)
  },
)

watch(
  () => sessionState.currentUser?.id,
  (userId) => {
    if (!sessionState.currentUser) {
      searchHistory.value = []
      notificationOpen.value = false
      disconnectNotifications()
      return
    }

    if (userId) {
      void refreshNotifications()
      void connectNotifications().catch(() => undefined)
    }

    if (searchFocused.value && !searchKeyword.value.trim()) {
      void loadSearchHistory()
    }
  },
)

watch(
  () => state.region,
  () => {
    applyWebDocumentMeta(state.region, route.name)
    suggestionRequestId += 1
    hotWordsRequestId += 1
    searchHistoryRequestId += 1
    suggestions.value = []
    hotWords.value = []
    searchHistory.value = []
    searchLoading.value = false
    searchHistoryLoading.value = false

    if (!searchFocused.value) {
      return
    }

    if (searchKeyword.value.trim()) {
      void loadSuggestions(searchKeyword.value)
      return
    }

    void Promise.all([loadHotWords(), loadSearchHistory()])
  },
)
</script>

<template>
  <header class="app-header">
    <div class="app-header__inner">
      <RouterLink class="brand" to="/">
        <span class="brand__mark">DP</span>
        <div class="brand__copy">
          <p class="brand__title">{{ strings.brand.title }}</p>
          <div class="brand__meta">
            <p class="brand__subtitle">{{ strings.brand.subtitle }}</p>
            <span class="brand__signal">{{ strings.brand.signal }}</span>
          </div>
        </div>
      </RouterLink>

      <nav class="top-nav">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="top-nav__link"
          :class="{ 'is-active': isActive(item.to, item.matchPrefix) }"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <form class="header-search" role="search" @submit.prevent="submitSearch">
        <label class="header-search__label" for="global-shop-search">{{ strings.search.label }}</label>
        <input
          id="global-shop-search"
          v-model="searchKeyword"
          type="search"
          :aria-label="strings.search.label"
          :placeholder="strings.search.placeholder"
          autocomplete="off"
          @focus="handleSearchFocus"
          @blur="handleSearchBlur"
        />
        <button type="submit">{{ strings.search.submit }}</button>
        <div v-if="showSearchPanel" class="search-popover" role="listbox" :aria-label="strings.search.suggestionsAria">
          <template v-for="section in searchPanelSections" :key="section.label">
            <div class="search-popover__heading">
              <p class="search-popover__label">{{ section.label }}</p>
              <button
                v-if="section.actionLabel"
                type="button"
                class="search-popover__action"
                :disabled="clearingSearchHistory"
                @mousedown.prevent
                @click="handleClearSearchHistory"
              >
                {{ clearingSearchHistory ? strings.search.clearing : section.actionLabel }}
              </button>
            </div>
            <div
              v-for="item in section.items"
              :key="item.key"
              class="search-popover__item-row"
            >
              <button
                type="button"
                class="search-popover__item"
                @mousedown.prevent="runSearch(item.term)"
              >
                <span>{{ item.term }}</span>
                <small>{{ item.meta }}</small>
              </button>
              <button
                v-if="item.historyId"
                type="button"
                class="search-popover__remove"
                :aria-label="strings.search.removeHistoryAria"
                @mousedown.prevent
                @click="handleRemoveSearchHistoryItem(item.historyId)"
              >
                ×
              </button>
            </div>
          </template>
          <p v-if="searchHistoryLoading" class="search-popover__loading">{{ strings.search.historyLoading }}</p>
          <p v-if="searchLoading" class="search-popover__loading">{{ strings.search.loading }}</p>
        </div>
      </form>

      <div class="header-actions">
        <div class="region-switch">
          <span class="region-switch__label">{{ strings.region.label }}</span>
          <div class="region-switch__actions">
            <button
              type="button"
              class="region-switch__button"
              :class="{ 'is-active': state.region === 'CN' }"
              @click="switchRegion('CN')"
            >
              CN
            </button>
            <button
              type="button"
              class="region-switch__button"
              :class="{ 'is-active': state.region === 'EU' }"
              @click="switchRegion('EU')"
            >
              EU
            </button>
          </div>
          <strong class="region-switch__value">{{ state.region === 'CN' ? strings.region.cnPerspective : strings.region.euPerspective }}</strong>
        </div>

        <button v-if="!sessionState.currentUser" type="button" class="primary-button header-login" @click="handleLogin">
          {{ strings.session.login }}
        </button>

        <template v-else>
        <div class="notification-menu">
          <button type="button" class="ghost-button notification-button" @click="notificationOpen = !notificationOpen">
            {{ strings.notifications.trigger }}
            <span v-if="notificationState.unreadCount" class="notification-badge">{{ notificationState.unreadCount }}</span>
          </button>
          <div v-if="notificationOpen" class="notification-popover">
            <div class="notification-popover__head">
              <strong>{{ strings.notifications.heading }}</strong>
              <span>{{ notificationState.connected ? strings.notifications.connected : strings.notifications.offline }}</span>
              <div class="notification-popover__actions">
                <button v-if="notificationState.unreadCount" type="button" class="ghost-button" data-testid="mark-all-notifications" @click.stop="handleMarkAllNotificationsRead">{{ strings.notifications.markAllRead }}</button>
                <RouterLink class="text-link" to="/user/notifications" @click="notificationOpen = false">{{ strings.notifications.viewAll }}</RouterLink>
              </div>
            </div>
            <p v-if="notificationState.loading" class="notification-empty">{{ strings.notifications.loading }}</p>
            <p v-else-if="notificationState.items.length === 0" class="notification-empty">{{ strings.notifications.empty }}</p>
            <button v-for="item in notificationState.items" :key="item.id" type="button" class="notification-item" :class="{ unread: !item.read }" @click="handleNotificationClick(item)">
              <strong>{{ notificationDisplayTitle(notificationStrings, item) }}<template v-if="item.aggregateCount > 1"> · x{{ item.aggregateCount }}</template></strong>
              <span>{{ notificationDisplayContent(notificationStrings, item) }}</span>
              <small>{{ formatWebDateTime(item.createdAt, notificationStrings.tag) }}{{ notificationHint(item) }}</small>
            </button>
          </div>
        </div>

        <div class="session-chip">
          <span class="session-chip__avatar">{{ userInitial }}</span>
          <div class="session-chip__meta">
            <strong>{{ sessionState.currentUser.nickname || strings.session.userFallback }}</strong>
            <span>Lv.{{ sessionState.currentUser.level }} · {{ sessionState.currentUser.preferredRegion }}</span>
          </div>
          <button type="button" class="ghost-button" :disabled="logoutLoading" @click="handleLogout">
            {{ logoutLoading ? strings.session.loggingOut : strings.session.logout }}
          </button>
        </div>
        </template>
      </div>
    </div>
  </header>
</template>
