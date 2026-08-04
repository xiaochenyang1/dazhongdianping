<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  createAdminPointsProduct,
  listAdminPointsProducts,
  removeAdminPointsProduct,
  updateAdminPointsProduct,
  updateAdminPointsProductStatus,
} from '@/services/admin'
import type { AdminPointsProduct, AdminPointsProductPayload, PageResult } from '@/types/admin'

type PointsProductEditor = AdminPointsProductPayload & {
  id?: number
}

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))
const canWrite = computed(() => state.permissions.includes('operations:points:write'))

const pageState = ref<PageResult<AdminPointsProduct> | null>(null)
const editor = ref<PointsProductEditor | null>(null)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const page = ref(1)
const pageSize = 10
let requestId = 0

const products = computed(() => pageState.value?.list ?? [])

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : strings.value.common.requestFailed
}

function resetMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

async function load() {
  const currentRequestId = ++requestId
  loading.value = true
  resetMessages()
  try {
    const next = await listAdminPointsProducts({ page: page.value, pageSize })
    if (currentRequestId !== requestId) return
    pageState.value = next
  } catch (error) {
    if (currentRequestId === requestId) {
      errorMessage.value = messageOf(error) || strings.value.pointsProducts.loadError
    }
  } finally {
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

function openEditor(item?: AdminPointsProduct) {
  if (!canWrite.value) return
  resetMessages()
  editor.value = item
    ? {
        id: item.id,
        name: item.name,
        coverImage: item.coverImage,
        description: item.description,
        pointsPrice: item.pointsPrice,
        stock: item.stock,
        exchangeLimitPerUser: item.exchangeLimitPerUser,
        fulfillType: item.fulfillType,
        sort: item.sort,
      }
    : {
        name: '',
        coverImage: '',
        description: '',
        pointsPrice: 100,
        stock: 0,
        exchangeLimitPerUser: 1,
        fulfillType: 1,
        sort: 0,
      }
}

async function submitEditor() {
  if (!editor.value || !canWrite.value) return
  resetMessages()
  saving.value = true
  const current = editor.value
  const payload: AdminPointsProductPayload = {
    name: current.name.trim(),
    coverImage: current.coverImage.trim(),
    description: current.description.trim(),
    pointsPrice: Number(current.pointsPrice),
    stock: Number(current.stock),
    exchangeLimitPerUser: Number(current.exchangeLimitPerUser),
    fulfillType: Number(current.fulfillType),
    sort: Number(current.sort),
  }
  try {
    if (current.id) {
      await updateAdminPointsProduct(current.id, payload)
      successMessage.value = strings.value.pointsProducts.updated
    } else {
      await createAdminPointsProduct(payload)
      successMessage.value = strings.value.pointsProducts.created
    }
    editor.value = null
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function toggleProduct(item: AdminPointsProduct) {
  if (!canWrite.value || saving.value) return
  resetMessages()
  saving.value = true
  const nextStatus = item.status === 1 ? 0 : 1
  try {
    await updateAdminPointsProductStatus(item.id, nextStatus)
    successMessage.value = nextStatus === 1
      ? strings.value.pointsProducts.enabled
      : strings.value.pointsProducts.disabled
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

async function deleteProduct(item: AdminPointsProduct) {
  if (!canWrite.value || saving.value) return
  if (!window.confirm(strings.value.pointsProducts.deleteConfirm(item.name))) return
  resetMessages()
  saving.value = true
  try {
    await removeAdminPointsProduct(item.id)
    successMessage.value = strings.value.pointsProducts.deleted
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error)
  } finally {
    saving.value = false
  }
}

function limitText(item: AdminPointsProduct) {
  return item.exchangeLimitPerUser > 0
    ? String(item.exchangeLimitPerUser)
    : strings.value.pointsProducts.unlimited
}

function changePage(delta: number) {
  const next = page.value + delta
  if (next < 1) return
  if (delta > 0 && !pageState.value?.hasMore) return
  page.value = next
  void load()
}

watch(
  () => state.region,
  () => {
    editor.value = null
    page.value = 1
    void load()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">{{ strings.pointsProducts.eyebrow }}</p>
        <h1>{{ strings.pointsProducts.heading }}</h1>
        <p>{{ strings.pointsProducts.description(state.region) }}</p>
      </div>
      <button
        v-if="canWrite"
        data-testid="create-points-product"
        class="secondary-button"
        type="button"
        @click="openEditor()"
      >
        {{ strings.pointsProducts.create }}
      </button>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <section class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.pointsProducts.listEyebrow }}</p>
          <h2>{{ strings.pointsProducts.listHeading }}</h2>
        </div>
      </div>

      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.pointsProducts.tableHeaders.name }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.points }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.stock }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.limit }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.exchanged }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.fulfillType }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.status }}</th>
              <th>{{ strings.pointsProducts.tableHeaders.sort }}</th>
              <th v-if="canWrite">{{ strings.pointsProducts.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="canWrite ? 9 : 8" class="table-empty">{{ strings.pointsProducts.loading }}</td>
            </tr>
            <tr v-else-if="!products.length">
              <td :colspan="canWrite ? 9 : 8" class="table-empty">{{ strings.pointsProducts.empty }}</td>
            </tr>
            <tr v-for="item in products" :key="item.id" :data-testid="`points-product-row-${item.id}`">
              <td>
                <strong>{{ item.name }}</strong>
                <div v-if="item.description" class="muted">{{ item.description }}</div>
              </td>
              <td>{{ item.pointsPrice }}</td>
              <td>
                {{ item.stock }}
                <span v-if="item.soldOut" class="muted">（{{ strings.pointsProducts.soldOut }}）</span>
              </td>
              <td>{{ limitText(item) }}</td>
              <td>{{ item.exchangeCount }}</td>
              <td>{{ strings.pointsProducts.fulfillTypeText(item.fulfillType, item.fulfillTypeText) }}</td>
              <td><span class="status-pill">{{ strings.pointsProducts.statusText(item.status) }}</span></td>
              <td>{{ item.sort }}</td>
              <td v-if="canWrite" class="table-actions">
                <button
                  :data-testid="`edit-points-product-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="openEditor(item)"
                >
                  {{ strings.pointsProducts.edit }}
                </button>
                <button
                  :data-testid="`toggle-points-product-${item.id}`"
                  class="table-action"
                  type="button"
                  @click="toggleProduct(item)"
                >
                  {{ item.status === 1 ? strings.pointsProducts.disable : strings.pointsProducts.enable }}
                </button>
                <button
                  :data-testid="`delete-points-product-${item.id}`"
                  class="table-action danger-action"
                  type="button"
                  @click="deleteProduct(item)"
                >
                  {{ strings.pointsProducts.delete }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button
          type="button"
          class="ghost-button system-pager-button"
          data-testid="points-product-prev"
          :disabled="page <= 1 || loading"
          @click="changePage(-1)"
        >
          {{ strings.pointsProducts.previousPage }}
        </button>
        <span class="numeric-cell">{{ strings.pointsProducts.page(page) }}</span>
        <button
          type="button"
          class="ghost-button system-pager-button"
          data-testid="points-product-next"
          :disabled="!pageState?.hasMore || loading"
          @click="changePage(1)"
        >
          {{ strings.pointsProducts.nextPage }}
        </button>
      </div>

      <p v-if="!canWrite" class="muted">{{ strings.pointsProducts.readOnly }}</p>
    </section>

    <section v-if="editor && canWrite" class="content-card">
      <div class="section-headline">
        <div>
          <p class="eyebrow">{{ strings.pointsProducts.editorEyebrow(Boolean(editor.id)) }}</p>
          <h2>{{ strings.pointsProducts.editorHeading(Boolean(editor.id)) }}</h2>
        </div>
      </div>

      <form data-testid="points-product-editor" class="editor-form" @submit.prevent="submitEditor">
        <div class="form-grid form-grid--two">
          <label class="field field--full">
            <span>{{ strings.pointsProducts.labels.name }}</span>
            <input v-model="editor.name" name="points-product-name" type="text" maxlength="80" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.pointsProducts.labels.coverImage }}</span>
            <input v-model="editor.coverImage" name="points-product-cover" type="text" maxlength="255" />
          </label>
          <label class="field field--full">
            <span>{{ strings.pointsProducts.labels.description }}</span>
            <textarea v-model="editor.description" name="points-product-description" rows="3" maxlength="500"></textarea>
          </label>
          <label class="field">
            <span>{{ strings.pointsProducts.labels.pointsPrice }}</span>
            <input v-model.number="editor.pointsPrice" name="points-product-price" type="number" min="1" required />
          </label>
          <label class="field">
            <span>{{ strings.pointsProducts.labels.stock }}</span>
            <input v-model.number="editor.stock" name="points-product-stock" type="number" min="0" required />
          </label>
          <label class="field">
            <span>{{ strings.pointsProducts.labels.limitPerUser }}</span>
            <input v-model.number="editor.exchangeLimitPerUser" name="points-product-limit" type="number" min="0" />
            <small class="muted">{{ strings.pointsProducts.limitHint }}</small>
          </label>
          <label class="field">
            <span>{{ strings.pointsProducts.labels.fulfillType }}</span>
            <select v-model.number="editor.fulfillType" name="points-product-fulfill-type">
              <option :value="1">{{ strings.pointsProducts.fulfillOptions.auto }}</option>
              <option :value="2">{{ strings.pointsProducts.fulfillOptions.manual }}</option>
            </select>
          </label>
          <label class="field">
            <span>{{ strings.pointsProducts.labels.sort }}</span>
            <input v-model.number="editor.sort" name="points-product-sort" type="number" min="0" />
          </label>
        </div>
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">
            {{ saving ? strings.pointsProducts.saving : strings.pointsProducts.save }}
          </button>
          <button class="secondary-button" type="button" @click="editor = null">{{ strings.common.cancel }}</button>
        </div>
      </form>
    </section>
  </section>
</template>
