<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { createAdminHotWord, listAdminHotWords, removeAdminHotWord, updateAdminHotWord, updateAdminHotWordStatus } from '@/services/admin'
import type { AdminHotWord, AdminHotWordPayload } from '@/types/admin'

type HotWordEditor = AdminHotWordPayload & {
  id?: number
}

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('operations:hotword:write'))

const hotWords = ref<AdminHotWord[]>([])
const editor = ref<HotWordEditor | null>(null)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let requestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : '请求失败'
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  resetMessages()
  try {
    const nextHotWords = await listAdminHotWords()
    if (currentRequestId !== requestId) return
    hotWords.value = nextHotWords
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error)
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

function openEditor(item?: AdminHotWord) {
  if (!canWrite.value) return
  resetMessages()
  editor.value = item
    ? {
        id: item.id,
        keyword: item.keyword,
        sortNo: item.sortNo,
      }
    : {
        keyword: '',
        sortNo: 0,
      }
}

async function submitEditor() {
  if (!editor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const current = editor.value
  const payload: AdminHotWordPayload = {
    keyword: current.keyword.trim(),
    sortNo: Number(current.sortNo),
  }
  try {
    if (current.id) {
      await updateAdminHotWord(current.id, payload)
      successMessage.value = '热词已更新'
    } else {
      await createAdminHotWord(payload)
      successMessage.value = '热词已创建'
    }
    editor.value = null
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleHotWord(item: AdminHotWord) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminHotWordStatus(item.id, !item.enabled)
    successMessage.value = item.enabled ? '热词已停用' : '热词已启用'
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteHotWord(item: AdminHotWord) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(`确认删除热词「${item.keyword}」？删除后公开端可能回退到统计结果。`)
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminHotWord(item.id)
    successMessage.value = '热词已删除'
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

watch(
  () => state.region,
  () => {
    editor.value = null
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">搜索运营</p>
        <h1>热词走真表，别再让 fallback 统计冒充运营决定。</h1>
        <p>当前区域 {{ state.region }}。只要存在启用热词，公开端 `/search/hot` 就优先按这里的排序返回；删空后才回退到分类和标签统计。</p>
      </div>
      <button v-if="canWrite" data-testid="create-hotword" class="secondary-button" type="button" @click="openEditor()">新建热词</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">热词列表</p>
          <h2>排序越小越靠前，停用后公开端会立刻忽略这条配置</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>关键词</th>
              <th>排序</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!hotWords.length">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">当前区域还没有配置热词，会回退到统计结果。</td>
            </tr>
            <tr v-for="item in hotWords" :key="item.id">
              <td><strong>{{ item.keyword }}</strong></td>
              <td>{{ item.sortNo }}</td>
              <td><span class="status-pill">{{ item.enabled ? '启用' : '停用' }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-hotword-${item.id}`" class="table-action" type="button" @click="openEditor(item)">编辑</button>
                <button :data-testid="`toggle-hotword-${item.id}`" class="table-action" type="button" @click="toggleHotWord(item)">
                  {{ item.enabled ? '停用' : '启用' }}
                </button>
                <button :data-testid="`delete-hotword-${item.id}`" class="table-action danger-action" type="button" @click="deleteHotWord(item)">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ editor.id ? '编辑热词' : '新建热词' }}</p>
          <h2>{{ editor.id ? '改完即影响公开搜索面板' : '新建后会按排序进入公开端热词列表' }}</h2>
        </div>
      </div>

      <form data-testid="hotword-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field field--full">
            <span>关键词</span>
            <input v-model="editor.keyword" name="hotword-keyword" type="text" maxlength="64" required />
          </label>
          <label class="field">
            <span>排序</span>
            <input v-model.number="editor.sortNo" name="hotword-sort-no" type="number" min="0" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存热词' }}</button>
          <button class="secondary-button" type="button" @click="editor = null">取消</button>
        </div>
      </form>
    </section>
  </section>
</template>
