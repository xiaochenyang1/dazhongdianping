<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminSensitiveWord,
  listAdminSensitiveWords,
  removeAdminSensitiveWord,
  updateAdminSensitiveWord,
  updateAdminSensitiveWordStatus,
} from '@/services/admin'
import type { AdminSensitiveWord, AdminSensitiveWordPayload } from '@/types/admin'

type SensitiveWordEditor = AdminSensitiveWordPayload & {
  id?: number
}

const { state } = useAdminSession()
const canWrite = computed(() => state.permissions.includes('operations:sensitive_word:write'))

const words = ref<AdminSensitiveWord[]>([])
const editor = ref<SensitiveWordEditor | null>(null)
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
    const nextWords = await listAdminSensitiveWords()
    if (currentRequestId !== requestId) return
    words.value = nextWords
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

function openEditor(item?: AdminSensitiveWord) {
  if (!canWrite.value) return
  resetMessages()
  editor.value = item
    ? {
        id: item.id,
        word: item.word,
        remark: item.remark,
      }
    : {
        word: '',
        remark: '',
      }
}

async function submitEditor() {
  if (!editor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const current = editor.value
  const payload: AdminSensitiveWordPayload = {
    word: current.word.trim(),
    remark: current.remark.trim(),
  }
  try {
    if (current.id) {
      await updateAdminSensitiveWord(current.id, payload)
      successMessage.value = '敏感词已更新'
    } else {
      await createAdminSensitiveWord(payload)
      successMessage.value = '敏感词已创建'
    }
    editor.value = null
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleWord(item: AdminSensitiveWord) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  try {
    await updateAdminSensitiveWordStatus(item.id, !item.enabled)
    successMessage.value = item.enabled ? '敏感词已停用' : '敏感词已启用'
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteWord(item: AdminSensitiveWord) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(`确认删除敏感词「${item.word}」？删除后对应拦截会立即失效。`)
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminSensitiveWord(item.id)
    successMessage.value = '敏感词已删除'
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
        <p class="eyebrow">内容治理</p>
        <h1>敏感词库先把机审底座立住，再谈第三方审核。</h1>
        <p>
          当前区域 {{ state.region }}。启用词会对点评、帖子、评论和私信写入做包含匹配拦截；停用或删除后立即失效。
        </p>
      </div>
      <button
        v-if="canWrite"
        data-testid="create-sensitive-word"
        class="secondary-button"
        type="button"
        @click="openEditor()"
      >
        新建敏感词
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">词库列表</p>
          <h2>按区域维护，写入侧实时按启用词拦截</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>敏感词</th>
              <th>备注</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">加载中...</td>
            </tr>
            <tr v-else-if="!words.length">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">当前区域还没有敏感词。</td>
            </tr>
            <tr v-for="item in words" :key="item.id">
              <td><strong>{{ item.word }}</strong></td>
              <td>{{ item.remark || '—' }}</td>
              <td><span class="status-pill">{{ item.enabled ? '启用' : '停用' }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button
                  :data-testid="`edit-sensitive-word-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="openEditor(item)"
                >
                  编辑
                </button>
                <button
                  :data-testid="`toggle-sensitive-word-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="toggleWord(item)"
                >
                  {{ item.enabled ? '停用' : '启用' }}
                </button>
                <button
                  :data-testid="`delete-sensitive-word-${item.id}`"
                  class="table-action danger-action"
                  type="button"
                  @click="deleteWord(item)"
                >
                  删除
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ editor.id ? '编辑敏感词' : '新建敏感词' }}</p>
          <h2>{{ editor.id ? '改完立即影响当前区域拦截' : '新建后默认启用并参与拦截' }}</h2>
        </div>
      </div>

      <form data-testid="sensitive-word-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field field--full">
            <span>敏感词</span>
            <input v-model="editor.word" name="sensitive-word" type="text" maxlength="64" required />
          </label>
          <label class="field field--full">
            <span>备注</span>
            <input v-model="editor.remark" name="sensitive-word-remark" type="text" maxlength="255" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">
            {{ saving ? '保存中...' : '保存敏感词' }}
          </button>
          <button class="secondary-button" type="button" @click="editor = null">取消</button>
        </div>
      </form>
    </section>
  </section>
</template>
