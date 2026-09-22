<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { fetchComplaints, fetchComplaint, disposeComplaint } from '@/services/admin'
import type { ComplaintTicket } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const copy = computed(() => strings.value.complaintArbitration)
const canWrite = computed(() => state.permissions.includes('audit:complaint:write'))

const filterStatus = ref<string>('')
const tickets = ref<ComplaintTicket[]>([])
const selected = ref<ComplaintTicket | null>(null)
const errorMessage = ref('')
const successMessage = ref('')
const submitting = ref(false)

const disposeForm = reactive<{ resolved: boolean; resolution: string }>({
  resolved: true,
  resolution: '',
})

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function typeLabel(type: number) {
  switch (type) {
    case 2: return copy.value.typeFalseAd
    case 3: return copy.value.typeRefund
    case 4: return copy.value.typeService
    case 5: return copy.value.typeOther
    default: return copy.value.typeQuality
  }
}

function statusLabel(status: number) {
  switch (status) {
    case 2: return copy.value.statusProcessing
    case 3: return copy.value.statusResolved
    case 4: return copy.value.statusRejected
    default: return copy.value.statusPending
  }
}

async function load() {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const page = await fetchComplaints({
      status: filterStatus.value ? Number(filterStatus.value) : undefined,
      page: 1,
      pageSize: 50,
    })
    tickets.value = page.list
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

async function openDetail(ticket: ComplaintTicket) {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    selected.value = await fetchComplaint(ticket.id)
    disposeForm.resolved = true
    disposeForm.resolution = ''
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

function closeDetail() {
  selected.value = null
}

const canDispose = computed(
  () => canWrite.value && selected.value != null
    && (selected.value.status === 1 || selected.value.status === 2),
)

async function submitDispose() {
  if (!canDispose.value || !selected.value) return
  errorMessage.value = ''
  successMessage.value = ''
  submitting.value = true
  try {
    await disposeComplaint(selected.value.id, {
      resolved: disposeForm.resolved,
      resolution: disposeForm.resolution,
    })
    selected.value = null
    await load()
    successMessage.value = copy.value.disposed
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.disposeError)
  } finally {
    submitting.value = false
  }
}

watch(() => state.region, () => { selected.value = null; load() }, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>{{ copy.title }}</h1>
      <p class="page-desc">{{ copy.description }}</p>
    </header>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="!canWrite" class="feedback">{{ copy.readOnly }}</p>

    <form class="filters" @submit.prevent="load">
      <label>
        <span>{{ copy.filterStatus }}</span>
        <select v-model="filterStatus" @change="load">
          <option value="">{{ copy.all }}</option>
          <option value="1">{{ copy.statusPending }}</option>
          <option value="2">{{ copy.statusProcessing }}</option>
          <option value="3">{{ copy.statusResolved }}</option>
          <option value="4">{{ copy.statusRejected }}</option>
        </select>
      </label>
    </form>

    <p v-if="tickets.length === 0" class="feedback">{{ copy.empty }}</p>
    <table v-else class="data-table">
      <thead>
        <tr>
          <th>{{ copy.colTicketNo }}</th>
          <th>{{ copy.colShop }}</th>
          <th>{{ copy.colType }}</th>
          <th>{{ copy.colUser }}</th>
          <th>{{ copy.colStatus }}</th>
          <th>{{ copy.colCreatedAt }}</th>
          <th>{{ copy.colActions }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="t in tickets" :key="t.id" :data-id="t.id">
          <td class="mono">{{ t.ticketNo }}</td>
          <td>{{ t.shopName }}</td>
          <td>{{ typeLabel(t.type) }}</td>
          <td>{{ t.userNickname }}</td>
          <td>{{ statusLabel(t.status) }}</td>
          <td>{{ t.createdAt }}</td>
          <td>
            <button type="button" class="link" @click="openDetail(t)">{{ copy.view }}</button>
          </td>
        </tr>
      </tbody>
    </table>

    <aside v-if="selected" class="detail-panel">
      <header class="detail-head">
        <h2>{{ copy.detailTitle }} · {{ selected.ticketNo }}</h2>
        <button type="button" class="link" @click="closeDetail">{{ copy.close }}</button>
      </header>
      <p><strong>{{ selected.title }}</strong> · {{ typeLabel(selected.type) }} · {{ statusLabel(selected.status) }}</p>
      <section>
        <h3>{{ copy.fieldContent }}</h3>
        <p>{{ selected.content }}</p>
      </section>
      <section>
        <h3>{{ copy.fieldMerchantReply }}</h3>
        <p>{{ selected.merchantReply || copy.noReply }}</p>
      </section>
      <section v-if="selected.resolution">
        <h3>{{ copy.fieldResolution }}</h3>
        <p>{{ selected.resolution }}</p>
      </section>
      <section v-if="selected.logs && selected.logs.length">
        <h3>{{ copy.fieldLogs }}</h3>
        <ul class="log-list">
          <li v-for="log in selected.logs" :key="log.id">
            <span class="mono">{{ log.createdAt }}</span> · {{ log.actorTypeText }} · {{ log.actionText }}
            <template v-if="log.remark"> — {{ log.remark }}</template>
          </li>
        </ul>
      </section>

      <form v-if="canDispose" class="dispose-form" @submit.prevent="submitDispose">
        <label class="radio">
          <input v-model="disposeForm.resolved" type="radio" :value="true" />
          <span>{{ copy.disposeResolve }}</span>
        </label>
        <label class="radio">
          <input v-model="disposeForm.resolved" type="radio" :value="false" />
          <span>{{ copy.disposeReject }}</span>
        </label>
        <textarea
          v-model="disposeForm.resolution"
          :placeholder="copy.resolutionPlaceholder"
          required
          rows="3"
        ></textarea>
        <button type="submit" :disabled="submitting">{{ copy.dispose }}</button>
      </form>
    </aside>
  </section>
</template>
