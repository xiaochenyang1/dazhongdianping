import { createRouter, createWebHistory } from 'vue-router'
import { useMerchantSession } from '@/composables/useMerchantSession'
import { fetchSettlementStatus } from '@/services/merchant'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: () => import('@/views/LoginView.vue'), meta: { title: '商户登录' } },
    { path: '/register', component: () => import('@/views/RegisterView.vue'), meta: { title: '商户入驻' } },
    { path: '/settlement', component: () => import('@/views/SettlementView.vue'), meta: { requiresAuth: true, title: '经营资质' } },
    {
      path: '/', component: () => import('@/layouts/MerchantLayout.vue'), meta: { requiresAuth: true },
      children: [
        { path: '', redirect: '/dashboard' },
        { path: 'dashboard', component: () => import('@/views/DashboardView.vue'), meta: { requiresAuth: true, title: '经营概览' } },
        { path: 'shops', component: () => import('@/views/ShopsView.vue'), meta: { requiresAuth: true, title: '门店管理' } },
        { path: 'reservations', component: () => import('@/views/ReservationsView.vue'), meta: { requiresAuth: true, title: '预订处理' } },
        { path: 'deals', component: () => import('@/views/DealsView.vue'), meta: { requiresAuth: true, title: '团购管理' } },
        { path: 'orders', component: () => import('@/views/OrdersView.vue'), meta: { requiresAuth: true, title: '订单退款' } },
      { path: 'reviews', component: () => import('@/views/ReviewsView.vue'), meta: { requiresAuth: true, title: '点评经营' } },
      { path: 'staffs', component: () => import('@/views/StaffsView.vue'), meta: { requiresAuth: true, title: '员工管理' } },
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

router.afterEach((to) => { document.title = `${String(to.meta.title ?? '商户工作台')} | 大众点评` })
export default router
