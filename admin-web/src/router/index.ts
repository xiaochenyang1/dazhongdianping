import { createRouter, createWebHistory } from 'vue-router'
import { useAdminSession } from '@/composables/useAdminSession'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: {
        title: '管理员登录',
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
            title: '控制台',
          },
        },
        {
          path: 'data/shops',
          name: 'shop-management',
          component: () => import('@/views/ShopManagementView.vue'),
          meta: {
            requiresAuth: true,
            title: '商户管理',
            requiredPermission: 'data:shop:read',
          },
        },
        {
          path: 'data/meta',
          name: 'basic-data-management',
          component: () => import('@/views/BasicDataManagementView.vue'),
          meta: {
            requiresAuth: true,
            title: '基础数据',
            requiredPermission: 'data:geo:read',
          },
        },
        {
          path: 'data/orders',
          name: 'data-orders',
          component: () => import('@/views/AdminOrdersView.vue'),
          meta: {
            requiresAuth: true,
            title: '订单退款',
            requiredPermission: 'data:order:read',
          },
        },
        {
          path: 'audit/reviews',
          name: 'audit-reviews',
          component: () => import('@/views/AuditReviewView.vue'),
          meta: {
            requiresAuth: true,
            title: '点评审核',
            requiredPermission: 'audit:review:read',
          },
        },
        {
          path: 'audit/review-appeals',
          name: 'audit-review-appeals',
          component: () => import('@/views/ReviewAppealAuditView.vue'),
          meta: {
            requiresAuth: true,
            title: '商户点评申诉',
            requiredPermission: 'audit:review_appeal:read',
          },
        },
        {
          path: 'audit/posts',
          name: 'audit-posts',
          component: () => import('@/views/PostAuditView.vue'),
          meta: {
            requiresAuth: true,
            title: '帖子审核',
            requiredPermission: 'audit:post:read',
          },
        },
        {
          path: 'audit/expert-certifications',
          name: 'audit-expert-certifications',
          component: () => import('@/views/ExpertCertificationAuditView.vue'),
          meta: {
            requiresAuth: true,
            title: '达人认证',
            requiredPermission: 'audit:expert_certification:read',
          },
        },
        {
          path: 'audit/merchant-applications',
          name: 'audit-merchant-applications',
          component: () => import('@/views/MerchantApplicationAuditView.vue'),
          meta: { requiresAuth: true, title: '商户资质审核', requiredPermission: 'audit:merchant_application:read' },
        },
        {
          path: 'data/import',
          name: 'shop-import',
          component: () => import('@/views/ImportView.vue'),
          meta: {
            requiresAuth: true,
            title: '种子导入',
            requiredPermission: 'data:shop:import',
          },
        },
        {
          path: 'operations/ranks',
          name: 'rank-config',
          component: () => import('@/views/RankConfigView.vue'),
          meta: { requiresAuth: true, title: '榜单规则', requiredPermission: 'operations:rank:read' },
        },
        { path: 'operations/growth', name: 'growth-config', component: () => import('@/views/GrowthConfigView.vue'), meta: { requiresAuth: true, title: '成长规则', requiredPermission: 'operations:growth:read' } },
        { path: 'operations/circles', name: 'circle-management', component: () => import('@/views/CircleManagementView.vue'), meta: { requiresAuth: true, title: '官方圈子', requiredPermission: 'operations:circle:read' } },
        { path: 'operations/topics', name: 'topic-management', component: () => import('@/views/TopicManagementView.vue'), meta: { requiresAuth: true, title: '话题治理', requiredPermission: 'operations:topic:read' } },
        {
          path: 'system/admins',
          name: 'system-admins',
          component: () => import('@/views/AdminAccountsView.vue'),
          meta: { requiresAuth: true, title: '管理员账号', requiredPermission: 'system:admin:read' },
        },
        {
          path: 'system/roles',
          name: 'system-roles',
          component: () => import('@/views/AdminRolesView.vue'),
          meta: { requiresAuth: true, title: '角色与权限', requiredPermission: 'system:role:read' },
        },
        {
          path: 'system/audit-logs',
          name: 'system-audit-logs',
          component: () => import('@/views/AdminAuditLogsView.vue'),
          meta: { requiresAuth: true, title: '审计日志', requiredPermission: 'system:audit_log:read' },
        },
        {
          path: 'system/privacy-tasks',
          name: 'system-privacy-tasks',
          component: () => import('@/views/AdminPrivacyTasksView.vue'),
          meta: { requiresAuth: true, title: '隐私任务', requiredPermission: 'system:privacy_task:read' },
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

router.afterEach((to) => {
  const title = typeof to.meta.title === 'string' ? to.meta.title : '管理端'
  document.title = `${title} | 大众点评后台`
})

export default router
