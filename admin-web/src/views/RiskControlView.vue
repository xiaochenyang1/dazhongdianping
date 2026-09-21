<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  fetchRiskEvents,
  disposeRiskEvent,
  fetchRiskRules,
  updateRiskRule,
} from '@/services/admin'
import type { RiskEvent, RiskRule } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const copy = computed(() => strings.value.riskControl)
const canWrite = computed(() => state.permissions.includes('risk:event:write'))

const tab = ref<'events' | 'rules'>('events')
const errorMessage = ref('')
const successMessage = ref('')

const filters = reactive<{ scene: string; decision: string; disposeStatus: string }>({
  scene: '',
  decision: '',
  disposeStatus: '',
})
const events = ref<RiskEvent[]>([])
const total = ref(0)
const disposeRemarks = reactive<Record<number, string>>({})

const rules = ref<RiskRule[]>([])

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function sceneLabel(scene: string) {
  if (scene === 'review_create') return copy.value.sceneReviewCreate
  if (scene === 'trade_order') return copy.value.sceneTradeOrder
  if (scene === 'auth_register') return copy.value.sceneAuthRegister
  return scene
}

function decisionLabel(decision: number) {
  if (decision === 3) return copy.value.decisionBlock
  if (decision === 2) return copy.value.decisionReview
  return copy.value.decisionPass
}

function disposeLabel(status: number) {
  if (status === 1) return copy.value.disposeConfirmed
  if (status === 2) return copy.value.disposeIgnored
  return copy.value.disposePending
}

async function loadEvents() {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const page = await fetchRiskEvents({
      scene: filters.scene || undefined,
      decision: filters.decision ? Number(filters.decision) : undefined,
      disposeStatus: filters.disposeStatus ? Number(filters.disposeStatus) : undefined,
      page: 1,
      pageSize: 50,
    })
    events.value = page.list
    total.value = page.total
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

async function loadRules() {
  errorMessage.value = ''
  try {
    rules.value = await fetchRiskRules()
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.loadError)
  }
}

async function dispose(event: RiskEvent, disposeStatus: number) {
  if (!canWrite.value) return
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await disposeRiskEvent(event.id, { disposeStatus, disposeRemark: disposeRemarks[event.id] ?? '' })
    successMessage.value = copy.value.eventDisposed
    await loadEvents()
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.saveError)
  }
}

async function saveRule(rule: RiskRule) {
  if (!canWrite.value) return
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await updateRiskRule(rule.id, {
      action: rule.action,
      threshold: rule.threshold,
      windowSeconds: rule.windowSeconds,
      riskScore: rule.riskScore,
      enabled: rule.enabled,
      remark: rule.remark,
    })
    successMessage.value = copy.value.ruleSaved
    await loadRules()
  } catch (cause) {
    errorMessage.value = messageOf(cause, copy.value.saveError)
  }
}

function switchTab(next: 'events' | 'rules') {
  tab.value = next
  if (next === 'events') loadEvents()
  else loadRules()
}

watch(() => state.region, () => {
  if (tab.value === 'events') loadEvents()
  else loadRules()
}, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>{{ copy.title }}</h1>
      <p class="page-desc">{{ copy.description }}</p>
    </header>

    <nav class="tabs">
      <button type="button" :class="{ active: tab === 'events' }" @click="switchTab('events')">{{ copy.tabEvents }}</button>
      <button type="button" :class="{ active: tab === 'rules' }" @click="switchTab('rules')">{{ copy.tabRules }}</button>
    </nav>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>
    <p v-if="!canWrite" class="feedback">{{ copy.readOnly }}</p>

    <div v-if="tab === 'events'">
      <form class="filters" @submit.prevent="loadEvents">
        <label>
          <span>{{ copy.filterScene }}</span>
          <select v-model="filters.scene">
            <option value="">{{ copy.all }}</option>
            <option value="review_create">{{ copy.sceneReviewCreate }}</option>
            <option value="trade_order">{{ copy.sceneTradeOrder }}</option>
            <option value="auth_register">{{ copy.sceneAuthRegister }}</option>
          </select>
        </label>
        <label>
          <span>{{ copy.filterDecision }}</span>
          <select v-model="filters.decision">
            <option value="">{{ copy.all }}</option>
            <option value="1">{{ copy.decisionPass }}</option>
            <option value="2">{{ copy.decisionReview }}</option>
            <option value="3">{{ copy.decisionBlock }}</option>
          </select>
        </label>
        <label>
          <span>{{ copy.filterDispose }}</span>
          <select v-model="filters.disposeStatus">
            <option value="">{{ copy.all }}</option>
            <option value="0">{{ copy.disposePending }}</option>
            <option value="1">{{ copy.disposeConfirmed }}</option>
            <option value="2">{{ copy.disposeIgnored }}</option>
          </select>
        </label>
        <button type="submit">{{ copy.filterScene }}</button>
      </form>

      <p v-if="events.length === 0" class="feedback">{{ copy.empty }}</p>
      <table v-else class="data-table">
        <thead>
          <tr>
            <th>{{ copy.colTime }}</th>
            <th>{{ copy.colScene }}</th>
            <th>{{ copy.colUser }}</th>
            <th>{{ copy.colDevice }}</th>
            <th>{{ copy.colScore }}</th>
            <th>{{ copy.colDecision }}</th>
            <th>{{ copy.colHitRules }}</th>
            <th>{{ copy.colReason }}</th>
            <th>{{ copy.colStatus }}</th>
            <th>{{ copy.colActions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="event in events" :key="event.id">
            <td>{{ event.createdAt }}</td>
            <td>{{ sceneLabel(event.scene) }}</td>
            <td>{{ event.userId ?? '-' }}</td>
            <td class="mono">{{ event.deviceFingerprint ?? '-' }}</td>
            <td>{{ event.riskScore }}</td>
            <td>{{ decisionLabel(event.decision) }}</td>
            <td class="mono">{{ event.hitRules }}</td>
            <td>{{ event.reason }}</td>
            <td>{{ disposeLabel(event.disposeStatus) }}</td>
            <td>
              <template v-if="canWrite && event.disposeStatus === 0">
                <input
                  v-model="disposeRemarks[event.id]"
                  :placeholder="copy.disposeRemarkPlaceholder"
                  type="text"
                />
                <button type="button" @click="dispose(event, 1)">{{ copy.confirmRisk }}</button>
                <button type="button" @click="dispose(event, 2)">{{ copy.ignoreEvent }}</button>
              </template>
              <span v-else>{{ event.disposeRemark }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else>
      <p v-if="rules.length === 0" class="feedback">{{ copy.empty }}</p>
      <table v-else class="data-table">
        <thead>
          <tr>
            <th>{{ copy.ruleName }}</th>
            <th>{{ copy.ruleCode }}</th>
            <th>{{ copy.colScene }}</th>
            <th>{{ copy.ruleAction }}</th>
            <th>{{ copy.ruleThreshold }}</th>
            <th>{{ copy.ruleWindow }}</th>
            <th>{{ copy.ruleScore }}</th>
            <th>{{ copy.ruleEnabled }}</th>
            <th>{{ copy.ruleRemark }}</th>
            <th>{{ copy.colActions }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="rule in rules" :key="rule.id">
            <td>{{ rule.name }}</td>
            <td class="mono">{{ rule.ruleCode }}</td>
            <td>{{ sceneLabel(rule.scene) }}</td>
            <td>
              <select v-model.number="rule.action" :disabled="!canWrite">
                <option :value="1">{{ copy.decisionPass }}</option>
                <option :value="2">{{ copy.decisionReview }}</option>
                <option :value="3">{{ copy.decisionBlock }}</option>
              </select>
            </td>
            <td><input v-model.number="rule.threshold" type="number" min="0" :disabled="!canWrite" /></td>
            <td><input v-model.number="rule.windowSeconds" type="number" min="0" :disabled="!canWrite" /></td>
            <td><input v-model.number="rule.riskScore" type="number" min="0" max="1000" :disabled="!canWrite" /></td>
            <td><input v-model="rule.enabled" type="checkbox" :disabled="!canWrite" /></td>
            <td><input v-model="rule.remark" type="text" :disabled="!canWrite" /></td>
            <td><button type="button" :disabled="!canWrite" @click="saveRule(rule)">{{ copy.saveRule }}</button></td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
