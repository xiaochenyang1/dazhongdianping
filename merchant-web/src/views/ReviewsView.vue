<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  createAppealDraft,
  fetchReviews,
  saveAppeal,
  saveReply,
  submitAppeal,
  type MerchantReview,
} from '@/services/merchant'

const props = withDefaults(defineProps<{ permissions?: string[] }>(), {
  permissions: () => [],
})

const loading = ref(true)
const error = ref('')
const items = ref<MerchantReview[]>([])
const replyDrafts = ref<Record<number, string>>({})
const appealReasons = ref<Record<number, string>>({})
const canReply = computed(() => props.permissions.includes('review:reply'))
const canSubmitAppeal = computed(() => props.permissions.includes('review:appeal'))

async function load() {
  loading.value = true
  error.value = ''
  try {
    items.value = (await fetchReviews({ page: 1, pageSize: 50 })).list
    replyDrafts.value = Object.fromEntries(
      items.value.map((item) => [item.id, item.merchantReply?.content ?? '']),
    )
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '点评加载失败'
  } finally {
    loading.value = false
  }
}

function canAppeal(item: MerchantReview) {
  return item.appeal == null || item.appeal.status === 0 || item.appeal.status === 3
}

async function reply(item: MerchantReview) {
  if (!canReply.value) return
  const content = (replyDrafts.value[item.id] ?? '').trim()
  if (!content) {
    error.value = '商家回复不能为空'
    return
  }
  error.value = ''
  try {
    await saveReply(item.id, content)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '回复失败'
  }
}

async function appeal(item: MerchantReview) {
  if (!canSubmitAppeal.value) return
  const reason = (appealReasons.value[item.id] ?? '').trim()
  if (reason.length < 10) {
    error.value = '申诉理由至少 10 个字。'
    return
  }
  error.value = ''
  try {
    const draft = await createAppealDraft(item.id)
    if (typeof draft.id === 'number') {
      await saveAppeal(draft.id, { reason, evidenceUrls: [] })
      await submitAppeal(draft.id)
    }
    delete appealReasons.value[item.id]
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '申诉失败'
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">回复可持续维护；申诉提交审核后转为只读状态。</span>
      <button type="button" @click="load">刷新</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">加载中...</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead><tr><th>用户</th><th>评分</th><th>内容</th><th>商家回复</th><th>点评申诉</th></tr></thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td>{{ item.userName }}</td>
            <td>{{ item.scoreOverall }}</td>
            <td>{{ item.content }}</td>
            <td>
              <div v-if="canReply" :data-testid="`reply-actions-${item.id}`">
                <textarea
                  v-model="replyDrafts[item.id]"
                  :name="`reply-${item.id}`"
                  maxlength="500"
                  placeholder="输入公开回复"
                  rows="3"
                />
                <button type="button" @click="reply(item)">保存回复</button>
              </div>
              <span v-else class="muted">{{ item.merchantReply?.content ?? '暂无回复' }}</span>
            </td>
            <td>
              <div v-if="canSubmitAppeal && canAppeal(item)" :data-testid="`appeal-actions-${item.id}`">
                <textarea
                  v-model="appealReasons[item.id]"
                  :name="`appeal-reason-${item.id}`"
                  maxlength="500"
                  placeholder="至少 10 个字，说明恶意或失实点"
                  rows="3"
                />
                <button type="button" :data-testid="`submit-appeal-${item.id}`" @click="appeal(item)">提交申诉</button>
              </div>
              <span v-else-if="item.appeal" class="status-pill status-0">{{ item.appeal.statusText }}</span>
              <span v-else class="muted">暂无申诉</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="5" class="feedback">当前筛选下没有点评。</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
