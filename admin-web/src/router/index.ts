import { createRouter, createWebHistory } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'
import {
  adminRouteTitleKey,
  adminStringsForRegion,
  type AdminRouteTitleKey,
} from '@/core/admin_localizations'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: {
        titleKey: 'login',
      },
    },
    {
      path: '/',
      component: () => import('@/layouts/AdminLayout.vue'),
      meta: {
        requiresAuth: true,
      },
      children: [
        {
          path: '',
          redirect: '/dashboard',
        },
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'dashboard',
          },
        },
        {
          path: 'data/shops',
          name: 'shop-management',
          component: () => import('@/views/ShopManagementView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'shopManagement',
            requiredPermission: 'data:shop:read',
          },
        },
        {
          path: 'data/meta',
          name: 'basic-data-management',
          component: () => import('@/views/BasicDataManagementView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'basicDataManagement',
            requiredPermission: 'data:geo:read',
          },
        },
        {
          path: 'data/orders',
          name: 'data-orders',
          component: () => import('@/views/AdminOrdersView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'dataOrders',
            requiredPermission: 'data:order:read',
          },
        },
        {
          path: 'audit/reviews',
          name: 'audit-reviews',
          component: () => import('@/views/AuditReviewView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditReviews',
            requiredPermission: 'audit:review:read',
          },
        },
        {
          path: 'audit/review-appeals',
          name: 'audit-review-appeals',
          component: () => import('@/views/ReviewAppealAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditReviewAppeals',
            requiredPermission: 'audit:review_appeal:read',
          },
        },
        {
          path: 'audit/posts',
          name: 'audit-posts',
          component: () => import('@/views/PostAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditPosts',
            requiredPermission: 'audit:post:read',
          },
        },
        {
          path: 'audit/expert-certifications',
          name: 'audit-expert-certifications',
          component: () => import('@/views/ExpertCertificationAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditExpertCertifications',
            requiredPermission: 'audit:expert_certification:read',
          },
        },
        {
          path: 'audit/verified-merchants',
          name: 'audit-verified-merchants',
          component: () => import('@/views/VerifiedMerchantAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditVerifiedMerchants',
            requiredPermission: 'audit:merchant_verification:read',
          },
        },
        {
          path: 'audit/reports',
          name: 'audit-reports',
          component: () => import('@/views/ReportManagementView.vue'),
          meta: { requiresAuth: true, titleKey: 'auditReports', requiredPermission: 'audit:report:read' },
        },
        {
          path: 'audit/user-appeals',
          name: 'audit-user-appeals',
          component: () => import('@/views/UserAppealAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditUserAppeals',
            requiredPermission: 'audit:user_appeal:read',
          },
        },
        {
          path: 'audit/merchant-applications',
          name: 'audit-merchant-applications',
          component: () => import('@/views/MerchantApplicationAuditView.vue'),
          meta: { requiresAuth: true, titleKey: 'auditMerchantApplications', requiredPermission: 'audit:merchant_application:read' },
        },
        {
          path: 'audit/shop-changes',
          name: 'audit-shop-changes',
          component: () => import('@/views/ShopChangeAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditShopChanges',
            requiredPermission: 'audit:shop_change:read',
          },
        },
        {
          path: 'audit/deals',
          name: 'audit-deals',
          component: () => import('@/views/DealAuditView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'auditDeals',
            requiredPermission: 'audit:deal:read',
          },
        },
        {
          path: 'data/import',
          name: 'shop-import',
          component: () => import('@/views/ImportView.vue'),
          meta: {
            requiresAuth: true,
            titleKey: 'shopImport',
            requiredPermission: 'data:shop:import',
          },
        },
        {
          path: 'operations/ranks',
          name: 'rank-config',
          component: () => import('@/views/RankConfigView.vue'),
          meta: { requiresAuth: true, titleKey: 'rankConfig', requiredPermission: 'operations:rank:read' },
        },
        { path: 'operations/growth', name: 'growth-config', component: () => import('@/views/GrowthConfigView.vue'), meta: { requiresAuth: true, titleKey: 'growthConfig', requiredPermission: 'operations:growth:read' } },
        { path: 'operations/circles', name: 'circle-management', component: () => import('@/views/CircleManagementView.vue'), meta: { requiresAuth: true, titleKey: 'circleManagement', requiredPermission: 'operations:circle:read' } },
        { path: 'operations/topics', name: 'topic-management', component: () => import('@/views/TopicManagementView.vue'), meta: { requiresAuth: true, titleKey: 'topicManagement', requiredPermission: 'operations:topic:read' } },
        { path: 'operations/banners', name: 'banner-management', component: () => import('@/views/BannerManagementView.vue'), meta: { requiresAuth: true, titleKey: 'bannerManagement', requiredPermission: 'operations:banner:read' } },
        { path: 'operations/hotwords', name: 'hotword-management', component: () => import('@/views/HotWordManagementView.vue'), meta: { requiresAuth: true, titleKey: 'hotwordManagement', requiredPermission: 'operations:hotword:read' } },
        { path: 'operations/sensitive-words', name: 'sensitive-word-management', component: () => import('@/views/SensitiveWordManagementView.vue'), meta: { requiresAuth: true, titleKey: 'sensitiveWordManagement', requiredPermission: 'operations:sensitive_word:read' } },
        { path: 'operations/activities', name: 'activity-management', component: () => import('@/views/OperationActivityManagementView.vue'), meta: { requiresAuth: true, titleKey: 'activityManagement', requiredPermission: 'operations:activity:read' } },
        { path: 'operations/points-products', name: 'points-product-management', component: () => import('@/views/PointsProductManagementView.vue'), meta: { requiresAuth: true, titleKey: 'pointsProductManagement', requiredPermission: 'operations:points:read' } },
        { path: 'operations/points-exchanges', name: 'points-exchange-management', component: () => import('@/views/PointsExchangeManagementView.vue'), meta: { requiresAuth: true, titleKey: 'pointsExchangeManagement', requiredPermission: 'operations:points:read' } },
        {
          path: 'system/admins',
          name: 'system-admins',
          component: () => import('@/views/AdminAccountsView.vue'),
          meta: { requiresAuth: true, titleKey: 'systemAdmins', requiredPermission: 'system:admin:read' },
        },
        {
          path: 'system/roles',
          name: 'system-roles',
          component: () => import('@/views/AdminRolesView.vue'),
          meta: { requiresAuth: true, titleKey: 'systemRoles', requiredPermission: 'system:role:read' },
        },
        {
          path: 'system/users',
          name: 'system-users',
          component: () => import('@/views/UserManagementView.vue'),
          meta: { requiresAuth: true, titleKey: 'systemUsers', requiredPermission: 'system:user:read' },
        },
        {
          path: 'system/audit-logs',
          name: 'system-audit-logs',
          component: () => import('@/views/AdminAuditLogsView.vue'),
          meta: { requiresAuth: true, titleKey: 'systemAuditLogs', requiredPermission: 'system:audit_log:read' },
        },
        {
          path: 'system/privacy-tasks',
          name: 'system-privacy-tasks',
          component: () => import('@/views/AdminPrivacyTasksView.vue'),
          meta: { requiresAuth: true, titleKey: 'systemPrivacyTasks', requiredPermission: 'system:privacy_task:read' },
        },
      ],
    },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

router.beforeEach((to) => {
  const { state } = useAdminSession()

  if (to.meta.requiresAuth && !state.token) {
    return {
      name: 'login',
      query: {
        redirect: to.fullPath,
      },
    }
  }

  const requiredPermission = typeof to.meta.requiredPermission === 'string'
    ? to.meta.requiredPermission
    : undefined
  if (requiredPermission && !state.permissions.includes(requiredPermission)) {
    return { name: 'dashboard' }
  }

  if (to.name === 'login' && state.token) {
    return { name: 'dashboard' }
  }

  return true
})

function routeTitleKey(titleKey: unknown): AdminRouteTitleKey {
  return adminRouteTitleKey(titleKey)
}

router.afterEach((to) => {
  const { state } = useAdminSession()
  const strings = adminStringsForRegion(state.region)
  const title = strings.routeTitles[routeTitleKey(to.meta.titleKey)]
  document.title = `${title} | ${strings.brand}`
})

export default router
