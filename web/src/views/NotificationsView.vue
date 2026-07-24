<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useNotifications } from '@/composables/useNotifications'
import { fetchNotifications } from '@/services/notification'
import type { UserNotification } from '@/types/notification'

const router = useRouter()
const { state, refresh, markRead, markAllRead } = useNotifications()

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

function notificationHint(item: UserNotification) {
  if (item.type === 'message.direct') return '请在 APP 查看私信'
  if (item.type === 'reservation.reminder') return '预订提醒'
  if (item.type === 'coupon.reminder') return '券码到期提醒'
  if (item.type === 'coupon.expired') return '券码已过期'
  if (item.type === 'order.refund.result') return '退款结果'
  if (item.type === 'reservation.status') return '预订状态'
  if (item.type === 'review.audit.result') return '点评审核'
  if (item.type === 'expert.certification.result') return '达人认证'
  if (item.type === 'social.mention') return '@提醒'
  return item.type
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
    error.value = cause instanceof Error ? cause.message : '通知加载失败'
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
    success.value = '全部通知已标记为已读'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '全部已读失败'
  } finally {
    acting.value = false
  }
}

onMounted(() => {
  void load(true)
})
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">消息中心</p>
        <h1>赞评、预订提醒和系统通知都在这里。</h1>
        <p>支持单条已读和全部已读；私信通知请到 APP 查看完整会话。</p>
      </div>
      <button
        type="button"
        class="secondary-button"
        data-testid="notifications-mark-all"
        :disabled="acting || state.unreadCount === 0"
        @click="handleMarkAll"
      >
        全部已读{{ state.unreadCount ? `（${state.unreadCount}）` : '' }}
      </button>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>
    <p v-if="loading" class="feedback">通知加载中...</p>
    <p v-else-if="items.length === 0" class="feedback">暂时没有通知。</p>

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
            {{ item.title }}
            <template v-if="item.aggregateCount > 1"> · x{{ item.aggregateCount }}</template>
          </strong>
          <span class="status-pill">{{ item.read ? '已读' : '未读' }}</span>
        </div>
        <p>{{ item.content }}</p>
        <div class="hero-actions">
          <span class="muted">{{ item.createdAt }} · {{ notificationHint(item) }}</span>
          <button type="button" class="secondary-button" @click="openItem(item)">
            {{ notificationRoute(item) ? '查看详情' : '标记已读' }}
          </button>
        </div>
      </article>
    </div>

    <div v-if="hasMore" class="hero-actions" style="margin-top: 16px">
      <button type="button" class="secondary-button" :disabled="loadingMore" @click="loadMore">
        {{ loadingMore ? '加载中...' : '加载更多' }}
      </button>
    </div>
  </section>
</template>
