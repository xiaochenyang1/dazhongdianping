<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion } from '@/core/admin_localizations'
import {
  createAdminRole,
  listAdminPermissions,
  listAdminRoles,
  removeAdminRole,
  updateAdminRole,
  updateAdminRoleStatus,
} from '@/services/admin'
import type { AdminPermissionItem, AdminRole, AdminRolePayload } from '@/types/admin'

const { state } = useAdminSession()
const strings = computed(() => adminStringsForRegion(state.region))

const roles = ref<AdminRole[]>([])
const permissions = ref<AdminPermissionItem[]>([])
const loading = ref(false)
const errorMessage = ref('')
const dialogOpen = ref(false)
const editingRole = ref<AdminRole | null>(null)
const saving = ref(false)

const form = reactive<AdminRolePayload>({
  code: '',
  name: '',
  description: '',
  permissionIds: [],
})

const canWrite = computed(() => state.permissions.includes('system:role:write'))
const isSuperAdmin = computed(() => editingRole.value?.code === 'super_admin')
const permissionGroups = computed(() => {
  const labels = strings.value.adminRoles.permissionGroupLabels
  const groups = new Map<string, AdminPermissionItem[]>()
  permissions.value.forEach((permission) => {
    const list = groups.get(permission.category) ?? []
    list.push(permission)
    groups.set(permission.category, list)
  })
  return [...groups.entries()].map(([category, items]) => {
    const label = category in labels
      ? labels[category as keyof typeof labels]
      : category
    return { category, label, items }
  })
})

function messageOf(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback
}

function roleStatusText(status: number) {
  return strings.value.adminRoles.statusText(status)
}

function roleStatusAction(status: number) {
  return status === 1 ? strings.value.adminRoles.disable : strings.value.adminRoles.enable
}

function resetForm() {
  form.code = ''
  form.name = ''
  form.description = ''
  form.permissionIds = []
  errorMessage.value = ''
}

function openCreate() {
  if (!canWrite.value) return
  editingRole.value = null
  resetForm()
  dialogOpen.value = true
}

function openEdit(role: AdminRole) {
  if (!canWrite.value) return
  editingRole.value = role
  form.code = role.code
  form.name = role.name
  form.description = role.description
  form.permissionIds = [...role.permissionIds]
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
    const [roleResult, permissionResult] = await Promise.all([listAdminRoles(), listAdminPermissions()])
    roles.value = roleResult
    permissions.value = permissionResult
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminRoles.loadError)
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  if (!canWrite.value || saving.value) return
  if (form.permissionIds.length === 0) {
    errorMessage.value = strings.value.adminRoles.permissionRequired
    return
  }
  saving.value = true
  errorMessage.value = ''
  const payload: AdminRolePayload = {
    code: form.code.trim(),
    name: form.name.trim(),
    description: form.description.trim(),
    permissionIds: [...form.permissionIds],
  }
  try {
    if (editingRole.value) {
      await updateAdminRole(editingRole.value.id, payload)
    } else {
      await createAdminRole(payload)
    }
    dialogOpen.value = false
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminRoles.saveError)
  } finally {
    saving.value = false
  }
}

async function changeStatus(role: AdminRole) {
  if (!canWrite.value || role.code === 'super_admin') {
    return
  }
  const nextStatus = role.status === 1 ? 2 : 1
  const action = nextStatus === 2 ? 'disable' : 'enable'
  if (!window.confirm(strings.value.adminRoles.statusConfirm(role.name, action))) {
    return
  }
  errorMessage.value = ''
  try {
    await updateAdminRoleStatus(role.id, nextStatus)
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminRoles.statusUpdateError)
  }
}

async function removeRole(role: AdminRole) {
  if (!canWrite.value || role.builtIn) {
    return
  }
  if (!window.confirm(strings.value.adminRoles.deleteConfirm(role.name))) {
    return
  }
  errorMessage.value = ''
  try {
    await removeAdminRole(role.id)
    await load()
  } catch (error) {
    errorMessage.value = messageOf(error, strings.value.adminRoles.deleteError)
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <section class="page-section system-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">{{ strings.adminRoles.eyebrow }}</p>
        <h1>{{ strings.adminRoles.heading }}</h1>
        <p>{{ strings.adminRoles.description }}</p>
      </div>
      <div class="header-actions">
        <button v-if="canWrite" type="button" class="primary-button" @click="openCreate">{{ strings.adminRoles.create }}</button>
      </div>
    </header>

    <p v-if="errorMessage && !dialogOpen" class="feedback is-error">{{ errorMessage }}</p>

    <article class="content-card system-table-card">
      <div class="system-table-card__meta">
        <span>{{ loading ? strings.adminRoles.metaLoading : strings.adminRoles.metaSummary(roles.length) }}</span>
        <span>{{ strings.adminRoles.metaDescription }}</span>
      </div>
      <div class="table-shell">
        <table class="data-table">
          <thead>
            <tr>
              <th>{{ strings.adminRoles.tableHeaders.role }}</th>
              <th>{{ strings.adminRoles.tableHeaders.permissions }}</th>
              <th>{{ strings.adminRoles.tableHeaders.admins }}</th>
              <th>{{ strings.adminRoles.tableHeaders.status }}</th>
              <th v-if="canWrite">{{ strings.adminRoles.tableHeaders.actions }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in roles" :key="role.id">
              <td>
                <strong>{{ role.name }}</strong>
                <p class="code-box">{{ role.code }}</p>
              </td>
              <td class="numeric-cell">{{ role.permissionIds.length }}</td>
              <td class="numeric-cell">{{ role.adminCount }}</td>
              <td>
                <span class="status-pill" :class="role.status === 1 ? 'status-pill--good' : 'status-pill--muted'">
                  {{ roleStatusText(role.status) }}
                </span>
              </td>
              <td v-if="canWrite">
                <div class="table-actions">
                  <button type="button" class="table-action" @click="openEdit(role)">{{ strings.adminRoles.edit }}</button>
                  <button
                    :data-testid="`role-status-${role.id}`"
                    type="button"
                    class="table-action"
                    :class="{ 'table-action--danger': role.status === 1 }"
                    :disabled="role.code === 'super_admin'"
                    :title="role.code === 'super_admin' ? strings.adminRoles.superAdminDisabledTitle : ''"
                    @click="changeStatus(role)"
                  >
                    {{ roleStatusAction(role.status) }}
                  </button>
                  <button type="button" class="table-action table-action--danger" :disabled="role.builtIn" @click="removeRole(role)">{{ strings.adminRoles.delete }}</button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && roles.length === 0">
              <td class="table-empty" :colspan="canWrite ? 5 : 4">{{ strings.adminRoles.empty }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </article>

    <div v-if="dialogOpen" class="dialog-backdrop" role="presentation" @click.self="closeDialog">
      <form class="dialog-panel system-dialog system-dialog--wide" data-testid="role-form" @submit.prevent="submitForm">
        <header class="dialog-panel__header">
          <div>
            <p class="eyebrow">{{ strings.adminRoles.formEyebrow }}</p>
            <h2>{{ strings.adminRoles.formHeading(Boolean(editingRole), editingRole?.name) }}</h2>
          </div>
          <button type="button" class="dialog-close" :aria-label="strings.common.cancel" :disabled="saving" @click="closeDialog">×</button>
        </header>

        <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

        <div class="form-grid form-grid--two">
          <label class="field">
            <span>{{ strings.adminRoles.labels.code }}</span>
            <input name="role-code" v-model="form.code" :disabled="Boolean(editingRole?.builtIn)" required />
          </label>
          <label class="field">
            <span>{{ strings.adminRoles.labels.name }}</span>
            <input name="role-name" v-model="form.name" required />
          </label>
          <label class="field field--full">
            <span>{{ strings.adminRoles.labels.description }}</span>
            <input name="role-description" v-model="form.description" />
          </label>
        </div>

        <section class="permission-matrix" :class="{ 'is-readonly': isSuperAdmin }">
          <header class="permission-matrix__header">
            <div>
              <h3>{{ strings.adminRoles.permissionHeading }}</h3>
              <p>{{ strings.adminRoles.permissionDescription }}</p>
            </div>
          </header>
          <div class="permission-matrix__groups">
            <section v-for="group in permissionGroups" :key="group.category" class="permission-group">
              <h4>{{ group.label }}</h4>
              <label v-for="permission in group.items" :key="permission.id" class="permission-option">
                <input
                  :name="`permission-${permission.id}`"
                  v-model="form.permissionIds"
                  type="checkbox"
                  :value="permission.id"
                  :disabled="isSuperAdmin"
                />
                <span><strong>{{ permission.name }}</strong><small>{{ permission.code }}</small></span>
              </label>
            </section>
          </div>
        </section>

        <footer class="form-actions dialog-panel__footer">
          <button type="button" class="ghost-button" :disabled="saving" @click="closeDialog">{{ strings.common.cancel }}</button>
          <button type="submit" class="primary-button" :disabled="saving">{{ saving ? strings.adminRoles.saving : strings.adminRoles.save }}</button>
        </footer>
      </form>
    </div>
  </section>
</template>
