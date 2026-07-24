<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import { getAdminAppUser, listAdminAppUsers, updateAdminAppUserStatus } from '@/services/admin'
import type { AdminAppUser, AdminAppUserDetail, PageResult } from '@/types/admin'

const router = useRouter()
const { state } = useAdminSession()
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
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

function accountSummary(user: AdminAppUser) {
  return user.email || user.phone || `user:${user.id}`
}

function statusPillClass(user: AdminAppUser) {
  if (user.status === 2) {
    return 'status-pill--warn'
  }
  if (user.status === 3) {
    return 'status-pill--muted'
  }
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
    errorMessage.value = cause instanceof Error ? cause.message : '用户数据加载失败'
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
    errorMessage.value = cause instanceof Error ? cause.message : '用户详情加载失败'
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
  if (!target) {
    return
  }
  const reason = banReason.value.trim()
  if (!reason) {
    errorMessage.value = '封禁原因不能为空'
    return
  }
  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateAdminAppUserStatus(target.id, { action: 'ban', reason })
    successMessage.value = `用户 ${target.nickname || target.id} 已封禁，全部登录态已失效。`
    banTarget.value = null
    banReason.value = ''
    if (detail.value?.id === target.id) {
      detail.value = null
    }
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '封禁操作失败'
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
    successMessage.value = `用户 ${user.nickname || user.id} 已解封。`
    if (detail.value?.id === user.id) {
      detail.value = null
    }
    await load()
  } catch (cause) {
    errorMessage.value = cause instanceof Error ? cause.message : '解封操作失败'
  } finally {
    acting.value = false
  }
}

watch(() => state.region, () => {
  filters.page = 1
  void load()
}, { immediate: true })

function goAppealAudit() {
  void router.push('/audit/user-appeals')
}
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">User Governance</p>
        <h1>用户管理</h1>
        <p>当前区域 {{ state.region }}。封禁会立即吊销该用户的全部登录态并拦截后续登录，动作会记录审计日志。</p>
      </div>
      <button class="secondary-button" type="button" @click="load">刷新列表</button>
    </header>

    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${pageState?.total ?? 0} 个用户` }}</span>
        <span>支持按昵称 / 邮箱 / 手机号关键词、用户 ID、账号状态和归属区域筛选。</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>关键词</span>
          <input name="app-user-keyword" v-model="filters.keyword" placeholder="昵称 / 邮箱 / 手机号" />
        </label>
        <label class="field">
          <span>用户 ID</span>
          <input name="app-user-id" v-model="filters.userId" inputmode="numeric" placeholder="例如 9001" />
        </label>
        <label class="field">
          <span>账号状态</span>
          <select name="app-user-status" v-model="filters.status">
            <option value="">全部</option>
            <option value="1">正常</option>
            <option value="2">已封禁</option>
            <option value="3">已注销</option>
          </select>
        </label>
        <label class="field">
          <span>归属区域</span>
          <select name="app-user-region" v-model="filters.preferredRegion">
            <option value="">全部</option>
            <option value="CN">CN</option>
            <option value="EU">EU</option>
          </select>
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>用户</th>
              <th>账号</th>
              <th>区域 / 等级</th>
              <th>成长值 / 积分</th>
              <th>状态</th>
              <th>最近登录</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7" class="table-empty">用户数据加载中...</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="7" class="table-empty">当前筛选下没有用户。</td>
            </tr>
            <tr v-for="user in pageState?.list" :key="user.id">
              <td>
                <strong>{{ user.nickname || `user:${user.id}` }}</strong>
                <p class="inline-note">ID {{ user.id }}</p>
              </td>
              <td>
                <p class="code-box">{{ accountSummary(user) }}</p>
              </td>
              <td>
                <strong>{{ user.preferredRegion }}</strong>
                <p class="inline-note">Lv{{ user.level }}</p>
              </td>
              <td class="numeric-cell">{{ user.growthValue }} / {{ user.points }}</td>
              <td>
                <span class="status-pill" :class="statusPillClass(user)">{{ user.statusText }}</span>
              </td>
              <td class="numeric-cell">{{ user.lastLoginAt || '--' }}</td>
              <td>
                <div class="table-actions">
                  <button class="table-action" type="button" @click="openDetail(user)">详情</button>
                  <button
                    v-if="canWrite && user.status === 1"
                    class="table-action table-action--danger"
                    type="button"
                    :disabled="acting"
                    @click="openBan(user)"
                  >
                    封禁
                  </button>
                  <button
                    v-if="canWrite && user.status === 2"
                    class="table-action"
                    type="button"
                    :disabled="acting"
                    @click="unban(user)"
                  >
                    解封
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="filters.page <= 1" @click="goPage(filters.page - 1)">
          上一页
        </button>
        <span class="numeric-cell">第 {{ filters.page }} 页</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!pageState?.hasMore" @click="goPage(filters.page + 1)">
          下一页
        </button>
      </div>
    </article>

    <div v-if="detailLoading" class="audit-drawer">
      <p class="inline-note">用户详情加载中...</p>
    </div>
    <div v-else-if="detail" class="audit-drawer">
      <div>
        <p class="eyebrow">用户详情</p>
        <h2>{{ detail.nickname || `user:${detail.id}` }}</h2>
        <p>
          <span class="status-pill" :class="statusPillClass(detail)">{{ detail.statusText }}</span>
          · {{ accountSummary(detail) }} · 区域 {{ detail.preferredRegion }}
        </p>
        <p v-if="detail.signature" class="inline-note">签名：{{ detail.signature }}</p>
        <p v-if="detail.banReason" class="inline-note">封禁原因：{{ detail.banReason }}</p>
        <p v-if="detail.pendingAppealCount > 0" class="inline-note">
          该用户有 {{ detail.pendingAppealCount }} 条待审封禁申诉。
          <button class="table-action" type="button" @click="goAppealAudit">去处理</button>
        </p>
        <p v-else-if="detail.latestAppealStatusText" class="inline-note">
          最近一次封禁申诉：{{ detail.latestAppealStatusText }}
        </p>
      </div>
      <dl class="detail-grid">
        <div><dt>点评数</dt><dd>{{ detail.reviewCount }}</dd></div>
        <div><dt>帖子数</dt><dd>{{ detail.postCount }}</dd></div>
        <div><dt>订单数</dt><dd>{{ detail.orderCount }}</dd></div>
        <div><dt>预订数</dt><dd>{{ detail.reservationCount }}</dd></div>
        <div><dt>收藏数</dt><dd>{{ detail.favoriteCount }}</dd></div>
        <div><dt>活跃会话</dt><dd>{{ detail.activeSessionCount }}</dd></div>
        <div><dt>成长值</dt><dd>{{ detail.growthValue }}</dd></div>
        <div><dt>注册时间</dt><dd>{{ detail.createdAt || '--' }}</dd></div>
      </dl>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="detail = null">关闭</button>
      </div>
    </div>

    <div v-if="banTarget" class="audit-drawer">
      <div>
        <p class="eyebrow">封禁用户</p>
        <h2>{{ banTarget.nickname || `user:${banTarget.id}` }}</h2>
        <p>封禁后该用户全部登录态立即失效，密码和验证码登录都会被拦截。原因会记录进审计日志。</p>
      </div>
      <label class="field field--full">
        <span>封禁原因</span>
        <textarea v-model="banReason" name="banReason" rows="4" placeholder="例如：发布垃圾广告" />
      </label>
      <div class="form-actions">
        <button class="ghost-button" type="button" @click="banTarget = null">取消</button>
        <button class="secondary-button" type="button" :disabled="acting" @click="confirmBan">确认封禁</button>
      </div>
    </div>
  </section>
</template>
