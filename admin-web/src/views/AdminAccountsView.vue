<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  createAdminAccount,
  listAdminAccounts,
  listAdminRoles,
  listAdminScopeCities,
  resetAdminAccountPassword,
  updateAdminAccount,
  updateAdminAccountStatus,
} from '@/services/admin'
import type { AdminAccount, AdminCityScope, AdminRole, AdminScopeCity, Region } from '@/types/admin'

const { state } = useAdminSession()

const accounts = ref<AdminAccount[]>([])
const roles = ref<AdminRole[]>([])
const scopeCities = ref<AdminScopeCity[]>([])
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

const form = reactive({
  account: '',
  password: '',
  name: '',
  roleIds: [] as number[],
  regions: [] as Region[],
  cityScopes: {
    CN: { allCities: true, cityIds: [] as number[] },
    EU: { allCities: true, cityIds: [] as number[] },
  },
})

const canWrite = computed(() => state.permissions.includes('system:admin:write'))
const activeRoles = computed(() => roles.value.filter((role) => role.status === 1))
const hasMore = computed(() => page.value * pageSize < total.value)
const dialogTitle = computed(() => editingAccount.value ? '编辑管理员' : '新建管理员')

function resetCityScope(region: Region) {
  form.cityScopes[region].allCities = true
  form.cityScopes[region].cityIds = []
}

function cityScope(region: Region) {
  return form.cityScopes[region]
}

function citiesForRegion(region: Region) {
  return scopeCities.value.filter((city) => city.region === region)
}

function onRegionToggle(region: Region) {
  if (!form.regions.includes(region)) resetCityScope(region)
}

function selectAllCities(region: Region) {
  if (form.cityScopes[region].allCities) form.cityScopes[region].cityIds = []
}

function buildCityScopes(): AdminCityScope[] {
  return form.regions.map((region) => ({
    region,
    allCities: form.cityScopes[region].allCities,
    cityIds: form.cityScopes[region].allCities ? [] : [...form.cityScopes[region].cityIds].sort((left, right) => left - right),
  }))
}

function formatCityScopes(account: AdminAccount) {
  return account.cityScopes.map((scope) => {
    if (scope.allCities) return `${scope.region}: 全部城市`
    const names = scope.cityIds.map((cityId) =>
      scopeCities.value.find((city) => city.id === cityId && city.region === scope.region)?.name ?? `#${cityId}`)
    return `${scope.region}: ${names.join(' / ')}`
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
    const [accountResult, roleResult, cityResult] = await Promise.all([
      listAdminAccounts({ page: page.value, pageSize }),
      listAdminRoles(),
      listAdminScopeCities(),
    ])
    accounts.value = accountResult.list
    total.value = accountResult.total
    roles.value = roleResult
    scopeCities.value = cityResult
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '管理员列表加载失败'
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  if (!canWrite.value || saving.value) return
  if (form.roleIds.length === 0) {
    errorMessage.value = '至少选择一个角色'
    return
  }
  if (form.regions.length === 0) {
    errorMessage.value = '至少选择一个区域'
    return
  }
  const incompleteRegion = form.regions.find((region) =>
    !form.cityScopes[region].allCities && form.cityScopes[region].cityIds.length === 0)
  if (incompleteRegion) {
    errorMessage.value = `${incompleteRegion} 至少选择一个城市`
    return
  }
  if (!editingAccount.value && form.password.length < 8) {
    errorMessage.value = '初始密码至少 8 位'
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
    errorMessage.value = error instanceof Error ? error.message : '管理员保存失败'
  } finally {
    saving.value = false
  }
}

async function changeStatus(account: AdminAccount) {
  if (account.id === state.profile?.id || !canWrite.value) {
    return
  }
  const nextStatus = account.status === 1 ? 2 : 1
  const action = nextStatus === 2 ? '停用' : '启用'
  if (!window.confirm(`确认${action}管理员「${account.name}」吗？`)) {
    return
  }
  if (!canWrite.value) return
  errorMessage.value = ''
  try {
    await updateAdminAccountStatus(account.id, nextStatus)
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '管理员状态更新失败'
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
    resetError.value = '新密码至少 8 位'
    return
  }
  resetError.value = ''
  try {
    await resetAdminAccountPassword(resetTarget.value.id, resetPassword.value)
    resetTarget.value = null
  } catch (error) {
    resetError.value = error instanceof Error ? error.message : '密码重置失败'
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
        <p class="eyebrow">System Access</p>
        <h1>管理员账号</h1>
        <p>账号、角色、区域与城市范围由服务端实时读取，停用后旧会话会在下一次请求失效。</p>
      </div>
      <div class="header-actions">
        <button v-if="canWrite" type="button" class="primary-button" @click="openCreate">新建管理员</button>
      </div>
    </header>

    <p v-if="errorMessage && !dialogOpen" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? '加载中...' : `共 ${total} 个管理员` }}</span>
        <span>当前操作者：{{ state.profile?.name ?? '--' }}</span>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>账号</th>
              <th>角色</th>
              <th>区域 / 城市</th>
              <th>最近登录</th>
              <th>状态</th>
              <th v-if="canWrite">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="account in accounts" :key="account.id">
              <td>
                <strong>{{ account.name }}</strong>
                <p class="code-box">{{ account.account }}</p>
              </td>
              <td><span class="tag-list">{{ account.roleNames.join(' / ') || '--' }}</span></td>
              <td><span class="region-list">{{ formatCityScopes(account) }}</span></td>
              <td class="numeric-cell">{{ account.lastLoginAt || '从未登录' }}</td>
              <td>
                <span class="status-pill" :class="account.status === 1 ? 'status-pill--good' : 'status-pill--muted'">
                  {{ account.status === 1 ? '启用' : '已停用' }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button type="button" class="table-action" @click="openEdit(account)">编辑</button>
                  <button type="button" class="table-action" @click="openPasswordReset(account)">重置密码</button>
                  <button
                    :data-testid="`status-admin-${account.id}`"
                    type="button"
                    class="table-action"
                    :class="{ 'table-action--danger': account.status === 1 }"
                    :disabled="account.id === state.profile?.id"
                    :title="account.id === state.profile?.id ? '当前账号不能停用自己' : ''"
                    @click="changeStatus(account)"
                  >
                    {{ account.status === 1 ? '停用' : '启用' }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && accounts.length === 0">
              <td class="table-empty" :colspan="canWrite ? 6 : 5">暂无管理员账号</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pager">
        <button type="button" class="ghost-button system-pager-button" :disabled="page === 1" @click="goPage(page - 1)">上一页</button>
        <span class="numeric-cell">第 {{ page }} 页</span>
        <button type="button" class="ghost-button system-pager-button" :disabled="!hasMore" @click="goPage(page + 1)">下一页</button>
      </div>
    </article>

    <div v-if="dialogOpen && canWrite" class="dialog-backdrop" role="presentation" @click.self="closeDialog">
      <form class="dialog-panel system-dialog system-dialog--wide" data-testid="admin-form" @submit.prevent="submitForm">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">Account Form</p>
            <h2>{{ dialogTitle }}</h2>
          </div>
          <button type="button" class="dialog-close" aria-label="关闭" :disabled="saving" @click="closeDialog">×</button>
        </header>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <div class="form-grid form-grid--two">
          <label class="field">
            <span>登录账号</span>
            <input name="admin-account" v-model="form.account" :disabled="Boolean(editingAccount)" autocomplete="username" required />
          </label>
          <label v-if="!editingAccount" class="field">
            <span>初始密码</span>
            <input name="admin-password" v-model="form.password" type="password" autocomplete="new-password" required />
          </label>
          <label class="field" :class="{ 'field--full': editingAccount }">
            <span>显示名称</span>
            <input name="admin-name" v-model="form.name" required />
          </label>
        </div>

        <fieldset class="selection-fieldset">
          <legend>角色</legend>
          <label v-for="role in activeRoles" :key="role.id" class="selection-option">
            <input :name="`role-${role.id}`" v-model="form.roleIds" type="checkbox" :value="role.id" />
            <span><strong>{{ role.name }}</strong><small>{{ role.code }}</small></span>
          </label>
        </fieldset>

        <fieldset class="selection-fieldset selection-fieldset--regions">
          <legend>区域范围</legend>
          <label v-for="region in regions" :key="region" class="selection-option selection-option--compact">
            <input :name="`region-${region}`" v-model="form.regions" type="checkbox" :value="region" @change="onRegionToggle(region)" />
            <span><strong>{{ region }}</strong></span>
          </label>
        </fieldset>

        <fieldset v-if="form.regions.length > 0" class="selection-fieldset city-scope-fieldset">
          <legend>城市范围</legend>
          <section v-for="region in form.regions" :key="region" class="city-scope-section">
            <div class="city-scope-section__header">
              <strong>{{ region }}</strong>
              <span>{{ cityScope(region).allCities ? '全部城市' : '指定城市' }}</span>
            </div>
            <div class="city-scope-modes">
              <label class="selection-option selection-option--compact">
                <input :name="`city-scope-${region}`" :data-testid="`city-scope-all-${region}`" v-model="cityScope(region).allCities" type="radio" :value="true" @change="selectAllCities(region)" />
                <span><strong>全部城市</strong></span>
              </label>
              <label class="selection-option selection-option--compact">
                <input :name="`city-scope-${region}`" :data-testid="`city-scope-selected-${region}`" v-model="cityScope(region).allCities" type="radio" :value="false" />
                <span><strong>指定城市</strong></span>
              </label>
            </div>
            <div v-if="!cityScope(region).allCities" class="city-scope-cities">
              <label v-for="city in citiesForRegion(region)" :key="city.id" class="selection-option selection-option--compact">
                <input :name="`city-${region}-${city.id}`" v-model="cityScope(region).cityIds" type="checkbox" :value="city.id" />
                <span><strong>{{ city.name }}</strong><small>#{{ city.id }}</small></span>
              </label>
              <p v-if="citiesForRegion(region).length === 0" class="inline-note">当前区域没有可分配城市。</p>
            </div>
          </section>
        </fieldset>

        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" :disabled="saving" @click="closeDialog">取消</button>
          <button type="submit" class="primary-button" :disabled="saving">{{ saving ? '保存中...' : '保存管理员' }}</button>
        </footer>
      </form>
    </div>

    <div v-if="resetTarget && canWrite" class="dialog-backdrop" role="presentation" @click.self="resetTarget = null">
      <form class="dialog-panel system-dialog system-dialog--compact" @submit.prevent="submitPasswordReset">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">Password Reset</p>
            <h2>重置 {{ resetTarget.name }} 的密码</h2>
          </div>
          <button type="button" class="dialog-close" aria-label="关闭" @click="resetTarget = null">×</button>
        </header>
        <p v-if="resetError" class="feedback is-error">{{ resetError }}</p>
        <label class="field">
          <span>新密码</span>
          <input name="reset-password" v-model="resetPassword" type="password" autocomplete="new-password" required />
        </label>
        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" @click="resetTarget = null">取消</button>
          <button type="submit" class="primary-button">确认重置</button>
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
