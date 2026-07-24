<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const loading = ref(false)
const acting = ref(false)
const error = ref('')
const success = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedId = ref<number | null>(null)
const passRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', page: 1, pageSize: 10 })
const selected = computed(
  () => pageState.value?.list.find((item) => item.id === selectedId.value) ?? pageState.value?.list[0] ?? null,
)
const canWrite = computed(() => state.permissions.includes('audit:user_appeal:write'))

async function load() {
  loading.value = true
  error.value = ''
  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 8,
      status: filters.status === '' ? undefined : Number(filters.status),
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((item) => item.id === selectedId.value)) {
      selectedId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (e) {
    error.value = e instanceof Error ? e.message : '申诉任务加载失败'
  } finally {
    loading.value = false
  }
}

async function pass() {
  if (!selected.value) return
  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await passAuditTask(selected.value.id, { remark: passRemark.value.trim() || undefined })
    success.value = `申诉任务 #${selected.value.id} 已通过，用户已自动解封。`
    passRemark.value = ''
    await load()
  } catch (e) {
    error.value = e instanceof Error ? e.message : '审核失败'
  } finally {
    acting.value = false
  }
}

async function reject() {
  if (!selected.value) return
  const reason = rejectReason.value.trim()
  if (!reason) {
    error.value = '驳回原因不能为空。'
    return
  }
  acting.value = true
  error.value = ''
  success.value = ''
  try {
    await rejectAuditTask(selected.value.id, { reason })
    success.value = `申诉任务 #${selected.value.id} 已驳回，用户保持封禁。`
    rejectReason.value = ''
    await load()
  } catch (e) {
    error.value = e instanceof Error ? e.message : '审核失败'
  } finally {
    acting.value = false
  }
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedId.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">用户封禁申诉</p>
        <h1>误封要能翻案，恶意申诉也要拦得住。</h1>
        <p>当前区域 {{ state.region }}，通过申诉会立即解封该用户并写入审计日志；驳回后用户保持封禁，可补充材料重新申诉。</p>
      </div>
      <button class="secondary-button" @click="load">刷新</button>
    </div>
    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="success" class="feedback is-success">{{ success }}</p>
    <div class="two-column-layout">
      <section class="content-card">
        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>状态</span>
            <select v-model="filters.status" @change="filters.page = 1; load()">
              <option value="">全部</option>
              <option value="0">待人审</option>
              <option value="1">通过</option>
              <option value="2">驳回</option>
            </select>
          </label>
        </div>
        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>任务</th>
                <th>申诉用户</th>
                <th>申诉理由</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">加载中...</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="5" class="table-empty">当前没有封禁申诉任务。</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>#{{ task.id }}<p>申诉 #{{ task.bizId }}</p></td>
                <td>{{ task.submittedBy || '--' }}</td>
                <td>{{ task.summary || '暂无理由' }}</td>
                <td>{{ task.statusText }}</td>
                <td><button class="table-action" @click="selectedId = task.id">查看</button></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="pager">
          <button class="ghost-button" :disabled="filters.page <= 1" @click="filters.page--; load()">上一页</button>
          <span>第 {{ filters.page }} 页 / 共 {{ pageState?.total ?? 0 }} 条</span>
          <button class="ghost-button" :disabled="!pageState?.hasMore" @click="filters.page++; load()">下一页</button>
        </div>
      </section>
      <section class="content-card editor-card">
        <template v-if="selected">
          <div class="editor-header">
            <div>
              <p class="eyebrow">申诉处理</p>
              <h2>任务 #{{ selected.id }}</h2>
            </div>
            <span class="inline-note">{{ selected.statusText }}</span>
          </div>
          <div class="hint-card">
            <strong>申诉用户</strong>
            <p>{{ selected.submittedBy || '--' }}</p>
            <strong>申诉理由</strong>
            <p>{{ selected.summary || '暂无理由' }}</p>
          </div>
          <label class="field field--full">
            <span>通过备注（通过后立即解封）</span>
            <textarea v-model="passRemark" rows="4" />
          </label>
          <label class="field field--full">
            <span>驳回原因（会展示给用户）</span>
            <textarea v-model="rejectReason" rows="4" />
          </label>
          <div class="form-actions">
            <button
              class="primary-button"
              :disabled="acting || selected.status !== 0 || !canWrite"
              @click="pass"
            >
              通过并解封
            </button>
            <button
              class="secondary-button"
              :disabled="acting || selected.status !== 0 || !canWrite"
              @click="reject"
            >
              驳回申诉
            </button>
          </div>
          <p v-if="!canWrite" class="inline-note">当前账号只有查看权限，无法处理申诉。</p>
        </template>
        <div v-else class="empty-state">请先选择一条申诉任务。</div>
      </section>
    </div>
  </section>
</template>
