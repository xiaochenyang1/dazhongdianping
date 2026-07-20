<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

interface AuditFilters {
  status: string
  page: number
  pageSize: number
}

const { state } = useAdminSession()

const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')

const filters = reactive<AuditFilters>({
  status: '0',
  page: 1,
  pageSize: 10,
})

const selectedTask = computed(() => {
  if (!pageState.value || pageState.value.list.length === 0) {
    return null
  }

  return pageState.value.list.find((item) => item.id === selectedTaskId.value) ?? pageState.value.list[0]
})

const canHandleSelected = computed(() => selectedTask.value?.status === 0)

async function loadTasks() {
  loading.value = true
  errorMessage.value = ''

  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 3,
      status: filters.status ? Number(filters.status) : undefined,
      page: filters.page,
      pageSize: filters.pageSize,
    })

    const exists = pageState.value.list.some((item) => item.id === selectedTaskId.value)
    selectedTaskId.value = exists ? selectedTaskId.value : (pageState.value.list[0]?.id ?? null)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核任务加载失败'
  } finally {
    loading.value = false
  }
}

function selectTask(taskId: number) {
  selectedTaskId.value = taskId
  approveRemark.value = ''
  rejectReason.value = ''
  successMessage.value = ''
  errorMessage.value = ''
}

async function handlePass() {
  if (!selectedTask.value) {
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await passAuditTask(selectedTask.value.id, {
      remark: approveRemark.value.trim() || undefined,
    })
    successMessage.value = `任务 #${selectedTask.value.id} 已审核通过。`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核通过失败'
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  if (!selectedTask.value) {
    return
  }

  const reason = rejectReason.value.trim()
  if (!reason) {
    errorMessage.value = '驳回原因不能为空。'
    return
  }

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await rejectAuditTask(selectedTask.value.id, { reason })
    successMessage.value = `任务 #${selectedTask.value.id} 已驳回。`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '审核驳回失败'
  } finally {
    acting.value = false
  }
}

function applyFilters() {
  filters.page = 1
  void loadTasks()
}

function goPrevPage() {
  if (!pageState.value || pageState.value.page <= 1) {
    return
  }

  filters.page -= 1
  void loadTasks()
}

function goNextPage() {
  if (!pageState.value?.hasMore) {
    return
  }

  filters.page += 1
  void loadTasks()
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedTaskId.value = null
    approveRemark.value = ''
    rejectReason.value = ''
    successMessage.value = ''
    errorMessage.value = ''
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">点评审核</p>
        <h1>先把待审点评捋顺，别让内容审核全靠数据库手改。</h1>
        <p>当前区域 {{ state.region }} 的点评审核任务都在这儿，先保住最小闭环。</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="loadTasks">刷新任务</button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">任务列表</p>
            <h2>先把待审任务抓出来，再谈审核效率。</h2>
          </div>
          <span class="inline-note">当前共 {{ pageState?.total ?? 0 }} 条点评审核任务</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>状态</span>
            <select v-model="filters.status">
              <option value="">全部状态</option>
              <option value="0">待人审</option>
              <option value="1">通过</option>
              <option value="2">驳回</option>
            </select>
          </label>

          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyFilters">应用筛选</button>
            <button type="button" class="ghost-button" @click="loadTasks">重置刷新</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>任务</th>
                <th>门店</th>
                <th>提交人</th>
                <th>状态</th>
                <th>提交时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="6" class="table-empty">点评审核任务加载中...</td>
              </tr>
              <tr v-else-if="!pageState || pageState.list.length === 0">
                <td colspan="6" class="table-empty">当前筛选下没有审核任务，别硬盯着空气发愣。</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>点评 #{{ task.bizId }}</p>
                </td>
                <td>
                  <strong>{{ task.shopName || '--' }}</strong>
                  <p>{{ task.region }} · {{ task.bizTypeText }}</p>
                </td>
                <td>{{ task.submittedBy || '匿名' }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="task.status === 0 ? 'status-pill--warn' : task.status === 1 ? 'status-pill--good' : 'status-pill--muted'"
                  >
                    {{ task.statusText }}
                  </span>
                </td>
                <td>{{ task.createdAt }}</td>
                <td class="table-actions">
                  <button type="button" class="table-action" @click="selectTask(task.id)">
                    {{ selectedTaskId === task.id ? '已选中' : '查看' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button type="button" class="ghost-button" :disabled="(pageState?.page ?? 1) <= 1" @click="goPrevPage">
            上一页
          </button>
          <span>第 {{ pageState?.page ?? 1 }} 页</span>
          <button type="button" class="ghost-button" :disabled="!pageState?.hasMore" @click="goNextPage">
            下一页
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <div class="editor-header">
          <div>
            <p class="eyebrow">任务处理</p>
            <h2>{{ selectedTask ? `任务 #${selectedTask.id}` : '先选一条任务' }}</h2>
          </div>
          <span class="inline-note">{{ selectedTask?.statusText ?? '暂无选中任务' }}</span>
        </div>

        <template v-if="selectedTask">
          <div class="meta-grid">
            <div>
              <span>门店</span>
              <strong>{{ selectedTask.shopName || '--' }}</strong>
            </div>
            <div>
              <span>提交人</span>
              <strong>{{ selectedTask.submittedBy || '匿名' }}</strong>
            </div>
            <div>
              <span>提交时间</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
            <div>
              <span>最近处理</span>
              <strong>{{ selectedTask.updatedAt || '--' }}</strong>
            </div>
          </div>

          <div class="hint-card">
            <strong>点评摘要</strong>
            <p>{{ selectedTask.summary || '当前没有可展示的点评摘要。' }}</p>
          </div>

          <label class="field field--full">
            <span>通过备注</span>
            <textarea
              v-model="approveRemark"
              rows="4"
              spellcheck="false"
              placeholder="可选。比如：内容真实、表达完整。"
            />
          </label>

          <label class="field field--full">
            <span>驳回原因</span>
            <textarea
              v-model="rejectReason"
              rows="4"
              spellcheck="false"
              placeholder="必填。别写成“自己体会”，那纯属摆烂。"
            />
          </label>

          <div class="form-actions">
            <button
              type="button"
              class="primary-button"
              :disabled="acting || !canHandleSelected"
              @click="handlePass"
            >
              {{ acting && canHandleSelected ? '处理中...' : '通过点评' }}
            </button>
            <button
              type="button"
              class="secondary-button"
              :disabled="acting || !canHandleSelected"
              @click="handleReject"
            >
              {{ acting && canHandleSelected ? '处理中...' : '驳回点评' }}
            </button>
          </div>

          <p class="inline-note" v-if="!canHandleSelected">
            当前任务已经处理过了，只能查看结果，别对着已完成任务猛点按钮。
          </p>
        </template>

        <div v-else class="empty-state">
          当前筛选下没有选中的审核任务。先从左边挑一条，别对着空白面板发功。
        </div>
      </section>
    </div>
  </section>
</template>
