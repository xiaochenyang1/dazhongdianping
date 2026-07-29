<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { createCircle, listCircles, updateCircle, updateCircleStatus, type AdminCircle } from '@/services/circle'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:circle:write'))
const rows = ref<AdminCircle[]>([])
const loading = ref(false)
const error = ref('')
const editingId = ref<number | null>(null)
const keyword = ref('')
const status = ref<number | undefined>(undefined)
const form = reactive({
  name: '',
  description: '',
  coverUrl: '',
  sort: 0,
})

function circleStatusText(circleStatus: number) {
  return strings.value.circles.statusText(circleStatus)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    rows.value = (await listCircles({ status: status.value, keyword: keyword.value, page: 1, pageSize: 20 })).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.circles.loadError
  } finally {
    loading.value = false
  }
}

function edit(row: AdminCircle) {
  if (!canWrite.value) return
  editingId.value = row.id
  Object.assign(form, {
    name: row.name,
    description: row.description,
    coverUrl: row.coverUrl,
    sort: row.sort,
  })
}

function reset() {
  editingId.value = null
  Object.assign(form, { name: '', description: '', coverUrl: '', sort: 0 })
}

async function save() {
  if (!canWrite.value) return
  error.value = ''
  try {
    const payload = { ...form }
    if (editingId.value) {
      await updateCircle(editingId.value, payload)
    } else {
      await createCircle(payload)
    }
    reset()
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.circles.saveError
  }
}

async function toggle(row: AdminCircle) {
  if (!canWrite.value) return
  error.value = ''
  try {
    await updateCircleStatus(row.id, row.status === 1 ? 2 : 1)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.circles.toggleError
  }
}

onMounted(load)
</script>

<template>
  <section class="circle-page">
    <header>
      <p class="eyebrow">{{ strings.circles.eyebrow }}</p>
      <h1>{{ strings.circles.heading }}</h1>
      <p>{{ strings.circles.description }}</p>
    </header>

    <div class="panel filters">
      <input v-model="keyword" :placeholder="strings.circles.keywordPlaceholder" />
      <select v-model="status">
        <option :value="undefined">{{ strings.circles.statusOptions.all }}</option>
        <option :value="1">{{ strings.circles.statusOptions.enabled }}</option>
        <option :value="2">{{ strings.circles.statusOptions.disabled }}</option>
      </select>
      <button @click="load">{{ strings.circles.query }}</button>
    </div>

    <form v-if="canWrite" class="panel editor" data-testid="circle-editor" @submit.prevent="save">
      <input
        v-model="form.name"
        name="circle-name"
        minlength="2"
        maxlength="64"
        :placeholder="strings.circles.editorPlaceholders.name"
        required
      />
      <input v-model="form.description" maxlength="500" :placeholder="strings.circles.editorPlaceholders.description" />
      <input v-model="form.coverUrl" maxlength="255" :placeholder="strings.circles.editorPlaceholders.coverUrl" />
      <input v-model.number="form.sort" type="number" :placeholder="strings.circles.editorPlaceholders.sort" />
      <button type="submit">{{ editingId ? strings.circles.saveUpdate : strings.circles.create }}</button>
      <button v-if="editingId" type="button" @click="reset">{{ strings.common.cancel }}</button>
    </form>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="loading">{{ strings.common.loading }}</p>

    <div v-else class="circle-grid">
      <article v-for="row in rows" :key="row.id" class="panel circle-card">
        <div>
          <span class="status" :class="{ off: row.status === 2 }">{{ circleStatusText(row.status) }}</span>
          <h2>{{ row.name }}</h2>
          <p>{{ row.description || strings.circles.emptyDescription }}</p>
          <small>{{ strings.circles.summary(row.memberCount, row.postCount, row.sort) }}</small>
        </div>
        <div v-if="canWrite" class="actions">
          <button @click="edit(row)">{{ strings.circles.edit }}</button>
          <button @click="toggle(row)">{{ row.status === 1 ? strings.circles.disable : strings.circles.enable }}</button>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.circle-page{display:grid;gap:18px}.panel{background:#fff;border-radius:18px;padding:18px;box-shadow:0 12px 32px rgba(15,23,42,.07)}.filters,.editor,.actions{display:flex;gap:10px;flex-wrap:wrap}.filters input,.editor input,.filters select{min-height:42px;padding:0 12px;border:1px solid #d8dee8;border-radius:10px}.circle-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px}.circle-card{display:flex;justify-content:space-between;gap:16px}.status{color:#16794b}.status.off{color:#9a3412}button{min-height:40px;padding:0 16px;border:0;border-radius:10px;cursor:pointer}.editor button[type=submit]{background:#e85d2a;color:#fff}.is-error{color:#b42318}
</style>
