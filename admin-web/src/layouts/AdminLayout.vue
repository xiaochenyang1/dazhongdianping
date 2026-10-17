<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  adminMenuLabel,
  adminRouteTitleKey,
  adminStringsForRegion,
} from '@/core/admin_localizations'
import { fetchAdminMe, fetchAdminMenus, getModerationQueueMetrics, logoutAdmin } from '@/services/admin'
import type { AdminAuditQueueMetric, AdminMenuItem, Region } from '@/types/admin'

const route = useRoute()
const router = useRouter()
const { state, clearSession, setRegion, updateIdentity } = useAdminSession()

const strings = computed(() => adminStringsForRegion(state.region))
const menus = ref<AdminMenuItem[]>([])
const loadingMenus = ref(false)
const errorMessage = ref('')
const identityReady = ref(false)
const moderationMetrics = ref<AdminAuditQueueMetric[]>([])
let hydrationRequestId = 0

const pageTitle = computed(() => strings.value.routeTitles[adminRouteTitleKey(route.meta.titleKey)])
const availableRegions = computed<Region[]>(() => state.regions.length > 0 ? state.regions : ['CN', 'EU'])
const canReadModeration = computed(() => state.permissions.includes('audit:automod:read'))
const moderationOverdueCount = computed(() => moderationMetrics.value.reduce((total, metric) => total + metric.overdueCount, 0))

async function refreshModerationAlerts() {
  if (!state.token || !canReadModeration.value) {
    moderationMetrics.value = []
    return
  }
  const token = state.token
  const region = state.region
  try {
    const latestMetrics = await getModerationQueueMetrics()
    if (state.token === token && state.region === region && canReadModeration.value) {
      moderationMetrics.value = latestMetrics
    }
  } catch {
    return
  }
}

function localizedMenuLabel(item: AdminMenuItem) {
  return adminMenuLabel(strings.value, item)
}

function regionOptionLabel(region: Region) {
  return `${region} · ${strings.value.common.regionLabel(region)}`
}

async function loadMenus() {
  const requestId = ++hydrationRequestId
  const token = state.token
  const fullPath = route.fullPath
  const isCurrentHydration = () => requestId === hydrationRequestId
    && state.token === token
    && route.fullPath === fullPath

  menus.value = []
  identityReady.value = false
  loadingMenus.value = true
  errorMessage.value = ''

  if (!state.token) {
    loadingMenus.value = false
    if (route.path !== '/login') {
      await router.replace('/login')
    }
    return
  }

  try {
    const identity = await fetchAdminMe()
    if (!isCurrentHydration()) {
      return
    }
    updateIdentity(identity)

    const requiredPermission = typeof route.meta.requiredPermission === 'string'
      ? route.meta.requiredPermission
      : undefined
    if (requiredPermission && !state.permissions.includes(requiredPermission)) {
      await router.replace('/dashboard')
      return
    }

    const loadedMenus = await fetchAdminMenus()
    if (!isCurrentHydration()) {
      return
    }
    menus.value = loadedMenus
    identityReady.value = true
  } catch (error) {
    if (isCurrentHydration()) {
      menus.value = []
      errorMessage.value = error instanceof Error ? error.message : strings.value.shell.menuLoadError
      identityReady.value = false
    }

    if (!state.token) {
      await router.replace('/login')
    }
  } finally {
    if (isCurrentHydration()) {
      loadingMenus.value = false
    }
  }
}

function isActive(path: string) {
  return route.path === path || route.path.startsWith(`${path}/`)
}

async function handleLogout() {
  await logoutAdmin().catch(() => undefined)
  clearSession()
  await router.replace('/login')
}

watch(
  () => [state.token, route.fullPath],
  () => {
    void loadMenus()
  },
  { immediate: true },
)

watch(() => [state.token, state.region, canReadModeration.value], () => {
  moderationMetrics.value = []
  void refreshModerationAlerts()
}, { immediate: true })

let alertRefreshTimer: number | undefined
onMounted(() => {
  alertRefreshTimer = window.setInterval(() => void refreshModerationAlerts(), 60_000)
})
onUnmounted(() => {
  if (alertRefreshTimer !== undefined) window.clearInterval(alertRefreshTimer)
})
</script>

<template>
  <div class="admin-shell">
    <aside class="admin-sidebar">
      <div class="brand-block">
        <p class="eyebrow">{{ strings.shell.appEyebrow }}</p>
        <h1>{{ strings.shell.appHeading }}</h1>
        <p>{{ strings.shell.appDescription }}</p>
      </div>

      <nav class="menu-groups" :aria-label="strings.shell.menuAriaLabel">
        <p v-if="loadingMenus" class="feedback">{{ strings.shell.menuLoading }}</p>

        <template v-else>
          <section v-for="menu in menus" :key="menu.code" class="menu-group">
            <p class="menu-group__title">{{ localizedMenuLabel(menu) }}</p>

            <RouterLink
              v-if="menu.children.length === 0"
              :to="menu.path"
              class="menu-link"
              :class="{ 'is-active': isActive(menu.path) }"
            >
              {{ localizedMenuLabel(menu) }}
            </RouterLink>

            <RouterLink
              v-for="child in menu.children"
              :key="child.code"
              :to="child.path"
              class="menu-link"
              :class="{ 'is-active': isActive(child.path) }"
            >
              {{ localizedMenuLabel(child) }}
            </RouterLink>
          </section>
        </template>
      </nav>

      <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    </aside>

    <div class="admin-main">
      <header class="admin-topbar">
        <div>
          <p class="eyebrow">{{ strings.shell.currentPageEyebrow }}</p>
          <h2>{{ pageTitle }}</h2>
        </div>

        <div class="topbar-actions">
          <RouterLink v-if="canReadModeration" to="/audit/sla-alerts" class="sla-nav-alert">
            {{ moderationOverdueCount > 0 ? `超时待审 ${moderationOverdueCount} · 查看记录` : '审核提醒记录' }}
          </RouterLink>
          <label class="compact-field">
            <span>{{ strings.shell.regionLabel }}</span>
            <select :value="state.region" @change="setRegion(($event.target as HTMLSelectElement).value as Region)">
              <option v-for="region in availableRegions" :key="region" :value="region">{{ regionOptionLabel(region) }}</option>
            </select>
          </label>

          <div class="topbar-profile">
            <strong>{{ state.profile?.name ?? strings.shell.loggedOutName }}</strong>
            <span>{{ state.profile?.account ?? strings.shell.unknownAccount }}</span>
          </div>

          <button type="button" class="ghost-button" @click="handleLogout">{{ strings.shell.logout }}</button>
        </div>
      </header>

      <main class="page-shell">
        <RouterView v-if="identityReady" />
        <p v-else-if="state.token" class="feedback">{{ strings.shell.identityLoading }}</p>
      </main>
    </div>
  </div>
</template>

<style scoped>
.sla-nav-alert {
  color: #b42318;
  font-weight: 700;
  white-space: nowrap;
}
</style>
