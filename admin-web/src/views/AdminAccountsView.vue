<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  createAdminAccount,
  listAdminAccounts,
  listAdminRoles,
  listAdminScopeCities,
  listAdminScopeShops,
  resetAdminAccountPassword,
  updateAdminAccount,
  updateAdminAccountStatus,
} from '@/services/admin'
import type { AdminAccount, AdminCityScope, AdminRole, AdminScopeCity, AdminScopeShop, Region } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const accounts = ref<AdminAccount[]>([])
const roles = ref<AdminRole[]>([])
const scopeCities = ref<AdminScopeCity[]>([])
const scopeShops = ref<AdminScopeShop[]>([])
const page = ref(1)
const total = ref(0)
const pageSize = 20
const loading = ref(false)
const errorMessage = ref('')
const dialogOpen = ref(false)
const editingAccount = ref<AdminAccount | null>(null)
const saving = ref(false)
const resetTarget = ref<AdminAccount | null>(null)
const resetPassword = ref('')
const resetError = ref('')
const regions: Region[] = ['CN', 'EU']
type ScopeMode = 'all' | 'cities' | 'shops'

const form = reactive({
  account: '',
  password: '',
  name: '',
  roleIds: [] as number[],
  regions: [] as Region[],
  cityScopes: {
    CN: { allCities: true, cityIds: [] as number[], shopIds: [] as number[] },
    EU: { allCities: true, cityIds: [] as number[], shopIds: [] as number[] },
  },
})
const selectedShopRegions = reactive<Record<Region, boolean>>({ CN: false, EU: false })

const canWrite = computed(() => state.permissions.includes('system:admin:write'))
const activeRoles = computed(() => roles.value.filter((role) => role.status === 1))
const hasMore = computed(() => page.value * pageSize < total.value)
const dialogTitle = computed(() => strings.value.adminAccounts.formHeading(Boolean(editingAccount.value)))

function resetCityScope(region: Region) {
  form.cityScopes[region].allCities = true
  form.cityScopes[region].cityIds = []
  form.cityScopes[region].shopIds = []
  selectedShopRegions[region] = false
}

function cityScope(region: Region) {
  return form.cityScopes[region]
}

function citiesForRegion(region: Region) {
  return scopeCities.value.filter((city) => city.region === region)
}

function shopsForRegion(region: Region) {
  return scopeShops.value.filter((shop) => shop.region === region)
}

function scopeMode(region: Region): ScopeMode {
  const scope = form.cityScopes[region]
  if (scope.allCities) return 'all'
  if (selectedShopRegions[region] || (scope.shopIds.length > 0 && scope.cityIds.length === 0)) return 'shops'
  return 'cities'
}

function scopeModeText(region: Region) {
  return strings.value.adminAccounts.scopeModeText(scopeMode(region))
}

function accountStatusText(status: number) {
  return strings.value.adminAccounts.statusText(status)
}

function accountStatusAction(status: number) {
  return status === 1 ? strings.value.adminAccounts.disable : strings.value.adminAccounts.enable
}

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function onRegionToggle(region: Region) {
  if (!form.regions.includes(region)) resetCityScope(region)
}

function selectAllCities(region: Region) {
  if (form.cityScopes[region].allCities) form.cityScopes[region].cityIds = []
  if (form.cityScopes[region].allCities) form.cityScopes[region].shopIds = []
  selectedShopRegions[region] = false
}

function selectCities(region: Region) {
  form.cityScopes[region].allCities = false
  form.cityScopes[region].shopIds = []
  selectedShopRegions[region] = false
}

function selectShops(region: Region) {
  form.cityScopes[region].allCities = false
  form.cityScopes[region].cityIds = []
  selectedShopRegions[region] = true
}

function buildCityScopes(): AdminCityScope[] {
  return form.regions.map((region) => ({
    region,
    allCities: form.cityScopes[region].allCities,
    cityIds: form.cityScopes[region].allCities ? [] : [...form.cityScopes[region].cityIds].sort((left, right) => left - right),
    shopIds: form.cityScopes[region].allCities ? [] : [...form.cityScopes[region].shopIds].sort((left, right) => left - right),
  }))
}

function formatCityScopes(account: AdminAccount) {
  return account.cityScopes.map((scope) => {
    if (scope.allCities) {
      return strings.value.adminAccounts.scopeEntry(scope.region, strings.value.adminAccounts.scopeAllCities)
    }
    const names = scope.cityIds.map((cityId) =>
      scopeCities.value.find((city) => city.id === cityId && city.region === scope.region)?.name ?? `#${cityId}`)
    const shopNames = (scope.shopIds ?? []).map((shopId) =>
      scopeShops.value.find((shop) => shop.id === shopId && shop.region === scope.region)?.name ?? `#${shopId}`)
    return strings.value.adminAccounts.scopeEntry(
      scope.region,
      [...names, ...shopNames].join(' / ') || '--',
    )
  }).join(' · ')
}

function resetForm() {
  form.account = ''
  form.password = ''
  form.name = ''
  form.roleIds = []
  form.regions = []
  regions.forEach(resetCityScope)
  errorMessage.value = ''
}

function openCreate() {
  if (!canWrite.value) return
  editingAccount.value = null
  resetForm()
  dialogOpen.value = true
}

function openEdit(account: AdminAccount) {
  if (!canWrite.value) return
  editingAccount.value = account
  form.account = account.account
  form.password = ''
  form.name = account.name
  form.roleIds = [...account.roleIds]
  form.regions = [...account.regions]
  regions.forEach((region) => {
    const scope = account.cityScopes.find((item) => item.region === region)
    form.cityScopes[region].allCities = scope?.allCities ?? true
    form.cityScopes[region].cityIds = scope?.allCities === false ? [...scope.cityIds] : []
    form.cityScopes[region].shopIds = scope?.allCities === false ? [...(scope.shopIds ?? [])] : []
    selectedShopRegions[region] = scope?.allCities === false && (scope.shopIds ?? []).length > 0 && (scope.cityIds ?? []).length === 0
  })
  errorMessage.value = ''
  dialogOpen.value = true
}

function closeDialog() {
  if (!saving.value) {
    dialogOpen.value = false
  }
}

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const [accountResult, roleResult, cityResult, shopResult] = await Promise.all([
      listAdminAccounts({ page: page.value, pageSize }),
      listAdminRoles(),
      listAdminScopeCities(),
      listAdminScopeShops(),
    ])
    accounts.value = accountResult.list
    total.value = accountResult.total
    roles.value = roleResult
    scopeCities.value = cityResult
    scopeShops.value = shopResult
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminAccounts.loadError)
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  if (!canWrite.value || saving.value) return
  if (form.roleIds.length === 0) {
    errorMessage.value = strings.value.adminAccounts.roleRequired
    return
  }
  if (form.regions.length === 0) {
    errorMessage.value = strings.value.adminAccounts.regionRequired
    return
  }
  const incompleteRegion = form.regions.find((region) =>
    !form.cityScopes[region].allCities && form.cityScopes[region].cityIds.length === 0 && form.cityScopes[region].shopIds.length === 0)
  if (incompleteRegion) {
    errorMessage.value = strings.value.adminAccounts.cityRequired(incompleteRegion)
    return
  }
  if (!editingAccount.value && form.password.length < 8) {
    errorMessage.value = strings.value.adminAccounts.passwordMin
    return
  }

  saving.value = true
  errorMessage.value = ''
  try {
    if (editingAccount.value) {
      await updateAdminAccount(editingAccount.value.id, {
        name: form.name.trim(),
        roleIds: [...form.roleIds],
        regions: [...form.regions],
        cityScopes: buildCityScopes(),
      })
    } else {
      await createAdminAccount({
        account: form.account.trim(),
        password: form.password,
        name: form.name.trim(),
        roleIds: [...form.roleIds],
        regions: [...form.regions],
        cityScopes: buildCityScopes(),
      })
    }
    dialogOpen.value = false
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminAccounts.saveError)
  } finally {
    saving.value = false
  }
}

async function changeStatus(account: AdminAccount) {
  if (account.id === state.profile?.id || !canWrite.value) {
    return
  }
  const nextStatus = account.status === 1 ? 2 : 1
  const action = nextStatus === 2 ? 'disable' : 'enable'
  if (!window.confirm(strings.value.adminAccounts.statusConfirm(account.name, action))) {
    return
  }
  if (!canWrite.value) return
  errorMessage.value = ''
  try {
    await updateAdminAccountStatus(account.id, nextStatus)
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminAccounts.statusUpdateError)
  }
}

function openPasswordReset(account: AdminAccount) {
  if (!canWrite.value) return
  resetTarget.value = account
  resetPassword.value = ''
  resetError.value = ''
}

async function submitPasswordReset() {
  if (!canWrite.value || !resetTarget.value) {
    return
  }
  if (resetPassword.value.length < 8) {
    resetError.value = strings.value.adminAccounts.resetPasswordMin
    return
  }
  resetError.value = ''
  try {
    await resetAdminAccountPassword(resetTarget.value.id, resetPassword.value)
    resetTarget.value = null
  } catch (error) {
    resetError.value = messageOf(error, strings.value.adminAccounts.resetPasswordError)
  }
}

async function goPage(nextPage: number) {
  page.value = Math.max(1, nextPage)
  await load()
}

onMounted(() => {
  void load()
})

watch(canWrite, (allowed) => {
  if (!allowed) {
    dialogOpen.value = false
    resetTarget.value = null
  }
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.adminAccounts.eyebrow }}</p>
        <h1>{{ strings.adminAccounts.heading }}</h1>
        <p>{{ strings.adminAccounts.description }}</p>
      </div>
      <div class="header-actions">
        <button v-if="canWrite" type="button" class="primary-button" @click="openCreate">{{ strings.adminAccounts.create }}</button>
      </div>
    </header>

    <p v-if="errorMessage && !dialogOpen" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.adminAccounts.metaLoading : strings.adminAccounts.metaSummary(total) }}</span>
        <span>{{ strings.adminAccounts.metaOperator(state.profile?.name ?? '--') }}</span>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.adminAccounts.tableHeaders.account }}</th>
              <th>{{ strings.adminAccounts.tableHeaders.roles }}</th>
              <th>{{ strings.adminAccounts.tableHeaders.scope }}</th>
              <th>{{ strings.adminAccounts.tableHeaders.lastLogin }}</th>
              <th>{{ strings.adminAccounts.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.adminAccounts.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="account in accounts" :key="account.id">
              <td>
                <strong>{{ account.name }}</strong>
                <p class="code-box">{{ account.account }}</p>
              </td>
              <td><span class="tag-list">{{ account.roleNames.join(' / ') || strings.adminAccounts.roleFallback }}</span></td>
              <td><span class="region-list">{{ formatCityScopes(account) }}</span></td>
              <td class="numeric-cell">{{ account.lastLoginAt || strings.adminAccounts.neverLoggedIn }}</td>
              <td>
                <span class="status-pill" :class="account.status === 1 ? 'status-pill--good' : 'status-pill--muted'">
                  {{ accountStatusText(account.status) }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button type="button" class="table-action" @click="openEdit(account)">{{ strings.adminAccounts.edit }}</button>
                  <button type="button" class="table-action" @click="openPasswordReset(account)">{{ strings.adminAccounts.resetPassword }}</button>
                  <button
                    :data-testid="`status-admin-${account.id}`"
                    type="button"
                    class="table-action"
                    :class="{ 'table-action--danger': account.status === 1 }"
                    :disabled="account.id === state.profile?.id"
                    :title="account.id === state.profile?.id ? strings.adminAccounts.selfDisableTitle : ''"
                    @click="changeStatus(account)"
                  >
                    {{ accountStatusAction(account.status) }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && accounts.length === 0">
              <td class="table-empty" :colspan="canWrite ? 6 : 5">{{ strings.adminAccounts.empty }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="page === 1" @click="goPage(page - 1)">{{ strings.adminAccounts.previousPage }}</button>
        <span class="numeric-cell">{{ strings.adminAccounts.page(page) }}</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!hasMore" @click="goPage(page + 1)">{{ strings.adminAccounts.nextPage }}</button>
      </div>
    </article>

    <div v-if="dialogOpen && canWrite" class="dialog-backdrop" role="presentation" @click.self="closeDialog">
      <form class="dialog-panel system-dialog system-dialog--wide" data-testid="admin-form" @submit.prevent="submitForm">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">{{ strings.adminAccounts.formEyebrow }}</p>
            <h2>{{ dialogTitle }}</h2>
          </div>
          <button type="button" class="dialog-close" :aria-label="strings.common.cancel" :disabled="saving" @click="closeDialog">×</button>
        </header>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.adminAccounts.labels.account }}</span>
            <input name="admin-account" v-model="form.account" :disabled="Boolean(editingAccount)" autocomplete="username" required />
          </label>
          <label v-if="!editingAccount" class="field">
            <span>{{ strings.adminAccounts.labels.password }}</span>
            <input name="admin-password" v-model="form.password" type="password" autocomplete="new-password" required />
          </label>
          <label class="field" :class="{ 'field--full': editingAccount }">
            <span>{{ strings.adminAccounts.labels.name }}</span>
            <input name="admin-name" v-model="form.name" required />
          </label>
        </div>

        <fieldset class="selection-fieldset">
          <legend>{{ strings.adminAccounts.labels.roles }}</legend>
          <label v-for="role in activeRoles" :key="role.id" class="selection-option">
            <input :name="`role-${role.id}`" v-model="form.roleIds" type="checkbox" :value="role.id" />
            <span><strong>{{ role.name }}</strong><small>{{ role.code }}</small></span>
          </label>
        </fieldset>

        <fieldset class="selection-fieldset selection-fieldset--regions">
          <legend>{{ strings.adminAccounts.labels.regions }}</legend>
          <label v-for="region in regions" :key="region" class="selection-option selection-option--compact">
            <input :name="`region-${region}`" v-model="form.regions" type="checkbox" :value="region" @change="onRegionToggle(region)" />
            <span><strong>{{ region }}</strong></span>
          </label>
        </fieldset>

        <fieldset v-if="form.regions.length > 0" class="selection-fieldset city-scope-fieldset">
          <legend>{{ strings.adminAccounts.labels.cityScopes }}</legend>
          <section v-for="region in form.regions" :key="region" class="city-scope-section">
            <div class="city-scope-section__header">
              <strong>{{ region }}</strong>
              <span>{{ scopeModeText(region) }}</span>
            </div>
            <div class="city-scope-modes">
              <label class="selection-option selection-option--compact">
                <input :name="`city-scope-${region}`" :data-testid="`city-scope-all-${region}`" v-model="cityScope(region).allCities" type="radio" :value="true" @change="selectAllCities(region)" />
                <span><strong>{{ strings.adminAccounts.scopeModeOptions.all }}</strong></span>
              </label>
              <label class="selection-option selection-option--compact">
                <input :name="`city-scope-${region}`" :data-testid="`city-scope-selected-${region}`" :checked="scopeMode(region) === 'cities'" type="radio" :value="false" @change="selectCities(region)" />
                <span><strong>{{ strings.adminAccounts.scopeModeOptions.cities }}</strong></span>
              </label>
              <label class="selection-option selection-option--compact">
                <input :name="`city-scope-${region}`" :data-testid="`city-scope-shops-${region}`" :checked="scopeMode(region) === 'shops'" type="radio" :value="false" @change="selectShops(region)" />
                <span><strong>{{ strings.adminAccounts.scopeModeOptions.shops }}</strong></span>
              </label>
            </div>
            <div v-if="scopeMode(region) === 'cities'" class="city-scope-cities">
              <label v-for="city in citiesForRegion(region)" :key="city.id" class="selection-option selection-option--compact">
                <input :name="`city-${region}-${city.id}`" v-model="cityScope(region).cityIds" type="checkbox" :value="city.id" />
                <span><strong>{{ city.name }}</strong><small>#{{ city.id }}</small></span>
              </label>
              <p v-if="citiesForRegion(region).length === 0" class="inline-note">{{ strings.adminAccounts.noCities }}</p>
            </div>
            <div v-if="scopeMode(region) === 'shops'" class="city-scope-cities">
              <label v-for="shop in shopsForRegion(region)" :key="shop.id" class="selection-option selection-option--compact">
                <input :name="`shop-${region}-${shop.id}`" v-model="cityScope(region).shopIds" type="checkbox" :value="shop.id" />
                <span><strong>{{ shop.name }}</strong><small>{{ shop.cityName }} · #{{ shop.id }}</small></span>
              </label>
              <p v-if="shopsForRegion(region).length === 0" class="inline-note">{{ strings.adminAccounts.noShops }}</p>
            </div>
          </section>
        </fieldset>

        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" :disabled="saving" @click="closeDialog">{{ strings.common.cancel }}</button>
          <button type="submit" class="primary-button" :disabled="saving">{{ saving ? strings.adminAccounts.saving : strings.adminAccounts.save }}</button>
        </footer>
      </form>
    </div>

    <div v-if="resetTarget && canWrite" class="dialog-backdrop" role="presentation" @click.self="resetTarget = null">
      <form class="dialog-panel system-dialog system-dialog--compact" @submit.prevent="submitPasswordReset">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">{{ strings.adminAccounts.resetEyebrow }}</p>
            <h2>{{ strings.adminAccounts.resetHeading(resetTarget.name) }}</h2>
          </div>
          <button type="button" class="dialog-close" :aria-label="strings.common.cancel" @click="resetTarget = null">×</button>
        </header>
        <p v-if="resetError" class="feedback is-error">{{ resetError }}</p>
        <label class="field">
          <span>{{ strings.adminAccounts.resetLabel }}</span>
          <input name="reset-password" v-model="resetPassword" type="password" autocomplete="new-password" required />
        </label>
        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" @click="resetTarget = null">{{ strings.common.cancel }}</button>
          <button type="submit" class="primary-button">{{ strings.adminAccounts.resetSubmit }}</button>
        </footer>
      </form>
    </div>
  </section>
</template>

<style scoped>
.city-scope-fieldset {
  grid-template-columns: 1fr;
}

.city-scope-section {
  display: grid;
  gap: 0.65rem;
  padding-block: 0.25rem 0.85rem;
  border-bottom: 1px solid var(--border);
}

.city-scope-section:last-child {
  padding-bottom: 0;
  border-bottom: 0;
}

.city-scope-section__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  color: var(--text-muted);
}

.city-scope-section__header strong {
  color: var(--text);
}

.city-scope-modes,
.city-scope-cities {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.65rem;
}

@media (max-width: 720px) {
  .city-scope-modes,
  .city-scope-cities {
    grid-template-columns: 1fr;
  }
}
</style>
