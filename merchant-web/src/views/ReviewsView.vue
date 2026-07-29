<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { merchantStringsForRegion } from '@/core/merchant_localizations'
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

const { state } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
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
    error.value = cause instanceof Error ? cause.message : strings.value.reviews.loadError
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
    error.value = strings.value.reviews.replyRequired
    return
  }
  error.value = ''
  try {
    await saveReply(item.id, content)
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : strings.value.reviews.replyError
  }
}

async function appeal(item: MerchantReview) {
  if (!canSubmitAppeal.value) return
  const reason = (appealReasons.value[item.id] ?? '').trim()
  if (reason.length < 10) {
    error.value = strings.value.reviews.appealMinLength
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
    error.value = cause instanceof Error ? cause.message : strings.value.reviews.appealError
  }
}

onMounted(load)
</script>

<template>
  <section>
    <div class="toolbar">
      <span class="muted">{{ strings.reviews.summary }}</span>
      <button type="button" @click="load">{{ strings.common.refresh }}</button>
    </div>
    <p v-if="error" class="error" role="alert">{{ error }}</p>
    <p v-if="loading" class="muted">{{ strings.common.loading }}</p>
    <div v-else class="card table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>{{ strings.reviews.headers.user }}</th>
            <th>{{ strings.reviews.headers.score }}</th>
            <th>{{ strings.reviews.headers.content }}</th>
            <th>{{ strings.reviews.headers.reply }}</th>
            <th>{{ strings.reviews.headers.appeal }}</th>
          </tr>
        </thead>
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
                  :placeholder="strings.reviews.replyPlaceholder"
                  rows="3"
                />
                <button type="button" @click="reply(item)">{{ strings.reviews.saveReply }}</button>
              </div>
              <span v-else class="muted">{{ item.merchantReply?.content ?? strings.reviews.noReply }}</span>
            </td>
            <td>
              <div v-if="canSubmitAppeal && canAppeal(item)" :data-testid="`appeal-actions-${item.id}`">
                <textarea
                  v-model="appealReasons[item.id]"
                  :name="`appeal-reason-${item.id}`"
                  maxlength="500"
                  :placeholder="strings.reviews.appealPlaceholder"
                  rows="3"
                />
                <button type="button" :data-testid="`submit-appeal-${item.id}`" @click="appeal(item)">
                  {{ strings.reviews.submitAppeal }}
                </button>
              </div>
              <span v-else-if="item.appeal" class="status-pill status-0">
                {{ strings.reviews.appealStatusText(item.appeal.status, item.appeal.statusText) }}
              </span>
              <span v-else class="muted">{{ strings.reviews.noAppeal }}</span>
            </td>
          </tr>
          <tr v-if="items.length === 0"><td colspan="5" class="feedback">{{ strings.reviews.empty }}</td></tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
