<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { campaignStringsForRegion } from '@/core/web_campaign_localizations'
import { fetchGroupBuy, joinGroupTeam, openGroupTeam } from '@/services/campaign'
import type { GroupBuyCampaign } from '@/types/campaign'

const { state } = useAppContext()
const copy = computed(() => campaignStringsForRegion(state.region))
const campaigns = ref<GroupBuyCampaign[]>([])
const loading = ref(false)
const errorMessage = ref('')
const teamId = ref('')
const opened = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    campaigns.value = await fetchGroupBuy()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  } finally {
    loading.value = false
  }
}

async function openTeam(campaign: GroupBuyCampaign) {
  errorMessage.value = ''
  try {
    const team = await openGroupTeam(campaign.id)
    opened.value = String(team.id)
    teamId.value = String(team.id)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

async function join() {
  errorMessage.value = ''
  try {
    const team = await joinGroupTeam(Number(teamId.value))
    opened.value = `${team.id} · ${team.memberCount} · ${team.status}`
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section>
    <header>
      <p class="eyebrow">{{ copy.groupEyebrow }}</p>
      <h1>{{ copy.groupTitle }}</h1>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="opened" class="feedback">{{ copy.teamId }} {{ opened }}</p>
    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-else-if="campaigns.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else>
      <li v-for="campaign in campaigns" :key="campaign.id" :data-testid="`group-${campaign.id}`">
        <h2>{{ campaign.title }}</h2>
        <p>{{ campaign.groupPrice }} {{ campaign.currency }} · {{ copy.size }} {{ campaign.groupSize }}</p>
        <button type="button" class="primary-button" @click="openTeam(campaign)">{{ copy.open }}</button>
      </li>
    </ul>
    <form @submit.prevent="join">
      <label class="field">
        <span>{{ copy.teamId }}</span>
        <input v-model="teamId" type="number" min="1" required data-testid="group-team-id" />
      </label>
      <button class="secondary-button" type="submit">{{ copy.join }}</button>
    </form>
  </section>
</template>
