<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { getAdminAppUser, listAdminAppUsers, updateAdminAppUserStatus } from '@/services/admin'
import type { AdminAppUser, AdminAppUserDetail, PageResult } from '@/types/admin'

const router = useRouter()
const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const pageSize = 20
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAppUser> | null>(null)
const detail = ref<AdminAppUserDetail | null>(null)
const detailLoading = ref(false)
const banTarget = ref<AdminAppUser | null>(null)
const banReason = ref('')
const filters = reactive({
  keyword: '',
  userId: '',
  status: '',
  preferredRegion: '',
  page: 1,
})

const canWrite = computed(() => state.permissions.includes('system:user:write'))

function normalizeNumber(value: string) {
  const normalized = value.trim()
  if (!normalized) return undefined
  const parsed = Number(normalized)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

function userLabel(user: AdminAppUser) {
  return user.nickname || strings.value.userManagement.userFallback(user.id)
}

function accountSummary(user: AdminAppUser) {
  return user.email || user.phone || strings.value.userManagement.userFallback(user.id)
}

function statusText(user: AdminAppUser) {
  return strings.value.userManagement.statusText(user.status, user.statusText)
}

function appealStatusText(statusText: string) {
  return strings.value.userManagement.appealStatusText(statusText)
}

function statusPillClass(user: AdminAppUser) {
  if (user.status === 2) return 'status-pill--warn'
  if (user.status === 3) return 'status-pill--muted'
  return 'status-pill--good'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminAppUsers({
      keyword: normalizeText(filters.keyword),
      userId: normalizeNumber(filters.userId),
      status: normalizeNumber(filters.status),
      preferredRegion: normalizeText(filters.preferredRegion),
      page: filters.page,
      pageSize,
    })
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.userManagement.loadError
  } finally {
    loading.value = false
  }
}

async function applyFilters() {
  filters.page = 1
  await load()
}

async function goPage(nextPage: number) {
  filters.page = Math.max(1, nextPage)
  await load()
}

async function openDetail(user: AdminAppUser) {
  detailLoading.value = true
  errorMessage.value = ''
  detail.value = null
  try {
    detail.value = await getAdminAppUser(user.id)
  } catch (cause) {
    errorMessage.value =
      cause instanceof Error ? cause.message : strings.value.userManagement.detailLoadError
  } finally {
    detailLoading.value = false
  }
}

function openBan(user: AdminAppUser) {
  banTarget.value = user
  banReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
}

async function confirmBan() {
  const target = banTarget.value
  if (!target) return

  const reason = banReason.value.trim()
  if (!reason) {
    errorMessage.value = strings.value.userManagement.banReasonRequired
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminAppUserStatus(target.id, { action: 'ban', reason })
    successMessage.value = strings.value.userManagement.bannedMessage(userLabel(target))
    banTarget.value = null
    banReason.value = ''
    if (detail.value?.id === target.id) {
      detail.value = null
    }
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.userManagement.banError
  } finally {
    acting.value = false
  }
}

async function unban(user: AdminAppUser) {
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminAppUserStatus(user.id, { action: 'unban', reason: '' })
    successMessage.value = strings.value.userManagement.unbannedMessage(userLabel(user))
    if (detail.value?.id === user.id) {
      detail.value = null
    }
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : strings.value.userManagement.unbanError
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    void load()
  },
  { immediate: true },
)

function goAppealAudit() {
  void router.push('/audit/user-appeals')
}
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.userManagement.eyebrow }}</p>
        <h1>{{ strings.userManagement.heading }}</h1>
        <p>{{ strings.userManagement.description(state.region) }}</p>
      </div>
      <button class="secondary-button" type="button" @click="load">
        {{ strings.userManagement.refresh }}
      </button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{
          loading
            ? strings.userManagement.metaLoading
            : strings.userManagement.metaSummary(pageState?.total ?? 0)
        }}</span>
        <span>{{ strings.userManagement.metaDescription }}</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>{{ strings.userManagement.filters.keyword }}</span>
          <input
            v-model="filters.keyword"
            name="app-user-keyword"
            :placeholder="strings.userManagement.filters.keywordPlaceholder"
          />
        </label>
        <label class="field">
          <span>{{ strings.userManagement.filters.userId }}</span>
          <input
            v-model="filters.userId"
            name="app-user-id"
            inputmode="numeric"
            :placeholder="strings.userManagement.filters.userIdPlaceholder"
          />
        </label>
        <label class="field">
          <span>{{ strings.userManagement.filters.status }}</span>
          <select v-model="filters.status" name="app-user-status">
            <option value="">{{ strings.userManagement.filters.statusOptions.all }}</option>
            <option value="1">{{ strings.userManagement.filters.statusOptions.active }}</option>
            <option value="2">{{ strings.userManagement.filters.statusOptions.banned }}</option>
            <option value="3">{{ strings.userManagement.filters.statusOptions.deleted }}</option>
          </select>
        </label>
        <label class="field">
          <span>{{ strings.userManagement.filters.region }}</span>
          <select v-model="filters.preferredRegion" name="app-user-region">
            <option value="">{{ strings.userManagement.filters.regionAll }}</option>
            <option value="CN">CN</option>
            <option value="EU">EU</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">
            {{ strings.userManagement.filters.apply }}
          </button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.userManagement.tableHeaders.user }}</th>
              <th>{{ strings.userManagement.tableHeaders.account }}</th>
              <th>{{ strings.userManagement.tableHeaders.regionLevel }}</th>
              <th>{{ strings.userManagement.tableHeaders.growthPoints }}</th>
              <th>{{ strings.userManagement.tableHeaders.status }}</th>
              <th>{{ strings.userManagement.tableHeaders.lastLogin }}</th>
              <th>{{ strings.userManagement.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7" class="table-empty">{{ strings.userManagement.listLoading }}</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="7" class="table-empty">{{ strings.userManagement.empty }}</td>
            </tr>
            <tr v-for="user in pageState?.list" :key="user.id">
              <td>
                <strong>{{ userLabel(user) }}</strong>
                <p class="inline-note">{{ strings.userManagement.userIdLabel(user.id) }}</p>
              </td>
              <td>
                <p class="code-box">{{ accountSummary(user) }}</p>
              </td>
              <td>
                <strong>{{ user.preferredRegion }}</strong>
                <p class="inline-note">{{ strings.userManagement.levelLabel(user.level) }}</p>
              </td>
              <td class="numeric-cell">{{ user.growthValue }} / {{ user.points }}</td>
              <td>
                <span class="status-pill" :class="statusPillClass(user)">{{ statusText(user) }}</span>
              </td>
              <td class="numeric-cell">{{ user.lastLoginAt || strings.userManagement.neverLoggedIn }}</td>
              <td>
                <div class="table-actions">
                  <button class="table-action" type="button" @click="openDetail(user)">
                    {{ strings.userManagement.detailAction }}
                  </button>
                  <button
                    v-if="canWrite && user.status === 1"
                    class="table-action table-action--danger"
                    type="button"
                    :disabled="acting"
                    @click="openBan(user)"
                  >
                    {{ strings.userManagement.banAction }}
                  </button>
                  <button
                    v-if="canWrite && user.status === 2"
                    class="table-action"
                    type="button"
                    :disabled="acting"
                    @click="unban(user)"
                  >
                    {{ strings.userManagement.unbanAction }}
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button
          type="button"
          class="ghost-button system-pager-button"
          :disabled="filters.page <= 1"
          @click="goPage(filters.page - 1)"
        >
          {{ strings.userManagement.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.userManagement.page(filters.page) }}</span>
        <button
          type="button"
          class="ghost-button system-pager-button"
          :disabled="!pageState?.hasMore"
          @click="goPage(filters.page + 1)"
        >
          {{ strings.userManagement.nextPage }}
        </button>
      </div>
    </article>

    <div v-if="detailLoading" class="audit-drawer">
      <p class="inline-note">{{ strings.userManagement.detailLoading }}</p>
    </div>
    <div v-else-if="detail" class="audit-drawer">
      <div>
        <p class="eyebrow">{{ strings.userManagement.detailEyebrow }}</p>
        <h2>{{ userLabel(detail) }}</h2>
        <p>
          <span class="status-pill" :class="statusPillClass(detail)">{{ statusText(detail) }}</span>
          · {{ strings.userManagement.detailSummary(accountSummary(detail), detail.preferredRegion) }}
        </p>
        <p v-if="detail.signature" class="inline-note">
          {{ strings.userManagement.signatureLabel }}：{{ detail.signature }}
        </p>
        <p v-if="detail.banReason" class="inline-note">
          {{ strings.userManagement.banReasonLabel }}：{{ detail.banReason }}
        </p>
        <p v-if="detail.pendingAppealCount > 0" class="inline-note">
          {{ strings.userManagement.pendingAppeal(detail.pendingAppealCount) }}
          <button class="table-action" type="button" @click="goAppealAudit">
            {{ strings.userManagement.goAppealAudit }}
          </button>
        </p>
        <p v-else-if="detail.latestAppealStatusText" class="inline-note">
          {{ strings.userManagement.latestAppealLabel }}：{{ appealStatusText(detail.latestAppealStatusText) }}
        </p>
      </div>
      <dl class="detail-grid">
        <div><dt>{{ strings.userManagement.stats.reviewCount }}</dt><dd>{{ detail.reviewCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.postCount }}</dt><dd>{{ detail.postCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.orderCount }}</dt><dd>{{ detail.orderCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.reservationCount }}</dt><dd>{{ detail.reservationCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.favoriteCount }}</dt><dd>{{ detail.favoriteCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.activeSessions }}</dt><dd>{{ detail.activeSessionCount }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.growthValue }}</dt><dd>{{ detail.growthValue }}</dd></div>
        <div><dt>{{ strings.userManagement.stats.createdAt }}</dt><dd>{{ detail.createdAt || '--' }}</dd></div>
      </dl>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="detail = null">
          {{ strings.userManagement.close }}
        </button>
      </div>
    </div>

    <div v-if="banTarget" class="audit-drawer">
      <div>
        <p class="eyebrow">{{ strings.userManagement.banEyebrow }}</p>
        <h2>{{ userLabel(banTarget) }}</h2>
        <p>{{ strings.userManagement.banDescription }}</p>
      </div>
      <label class="field field--full">
        <span>{{ strings.userManagement.banReasonField }}</span>
        <textarea
          v-model="banReason"
          name="banReason"
          rows="4"
          :placeholder="strings.userManagement.banPlaceholder"
        />
      </label>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="banTarget = null">
          {{ strings.common.cancel }}
        </button>
        <button class="secondary-button" type="button" :disabled="acting" @click="confirmBan">
          {{ strings.userManagement.confirmBan }}
        </button>
      </div>
    </div>
  </section>
</template>
