<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
import { fetchComplaints, replyComplaint, type MerchantComplaint } from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const copy = computed(() => strings.value.complaints)
const loading = ref(true)
const error = ref('')
const success = ref('')
const items = ref<MerchantComplaint[]>([])
const replyDrafts = ref<Record<number, string>>({})
const statusFilter = ref<number | ''>('')

const canView = computed(() => props.permissions.includes('complaint:view'))
const canReply = computed(() => props.permissions.includes('complaint:reply'))

function canRebut(item: MerchantComplaint) {
  return item.status === 1 || item.status === 2
}

async function load() {
  loading.value = true
  error.value = ''
  success.value = ''
  try {
    const page = await fetchComplaints({
      status: statusFilter.value === '' ? undefined : Number(statusFilter.value),
      page: 1,
      pageSize: 50,
    })
    items.value = page.list
    replyDrafts.value = Object.fromEntries(items.value.map((i) => [i.id, i.merchantReply ?? '']))
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.loadError
  } finally {
    loading.value = false
  }
}

async function reply(item: MerchantComplaint) {
  if (!canReply.value) return
  const text = (replyDrafts.value[item.id] ?? '').trim()
  if (!text) {
    error.value = copy.value.replyRequired
    return
  }
  error.value = ''
  success.value = ''
  try {
    await replyComplaint(item.id, text)
    success.value = copy.value.replySuccess
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : copy.value.replyError
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ copy.summary }}</span>
      <label>
        {{ copy.filterStatus }}
        <select v-model="statusFilter" @change="load">
          <option value="">{{ copy.all }}</option>
          <option :value="1">{{ copy.statusText(1) }}</option>
          <option :value="2">{{ copy.statusText(2) }}</option>
          <option :value="3">{{ copy.statusText(3) }}</option>
          <option :value="4">{{ copy.statusText(4) }}</option>
        </select>
      </label>
      <button type="button" @click="load">{{ strings.common.refresh }}</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="success" class="muted" role="status">{{ success }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ copy.headers.ticketNo }}</th>
            <th>{{ copy.headers.shop }}</th>
            <th>{{ copy.headers.type }}</th>
            <th>{{ copy.headers.user }}</th>
            <th>{{ copy.headers.status }}</th>
            <th>{{ copy.headers.content }}</th>
            <th>{{ copy.headers.reply }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td class="mono">{{ item.ticketNo }}</td>
            <td>{{ item.shopName }}</td>
            <td>{{ copy.typeText(item.type, item.typeText) }}</td>
            <td>{{ item.userNickname }}</td>
            <td>{{ copy.statusText(item.status, item.statusText) }}</td>
            <td>
              <p>{{ item.content }}</p>
              <p v-if="item.resolution" class="muted">{{ copy.resolution }}: {{ item.resolution }}</p>
            </td>
            <td>
              <div v-if="canReply && canRebut(item)" :data-testid="`reply-actions-${item.id}`">
                <textarea
                  v-model="replyDrafts[item.id]"
                  :name="`reply-${item.id}`"
                  maxlength="2000"
                  :placeholder="copy.replyPlaceholder"
                  rows="3"
                />
                <button type="button" :data-testid="`submit-reply-${item.id}`" @click="reply(item)">
                  {{ copy.saveReply }}
                </button>
              </div>
              <span v-else class="muted">{{ item.merchantReply || copy.noReply }}</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="7" class="feedback">{{ copy.empty }}</td></tr>
        </tbody>
      </table>
    </div>
    <p v-if="!canView" class="muted">{{ copy.noReply }}</p>
  </section>
</template>
