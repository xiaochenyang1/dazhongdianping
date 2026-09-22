<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import { fetchAdCampaigns, auditAdCampaign } from '@/services/admin'
import type { AdCampaign } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const copy = computed(() => strings.value.adReview)
const canWrite = computed(() => state.permissions.includes('operations:ad:write'))

const filterAudit = ref<string>('')
const campaigns = ref<AdCampaign[]>([])
const rejectReasons = reactive<Record<number, string>>({})
const errorMessage = ref('')
const successMessage = ref('')

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function slotLabel(slotType: number) {
  return slotType === 2 ? copy.value.slotList : copy.value.slotSearch
}

function statusLabel(status: number) {
  if (status === 0) return copy.value.statusOffline
  if (status === 2) return copy.value.statusPaused
  return copy.value.statusServing
}

function auditLabel(auditStatus: number) {
  if (auditStatus === 2) return copy.value.auditApproved
  if (auditStatus === 3) return copy.value.auditRejected
  return copy.value.auditPending
}

async function load() {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const page = await fetchAdCampaigns({
      auditStatus: filterAudit.value ? Number(filterAudit.value) : undefined,
      page: 1,
      pageSize: 50,
    })
    campaigns.value = page.list
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

async function audit(campaign: AdCampaign, approved: boolean) {
  if (!canWrite.value) return
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await auditAdCampaign(campaign.id, {
      approved,
      rejectReason: approved ? undefined : (rejectReasons[campaign.id] ?? ''),
    })
    await load()
    successMessage.value = approved ? copy.value.approved : copy.value.rejected
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.auditError)
  }
}

watch(() => state.region, load, { immediate: true })
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
        <span>{{ copy.filterAudit }}</span>
        <select v-model="filterAudit" @change="load">
          <option value="">{{ copy.all }}</option>
          <option value="1">{{ copy.auditPending }}</option>
          <option value="2">{{ copy.auditApproved }}</option>
          <option value="3">{{ copy.auditRejected }}</option>
        </select>
      </label>
    </form>

    <p v-if="campaigns.length === 0" class="feedback">{{ copy.empty }}</p>
    <table v-else class="data-table">
      <thead>
        <tr>
          <th>{{ copy.colName }}</th>
          <th>{{ copy.colShop }}</th>
          <th>{{ copy.colSlot }}</th>
          <th>{{ copy.colKeyword }}</th>
          <th>{{ copy.colBid }}</th>
          <th>{{ copy.colBudget }}</th>
          <th>{{ copy.colSpent }}</th>
          <th>{{ copy.colStatus }}</th>
          <th>{{ copy.colAudit }}</th>
          <th>{{ copy.colActions }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="c in campaigns" :key="c.id" :data-id="c.id">
          <td>{{ c.name }}</td>
          <td>{{ c.shopName }}</td>
          <td>{{ slotLabel(c.slotType) }}</td>
          <td>{{ c.keyword || '—' }}</td>
          <td>{{ c.bidCpc }}</td>
          <td>{{ c.dailyBudget === 0 ? copy.unlimited : c.dailyBudget }}</td>
          <td>{{ c.totalSpent }}</td>
          <td>{{ statusLabel(c.status) }}</td>
          <td>{{ auditLabel(c.auditStatus) }}</td>
          <td>
            <template v-if="canWrite && c.auditStatus === 1">
              <input
                v-model="rejectReasons[c.id]"
                :placeholder="copy.rejectPlaceholder"
                type="text"
              />
              <button type="button" :data-testid="`approve-${c.id}`" @click="audit(c, true)">{{ copy.approve }}</button>
              <button type="button" :data-testid="`reject-${c.id}`" @click="audit(c, false)">{{ copy.reject }}</button>
            </template>
            <span v-else-if="c.auditStatus === 3">{{ c.rejectReason }}</span>
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
