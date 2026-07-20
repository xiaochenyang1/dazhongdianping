<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { logoutUser } from '@/services/auth'
import { clearSearchHistory, fetchHotSearchWords, fetchSearchHistory, fetchSearchSuggestions } from '@/services/browse'
import type { SearchHistoryItem, SearchHotWord, SearchSuggestion } from '@/types/browse'
import { useNotifications } from '@/composables/useNotifications'

interface SearchPanelItem {
  key: string
  term: string
  meta: string
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
const { state: notificationState, refresh: refreshNotifications, connect: connectNotifications, disconnect: disconnectNotifications, markRead } = useNotifications()
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

const navItems = [
  { to: '/', label: '首页' },
  { to: '/shops', label: '商户列表' },
  { to: '/ranks', label: '城市榜单', matchPrefix: '/ranks' },
  { to: '/community', label: '华人社区', matchPrefix: '/community' },
  { to: '/user/reviews', label: '我的点评', matchPrefix: '/user/reviews' },
  { to: '/user/favorites', label: '我的收藏', matchPrefix: '/user/favorites' },
  { to: '/user/orders', label: '我的订单', matchPrefix: '/user/orders' },
  { to: '/user/coupons', label: '我的券', matchPrefix: '/user/coupons' },
  { to: '/user/reservations', label: '我的预订', matchPrefix: '/user/reservations' },
  { to: '/user/profile', label: '我的资料', matchPrefix: '/user/profile' },
  { to: '/user/growth-records', label: '成长值流水', matchPrefix: '/user/growth-records' },
]

const userInitial = computed(() => (sessionState.currentUser?.nickname?.slice(0, 1) || '我').toUpperCase())
const searchPanelSections = computed<SearchPanelSection[]>(() => {
  const keyword = searchKeyword.value.trim()
  if (keyword) {
    return [
      {
        label: '猜你要找',
        items: suggestions.value.map((item) => ({
          key: `${item.type}-${item.refId}-${item.term}`,
          term: item.term,
          meta: item.type === 'shop' ? '商户' : '分类',
        })),
      },
    ].filter((section) => section.items.length > 0)
  }

  const sections: SearchPanelSection[] = []

  if (sessionState.currentUser && searchHistory.value.length > 0) {
    sections.push({
      label: '最近搜过',
      actionLabel: '清空',
      items: searchHistory.value.map((item) => ({
        key: `history-${item.id}`,
        term: item.keyword,
        meta: item.updatedAt,
      })),
    })
  }

  if (hotWords.value.length > 0) {
    sections.push({
      label: '当前热词',
      items: hotWords.value.map((item) => ({
        key: `hot-${item.term}`,
        term: item.term,
        meta: `${item.score} 热度`,
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
          <p class="brand__title">大众点评(仿)</p>
          <div class="brand__meta">
            <p class="brand__subtitle">M1 PC Web Scaffold</p>
            <span class="brand__signal">Live Flow</span>
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
        <label class="header-search__label" for="global-shop-search">搜索商户</label>
        <input
          id="global-shop-search"
          v-model="searchKeyword"
          type="search"
          aria-label="搜索商户"
          placeholder="搜火锅、咖啡、商圈"
          autocomplete="off"
          @focus="handleSearchFocus"
          @blur="handleSearchBlur"
        />
        <button type="submit">搜索</button>
        <div v-if="showSearchPanel" class="search-popover" role="listbox" aria-label="搜索建议">
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
                {{ clearingSearchHistory ? '清空中...' : section.actionLabel }}
              </button>
            </div>
            <button
              v-for="item in section.items"
              :key="item.key"
              type="button"
              class="search-popover__item"
              @mousedown.prevent="runSearch(item.term)"
            >
              <span>{{ item.term }}</span>
              <small>{{ item.meta }}</small>
            </button>
          </template>
          <p v-if="searchHistoryLoading" class="search-popover__loading">搜索历史加载中...</p>
          <p v-if="searchLoading" class="search-popover__loading">搜索中...</p>
        </div>
      </form>

      <div class="header-actions">
        <div class="region-switch">
          <span class="region-switch__label">区域视角</span>
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
          <strong class="region-switch__value">{{ state.region === 'CN' ? '国内站视角' : '欧洲站视角' }}</strong>
        </div>

        <button v-if="!sessionState.currentUser" type="button" class="primary-button header-login" @click="handleLogin">
          登录 / 注册
        </button>

        <template v-else>
        <div class="notification-menu">
          <button type="button" class="ghost-button notification-button" @click="notificationOpen = !notificationOpen">
            通知
            <span v-if="notificationState.unreadCount" class="notification-badge">{{ notificationState.unreadCount }}</span>
          </button>
          <div v-if="notificationOpen" class="notification-popover">
            <div class="notification-popover__head"><strong>消息通知</strong><span>{{ notificationState.connected ? '实时在线' : '离线补偿' }}</span></div>
            <p v-if="notificationState.loading" class="notification-empty">加载中...</p>
            <p v-else-if="notificationState.items.length === 0" class="notification-empty">暂无通知</p>
            <button v-for="item in notificationState.items" :key="item.id" type="button" class="notification-item" :class="{ unread: !item.read }" @click="markRead(item); item.linkUrl && router.push(item.linkUrl); notificationOpen = false">
              <strong>{{ item.title }}</strong><span>{{ item.content }}</span><small>{{ item.createdAt }}</small>
            </button>
          </div>
        </div>

        <div class="session-chip">
          <span class="session-chip__avatar">{{ userInitial }}</span>
          <div class="session-chip__meta">
            <strong>{{ sessionState.currentUser.nickname || '已登录用户' }}</strong>
            <span>Lv.{{ sessionState.currentUser.level }} · {{ sessionState.currentUser.preferredRegion }}</span>
          </div>
          <button type="button" class="ghost-button" :disabled="logoutLoading" @click="handleLogout">
            {{ logoutLoading ? '退出中...' : '退出' }}
          </button>
        </div>
        </template>
      </div>
    </div>
  </header>
</template>
