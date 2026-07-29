<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createAdminHotWord, listAdminHotWords, removeAdminHotWord, updateAdminHotWord, updateAdminHotWordStatus } from '@/services/admin'
import type { AdminHotWord, AdminHotWordPayload } from '@/types/admin'

type HotWordEditor = AdminHotWordPayload & {
  id?: number
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:hotword:write'))

const hotWords = ref<AdminHotWord[]>([])
const editor = ref<HotWordEditor | null>(null)
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
      successMessage.value = strings.value.hotWords.updated
    } else {
      await createAdminHotWord(payload)
      successMessage.value = strings.value.hotWords.created
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
    successMessage.value = item.enabled ? strings.value.hotWords.disabled : strings.value.hotWords.enabled
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteHotWord(item: AdminHotWord) {
  if (!canWrite.value || saving.value) return
  const confirmed = window.confirm(strings.value.hotWords.deleteConfirm(item.keyword))
  if (!confirmed) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminHotWord(item.id)
    successMessage.value = strings.value.hotWords.deleted
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
        <p class="eyebrow">{{ strings.hotWords.eyebrow }}</p>
        <h1>{{ strings.hotWords.heading }}</h1>
        <p>{{ strings.hotWords.description(state.region) }}</p>
      </div>
      <button v-if="canWrite" data-testid="create-hotword" class="secondary-button" type="button" @click="openEditor()">{{ strings.hotWords.create }}</button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.hotWords.listEyebrow }}</p>
          <h2>{{ strings.hotWords.listHeading }}</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.hotWords.tableHeaders.keyword }}</th>
              <th>{{ strings.hotWords.tableHeaders.sort }}</th>
              <th>{{ strings.hotWords.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.hotWords.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">{{ strings.hotWords.loading }}</td>
            </tr>
            <tr v-else-if="!hotWords.length">
              <td :colspan="canWrite ? 4 : 3" class="table-empty">{{ strings.hotWords.empty }}</td>
            </tr>
            <tr v-for="item in hotWords" :key="item.id">
              <td><strong>{{ item.keyword }}</strong></td>
              <td>{{ item.sortNo }}</td>
              <td><span class="status-pill">{{ strings.hotWords.statusText(item.enabled) }}</span></td>
              <td v-if="canWrite" class="table-actions">
                <button :data-testid="`edit-hotword-${item.id}`" class="table-action" type="button" @click="openEditor(item)">{{ strings.hotWords.edit }}</button>
                <button :data-testid="`toggle-hotword-${item.id}`" class="table-action" type="button" @click="toggleHotWord(item)">
                  {{ item.enabled ? strings.hotWords.disable : strings.hotWords.enable }}
                </button>
                <button :data-testid="`delete-hotword-${item.id}`" class="table-action danger-action" type="button" @click="deleteHotWord(item)">{{ strings.hotWords.delete }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.hotWords.editorEyebrow(Boolean(editor.id)) }}</p>
          <h2>{{ strings.hotWords.editorHeading(Boolean(editor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="hotword-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field field--full">
            <span>{{ strings.hotWords.labels.keyword }}</span>
            <input v-model="editor.keyword" name="hotword-keyword" type="text" maxlength="64" required />
          </label>
          <label class="field">
            <span>{{ strings.hotWords.labels.sort }}</span>
            <input v-model.number="editor.sortNo" name="hotword-sort-no" type="number" min="0" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">{{ saving ? strings.hotWords.saving : strings.hotWords.save }}</button>
          <button class="secondary-button" type="button" @click="editor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>
  </section>
</template>
