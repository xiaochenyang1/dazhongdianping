<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { exchangePointsProduct, fetchPointsProduct } from '@/services/points'
import { fetchCurrentUser } from '@/services/auth'
import type { PointsProduct } from '@/types/points'

const props = defineProps<{ productId: number }>()
const router = useRouter()
const { state, setCurrentUser } = useUserSession()
const { state: appState } = useAppContext()
const strings = computed(() => userStringsForRegion(appState.region))
const copy = computed(() => strings.value.pointsMall)

const product = ref<PointsProduct | null>(null)
const loading = ref(false)
const exchanging = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const balance = computed(() => state.currentUser?.points ?? 0)
const canExchange = computed(() => {
  if (!product.value || exchanging.value) return false
  if (product.value.soldOut) return false
  if (balance.value < product.value.pointsPrice) return false
  return true
})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    product.value = await fetchPointsProduct(props.productId)
  } catch (error) {
    errorMessage.value = localizeWebUserError(strings.value, error, copy.value.loadFailed)
  } finally {
    loading.value = false
  }
}

async function exchange() {
  if (!canExchange.value || !product.value) return
  exchanging.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await exchangePointsProduct(product.value.id)
    const updated = await fetchCurrentUser()
    setCurrentUser(updated)
    successMessage.value = copy.value.exchangeSuccess(product.value.name)
    setTimeout(() => {
      router.push({ name: 'user-points-mall', query: { tab: 'exchanges', exchanged: '1' } })
    }, 1500)
  } catch (error) {
    errorMessage.value = localizeWebUserError(strings.value, error, copy.value.exchangeFailed)
  } finally {
    exchanging.value = false
  }
}

watch(() => props.productId, () => void load(), { immediate: true })
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.productDetail }}</h1>
      </div>
    </div>

    <p v-if="loading" class="feedback">{{ copy.loading }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div v-if="product && !loading" class="product-detail">
      <div class="product-media">
        <img :src="product.coverImage" :alt="product.name" class="product-cover" />
      </div>

      <div class="product-info">
        <h2 class="product-name">{{ product.name }}</h2>
        <div class="product-price">
          <span class="price-value">{{ product.pointsPrice }}</span>
          <span class="price-unit">{{ copy.pointsUnit }}</span>
        </div>

        <div v-if="product.soldOut" class="product-badge product-badge--soldout">
          {{ copy.soldOut }}
        </div>
        <div v-else-if="balance < product.pointsPrice" class="product-badge product-badge--warn">
          {{ copy.insufficientBalance }}
        </div>

        <dl class="product-meta">
          <div class="meta-row">
            <dt>{{ copy.stockLabel }}</dt>
            <dd>{{ product.stock > 9999 ? copy.abundant : product.stock }}</dd>
          </div>
          <div class="meta-row">
            <dt>{{ copy.exchangeLimitLabel }}</dt>
            <dd>{{ product.exchangeLimitPerUser <= 0 ? copy.unlimited : product.exchangeLimitPerUser }}</dd>
          </div>
          <div class="meta-row">
            <dt>{{ copy.fulfillTypeLabel }}</dt>
            <dd>{{ product.fulfillTypeText }}</dd>
          </div>
          <div class="meta-row">
            <dt>{{ copy.exchangeCount }}</dt>
            <dd>{{ product.exchangeCount }}</dd>
          </div>
        </dl>

        <div class="product-description">
          <h3>{{ copy.productDescription }}</h3>
          <p>{{ product.description }}</p>
        </div>

        <div class="product-actions">
          <button
            class="btn btn--primary"
            :disabled="!canExchange"
            @click="exchange"
          >
            {{ exchanging ? copy.exchanging : copy.exchangeNow }}
          </button>
          <RouterLink :to="{ name: 'user-points-mall' }" class="btn btn--secondary">
            {{ copy.backToMall }}
          </RouterLink>
        </div>

        <div class="current-balance">
          <span class="balance-label">{{ copy.yourBalance }}</span>
          <span class="balance-value">{{ balance }} {{ copy.pointsUnit }}</span>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.product-detail {
  display: flex;
  gap: 2rem;
  margin-top: 2rem;
}

.product-media {
  flex: 0 0 400px;
}

.product-cover {
  width: 100%;
  border-radius: 8px;
  display: block;
}

.product-info {
  flex: 1;
}

.product-name {
  font-size: 1.75rem;
  margin: 0 0 1rem;
}

.product-price {
  font-size: 2rem;
  font-weight: 600;
  color: #f87171;
  margin-bottom: 1rem;
}

.price-unit {
  font-size: 1rem;
  margin-left: 0.25rem;
}

.product-badge {
  display: inline-block;
  padding: 0.375rem 0.75rem;
  border-radius: 4px;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 1.5rem;
}

.product-badge--soldout {
  background: #f3f4f6;
  color: #6b7280;
}

.product-badge--warn {
  background: #fef3c7;
  color: #92400e;
}

.product-meta {
  margin: 0 0 2rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 6px;
}

.meta-row {
  display: flex;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.meta-row:last-child {
  border-bottom: none;
}

.meta-row dt {
  flex: 0 0 120px;
  font-weight: 500;
  color: #6b7280;
}

.meta-row dd {
  margin: 0;
  color: #111827;
}

.product-description {
  margin-bottom: 2rem;
}

.product-description h3 {
  font-size: 1.125rem;
  margin: 0 0 0.75rem;
}

.product-description p {
  color: #4b5563;
  line-height: 1.6;
  margin: 0;
}

.product-actions {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.current-balance {
  padding: 1rem;
  background: #f0fdf4;
  border-radius: 6px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.balance-label {
  color: #166534;
  font-weight: 500;
}

.balance-value {
  color: #15803d;
  font-size: 1.25rem;
  font-weight: 600;
}

@media (max-width: 768px) {
  .product-detail {
    flex-direction: column;
  }

  .product-media {
    flex: none;
  }

  .product-actions {
    flex-direction: column;
  }
}
</style>
