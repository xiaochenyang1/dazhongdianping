<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { formatWebDateTime } from '@/core/web_localizations'
import { localizeWebUserError, userStringsForRegion } from '@/core/web_user_localizations'
import { fetchCurrentUser } from '@/services/auth'
import {
  exchangePointsProduct,
  fetchMyPointsExchanges,
  fetchPointsProducts,
} from '@/services/points'
import type { PageResult } from '@/types/browse'
import type { AuthCurrentUser } from '@/types/auth'
import type { PointsExchange, PointsProduct } from '@/types/points'

type MallTab = 'products' | 'exchanges'

const { state, setCurrentUser } = useUserSession()
const { state: appState } = useAppContext()
const strings = computed(() => userStringsForRegion(appState.region))
const copy = computed(() => strings.value.pointsMall)
const locale = computed(() => strings.value.tag)

const tab = ref<MallTab>('products')
const profile = ref<AuthCurrentUser | null>(state.currentUser ?? null)
const productPage = ref<PageResult<PointsProduct> | null>(null)
const exchangePage = ref<PageResult<PointsExchange> | null>(null)
const productFilters = reactive({ page: 1, pageSize: 12 })
const exchangeFilters = reactive({ page: 1, pageSize: 10 })

const loadingProducts = ref(false)
const loadingExchanges = ref(false)
const exchangingId = ref<number | null>(null)
const productError = ref('')
const exchangeError = ref('')
const successMessage = ref('')

let productRequestId = 0
let exchangeRequestId = 0

const balance = computed(() => profile.value?.points ?? state.currentUser?.points ?? 0)
const level = computed(() => profile.value?.level ?? state.currentUser?.level ?? 1)

function statusClass(status: number) {
  if (status === 1) return 'status-pill status-pill--good'
  if (status === 2) return 'status-pill status-pill--muted'
  return 'status-pill status-pill--warn'
}

function canExchange(product: PointsProduct) {
  if (product.soldOut || product.stock <= 0) return false
  if (balance.value < product.pointsPrice) return false
  return true
}

function exchangeDisabledReason(product: PointsProduct) {
  if (product.soldOut || product.stock <= 0) return copy.value.soldOut
  if (balance.value < product.pointsPrice) return copy.value.insufficientPoints
  return ''
}

async function refreshProfile() {
  try {
    const next = await fetchCurrentUser()
    profile.value = next
    setCurrentUser(next)
  } catch {
    // Balance refresh is best-effort after a successful exchange.
  }
}

async function loadProducts() {
  const requestId = ++productRequestId
  loadingProducts.value = true
  productError.value = ''

  try {
    const page = await fetchPointsProducts({
      page: productFilters.page,
      pageSize: productFilters.pageSize,
    })
    if (requestId !== productRequestId) return
    productPage.value = page
  } catch (error) {
    if (requestId !== productRequestId) return
    productPage.value = null
    productError.value = localizeWebUserError(strings.value, error, copy.value.loadFailed)
  } finally {
    if (requestId === productRequestId) {
      loadingProducts.value = false
    }
  }
}

async function loadExchanges() {
  const requestId = ++exchangeRequestId
  loadingExchanges.value = true
  exchangeError.value = ''

  try {
    const page = await fetchMyPointsExchanges({
      page: exchangeFilters.page,
      pageSize: exchangeFilters.pageSize,
    })
    if (requestId !== exchangeRequestId) return
    exchangePage.value = page
  } catch (error) {
    if (requestId !== exchangeRequestId) return
    exchangePage.value = null
    exchangeError.value = localizeWebUserError(strings.value, error, copy.value.loadFailed)
  } finally {
    if (requestId === exchangeRequestId) {
      loadingExchanges.value = false
    }
  }
}

async function selectTab(next: MallTab) {
  tab.value = next
  successMessage.value = ''
  if (next === 'exchanges' && !exchangePage.value && !loadingExchanges.value) {
    await loadExchanges()
  }
}

async function submitExchange(product: PointsProduct) {
  if (exchangingId.value != null || !canExchange(product)) {
    return
  }

  const confirmed = window.confirm(copy.value.confirmExchange(product.name, product.pointsPrice))
  if (!confirmed) {
    return
  }

  exchangingId.value = product.id
  productError.value = ''
  successMessage.value = ''

  try {
    const exchange = await exchangePointsProduct(product.id)
    const code = exchange.redeemCode?.trim()
    successMessage.value = code
      ? copy.value.exchangeSuccessWithCode(code)
      : copy.value.exchangeSuccess(product.name)

    await Promise.all([loadProducts(), refreshProfile()])

    if (tab.value === 'exchanges' || exchangePage.value) {
      exchangeFilters.page = 1
      await loadExchanges()
    }
  } catch (error) {
    productError.value = localizeWebUserError(strings.value, error, copy.value.exchangeFailed)
  } finally {
    exchangingId.value = null
  }
}

function applyProductPageSize() {
  productFilters.page = 1
  void loadProducts()
}

function applyExchangePageSize() {
  exchangeFilters.page = 1
  void loadExchanges()
}

function goProductPrev() {
  if (!productPage.value || productPage.value.page <= 1) return
  productFilters.page -= 1
  void loadProducts()
}

function goProductNext() {
  if (!productPage.value?.hasMore) return
  productFilters.page += 1
  void loadProducts()
}

function goExchangePrev() {
  if (!exchangePage.value || exchangePage.value.page <= 1) return
  exchangeFilters.page -= 1
  void loadExchanges()
}

function goExchangeNext() {
  if (!exchangePage.value?.hasMore) return
  exchangeFilters.page += 1
  void loadExchanges()
}

watch(
  () => appState.region,
  () => {
    productFilters.page = 1
    exchangeFilters.page = 1
    productPage.value = null
    exchangePage.value = null
    successMessage.value = ''
    void refreshProfile()
    void loadProducts()
    if (tab.value === 'exchanges') {
      void loadExchanges()
    }
  },
  { immediate: true },
)
</script>

<template>
  <div class="page-stack">
    <section class="hero-panel hero-panel--compact">
      <div class="hero-panel__content">
        <p class="eyebrow">{{ copy.eyebrow }}</p>
        <h1>{{ copy.title }}</h1>
        <p class="hero-panel__summary">{{ copy.summary }}</p>
        <div class="hero-actions">
          <RouterLink to="/user/profile" class="ghost-button">{{ copy.backProfile }}</RouterLink>
          <RouterLink to="/user/check-in" class="secondary-button">{{ copy.checkIn }}</RouterLink>
          <RouterLink to="/user/growth-records" class="secondary-button">{{ copy.growthHistory }}</RouterLink>
        </div>
      </div>

      <div class="hero-panel__side">
        <div class="hero-metric" data-testid="points-balance">
          <span>{{ copy.balance }}</span>
          <strong>{{ balance }}</strong>
        </div>
        <div class="hero-metric">
          <span>{{ copy.level }}</span>
          <strong>Lv.{{ level }}</strong>
        </div>
      </div>
    </section>

    <section class="content-section">
      <div class="section-header">
        <div>
          <p class="eyebrow">{{ tab === 'products' ? copy.productsEyebrow : copy.exchangesEyebrow }}</p>
          <h2>{{ tab === 'products' ? copy.productsTitle : copy.exchangesTitle }}</h2>
        </div>
      </div>

      <div class="hero-actions" data-testid="points-mall-tabs">
        <button
          type="button"
          :class="tab === 'products' ? 'primary-button' : 'secondary-button'"
          data-testid="points-tab-products"
          @click="selectTab('products')"
        >
          {{ copy.tabProducts }}
        </button>
        <button
          type="button"
          :class="tab === 'exchanges' ? 'primary-button' : 'secondary-button'"
          data-testid="points-tab-exchanges"
          @click="selectTab('exchanges')"
        >
          {{ copy.tabExchanges }}
        </button>
      </div>

      <p v-if="successMessage" class="feedback is-success" data-testid="points-success">{{ successMessage }}</p>

      <template v-if="tab === 'products'">
        <div class="field-row field-row--two">
          <label class="field">
            <span>{{ copy.pageSize }}</span>
            <select v-model.number="productFilters.pageSize" @change="applyProductPageSize">
              <option :value="12">{{ copy.rows(12) }}</option>
              <option :value="24">{{ copy.rows(24) }}</option>
            </select>
          </label>
          <div class="hero-actions hero-actions--align-end">
            <button type="button" class="secondary-button" :disabled="loadingProducts" @click="loadProducts">
              {{ copy.refresh }}
            </button>
          </div>
        </div>

        <p v-if="productError" class="feedback is-error" data-testid="points-product-error">{{ productError }}</p>
        <p v-if="loadingProducts && !productPage" class="feedback">{{ copy.loading }}</p>
        <p v-else-if="!loadingProducts && (!productPage || productPage.list.length === 0)" class="feedback">
          {{ copy.emptyProducts }}
        </p>

        <div class="stack-list">
          <article
            v-for="item in productPage?.list"
            :key="item.id"
            class="manage-card"
            :data-testid="`points-product-${item.id}`"
          >
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">{{ copy.fulfillType(item.fulfillType, item.fulfillTypeText) }}</p>
                <h3>{{ item.name }}</h3>
              </div>
              <span :class="item.soldOut ? 'status-pill status-pill--muted' : 'status-pill status-pill--good'">
                {{ item.soldOut ? copy.soldOut : copy.pointsPrice(item.pointsPrice) }}
              </span>
            </div>

            <p class="manage-card__copy">{{ item.description || '—' }}</p>

            <div class="profile-grid">
              <div class="hero-metric">
                <span>{{ copy.pointsPrice(item.pointsPrice) }}</span>
                <strong>{{ item.pointsPrice }}</strong>
              </div>
              <div class="hero-metric">
                <span>{{ copy.stock(item.stock) }}</span>
                <strong>{{ item.stock }}</strong>
              </div>
              <div class="hero-metric">
                <span>{{ item.exchangeLimitPerUser > 0 ? copy.limit(item.exchangeLimitPerUser) : copy.unlimited }}</span>
                <strong>{{ item.exchangeCount }}</strong>
              </div>
            </div>

            <div class="manage-card__footer">
              <span>{{ exchangeDisabledReason(item) || copy.fulfillType(item.fulfillType, item.fulfillTypeText) }}</span>
              <div class="hero-actions">
                <RouterLink
                  :to="{ name: 'user-points-product-detail', params: { id: item.id } }"
                  class="secondary-button"
                >
                  {{ copy.viewDetail }}
                </RouterLink>
                <button
                  type="button"
                  class="primary-button"
                  :data-testid="`points-exchange-${item.id}`"
                  :disabled="exchangingId != null || !canExchange(item)"
                  @click="submitExchange(item)"
                >
                  {{ exchangingId === item.id ? copy.exchanging : copy.exchange }}
                </button>
              </div>
            </div>
          </article>
        </div>

        <div v-if="productPage && productPage.total > 0" class="hero-actions">
          <button type="button" class="ghost-button" :disabled="productPage.page <= 1 || loadingProducts" @click="goProductPrev">
            {{ copy.previous }}
          </button>
          <span class="support-copy">{{ copy.pagination(productPage.page, productPage.total) }}</span>
          <button type="button" class="ghost-button" :disabled="!productPage.hasMore || loadingProducts" @click="goProductNext">
            {{ copy.next }}
          </button>
        </div>
      </template>

      <template v-else>
        <div class="field-row field-row--two">
          <label class="field">
            <span>{{ copy.pageSize }}</span>
            <select v-model.number="exchangeFilters.pageSize" @change="applyExchangePageSize">
              <option :value="10">{{ copy.rows(10) }}</option>
              <option :value="20">{{ copy.rows(20) }}</option>
            </select>
          </label>
          <div class="hero-actions hero-actions--align-end">
            <button type="button" class="secondary-button" :disabled="loadingExchanges" @click="loadExchanges">
              {{ copy.refresh }}
            </button>
          </div>
        </div>

        <p v-if="exchangeError" class="feedback is-error" data-testid="points-exchange-error">{{ exchangeError }}</p>
        <p v-if="loadingExchanges && !exchangePage" class="feedback">{{ copy.loading }}</p>
        <p v-else-if="!loadingExchanges && (!exchangePage || exchangePage.list.length === 0)" class="feedback">
          {{ copy.emptyExchanges }}
        </p>

        <div class="stack-list">
          <article
            v-for="item in exchangePage?.list"
            :key="item.id"
            class="manage-card"
            :data-testid="`points-exchange-row-${item.id}`"
          >
            <div class="manage-card__header">
              <div>
                <p class="eyebrow">#{{ item.id }}</p>
                <h3>{{ item.productName }}</h3>
              </div>
              <span :class="statusClass(item.status)">
                {{ copy.status(item.status, item.statusText) }}
              </span>
            </div>

            <div class="profile-grid">
              <div class="hero-metric">
                <span>{{ copy.cost }}</span>
                <strong>{{ item.pointsCost }}</strong>
              </div>
              <div class="hero-metric">
                <span>{{ copy.quantity }}</span>
                <strong>{{ item.quantity }}</strong>
              </div>
              <div class="hero-metric">
                <span>{{ copy.redeemCode }}</span>
                <strong data-testid="points-redeem-code">
                  {{ item.status === 1 && item.redeemCode ? item.redeemCode : copy.noRedeemCode }}
                </strong>
              </div>
              <div class="hero-metric">
                <span>{{ copy.orderedAt }}</span>
                <strong>{{ formatWebDateTime(item.createdAt, locale) }}</strong>
              </div>
              <div v-if="item.fulfilledAt" class="hero-metric">
                <span>{{ copy.fulfilledAt }}</span>
                <strong>{{ formatWebDateTime(item.fulfilledAt, locale) }}</strong>
              </div>
            </div>

            <p v-if="item.remark" class="manage-card__copy">{{ copy.remark }}：{{ item.remark }}</p>
          </article>
        </div>

        <div v-if="exchangePage && exchangePage.total > 0" class="hero-actions">
          <button type="button" class="ghost-button" :disabled="exchangePage.page <= 1 || loadingExchanges" @click="goExchangePrev">
            {{ copy.previous }}
          </button>
          <span class="support-copy">{{ copy.pagination(exchangePage.page, exchangePage.total) }}</span>
          <button type="button" class="ghost-button" :disabled="!exchangePage.hasMore || loadingExchanges" @click="goExchangeNext">
            {{ copy.next }}
          </button>
        </div>
      </template>
    </section>
  </div>
</template>
