<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import {
  merchantStringsForRegion,
  type MerchantRouteTitleKey,
} from '@/core/merchant_localizations'
import { fetchAccount } from '@/services/merchant'

const route = useRoute()
const router = useRouter()
const { state, clearSession } = useMerchantSession()
const strings = computed(() => merchantStringsForRegion(state.region))
const title = computed(() => {
  const titleKey = typeof route.meta.titleKey === 'string'
    ? route.meta.titleKey as MerchantRouteTitleKey
    : 'workbench'
  return strings.value.routeTitles[titleKey]
})
const permissions = ref<string[]>([])
const baseLinks = computed(() => [
  { path: '/dashboard', label: strings.value.routeTitles.dashboard, permission: 'dashboard:view' },
  { path: '/shops', label: strings.value.routeTitles.shops, permission: 'shop:view' },
  { path: '/reservations', label: strings.value.routeTitles.reservations, permission: 'reservation:view' },
  { path: '/reservation-slots', label: strings.value.routeTitles.reservationSlots, permission: 'reservation:view' },
  { path: '/deals', label: strings.value.routeTitles.deals, permission: 'deal:edit' },
  { path: '/orders', label: strings.value.routeTitles.orders, permission: 'order:view' },
  { path: '/coupons', label: strings.value.routeTitles.coupons, permission: 'coupon:verify' },
  { path: '/reviews', label: strings.value.routeTitles.reviews, permission: 'shop:view' },
  { path: '/verified', label: strings.value.routeTitles.verified, permission: 'merchant:verify' },
  { path: '/staffs', label: strings.value.routeTitles.staffs, permission: 'staff:manage' },
])
const links = computed(() => baseLinks.value.filter((link) => permissions.value.includes(link.permission)))

function logout() {
  clearSession()
  void router.replace('/login')
}

onMounted(async () => {
  try {
    permissions.value = (await fetchAccount()).permissions
  } catch {
    permissions.value = []
  }
})
</script>

<template>
  <div class="shell">
    <aside class="sidebar">
      <p class="eyebrow">{{ strings.shell.workbenchEyebrow }}</p>
      <h1>{{ strings.brand }}</h1>
      <nav>
        <RouterLink
          v-for="link in links"
          :key="link.path"
          :to="link.path"
          :class="{ active: route.path === link.path }"
        >
          {{ link.label }}
        </RouterLink>
      </nav>
    </aside>

    <section class="main">
      <header>
        <div>
          <p class="eyebrow">{{ strings.shell.currentPageEyebrow }}</p>
          <h2>{{ title }}</h2>
        </div>
        <div class="actions">
          <span data-testid="merchant-fixed-region">
            {{ state.region }} · {{ strings.common.regionLabel(state.region) }}
          </span>
          <span>{{ state.account }}</span>
          <button class="ghost" @click="logout">{{ strings.shell.logout }}</button>
        </div>
      </header>
      <main class="page"><RouterView :permissions="permissions" /></main>
    </section>
  </div>
</template>
