<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { fetchLevelPrivileges, type LevelPrivileges } from '@/services/contentTrust'

const { state } = useAppContext()
const copy = computed(() => state.region === 'EU'
  ? { eyebrow: 'Level', title: 'Level privileges', loading: 'Loading...', failed: 'Could not load privileges' }
  : { eyebrow: '等级', title: '等级权益', loading: '加载中...', failed: '权益加载失败' })
const data = ref<LevelPrivileges | null>(null)
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  data.value = null
  try {
    data.value = await fetchLevelPrivileges()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.failed
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section>
    <header>
      <p class="eyebrow">{{ copy.eyebrow }}</p>
      <h1>{{ copy.title }}</h1>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-else-if="!data" class="feedback">{{ copy.loading }}</p>
    <div v-else data-testid="level-privileges">
      <h2>{{ data.levelName }} · Lv.{{ data.level }}</h2>
      <p>{{ data.growthValue }}</p>
      <pre>{{ JSON.stringify(data.privileges, null, 2) }}</pre>
    </div>
  </section>
</template>
