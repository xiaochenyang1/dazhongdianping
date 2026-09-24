<script setup lang="ts">
import { ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { fetchAutomodHits, type OpsAutomodHit } from '@/services/ops'

const { state } = useAdminSession()
const hits = ref<OpsAutomodHit[]>([])
const decision = ref<number | ''>('')
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  try {
    const page = await fetchAutomodHits({
      decision: decision.value === '' ? undefined : Number(decision.value),
      page: 1,
      pageSize: 20,
    })
    hits.value = page.list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '加载失败'
  }
}

watch(() => state.region, load, { immediate: true })
</script>

<template>
  <section class="page">
    <header class="page-header">
      <h1>机审命中</h1>
      <p class="page-desc">关键词命中并拦截的内容会记在这里。通过的内容不会落库。</p>
    </header>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <div class="toolbar">
      <select v-model="decision" @change="load">
        <option value="">全部</option>
        <option :value="3">拦截</option>
        <option :value="2">待复审</option>
        <option :value="1">通过</option>
      </select>
    </div>
    <table class="data-table">
      <thead>
        <tr><th>业务</th><th>用户</th><th>决定</th><th>原因</th><th>时间</th></tr>
      </thead>
      <tbody>
        <tr v-for="hit in hits" :key="hit.id">
          <td>{{ hit.bizType }} #{{ hit.bizId }}</td>
          <td>{{ hit.userId }}</td>
          <td>{{ hit.decision }}</td>
          <td>{{ hit.reason }}</td>
          <td>{{ hit.createdAt }}</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
