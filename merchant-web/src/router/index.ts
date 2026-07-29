import { createRouter, createWebHistory } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import {
  merchantStringsForRegion,
  type MerchantRouteTitleKey,
} from '@/core/merchant_localizations'
import { fetchSettlementStatus } from '@/services/merchant'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: () => import('@/views/LoginView.vue'), meta: { titleKey: 'login' } },
    { path: '/register', component: () => import('@/views/RegisterView.vue'), meta: { titleKey: 'register' } },
    { path: '/settlement', component: () => import('@/views/SettlementView.vue'), meta: { requiresAuth: true, titleKey: 'settlement' } },
    {
      path: '/', component: () => import('@/layouts/MerchantLayout.vue'), meta: { requiresAuth: true },
      children: [
        { path: '', redirect: '/dashboard' },
        { path: 'dashboard', component: () => import('@/views/DashboardView.vue'), meta: { requiresAuth: true, titleKey: 'dashboard' } },
        { path: 'shops', component: () => import('@/views/ShopsView.vue'), meta: { requiresAuth: true, titleKey: 'shops' } },
        { path: 'reservations', component: () => import('@/views/ReservationsView.vue'), meta: { requiresAuth: true, titleKey: 'reservations' } },
        { path: 'reservation-slots', component: () => import('@/views/ReservationSlotsView.vue'), meta: { requiresAuth: true, titleKey: 'reservationSlots' } },
        { path: 'deals', component: () => import('@/views/DealsView.vue'), meta: { requiresAuth: true, titleKey: 'deals' } },
        { path: 'orders', component: () => import('@/views/OrdersView.vue'), meta: { requiresAuth: true, titleKey: 'orders' } },
        { path: 'coupons', component: () => import('@/views/CouponsView.vue'), meta: { requiresAuth: true, titleKey: 'coupons' } },
        { path: 'reviews', component: () => import('@/views/ReviewsView.vue'), meta: { requiresAuth: true, titleKey: 'reviews' } },
        { path: 'verified', component: () => import('@/views/VerifiedCertificationView.vue'), meta: { requiresAuth: true, titleKey: 'verified' } },
        { path: 'staffs', component: () => import('@/views/StaffsView.vue'), meta: { requiresAuth: true, titleKey: 'staffs' } },
      ],
    },
  ],
})

router.beforeEach(async (to) => {
  const { state } = useMerchantSession()
  if (to.meta.requiresAuth && !state.token) return { path: '/login', query: { redirect: to.fullPath } }
  if ((to.path === '/login' || to.path === '/register') && state.token) return { path: '/dashboard' }
  if (to.meta.requiresAuth && state.token && to.path !== '/settlement') {
    try {
      const settlement = await fetchSettlementStatus()
      if (settlement.status !== 1) return { path: '/settlement' }
    } catch (error) {
      if (!state.token) return { path: '/login', query: { redirect: to.fullPath } }
      throw error
    }
  }
  return true
})

function routeTitleKey(titleKey: unknown): MerchantRouteTitleKey {
  return typeof titleKey === 'string' ? titleKey as MerchantRouteTitleKey : 'workbench'
}

router.afterEach((to) => {
  const { state } = useMerchantSession()
  const strings = merchantStringsForRegion(state.region)
  const title = strings.routeTitles[routeTitleKey(to.meta.titleKey)]
  document.title = `${title} | ${strings.brand}`
})

export default router
