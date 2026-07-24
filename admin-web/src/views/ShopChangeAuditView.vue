<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { listAuditTasks, passAuditTask, rejectAuditTask } from '@/services/admin'
import type { AdminAuditTask, PageResult } from '@/types/admin'

const { state } = useAdminSession()
const loading = ref(false)
const acting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const pageState = ref<PageResult<AdminAuditTask> | null>(null)
const selectedTaskId = ref<number | null>(null)
const approveRemark = ref('')
const rejectReason = ref('')
const filters = reactive({ status: '0', page: 1, pageSize: 10 })

const selectedTask = computed(
  () =>
    pageState.value?.list.find((task) => task.id === selectedTaskId.value) ??
    pageState.value?.list[0] ??
    null,
)
const canHandleSelected = computed(() => selectedTask.value?.status === 0)

async function loadTasks() {
  loading.value = true
  errorMessage.value = ''
  try {
    pageState.value = await listAuditTasks({
      region: state.region,
      bizType: 5,
      status: filters.status === '' ? undefined : Number(filters.status),
      page: filters.page,
      pageSize: filters.pageSize,
    })
    if (!pageState.value.list.some((task) => task.id === selectedTaskId.value)) {
      selectedTaskId.value = pageState.value.list[0]?.id ?? null
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店草稿审核任务加载失败'
  } finally {
    loading.value = false
  }
}

function selectTask(taskId: number) {
  selectedTaskId.value = taskId
  approveRemark.value = ''
  rejectReason.value = ''
  errorMessage.value = ''
  successMessage.value = ''
}

async function handlePass() {
  if (!selectedTask.value) return

  acting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await passAuditTask(selectedTask.value.id, { remark: approveRemark.value.trim() || undefined })
    successMessage.value = `门店草稿审核任务 #${selectedTask.value.id} 已通过，变更将应用到线上门店。`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店草稿审核通过失败'
  } finally {
    acting.value = false
  }
}

async function handleReject() {
  if (!selectedTask.value) return

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
    successMessage.value = `门店草稿审核任务 #${selectedTask.value.id} 已驳回。`
    approveRemark.value = ''
    rejectReason.value = ''
    await loadTasks()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '门店草稿审核驳回失败'
  } finally {
    acting.value = false
  }
}

function applyFilters() {
  filters.page = 1
  void loadTasks()
}

watch(
  () => state.region,
  () => {
    filters.page = 1
    selectedTaskId.value = null
    void loadTasks()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">门店草稿审核</p>
        <h1>商户改门店资料，先审再上线。</h1>
        <p>
          当前区域 {{ state.region }}。这里只处理 `bizType=5` 的门店完整草稿；通过后整体应用基础资料/相册/菜单，驳回后商户可改草稿重提。
        </p>
      </div>
      <button type="button" class="secondary-button" @click="loadTasks">刷新任务</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">任务列表</p>
            <h2>新建门店和修改门店都走同一套草稿审核。</h2>
          </div>
          <span class="inline-note">共 {{ pageState?.total ?? 0 }} 条门店草稿任务</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>状态</span>
            <select v-model="filters.status" name="shop-change-status-filter">
              <option value="">全部状态</option>
              <option value="0">待人审</option>
              <option value="1">通过</option>
              <option value="2">驳回</option>
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
                <th>任务</th>
                <th>商户</th>
                <th>候选门店</th>
                <th>摘要</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="6" class="table-empty">门店草稿审核任务加载中...</td>
              </tr>
              <tr v-else-if="!pageState?.list.length">
                <td colspan="6" class="table-empty">当前没有门店草稿审核任务。</td>
              </tr>
              <tr v-for="task in pageState?.list" :key="task.id">
                <td>
                  <strong>#{{ task.id }}</strong>
                  <p>草稿 #{{ task.bizId }}</p>
                </td>
                <td>{{ task.submittedBy || '未知商户' }}</td>
                <td>
                  <strong>{{ task.shopName || '未命名门店' }}</strong>
                  <p v-if="task.shopId">目标门店 #{{ task.shopId }}</p>
                  <p v-else>新建门店</p>
                </td>
                <td>{{ task.summary || '暂无摘要' }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="
                      task.status === 0
                        ? 'status-pill--warn'
                        : task.status === 1
                          ? 'status-pill--good'
                          : 'status-pill--muted'
                    "
                  >
                    {{ task.statusText }}
                  </span>
                </td>
                <td>
                  <button type="button" class="table-action" @click="selectTask(task.id)">
                    {{ selectedTaskId === task.id ? '已选中' : '查看' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button
            type="button"
            class="ghost-button"
            :disabled="filters.page <= 1"
            @click="
              filters.page--;
              loadTasks()
            "
          >
            上一页
          </button>
          <span>第 {{ filters.page }} 页</span>
          <button
            type="button"
            class="ghost-button"
            :disabled="!pageState?.hasMore"
            @click="
              filters.page++;
              loadTasks()
            "
          >
            下一页
          </button>
        </div>
      </section>

      <section class="content-card editor-card">
        <template v-if="selectedTask">
          <div class="editor-header">
            <div>
              <p class="eyebrow">任务处理</p>
              <h2>任务 #{{ selectedTask.id }}</h2>
            </div>
            <span class="inline-note">{{ selectedTask.statusText }}</span>
          </div>
          <div class="meta-grid">
            <div>
              <span>草稿</span>
              <strong>#{{ selectedTask.bizId }}</strong>
            </div>
            <div>
              <span>商户</span>
              <strong>{{ selectedTask.submittedBy || '未知商户' }}</strong>
            </div>
            <div>
              <span>候选门店</span>
              <strong>{{ selectedTask.shopName || '未命名门店' }}</strong>
            </div>
            <div>
              <span>目标门店</span>
              <strong>{{ selectedTask.shopId ? `#${selectedTask.shopId}` : '新建门店' }}</strong>
            </div>
            <div>
              <span>区域</span>
              <strong>{{ selectedTask.region }}</strong>
            </div>
            <div>
              <span>提交时间</span>
              <strong>{{ selectedTask.createdAt }}</strong>
            </div>
          </div>
          <div class="hint-card">
            <strong>门店摘要</strong>
            <p>{{ selectedTask.summary || '暂无摘要' }}</p>
          </div>
          <label class="field field--full">
            <span>通过备注</span>
            <textarea
              v-model="approveRemark"
              name="approve-remark"
              rows="4"
              placeholder="可选，记录通过依据。"
            />
          </label>
          <label class="field field--full">
            <span>驳回原因</span>
            <textarea
              v-model="rejectReason"
              name="reject-reason"
              rows="4"
              placeholder="必填，商户端会看到这段原因。"
            />
          </label>
          <div class="form-actions">
            <button
              type="button"
              class="primary-button"
              :disabled="acting || !canHandleSelected"
              @click="handlePass"
            >
              通过门店草稿
            </button>
            <button
              type="button"
              class="secondary-button"
              :disabled="acting || !canHandleSelected"
              @click="handleReject"
            >
              驳回门店草稿
            </button>
          </div>
          <p v-if="!canHandleSelected" class="inline-note">当前任务已经处理，只保留查看。</p>
        </template>
        <div v-else class="empty-state">请先选择一条门店草稿审核任务。</div>
      </section>
    </div>
  </section>
</template>
