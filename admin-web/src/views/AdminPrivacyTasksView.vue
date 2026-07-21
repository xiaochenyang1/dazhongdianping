<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { listAdminPrivacyTasks } from '@/services/admin'
import type { AdminPrivacyTask, PageResult } from '@/types/admin'

const pageSize = 20
const loading = ref(false)
const errorMessage = ref('')
const pageState = ref<PageResult<AdminPrivacyTask> | null>(null)
const filters = reactive({
  userId: '',
  taskType: '',
  status: '',
  keyword: '',
  page: 1,
})

const statusOptions = computed(() => {
  if (filters.taskType === '2') {
    return [
      { value: '', label: '全部状态' },
      { value: '0', label: '待确认' },
      { value: '1', label: '冷静期中' },
      { value: '2', label: '处理中' },
      { value: '3', label: '已完成' },
      { value: '4', label: '已取消' },
      { value: '5', label: '已驳回' },
    ]
  }
  if (filters.taskType === '1') {
    return [
      { value: '', label: '全部状态' },
      { value: '0', label: '待处理' },
      { value: '1', label: '处理中' },
      { value: '2', label: '可下载' },
      { value: '3', label: '已过期' },
      { value: '4', label: '失败' },
      { value: '5', label: '已取消' },
    ]
  }
  return [
    { value: '', label: '全部状态' },
    { value: '0', label: '0: 待处理/待确认' },
    { value: '1', label: '1: 处理中/冷静期中' },
    { value: '2', label: '2: 可下载/处理中' },
    { value: '3', label: '3: 已过期/已完成' },
    { value: '4', label: '4: 失败/已取消' },
    { value: '5', label: '5: 已取消/已驳回' },
  ]
})

function normalizeNumber(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return undefined
  }
  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : undefined
}

function normalizeText(value: string) {
  const normalized = value.trim()
  return normalized ? normalized : undefined
}

function taskSummary(task: AdminPrivacyTask) {
  if (task.taskType === 1) {
    const modules = task.modules.join(' / ')
    return modules || '全部模块'
  }
  return task.reason || '无说明'
}

function taskDeadline(task: AdminPrivacyTask) {
  if (task.taskType === 1) {
    return task.expireAt || '--'
  }
  return task.coolingOffExpireAt || task.completedAt || task.cancelledAt || '--'
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAdminPrivacyTasks({
      userId: normalizeNumber(filters.userId),
      taskType: normalizeNumber(filters.taskType),
      status: normalizeNumber(filters.status),
      keyword: normalizeText(filters.keyword),
      page: filters.page,
      pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '隐私任务加载失败'
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

function handleTaskTypeChange() {
  filters.status = ''
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Privacy Operations</p>
        <h1>隐私任务</h1>
        <p>这里查的是用户数据导出和账号删除任务。合规链路别靠猜，先看任务状态和时间线。</p>
      </div>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${pageState?.total ?? 0} 条隐私任务` }}</span>
        <span>支持按用户、任务类型、状态和关键词交叉筛选。</span>
      </div>

      <div class="toolbar-grid toolbar-grid--filters">
        <label class="field">
          <span>用户 ID</span>
          <input name="privacy-task-user-id" v-model="filters.userId" inputmode="numeric" placeholder="例如 9001" />
        </label>
        <label class="field">
          <span>任务类型</span>
          <select name="privacy-task-type" v-model="filters.taskType" @change="handleTaskTypeChange">
            <option value="">全部类型</option>
            <option value="1">数据导出</option>
            <option value="2">账号删除</option>
          </select>
        </label>
        <label class="field">
          <span>状态</span>
          <select name="privacy-task-status" v-model="filters.status">
            <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </label>
        <label class="field">
          <span>关键词</span>
          <input name="privacy-task-keyword" v-model="filters.keyword" placeholder="账号、模块、原因、失败信息" />
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
              <th>任务</th>
              <th>用户</th>
              <th>状态</th>
              <th>关键信息</th>
              <th>时效</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="table-empty">隐私任务加载中...</td>
            </tr>
            <tr v-else-if="!(pageState?.list.length)">
              <td colspan="6" class="table-empty">当前筛选下没有隐私任务，条件别拧巴过头。</td>
            </tr>
            <tr v-for="task in pageState?.list" :key="`${task.taskType}-${task.id}`">
              <td class="numeric-cell">{{ task.createdAt }}</td>
              <td>
                <strong>{{ task.taskTypeText }}</strong>
                <p class="code-box">#{{ task.id }}</p>
              </td>
              <td>
                <strong>{{ task.userNickname || '--' }}</strong>
                <p class="code-box">{{ task.account || `user:${task.userId}` }}</p>
              </td>
              <td>
                <span class="status-pill" :class="task.status === 2 && task.taskType === 1 ? 'status-pill--good' : task.status >= 4 ? 'status-pill--muted' : 'status-pill--warn'">
                  {{ task.statusText }}
                </span>
              </td>
              <td>
                <p>{{ taskSummary(task) }}</p>
                <p class="inline-note" v-if="task.taskType === 1">
                  {{ task.fileName || '尚未生成文件' }}
                  <span v-if="task.failReason"> · {{ task.failReason }}</span>
                </p>
                <p class="inline-note" v-else>
                  验证方式：{{ task.verifyType || '--' }}
                </p>
              </td>
              <td class="numeric-cell">{{ taskDeadline(task) }}</td>
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
