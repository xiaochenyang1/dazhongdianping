import { createRouter, createWebHistory } from 'vue-router'
import { useUserSession } from '@/composables/useUserSession'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
      meta: {
        title: '首页',
        description: '大众点评仿站首页，浏览本地生活推荐、精选门店和城市频道。',
      },
    },
    {
      path: '/shops',
      name: 'shop-list',
      component: () => import('@/views/ShopListView.vue'),
      meta: {
        title: '商户列表',
        description: '按城市、分类和商圈筛选本地生活商户。',
      },
    },
    {
      path: '/ranks',
      name: 'rank-list',
      component: () => import('@/views/RankListView.vue'),
      meta: { title: '城市榜单', description: '浏览按城市和分类发布的必吃榜、好评榜与热门榜。' },
    },
    { path: '/community', name: 'community', component: () => import('@/views/CommunityView.vue'), meta: { title: '华人社区', description: '只读浏览欧洲华人攻略、探店和生活经验。' } },
    { path: '/community/posts/:id', name: 'community-post', component: () => import('@/views/PostDetailView.vue'), props: r => ({ postId: Number(r.params.id) }), meta: { title: '社区帖子', description: '阅读公开社区帖子与评论。' } },
    { path: '/groups', name: 'circle-list', component: () => import('@/views/CircleListView.vue'), meta: { title: '官方圈子', description: '只读浏览当前区域官方社区圈子。' } },
    { path: '/groups/:id', name: 'circle-detail', component: () => import('@/views/CircleDetailView.vue'), props: r => ({ circleId: Number(r.params.id) }), meta: { title: '圈子详情', description: '查看官方圈子资料和公开帖子。' } },
    { path: '/topics', name: 'topic-list', component: () => import('@/views/TopicListView.vue'), meta: { title: '话题广场', description: '浏览当前区域推荐话题与最近 7 天热榜。' } },
    { path: '/topics/:id', name: 'topic-detail', component: () => import('@/views/TopicDetailView.vue'), props: r => ({ topicId: Number(r.params.id) }), meta: { title: '话题详情', description: '查看话题热度构成和公开社区帖子。' } },
    {
      path: '/ranks/:id',
      name: 'rank-detail',
      component: () => import('@/views/RankDetailView.vue'),
      props: (route) => ({ rankId: Number(route.params.id) }),
      meta: { title: '榜单详情', description: '查看榜单发布快照、门店排名和入榜理由。' },
    },
    {
      path: '/shops/:id',
      name: 'shop-detail',
      component: () => import('@/views/ShopDetailView.vue'),
      props: true,
      meta: {
        title: '商户详情',
        description: '查看商户基础信息、相册、推荐菜和公开点评。',
      },
    },
    { path: '/deals/:id', name: 'deal-detail', component: () => import('@/views/DealDetailView.vue'), props: r => ({ dealId: Number(r.params.id) }), meta: { title: '团购详情', description: '查看团购内容、有效期、使用规则并下单。' } },
    { path: '/shops/:id/reserve', name: 'reservation-create', component: () => import('@/views/ReservationCreateView.vue'), props: r => ({ shopId: Number(r.params.id) }), meta: { requiresAuth: true, title: '在线预订', description: '查询门店可订时段并提交预订。' } },
    {
      path: '/shops/:id/reviews',
      name: 'shop-reviews',
      component: () => import('@/views/ShopReviewsView.vue'),
      props: (route) => ({
        shopId: Number(route.params.id),
      }),
      meta: {
        title: '门店点评',
        description: '查看门店公开点评列表、评分和互动计数。',
      },
    },
    {
      path: '/shops/:id/reviews/new',
      name: 'review-create',
      component: () => import('@/views/ReviewEditorView.vue'),
      props: (route) => ({
        shopId: Number(route.params.id),
      }),
      meta: {
        requiresAuth: true,
        title: '写点评',
        description: '发布门店点评，提交评分、正文、标签和图片。',
      },
    },
    {
      path: '/reviews/:id',
      name: 'review-detail',
      component: () => import('@/views/ReviewDetailView.vue'),
      props: (route) => ({
        reviewId: Number(route.params.id),
        owned: false,
      }),
      meta: {
        title: '点评详情',
        description: '查看公开点评详情、图片、点赞、评论和举报入口。',
      },
    },
    {
      path: '/reviews/:id/edit',
      name: 'review-edit',
      component: () => import('@/views/ReviewEditorView.vue'),
      props: (route) => ({
        reviewId: Number(route.params.id),
      }),
      meta: {
        requiresAuth: true,
        title: '编辑点评',
        description: '编辑我的点评并重新提交审核。',
      },
    },
    {
      path: '/user/reviews',
      name: 'my-reviews',
      component: () => import('@/views/MyReviewsView.vue'),
      meta: {
        requiresAuth: true,
        title: '我的点评',
        description: '管理我发布过的点评和审核状态。',
      },
    },
    {
      path: '/user/favorites',
      name: 'user-favorites',
      component: () => import('@/views/FavoritesView.vue'),
      meta: { requiresAuth: true, title: '我的收藏', description: '查看和管理当前用户收藏的门店。' },
    },
    { path: '/user/orders', name: 'user-orders', component: () => import('@/views/OrdersView.vue'), meta: { requiresAuth: true, title: '我的订单', description: '查看团购订单及支付退款状态。' } },
    { path: '/user/orders/:id', name: 'user-order-detail', component: () => import('@/views/OrderDetailView.vue'), props: r => ({ orderId: Number(r.params.id) }), meta: { requiresAuth: true, title: '订单详情', description: '查看订单、支付和券码信息。' } },
    { path: '/user/coupons', name: 'user-coupons', component: () => import('@/views/CouponsView.vue'), meta: { requiresAuth: true, title: '我的券', description: '查看待使用、已使用、过期和退款券码。' } },
    { path: '/user/reservations', name: 'user-reservations', component: () => import('@/views/ReservationsView.vue'), meta: { requiresAuth: true, title: '我的预订', description: '查看预订状态和改期记录。' } },
    { path: '/user/reservations/:id', name: 'user-reservation-detail', component: () => import('@/views/ReservationDetailView.vue'), props: r => ({ reservationId: Number(r.params.id) }), meta: { requiresAuth: true, title: '预订详情', description: '查看、取消或改期预订。' } },
    {
      path: '/user/reviews/:id',
      name: 'my-review-detail',
      component: () => import('@/views/ReviewDetailView.vue'),
      props: (route) => ({
        reviewId: Number(route.params.id),
        owned: true,
      }),
      meta: {
        requiresAuth: true,
        title: '我的点评详情',
        description: '查看我的点评详情、审核状态和驳回原因。',
      },
    },
    {
      path: '/user/profile',
      name: 'user-profile',
      component: () => import('@/views/ProfileView.vue'),
      meta: {
        requiresAuth: true,
        title: '我的资料',
        description: '查看和修改个人资料、账号绑定和登录密码。',
      },
    },
    {
      path: '/user/growth-records',
      name: 'user-growth-records',
      component: () => import('@/views/UserGrowthRecordsView.vue'),
      meta: {
        requiresAuth: true,
        title: '成长值流水',
        description: '查看成长值和积分流水，确认每一笔奖励从哪来、落到哪。',
      },
    },
    {
      path: '/user/privacy',
      name: 'user-privacy',
      component: () => import('@/views/PrivacyCenterView.vue'),
      meta: {
        requiresAuth: true,
        title: '隐私中心',
        description: '导出个人数据，管理账号删除申请和冷静期撤销。',
      },
    },
    {
      path: '/users/:id',
      name: 'public-user-profile',
      component: () => import('@/views/PublicUserProfileView.vue'),
      props: (route) => ({
        userId: Number(route.params.id),
      }),
      meta: {
        title: '用户主页',
        description: '查看公开用户资料和点评概览。',
      },
    },
    { path: '/users/:id/followers', name: 'public-user-followers', component: () => import('@/views/UserRelationshipsView.vue'), props: route => ({ userId: Number(route.params.id), mode: 'followers' }), meta: { title: '用户粉丝', description: '只读查看用户公开粉丝列表。' } },
    { path: '/users/:id/following', name: 'public-user-following', component: () => import('@/views/UserRelationshipsView.vue'), props: route => ({ userId: Number(route.params.id), mode: 'following' }), meta: { title: '用户关注', description: '只读查看用户公开关注列表。' } },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

router.beforeEach((to, from) => {
  const { state, openAuthDialog } = useUserSession()

  if (to.meta.requiresAuth && !state.accessToken) {
    openAuthDialog({
      mode: 'password',
      redirectTo: to.fullPath,
    })

    if (from.matched.length > 0) {
      return false
    }

    return { name: 'home' }
  }

  return true
})

router.afterEach((to) => {
  const title = typeof to.meta.title === 'string' ? to.meta.title : '大众点评(仿)'
  const description =
    typeof to.meta.description === 'string'
      ? to.meta.description
      : '大众点评仿站本地生活平台，支持商户浏览、点评、审核和用户中心。'
  document.title = `${title} | 大众点评(仿)`
  let descriptionTag = document.querySelector('meta[name="description"]')
  if (!descriptionTag) {
    descriptionTag = document.createElement('meta')
    descriptionTag.setAttribute('name', 'description')
    document.head.appendChild(descriptionTag)
  }
  descriptionTag.setAttribute('content', description)
})

export default router
