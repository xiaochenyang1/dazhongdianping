<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useNotifications } from '@/composables/useNotifications'
import { formatWebDateTime } from '@/core/web_localizations'
import {
  localizeWebNotificationError,
  notificationDisplayContent,
  notificationDisplayTitle,
  notificationHint,
  notificationStringsForRegion,
} from '@/core/web_notification_localizations'
import { fetchNotifications } from '@/services/notification'
import type { UserNotification } from '@/types/notification'

const router = useRouter()
const { state: appState } = useAppContext()
const { state, refresh, markRead, markAllRead } = useNotifications()
const copy = computed(() => notificationStringsForRegion(appState.region))

const loading = ref(false)
const loadingMore = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const page = ref(1)
const pageSize = 20
const hasMore = ref(false)
const items = ref<UserNotification[]>([])

function notificationRoute(item: UserNotification) {
  if (item.type === 'message.direct') return null
  if (!item.linkUrl) return null
  // Coupon reminders need status/code query so the coupons page can highlight the target code.
  if (item.type === 'coupon.reminder' || item.type === 'coupon.expired') {
    const [path, search = ''] = item.linkUrl.split('?')
    const query: Record<string, string> = {}
    new URLSearchParams(search).forEach((value, key) => {
      query[key] = value
    })
    return { path: path || '/user/coupons', query }
  }
  return item.linkUrl.split('?')[0] || null
}

async function load(reset = true) {
  if (reset) {
    loading.value = true
    page.value = 1
  } else {
    loadingMore.value = true
  }
  error.value = ''
  try {
    const result = await fetchNotifications(page.value, pageSize)
    items.value = reset ? result.list : [...items.value, ...result.list]
    hasMore.value = result.hasMore
    // keep global header state roughly in sync on first page
    if (reset) {
      await refresh()
    }
  } catch (cause) {
    error.value = localizeWebNotificationError(copy.value, cause, copy.value.page.loadFailed)
  } finally {
    loading.value = false
    loadingMore.value = false
  }
}

async function loadMore() {
  if (!hasMore.value || loadingMore.value) return
  page.value += 1
  await load(false)
}

async function openItem(item: UserNotification) {
  try {
    await markRead(item)
    const idx = items.value.findIndex((row) => row.id === item.id)
    if (idx >= 0) items.value[idx] = { ...items.value[idx], ...item, read: true }
  } catch {
    // continue navigation even if ack fails
  }
  const target = notificationRoute(item)
  if (target) {
    await router.push(target)
  }
}

async function handleMarkAll() {
  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await markAllRead()
    items.value = items.value.map((item) => ({ ...item, read: true }))
    success.value = copy.value.page.markAllSuccess
  } catch (cause) {
    error.value = localizeWebNotificationError(copy.value, cause, copy.value.page.markAllFailed)
  } finally {
    acting.value = false
  }
}

watch(
  () => appState.region,
  () => {
    items.value = []
    success.value = ''
    void load(true)
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.page.eyebrow }}</p>
        <h1>{{ copy.page.title }}</h1>
        <p>{{ copy.page.summary }}</p>
      </div>
      <button
        type="button"
        class="secondary-button"
        data-testid="notifications-mark-all"
        :disabled="acting || state.unreadCount === 0"
        @click="handleMarkAll"
      >
        {{ copy.page.markAllRead(state.unreadCount) }}
      </button>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>
    <p v-if="loading" class="feedback">{{ copy.page.loading }}</p>
    <p v-else-if="items.length === 0" class="feedback">{{ copy.page.empty }}</p>

    <div v-else class="review-list">
      <article
        v-for="item in items"
        :key="item.id"
        class="review-card notification-card"
        :class="{ unread: !item.read }"
        :data-testid="`notification-item-${item.id}`"
      >
        <div class="shop-card__heading">
          <strong>
            {{ notificationDisplayTitle(copy, item) }}
            <template v-if="item.aggregateCount > 1"> · x{{ item.aggregateCount }}</template>
          </strong>
          <span class="status-pill">{{ item.read ? copy.page.read : copy.page.unread }}</span>
        </div>
        <p>{{ notificationDisplayContent(copy, item) }}</p>
        <div class="hero-actions">
          <span class="muted">
            {{ formatWebDateTime(item.createdAt, copy.tag) }} · {{ notificationHint(copy, item) }}
          </span>
          <button type="button" class="secondary-button" @click="openItem(item)">
            {{ notificationRoute(item) ? copy.page.viewDetails : copy.page.markRead }}
          </button>
        </div>
      </article>
    </div>

    <div v-if="hasMore" class="hero-actions" style="margin-top: 16px">
      <button type="button" class="secondary-button" :disabled="loadingMore" @click="loadMore">
        {{ loadingMore ? copy.page.loadingMore : copy.page.loadMore }}
      </button>
    </div>
  </section>
</template>
