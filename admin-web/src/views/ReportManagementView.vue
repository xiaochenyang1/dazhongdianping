<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { listAdminReports, resolveAdminReport } from '@/services/admin'
import type { AdminReport, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('audit:report:write'))

const loading = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const pageState = ref<PageResult<AdminReport> | null>(null)
const selectedId = ref<number | null>(null)
const selectedType = ref<string>('')
const remark = ref('')

const filters = reactive({
  reportType: '',
  status: '0',
  keyword: '',
  page: 1,
  pageSize: 10,
})

const selected = computed(() => {
  if (!pageState.value) return null
  return (
    pageState.value.list.find(
      (item) => item.id === selectedId.value && item.reportType === selectedType.value,
    ) ??
    pageState.value.list[0] ??
    null
  )
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    pageState.value = await listAdminReports({
      reportType: filters.reportType || undefined,
      status: filters.status === '' ? undefined : Number(filters.status),
      keyword: filters.keyword.trim() || undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })
    const first = pageState.value.list[0]
    if (
      !pageState.value.list.some(
        (item) => item.id === selectedId.value && item.reportType === selectedType.value,
      )
    ) {
      selectedId.value = first?.id ?? null
      selectedType.value = first?.reportType ?? ''
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '举报列表加载失败'
  } finally {
    loading.value = false
  }
}

function select(item: AdminReport) {
  selectedId.value = item.id
  selectedType.value = item.reportType
  remark.value = ''
  success.value = ''
  error.value = ''
}

async function resolve(action: 'dismiss' | 'hide') {
  if (!selected.value || !canWrite.value) return
  if (action === 'hide' && selected.value.reportType === 'message') {
    // still allowed; backend marks as established without public hide
  }
  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await resolveAdminReport(selected.value.reportType, selected.value.id, {
      action,
      remark: remark.value.trim() || undefined,
    })
    success.value =
      action === 'hide'
        ? `举报 #${selected.value.id} 已成立${selected.value.reportType === 'message' ? '' : '，内容已隐藏'}`
        : `举报 #${selected.value.id} 已驳回`
    remark.value = ''
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '处理失败'
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedId.value = null
    selectedType.value = ''
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">内容举报</p>
        <h1>点评、帖子、私信举报统一收口，别再让举报沉在业务表里。</h1>
        <p>
          当前区域 {{ state.region }}。点评/帖子按区域过滤；私信举报为全局队列。成立可隐藏公开内容，驳回仅关闭举报。
        </p>
      </div>
    </div>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>

    <section class="content-card">
      <div class="toolbar">
        <label>
          <span class="muted">类型</span>
          <select v-model="filters.reportType" data-testid="report-type-filter" @change="filters.page = 1; load()">
            <option value="">全部</option>
            <option value="review">点评</option>
            <option value="post">帖子</option>
            <option value="message">私信</option>
          </select>
        </label>
        <label>
          <span class="muted">状态</span>
          <select v-model="filters.status" data-testid="report-status-filter" @change="filters.page = 1; load()">
            <option value="">全部</option>
            <option value="0">待处理</option>
            <option value="1">已成立</option>
            <option value="2">已驳回</option>
          </select>
        </label>
        <label>
          <span class="muted">关键词</span>
          <input
            v-model="filters.keyword"
            data-testid="report-keyword-filter"
            type="search"
            placeholder="举报人/原因/内容摘要"
            @keyup.enter="filters.page = 1; load()"
          />
        </label>
        <button type="button" class="secondary-button" @click="filters.page = 1; load()">查询</button>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>类型</th>
              <th>摘要</th>
              <th>举报人</th>
              <th>原因</th>
              <th>状态</th>
              <th>时间</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!pageState?.list.length">
              <td colspan="6" class="table-empty">当前筛选下没有举报。</td>
            </tr>
            <tr
              v-for="item in pageState?.list || []"
              :key="`${item.reportType}-${item.id}`"
              :class="{ 'is-selected': selected?.id === item.id && selected?.reportType === item.reportType }"
              :data-testid="`report-row-${item.reportType}-${item.id}`"
              @click="select(item)"
            >
              <td>{{ item.reportTypeText }}</td>
              <td>
                <strong>#{{ item.targetId }}</strong>
                <div class="muted">{{ item.targetSummary || '—' }}</div>
              </td>
              <td>{{ item.reporterUserName || item.reporterUserId }}</td>
              <td>{{ item.reason }}</td>
              <td><span class="status-pill">{{ item.statusText }}</span></td>
              <td>{{ item.createdAt }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="selected" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">举报详情</p>
          <h2>{{ selected.reportTypeText }} #{{ selected.id }}</h2>
        </div>
        <span class="status-pill">{{ selected.statusText }}</span>
      </div>
      <div class="detail-grid">
        <p><strong>目标</strong>：#{{ selected.targetId }} {{ selected.targetTypeText }}</p>
        <p><strong>作者</strong>：{{ selected.targetAuthorName || '—' }}</p>
        <p><strong>目标状态</strong>：{{ selected.targetStatusText || '—' }}</p>
        <p><strong>举报人</strong>：{{ selected.reporterUserName || selected.reporterUserId }}</p>
        <p><strong>原因</strong>：{{ selected.reason }}</p>
        <p><strong>摘要</strong>：{{ selected.targetSummary || '—' }}</p>
        <p><strong>时间</strong>：{{ selected.createdAt }}</p>
      </div>

      <div v-if="canWrite && selected.status === 0" class="form-actions" style="margin-top: 16px; gap: 12px; display: flex; flex-wrap: wrap">
        <input
          v-model="remark"
          data-testid="report-resolve-remark"
          type="text"
          maxlength="255"
          placeholder="处理备注（隐藏时建议填写）"
          style="min-width: 240px; flex: 1"
        />
        <button
          type="button"
          class="secondary-button"
          data-testid="report-dismiss"
          :disabled="acting"
          @click="resolve('dismiss')"
        >
          驳回举报
        </button>
        <button
          type="button"
          class="primary-button"
          data-testid="report-hide"
          :disabled="acting"
          @click="resolve('hide')"
        >
          成立并处理
        </button>
      </div>
      <p v-else-if="!canWrite" class="muted">当前账号仅可查看，无处理权限。</p>
      <p v-else class="muted">该举报已处理，无需再操作。</p>
    </section>
  </section>
</template>
