<script setup lang="ts">
import { ref, watch } from 'vue'
import { createDishReview, fetchDishReviews, type DishReview } from '@/services/contentTrust'

const props = defineProps<{ shopId: number; dishId: number; dishName: string }>()
const reviews = ref<DishReview[]>([])
const score = ref(5)
const content = ref('')
const errorMessage = ref('')

async function load() {
  errorMessage.value = ''
  try {
    reviews.value = await fetchDishReviews(props.shopId, props.dishId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : ''
  }
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

watch(() => [props.shopId, props.dishId], load, { immediate: true })
</script>

<template>
  <div class="dish-reviews" :data-testid="`dish-reviews-${dishId}`">
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <ul>
      <li v-for="review in reviews" :key="review.id">{{ review.score }} · {{ review.content }}</li>
    </ul>
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
