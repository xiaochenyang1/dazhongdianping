<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { listAdminAuditLogs } from '@/services/admin'
import type { AdminAuditLog, PageResult } from '@/types/admin'

const pageSize = 20
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminAuditLog> | null>(null)
const filters = reactive({
  adminId: '',
  action: '',
  target: '',
  keyword: '',
  page: 1,
})

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

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminAuditLogs({
      adminId: normalizeNumber(filters.adminId),
      action: normalizeText(filters.action),
      target: normalizeText(filters.target),
      keyword: normalizeText(filters.keyword),
      page: filters.page,
      pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审计日志加载失败'
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

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Audit Trail</p>
        <h1>审计日志</h1>
        <p>管理员登录、角色变更、审核动作都会往这儿落。查问题别靠拍脑门，先翻日志。</p>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${pageState?.total ?? 0} 条日志` }}</span>
        <span>支持按管理员、动作、目标和关键词交叉过滤。</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>管理员 ID</span>
          <input name="audit-log-admin-id" v-model="filters.adminId" inputmode="numeric" placeholder="例如 1" />
        </label>
        <label class="field">
          <span>动作</span>
          <input name="audit-log-action" v-model="filters.action" placeholder="例如 system.role_update" />
        </label>
        <label class="field">
          <span>目标</span>
          <input name="audit-log-target" v-model="filters.target" placeholder="例如 role:7" />
        </label>
        <label class="field">
          <span>关键词</span>
          <input name="audit-log-keyword" v-model="filters.keyword" placeholder="搜索详情、IP、账号" />
        </label>
        <div class="toolbar-actions">
          <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>操作人</th>
              <th>动作</th>
              <th>目标</th>
              <th>详情</th>
              <th>IP</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">审计日志加载中...</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="6" class="table-empty">当前筛选下没有审计日志，条件别拧得太邪乎。</td>
            </tr>
            <tr v-for="item in pageState?.list" :key="item.id">
              <td class="numeric-cell">{{ item.createdAt }}</td>
              <td>
                <strong>{{ item.adminName || '系统' }}</strong>
                <p class="code-box">{{ item.adminAccount || `admin:${item.adminId}` }}</p>
              </td>
              <td><p class="code-box">{{ item.action }}</p></td>
              <td><p class="code-box">{{ item.target || '--' }}</p></td>
              <td>{{ item.detail || '无详情' }}</td>
              <td class="numeric-cell">{{ item.ip || '--' }}</td>
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
  </section>
</template>
