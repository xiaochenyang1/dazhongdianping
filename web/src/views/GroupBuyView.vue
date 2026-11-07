<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { campaignStringsForRegion, localizeWebCampaignError } from '@/core/web_campaign_localizations'
import { formatMoney } from '@/lib/currency'
import { fetchGroupBuy, joinGroupTeam, openGroupTeam } from '@/services/campaign'
import type { GroupBuyCampaign } from '@/types/campaign'

const { state } = useAppContext()
const { state: session, openAuthDialog } = useUserSession()
const router = useRouter()
const route = useRoute()
const copy = computed(() => campaignStringsForRegion(state.region))
const campaigns = ref<GroupBuyCampaign[]>([])
const loading = ref(false)
const actingId = ref<number | null>(null)
const joining = ref(false)
const errorMessage = ref('')
const teamId = ref('')
let scopeVersion = 0
let loadVersion = 0

async function load() {
  const request = ++loadVersion
  loading.value = true
  errorMessage.value = ''
  try {
    const result = await fetchGroupBuy()
    if (request === loadVersion) campaigns.value = result
  } catch (error) {
    if (request === loadVersion) errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.loadFailed)
  } finally {
    if (request === loadVersion) loading.value = false
  }
}

async function openTeam(campaign: GroupBuyCampaign) {
  if (actingId.value !== null || joining.value) return
  if (!session.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: '/marketing/groupbuy' })
    return
  }
  const scope = scopeVersion
  actingId.value = campaign.id
  errorMessage.value = ''
  try {
    const team = await openGroupTeam(campaign.id)
    if (scope === scopeVersion) await router.push(`/user/orders/${team.orderId}`)
  } catch (error) {
    if (scope === scopeVersion) errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.openFailed)
  } finally {
    if (scope === scopeVersion) actingId.value = null
  }
}

async function join() {
  if (actingId.value !== null || joining.value) return
  if (!session.accessToken) {
    openAuthDialog({ mode: 'password', redirectTo: '/marketing/groupbuy' })
    return
  }
  const scope = scopeVersion
  joining.value = true
  errorMessage.value = ''
  try {
    const team = await joinGroupTeam(Number(teamId.value))
    if (scope === scopeVersion) await router.push(`/user/orders/${team.orderId}`)
  } catch (error) {
    if (scope === scopeVersion) errorMessage.value = localizeWebCampaignError(copy.value, error, copy.value.joinFailed)
  } finally {
    if (scope === scopeVersion) joining.value = false
  }
}

watch([() => state.region, () => session.accessToken, () => session.currentUser?.id], () => {
  scopeVersion++
  actingId.value = null
  joining.value = false
  campaigns.value = []
  void load()
}, { immediate: true })
watch(() => route.query.teamId, (value) => {
  const parsed = Number(Array.isArray(value) ? value[0] : value)
  if (Number.isInteger(parsed) && parsed > 0) teamId.value = String(parsed)
}, { immediate: true })
onBeforeUnmount(() => { scopeVersion++; loadVersion++ })
</script>

<template>
  <section class="page-section">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ copy.groupEyebrow }}</p>
        <h1>{{ copy.groupTitle }}</h1>
        <p>{{ copy.groupRules }}</p>
      </div>
    </header>
    <p v-if="errorMessage" class="feedback is-error" role="alert">{{ errorMessage }}</p>
    <button v-if="errorMessage" type="button" class="secondary-button" :disabled="loading" @click="load">{{ copy.retry }}</button>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="campaigns.length === 0 && !errorMessage" class="feedback">{{ copy.empty }}</p>
    <div v-else class="rank-list">
      <article v-for="campaign in campaigns" :key="campaign.id" class="content-card" :data-testid="`group-${campaign.id}`">
        <h2>{{ campaign.title }}</h2>
        <p><strong>{{ formatMoney(campaign.groupPrice, campaign.currency) }}</strong> · {{ copy.size }} {{ campaign.groupSize }}</p>
        <div class="hero-actions">
          <RouterLink class="secondary-button" :to="`/deals/${campaign.dealId}`">{{ copy.offerDetails }}</RouterLink>
          <button type="button" class="primary-button" :disabled="actingId !== null || joining" :data-testid="`group-open-${campaign.id}`" @click="openTeam(campaign)">
            {{ actingId === campaign.id ? copy.opening : copy.open }}
          </button>
        </div>
      </article>
    </div>
    <form class="content-card" @submit.prevent="join">
      <label class="field">
        <span>{{ copy.teamId }}</span>
        <input v-model="teamId" type="number" min="1" required data-testid="group-team-id" />
      </label>
      <button class="secondary-button" type="submit" :disabled="actingId !== null || joining" data-testid="group-join">
        {{ joining ? copy.joining : copy.join }}
      </button>
    </form>
  </section>
</template>
