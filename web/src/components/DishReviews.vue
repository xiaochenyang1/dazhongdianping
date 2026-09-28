<script setup lang="ts">
import { ref, watch } from 'vue'
import { createDishReview, fetchDishReviews, type DishReview } from '@/services/contentTrust'

const props = defineProps<{ shopId: number; dishId: number; dishName: string }>()
const reviews = ref<DishReview[]>([])
const score = ref(5)
const content = ref('')
const errorMessage = ref('')
const page = ref(1)
const pageSize = 20
const hasMore = ref(false)

async function load(reset = true) {
  errorMessage.value = ''
  try {
    if (reset) {
      page.value = 1
    }
    const result = await fetchDishReviews(props.shopId, props.dishId, page.value, pageSize)
    reviews.value = reset ? result.list : [...reviews.value, ...result.list]
    hasMore.value = result.hasMore
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : ''
  }
}

async function loadMore() {
  page.value += 1
  await load(false)
}

async function submit() {
  errorMessage.value = ''
  try {
    await createDishReview(props.shopId, props.dishId, { score: score.value, content: content.value.trim() })
    content.value = ''
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : ''
  }
}

watch(() => [props.shopId, props.dishId], () => load(), { immediate: true })
</script>

<template>
  <div class="dish-reviews" :data-testid="`dish-reviews-${dishId}`">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <ul>
      <li v-for="review in reviews" :key="review.id">{{ review.score }} · {{ review.content }}</li>
    </ul>
    <button v-if="hasMore" class="secondary-button" type="button" @click="loadMore">More</button>
    <form @submit.prevent="submit">
      <label class="field">
        <span>{{ dishName }}</span>
        <input v-model.number="score" type="number" min="1" max="5" required />
      </label>
      <label class="field">
        <textarea v-model="content" required maxlength="500" rows="2" />
      </label>
      <button class="secondary-button" type="submit">OK</button>
    </form>
  </div>
</template>
