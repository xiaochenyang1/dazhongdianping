<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
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
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:sensitive_word:write'))

const words = ref<AdminSensitiveWord[]>([])
const editor = ref<SensitiveWordEditor | null>(null)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let requestId = 0

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : strings.value.common.requestFailed
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
      successMessage.value = strings.value.sensitiveWords.updated
    } else {
      await createAdminSensitiveWord(payload)
      successMessage.value = strings.value.sensitiveWords.created
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
    successMessage.value = item.enabled ? strings.value.sensitiveWords.disabled : strings.value.sensitiveWords.enabled
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteWord(item: AdminSensitiveWord) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(strings.value.sensitiveWords.deleteConfirm(item.word))
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminSensitiveWord(item.id)
    successMessage.value = strings.value.sensitiveWords.deleted
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
        <p class="eyebrow">{{ strings.sensitiveWords.eyebrow }}</p>
        <h1>{{ strings.sensitiveWords.heading }}</h1>
        <p>{{ strings.sensitiveWords.description(state.region) }}</p>
      </div>
      <button
        v-if="canWrite"
        data-testid="create-sensitive-word"
        class="secondary-button"
        type="button"
        @click="openEditor()"
      >
        {{ strings.sensitiveWords.create }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.sensitiveWords.listEyebrow }}</p>
          <h2>{{ strings.sensitiveWords.listHeading }}</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.sensitiveWords.tableHeaders.word }}</th>
              <th>{{ strings.sensitiveWords.tableHeaders.remark }}</th>
              <th>{{ strings.sensitiveWords.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.sensitiveWords.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">{{ strings.sensitiveWords.loading }}</td>
            </tr>
            <tr v-else-if="!words.length">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">{{ strings.sensitiveWords.empty }}</td>
            </tr>
            <tr v-for="item in words" :key="item.id">
              <td><strong>{{ item.word }}</strong></td>
              <td>{{ item.remark || strings.sensitiveWords.remarkFallback }}</td>
              <td><span class="status-pill">{{ strings.sensitiveWords.statusText(item.enabled) }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button
                  :data-testid="`edit-sensitive-word-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="openEditor(item)"
                >
                  {{ strings.sensitiveWords.edit }}
                </button>
                <button
                  :data-testid="`toggle-sensitive-word-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="toggleWord(item)"
                >
                  {{ item.enabled ? strings.sensitiveWords.disable : strings.sensitiveWords.enable }}
                </button>
                <button
                  :data-testid="`delete-sensitive-word-${item.id}`"
                  class="table-action danger-action"
                  type="button"
                  @click="deleteWord(item)"
                >
                  {{ strings.sensitiveWords.delete }}
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
          <p class="eyebrow">{{ strings.sensitiveWords.editorEyebrow(Boolean(editor.id)) }}</p>
          <h2>{{ strings.sensitiveWords.editorHeading(Boolean(editor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="sensitive-word-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field field--full">
            <span>{{ strings.sensitiveWords.labels.word }}</span>
            <input v-model="editor.word" name="sensitive-word" type="text" maxlength="64" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.sensitiveWords.labels.remark }}</span>
            <input v-model="editor.remark" name="sensitive-word-remark" type="text" maxlength="255" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">
            {{ saving ? strings.sensitiveWords.saving : strings.sensitiveWords.save }}
          </button>
          <button class="secondary-button" type="button" @click="editor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>
  </section>
</template>
