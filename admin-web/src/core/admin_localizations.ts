import type { Region } from '@/types/admin'

export type AdminLocaleTag = 'zh-CN' | 'en'

export interface AdminStrings {
  tag: AdminLocaleTag
  brand: string
  common: {
    requestFailed: string
    loading: string
    refresh: string
    cancel: string
    regionLabel: (region: Region) => string
  }
  routeTitles: {
    workbench: string
    login: string
    dashboard: string
    shopManagement: string
    basicDataManagement: string
    dataOrders: string
    auditReviews: string
    auditReviewAppeals: string
    auditPosts: string
    auditExpertCertifications: string
    auditVerifiedMerchants: string
    auditReports: string
    auditUserAppeals: string
    auditMerchantApplications: string
    auditShopChanges: string
    auditDeals: string
    shopImport: string
    rankConfig: string
    growthConfig: string
    circleManagement: string
    topicManagement: string
    bannerManagement: string
    hotwordManagement: string
    sensitiveWordManagement: string
    activityManagement: string
    systemAdmins: string
    systemRoles: string
    systemUsers: string
    systemAuditLogs: string
    systemPrivacyTasks: string
  }
  menuGroups: {
    data: string
    audit: string
    operations: string
    system: string
  }
  shell: {
    appEyebrow: string
    appHeading: string
    appDescription: string
    menuAriaLabel: string
    menuLoading: string
    currentPageEyebrow: string
    regionLabel: string
    loggedOutName: string
    unknownAccount: string
    logout: string
    identityLoading: string
    menuLoadError: string
  }
  auth: {
    brandEyebrow: string
    brandHeading: string
    heroTitle: string
    heroDescription: string
    ribbonRegion: (region: Region) => string
    ribbonDatabaseRbac: string
    ribbonLivePermissions: string
    spotlightCredentialsLabel: string
    spotlightCredentialsValue: string
    spotlightCredentialsDetail: string
    spotlightRegionScopeLabel: string
    spotlightRegionScopeValue: (region: Region) => string
    spotlightRegionScopeDetail: string
    spotlightAuthModelLabel: string
    spotlightAuthModelValue: string
    spotlightAuthModelDetail: string
    entryTargetRouteLabel: string
    entrySessionModeLabel: string
    entrySessionModeValue: string
    entryRegionPerspectiveLabel: string
    noteRegionScopeTitle: string
    noteRegionScopeDetail: string
    noteLivePermissionsTitle: string
    noteLivePermissionsDetail: string
    noteAdminRbacTitle: string
    noteAdminRbacDetail: string
    formEyebrow: string
    formHeading: string
    formBadge: string
    formSummary: (target: string) => string
    regionFieldLabel: string
    regionOptionCn: string
    regionOptionEu: string
    accountLabel: string
    accountPlaceholder: string
    passwordLabel: string
    passwordPlaceholder: string
    loginError: string
    loginSubmitting: string
    loginButton: string
    footerText: string
    footerChips: [string, string, string]
  }
  dashboard: {
    eyebrow: string
    heading: (region: Region) => string
    description: string
    loadError: string
    loading: string
    noData: string
    headerActions: {
      manageShops: string
      importShops: string
      viewOrders: string
    }
    metrics: {
      shopCount: {
        label: string
        note: (region: Region) => string
      }
      importBatchCount: {
        label: string
        note: string
      }
      paidOrderCount: {
        label: string
        note: string
      }
      pendingRefundCount: {
        label: string
        note: string
      }
      pendingAuditTaskCount: {
        label: string
        note: string
      }
      userCount: {
        label: string
        note: string
      }
    }
    quickLinks: {
      eyebrow: string
      heading: string
      pendingDeals: {
        label: string
        note: string
      }
      pendingShopChanges: {
        label: string
        note: string
      }
      pendingReviews: {
        label: string
        note: string
      }
      pendingPosts: {
        label: string
        note: string
      }
      pendingRefunds: {
        label: string
        note: string
      }
    }
    recentShops: {
      eyebrow: string
      heading: string
      viewAll: string
      empty: string
      openNow: string
      closed: string
    }
    recentBatches: {
      eyebrow: string
      heading: string
      viewAll: string
      empty: string
      batchSummary: (success: number, failed: number, total: number) => string
      statusText: (status: number, fallback?: string) => string
    }
    pendingAudit: {
      eyebrow: string
      heading: string
      empty: string
      bizTypeLabels: {
        deals: string
        reviews: string
        posts: string
        shopChanges: string
        reviewAppeals: string
        expertCertifications: string
        userAppeals: string
        verifiedMerchants: string
      }
      fallbackLabel: (bizType: number) => string
      detailsNote: (bizType: number) => string
      countSummary: (count: number) => string
    }
  }
  auditLogs: {
    eyebrow: string
    heading: string
    description: string
    loadError: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    labels: {
      adminId: string
      action: string
      target: string
      keyword: string
    }
    placeholders: {
      adminId: string
      action: string
      target: string
      keyword: string
    }
    applyFilters: string
    tableHeaders: {
      time: string
      operator: string
      action: string
      target: string
      detail: string
      ip: string
    }
    loadingRow: string
    empty: string
    systemFallback: string
    detailFallback: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
  }
  adminOrders: {
    eyebrow: string
    heading: string
    description: (region: Region) => string
    reconcileRunning: string
    reconcileRun: string
    loadError: string
    auditReasonRequired: string
    auditSubmitError: string
    reconcileError: string
    auditNotice: (orderNo: string, decision: 'approve' | 'reject') => string
    reconcileNotice: (closedOrders: number, restoredStockOrders: number, failedPayments: number) => string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    filters: {
      merchantId: string
      shopId: string
      userId: string
      payStatus: string
      refundStatus: string
      orderNo: string
      dateFrom: string
      dateTo: string
    }
    placeholders: {
      merchantId: string
      shopId: string
      userId: string
      orderNo: string
      auditReason: string
    }
    payStatusOptions: {
      all: string
      pending: string
      paid: string
      refunded: string
      partialRefund: string
    }
    refundStatusOptions: {
      all: string
      pending: string
      success: string
      rejected: string
    }
    applyFilters: string
    tableHeaders: {
      time: string
      order: string
      merchantShop: string
      user: string
      amount: string
      payment: string
      refund: string
      actions: string
    }
    dealFallback: (dealId: number) => string
    merchantFallback: (merchantId: number) => string
    shopFallback: (shopId: number) => string
    userFallback: (userId: number) => string
    amountSummary: (quantity: number, unitPrice: number) => string
    paymentChannelFallback: string
    noRefundRequest: string
    noReason: string
    payStatusText: (status: number, fallback?: string) => string
    refundStatusText: (status: number, fallback?: string) => string
    refundSummary: (statusText: string, reason: string) => string
    noRefund: string
    paidAt: (paidAt: string) => string
    auditRemarkLabel: (reason: string) => string
    refundArbitration: string
    approveRefund: string
    rejectRefund: string
    noPendingRefund: string
    loadingRow: string
    empty: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
  }
  privacyTasks: {
    eyebrow: string
    heading: string
    description: string
    loadError: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    labels: {
      userId: string
      taskType: string
      status: string
      keyword: string
    }
    placeholders: {
      userId: string
      keyword: string
    }
    taskTypeOptions: {
      all: string
      export: string
      delete: string
    }
    statusOptions: {
      all: string
      exportPending: string
      exportProcessing: string
      exportReady: string
      exportExpired: string
      exportFailed: string
      exportCancelled: string
      deletePendingConfirm: string
      deleteCoolingOff: string
      deleteProcessing: string
      deleteCompleted: string
      deleteCancelled: string
      deleteRejected: string
      mixed0: string
      mixed1: string
      mixed2: string
      mixed3: string
      mixed4: string
      mixed5: string
    }
    applyFilters: string
    tableHeaders: {
      time: string
      task: string
      user: string
      status: string
      keyInfo: string
      deadline: string
    }
    loadingRow: string
    empty: string
    taskTypeText: (taskType: number, fallback?: string) => string
    taskStatusText: (taskType: number, status: number, fallback?: string) => string
    allModules: string
    noReason: string
    deadlineFallback: string
    exportFilePending: string
    verificationMethod: (method: string) => string
    previousPage: string
    page: (page: number) => string
    nextPage: string
  }
}

export type AdminRouteTitleKey = keyof AdminStrings['routeTitles']

const ROUTE_TITLE_KEYS: Partial<Record<string, AdminRouteTitleKey>> = {
  '/login': 'login',
  '/dashboard': 'dashboard',
  '/data/shops': 'shopManagement',
  '/data/meta': 'basicDataManagement',
  '/data/orders': 'dataOrders',
  '/audit/reviews': 'auditReviews',
  '/audit/review-appeals': 'auditReviewAppeals',
  '/audit/posts': 'auditPosts',
  '/audit/expert-certifications': 'auditExpertCertifications',
  '/audit/verified-merchants': 'auditVerifiedMerchants',
  '/audit/reports': 'auditReports',
  '/audit/user-appeals': 'auditUserAppeals',
  '/audit/merchant-applications': 'auditMerchantApplications',
  '/audit/shop-changes': 'auditShopChanges',
  '/audit/deals': 'auditDeals',
  '/data/import': 'shopImport',
  '/operations/ranks': 'rankConfig',
  '/operations/growth': 'growthConfig',
  '/operations/circles': 'circleManagement',
  '/operations/topics': 'topicManagement',
  '/operations/banners': 'bannerManagement',
  '/operations/hotwords': 'hotwordManagement',
  '/operations/sensitive-words': 'sensitiveWordManagement',
  '/operations/activities': 'activityManagement',
  '/system/admins': 'systemAdmins',
  '/system/roles': 'systemRoles',
  '/system/users': 'systemUsers',
  '/system/audit-logs': 'systemAuditLogs',
  '/system/privacy-tasks': 'systemPrivacyTasks',
}

const MENU_GROUP_KEYS = {
  data: 'data',
  audit: 'audit',
  operations: 'operations',
  system: 'system',
} as const

const zhCnStrings: AdminStrings = {
  tag: 'zh-CN',
  brand: '大众点评后台',
  common: {
    requestFailed: '请求失败',
    loading: '加载中...',
    refresh: '刷新',
    cancel: '取消',
    regionLabel: (region) => region === 'EU' ? '欧洲' : '中国大陆',
  },
  routeTitles: {
    workbench: '管理端',
    login: '管理员登录',
    dashboard: '控制台',
    shopManagement: '商户管理',
    basicDataManagement: '基础数据',
    dataOrders: '订单退款',
    auditReviews: '点评审核',
    auditReviewAppeals: '商户点评申诉',
    auditPosts: '帖子审核',
    auditExpertCertifications: '达人认证',
    auditVerifiedMerchants: '认证商户',
    auditReports: '内容举报',
    auditUserAppeals: '用户封禁申诉',
    auditMerchantApplications: '商户资质审核',
    auditShopChanges: '门店草稿审核',
    auditDeals: '团购审核',
    shopImport: '种子导入',
    rankConfig: '榜单规则',
    growthConfig: '成长规则',
    circleManagement: '官方圈子',
    topicManagement: '话题治理',
    bannerManagement: 'Banner 配置',
    hotwordManagement: '搜索热词',
    sensitiveWordManagement: '敏感词库',
    activityManagement: '运营活动',
    systemAdmins: '管理员账号',
    systemRoles: '角色与权限',
    systemUsers: '用户管理',
    systemAuditLogs: '审计日志',
    systemPrivacyTasks: '隐私任务',
  },
  menuGroups: {
    data: '数据',
    audit: '审核',
    operations: '运营',
    system: '系统',
  },
  shell: {
    appEyebrow: '运营后台',
    appHeading: '大众点评运营控制台',
    appDescription: '账户、角色和区域范围由服务端实时核验，页面菜单只是工作入口，不是安全边界。',
    menuAriaLabel: '后台菜单',
    menuLoading: '菜单加载中...',
    currentPageEyebrow: '当前页面',
    regionLabel: '区域',
    loggedOutName: '未登录管理员',
    unknownAccount: '--',
    logout: '退出登录',
    identityLoading: '正在核验管理员身份...',
    menuLoadError: '菜单加载失败',
  },
  auth: {
    brandEyebrow: '后台入口',
    brandHeading: '运营控制席',
    heroTitle: '管理员身份、角色权限与区域范围由数据库统一管理。',
    heroDescription: '登录响应会载入管理员资料、权限与区域范围；进入后台后通过 auth/me 实时水合，页面能力以服务端核验为准。',
    ribbonRegion: (region) => `当前区域 ${region} · ${zhCnStrings.common.regionLabel(region)}`,
    ribbonDatabaseRbac: '数据库 RBAC',
    ribbonLivePermissions: '实时权限核验',
    spotlightCredentialsLabel: '登录凭据',
    spotlightCredentialsValue: 'admin / admin123456',
    spotlightCredentialsDetail: '示例账号来自数据库种子；请使用已启用且已分配角色的管理员账号登录。',
    spotlightRegionScopeLabel: '区域范围',
    spotlightRegionScopeValue: (region) => `${region} · ${zhCnStrings.common.regionLabel(region)}`,
    spotlightRegionScopeDetail: '登录响应会载入管理员资料、权限与区域范围，并按授权更新工作视角。',
    spotlightAuthModelLabel: '授权模型',
    spotlightAuthModelValue: '数据库 RBAC 授权',
    spotlightAuthModelDetail: '管理员、角色和权限由服务端持久化管理，后台能力按授权加载。',
    entryTargetRouteLabel: '目标路由',
    entrySessionModeLabel: '会话模式',
    entrySessionModeValue: '数据库 RBAC 授权',
    entryRegionPerspectiveLabel: '区域视角',
    noteRegionScopeTitle: '区域范围',
    noteRegionScopeDetail: '登录响应会载入管理员资料、权限与区域范围；进入后台后按账号授权选择工作视角。',
    noteLivePermissionsTitle: '实时权限',
    noteLivePermissionsDetail: '进入后台后通过 auth/me 实时水合管理员资料、权限与区域范围。',
    noteAdminRbacTitle: '管理员与角色管理',
    noteAdminRbacDetail: '管理员账号、角色、权限和区域范围由数据库维护，页面能力以服务端实时核验为准。',
    formEyebrow: '管理员登录',
    formHeading: '先进去把数据管起来。',
    formBadge: 'Control Entry',
    formSummary: (target) => `登录后会跳到 ${target}，系统根据数据库 RBAC 授权载入管理员资料、权限与区域范围，并在进入后台后实时核验。`,
    regionFieldLabel: '区域视角',
    regionOptionCn: 'CN · 中国大陆',
    regionOptionEu: 'EU · 欧洲',
    accountLabel: '账号',
    accountPlaceholder: '请输入管理员账号',
    passwordLabel: '密码',
    passwordPlaceholder: '请输入管理员密码',
    loginError: '登录失败',
    loginSubmitting: '登录中...',
    loginButton: '进入后台',
    footerText: '管理员与角色管理、权限和区域范围由服务端实时核验，后台能力以数据库授权为准。',
    footerChips: ['管理员管理', '角色与权限', '区域范围'],
  },
  dashboard: {
    eyebrow: '控制台概览',
    heading: (region) => `当前区域 ${region} 的经营与审核状态，一眼看明白。`,
    description: '汇总门店、导入、订单退款和待审任务，先保证运营能用。',
    loadError: '控制台数据加载失败',
    loading: '控制台数据刷新中...',
    noData: '当前账号暂无可查看的控制台数据。',
    headerActions: {
      manageShops: '去管门店',
      importShops: '去做导入',
      viewOrders: '看订单退款',
    },
    metrics: {
      shopCount: {
        label: '当前区域门店数',
        note: (region) => `区域 ${region} 下的最小可管理存量`,
      },
      importBatchCount: {
        label: '导入批次数',
        note: '看得见批次，才谈得上运营回灌',
      },
      paidOrderCount: {
        label: '已支付订单',
        note: '当前区域累计已支付订单',
      },
      pendingRefundCount: {
        label: '待处理退款',
        note: '需要商户或平台继续处理',
      },
      pendingAuditTaskCount: {
        label: '待审任务',
        note: '按当前账号审核权限汇总',
      },
      userCount: {
        label: 'C 端用户数',
        note: '不含已注销匿名化用户',
      },
    },
    quickLinks: {
      eyebrow: '快捷入口',
      heading: '有待办就直接跳，别在菜单里翻半天。',
      pendingDeals: {
        label: '待审团购',
        note: '审核团购创建与重提',
      },
      pendingShopChanges: {
        label: '待审门店草稿',
        note: '审核门店新建/修改快照',
      },
      pendingReviews: {
        label: '待审点评',
        note: '处理用户点评审核',
      },
      pendingPosts: {
        label: '待审帖子',
        note: '处理社区内容审核',
      },
      pendingRefunds: {
        label: '待处理退款',
        note: '进入订单退款页继续处理',
      },
    },
    recentShops: {
      eyebrow: '最近门店',
      heading: '谁刚被录进来，别装看不见。',
      viewAll: '查看全部',
      empty: '当前区域还没有门店，先去导一批数据。',
      openNow: '营业中',
      closed: '休息中',
    },
    recentBatches: {
      eyebrow: '最近批次',
      heading: '批次结果得明明白白，不然导入失败都没人知道。',
      viewAll: '查看批次',
      empty: '当前区域还没有导入批次，去导一包种子商户试试。',
      batchSummary: (success, failed, total) => `成功 ${success} / 失败 ${failed} / 共 ${total}`,
      statusText: (status, fallback) => {
        if (status === 1) return '完成'
        if (status === 2) return '失败'
        if (status === 0) return '处理中'
        return fallback || `状态 ${status}`
      },
    },
    pendingAudit: {
      eyebrow: '待审拆分',
      heading: '按当前账号权限拆开看，别把没权限的任务也算进去。',
      empty: '当前账号没有可查看的待审任务。',
      bizTypeLabels: {
        deals: '团购审核',
        reviews: '点评审核',
        posts: '帖子审核',
        shopChanges: '门店草稿审核',
        reviewAppeals: '商户点评申诉',
        expertCertifications: '达人认证',
        userAppeals: '用户封禁申诉',
        verifiedMerchants: '认证商户',
      },
      fallbackLabel: (bizType) => `审核任务 ${bizType}`,
      detailsNote: (bizType) => `bizType=${bizType} · 点击进入审核页`,
      countSummary: (count) => `${count} 条`,
    },
  },
  auditLogs: {
    eyebrow: 'Audit Trail',
    heading: '审计日志',
    description: '管理员登录、角色变更、审核动作都会往这儿落。查问题别靠拍脑门，先翻日志。',
    loadError: '审计日志加载失败',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 条日志`,
    metaDescription: '支持按管理员、动作、目标和关键词交叉过滤。',
    labels: {
      adminId: '管理员 ID',
      action: '动作',
      target: '目标',
      keyword: '关键词',
    },
    placeholders: {
      adminId: '例如 1',
      action: '例如 system.role_update',
      target: '例如 role:7',
      keyword: '搜索详情、IP、账号',
    },
    applyFilters: '应用筛选',
    tableHeaders: {
      time: '时间',
      operator: '操作人',
      action: '动作',
      target: '目标',
      detail: '详情',
      ip: 'IP',
    },
    loadingRow: '审计日志加载中...',
    empty: '当前筛选下没有审计日志，条件别拧得太邪乎。',
    systemFallback: '系统',
    detailFallback: '无详情',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
  },
  adminOrders: {
    eyebrow: 'Orders & Reconciliation',
    heading: '订单退款',
    description: (region) => `当前区域 ${region}。支持平台退款仲裁、超时未支付关单与待回调支付流水补偿。`,
    reconcileRunning: '补偿执行中...',
    reconcileRun: '执行对账补偿',
    loadError: '订单数据加载失败',
    auditReasonRequired: '退款仲裁必须填写原因',
    auditSubmitError: '退款仲裁提交失败',
    reconcileError: '对账补偿执行失败',
    auditNotice: (orderNo, decision) => `订单 ${orderNo} 退款已${decision === 'approve' ? '通过' : '驳回'}`,
    reconcileNotice: (closedOrders, restoredStockOrders, failedPayments) =>
      `对账补偿完成：关闭超时未支付订单 ${closedOrders} 笔，恢复库存 ${restoredStockOrders} 笔，标记失败支付流水 ${failedPayments} 笔`,
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 条订单`,
    metaDescription: '支持按商户、门店、用户、支付/退款状态、订单号和日期范围筛选。',
    filters: {
      merchantId: '商户 ID',
      shopId: '门店 ID',
      userId: '用户 ID',
      payStatus: '支付状态',
      refundStatus: '退款状态',
      orderNo: '订单号',
      dateFrom: '起始日期',
      dateTo: '结束日期',
    },
    placeholders: {
      merchantId: '例如 1001',
      shopId: '例如 10001',
      userId: '例如 9001',
      orderNo: '例如 ADMIN-ORDER-001',
      auditReason: '填写仲裁原因（必填）',
    },
    payStatusOptions: {
      all: '全部',
      pending: '待支付',
      paid: '已支付',
      refunded: '已退款',
      partialRefund: '部分退款',
    },
    refundStatusOptions: {
      all: '全部',
      pending: '申请中',
      success: '退款成功',
      rejected: '已驳回',
    },
    applyFilters: '应用筛选',
    tableHeaders: {
      time: '时间',
      order: '订单',
      merchantShop: '商户 / 门店',
      user: '用户',
      amount: '金额',
      payment: '支付',
      refund: '退款',
      actions: '操作',
    },
    dealFallback: (dealId) => `deal:${dealId}`,
    merchantFallback: (merchantId) => `merchant:${merchantId}`,
    shopFallback: (shopId) => `shop:${shopId}`,
    userFallback: (userId) => `user:${userId}`,
    amountSummary: (quantity, unitPrice) => `x${quantity} · 单价 ${unitPrice}`,
    paymentChannelFallback: '--',
    noRefundRequest: '无退款申请',
    noReason: '无原因',
    payStatusText: (status, fallback) => {
      if (status === 1) return '已支付'
      if (status === 2) return '已退款'
      if (status === 3) return '部分退款'
      if (status === 0) return '待支付'
      return fallback || `状态 ${status}`
    },
    refundStatusText: (status, fallback) => {
      if (status === 1) return '退款成功'
      if (status === 2) return '已驳回'
      if (status === 0) return '申请中'
      return fallback || `状态 ${status}`
    },
    refundSummary: (statusText, reason) => `${statusText} · ${reason}`,
    noRefund: '无退款',
    paidAt: (paidAt) => `支付时间：${paidAt}`,
    auditRemarkLabel: (reason) => `审核备注：${reason}`,
    refundArbitration: '退款仲裁',
    approveRefund: '通过退款',
    rejectRefund: '驳回退款',
    noPendingRefund: '无待处理退款',
    loadingRow: '订单数据加载中...',
    empty: '当前筛选下没有订单，条件别拧得太邪乎。',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
  },
  privacyTasks: {
    eyebrow: 'Privacy Operations',
    heading: '隐私任务',
    description: '这里查的是用户数据导出和账号删除任务。合规链路别靠猜，先看任务状态和时间线。',
    loadError: '隐私任务加载失败',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 条隐私任务`,
    metaDescription: '支持按用户、任务类型、状态和关键词交叉筛选。',
    labels: {
      userId: '用户 ID',
      taskType: '任务类型',
      status: '状态',
      keyword: '关键词',
    },
    placeholders: {
      userId: '例如 9001',
      keyword: '账号、模块、原因、失败信息',
    },
    taskTypeOptions: {
      all: '全部类型',
      export: '数据导出',
      delete: '账号删除',
    },
    statusOptions: {
      all: '全部状态',
      exportPending: '待处理',
      exportProcessing: '处理中',
      exportReady: '可下载',
      exportExpired: '已过期',
      exportFailed: '失败',
      exportCancelled: '已取消',
      deletePendingConfirm: '待确认',
      deleteCoolingOff: '冷静期中',
      deleteProcessing: '处理中',
      deleteCompleted: '已完成',
      deleteCancelled: '已取消',
      deleteRejected: '已驳回',
      mixed0: '0: 待处理/待确认',
      mixed1: '1: 处理中/冷静期中',
      mixed2: '2: 可下载/处理中',
      mixed3: '3: 已过期/已完成',
      mixed4: '4: 失败/已取消',
      mixed5: '5: 已取消/已驳回',
    },
    applyFilters: '应用筛选',
    tableHeaders: {
      time: '时间',
      task: '任务',
      user: '用户',
      status: '状态',
      keyInfo: '关键信息',
      deadline: '时效',
    },
    loadingRow: '隐私任务加载中...',
    empty: '当前筛选下没有隐私任务，条件别拧巴过头。',
    taskTypeText: (taskType, fallback) => {
      if (taskType === 1) return '数据导出'
      if (taskType === 2) return '账号删除'
      return fallback || `任务类型 ${taskType}`
    },
    taskStatusText: (taskType, status, fallback) => {
      if (taskType === 1) {
        if (status === 0) return '待处理'
        if (status === 1) return '处理中'
        if (status === 2) return '可下载'
        if (status === 3) return '已过期'
        if (status === 4) return '失败'
        if (status === 5) return '已取消'
      }
      if (taskType === 2) {
        if (status === 0) return '待确认'
        if (status === 1) return '冷静期中'
        if (status === 2) return '处理中'
        if (status === 3) return '已完成'
        if (status === 4) return '已取消'
        if (status === 5) return '已驳回'
      }
      return fallback || `状态 ${status}`
    },
    allModules: '全部模块',
    noReason: '无说明',
    deadlineFallback: '--',
    exportFilePending: '尚未生成文件',
    verificationMethod: (method) => `验证方式：${method}`,
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
  },
}

const enStrings: AdminStrings = {
  tag: 'en',
  brand: 'Dazhong Dianping Admin',
  common: {
    requestFailed: 'Request failed.',
    loading: 'Loading...',
    refresh: 'Refresh',
    cancel: 'Cancel',
    regionLabel: (region) => region === 'EU' ? 'Europe' : 'Mainland China',
  },
  routeTitles: {
    workbench: 'Admin Console',
    login: 'Admin Login',
    dashboard: 'Dashboard',
    shopManagement: 'Shop Management',
    basicDataManagement: 'Basic Data',
    dataOrders: 'Orders & Refunds',
    auditReviews: 'Review Audit',
    auditReviewAppeals: 'Merchant Review Appeals',
    auditPosts: 'Post Audit',
    auditExpertCertifications: 'Expert Certifications',
    auditVerifiedMerchants: 'Verified Merchants',
    auditReports: 'Content Reports',
    auditUserAppeals: 'User Ban Appeals',
    auditMerchantApplications: 'Merchant Applications',
    auditShopChanges: 'Shop Draft Audit',
    auditDeals: 'Deal Audit',
    shopImport: 'Seed Imports',
    rankConfig: 'Ranking Rules',
    growthConfig: 'Growth Rules',
    circleManagement: 'Official Circles',
    topicManagement: 'Topic Governance',
    bannerManagement: 'Banner Management',
    hotwordManagement: 'Hot Keywords',
    sensitiveWordManagement: 'Sensitive Words',
    activityManagement: 'Operation Activities',
    systemAdmins: 'Admin Accounts',
    systemRoles: 'Roles & Permissions',
    systemUsers: 'User Management',
    systemAuditLogs: 'Audit Logs',
    systemPrivacyTasks: 'Privacy Tasks',
  },
  menuGroups: {
    data: 'Data',
    audit: 'Audit',
    operations: 'Operations',
    system: 'System',
  },
  shell: {
    appEyebrow: 'Admin backend',
    appHeading: 'Dazhong Dianping admin console',
    appDescription: 'Accounts, roles, and regional scope are validated by the server in real time. The menu is only an entry point, not a security boundary.',
    menuAriaLabel: 'Admin navigation',
    menuLoading: 'Loading menus...',
    currentPageEyebrow: 'Current page',
    regionLabel: 'Region',
    loggedOutName: 'Signed-out admin',
    unknownAccount: '--',
    logout: 'Sign out',
    identityLoading: 'Verifying admin identity...',
    menuLoadError: 'Failed to load menus.',
  },
  auth: {
    brandEyebrow: 'Admin Concierge',
    brandHeading: 'Operations control desk',
    heroTitle: 'Admin identities, roles, permissions, and regional scope are managed centrally in the database.',
    heroDescription: 'The login response loads the admin profile, permissions, and regional scope. After entering the console, auth/me rehydrates them in real time and the server remains the source of truth.',
    ribbonRegion: (region) => `Current region ${region} · ${enStrings.common.regionLabel(region)}`,
    ribbonDatabaseRbac: 'Database-backed RBAC',
    ribbonLivePermissions: 'Live permission checks',
    spotlightCredentialsLabel: 'Credentials',
    spotlightCredentialsValue: 'admin / admin123456',
    spotlightCredentialsDetail: 'The sample account comes from seed data. Use an enabled admin account with assigned roles to sign in.',
    spotlightRegionScopeLabel: 'Regional scope',
    spotlightRegionScopeValue: (region) => `${region} · ${enStrings.common.regionLabel(region)}`,
    spotlightRegionScopeDetail: 'The login response loads the admin profile, permissions, and regional scope, then updates the working perspective according to authorization.',
    spotlightAuthModelLabel: 'Authorization model',
    spotlightAuthModelValue: 'Database-backed RBAC',
    spotlightAuthModelDetail: 'Admins, roles, and permissions are persisted on the server and console capabilities are loaded from granted permissions.',
    entryTargetRouteLabel: 'Target route',
    entrySessionModeLabel: 'Session mode',
    entrySessionModeValue: 'Database-backed RBAC',
    entryRegionPerspectiveLabel: 'Region perspective',
    noteRegionScopeTitle: 'Regional scope',
    noteRegionScopeDetail: 'The login response loads the admin profile, permissions, and regional scope. Once inside, the console chooses the working perspective allowed by the account.',
    noteLivePermissionsTitle: 'Live permissions',
    noteLivePermissionsDetail: 'After sign-in, auth/me rehydrates the admin profile, permissions, and regional scope in real time.',
    noteAdminRbacTitle: 'Admin and role management',
    noteAdminRbacDetail: 'Admin accounts, roles, permissions, and regional scope are maintained in the database. Server-side authorization remains the source of truth.',
    formEyebrow: 'Admin Login',
    formHeading: 'Get in and manage the data.',
    formBadge: 'Control Entry',
    formSummary: (target) => `After sign-in you will be redirected to ${target}. The system loads the admin profile, permissions, and regional scope from database-backed RBAC and verifies them again inside the console.`,
    regionFieldLabel: 'Region perspective',
    regionOptionCn: 'CN · Mainland China',
    regionOptionEu: 'EU · Europe',
    accountLabel: 'Account',
    accountPlaceholder: 'Enter the admin account',
    passwordLabel: 'Password',
    passwordPlaceholder: 'Enter the admin password',
    loginError: 'Failed to sign in.',
    loginSubmitting: 'Signing in...',
    loginButton: 'Enter console',
    footerText: 'Admin accounts, roles, permissions, and regional scope are verified by the server in real time. Console capabilities follow database authorization.',
    footerChips: ['Admin Accounts', 'Roles & Permissions', 'Regional Scope'],
  },
  dashboard: {
    eyebrow: 'Overview',
    heading: (region) => `See the operating and audit state for region ${region} at a glance.`,
    description: 'This page summarizes shops, imports, order refunds, and pending audits so operations can actually move.',
    loadError: 'Failed to load dashboard data.',
    loading: 'Refreshing dashboard data...',
    noData: 'This account does not have any dashboard data to view.',
    headerActions: {
      manageShops: 'Manage shops',
      importShops: 'Run imports',
      viewOrders: 'Review orders',
    },
    metrics: {
      shopCount: {
        label: 'Shops in region',
        note: (region) => `Minimum manageable shop inventory for region ${region}`,
      },
      importBatchCount: {
        label: 'Import batches',
        note: 'You need visible batches before import operations are trustworthy.',
      },
      paidOrderCount: {
        label: 'Paid orders',
        note: 'Cumulative paid orders in the current region',
      },
      pendingRefundCount: {
        label: 'Pending refunds',
        note: 'Still waiting on merchant or platform action',
      },
      pendingAuditTaskCount: {
        label: 'Pending audits',
        note: 'Aggregated from the current account audit permissions',
      },
      userCount: {
        label: 'Consumer users',
        note: 'Excludes anonymized deleted users',
      },
    },
    quickLinks: {
      eyebrow: 'Quick links',
      heading: 'Jump straight into work instead of digging through the menu.',
      pendingDeals: {
        label: 'Pending deals',
        note: 'Review new and resubmitted deals',
      },
      pendingShopChanges: {
        label: 'Pending shop drafts',
        note: 'Review new and updated shop snapshots',
      },
      pendingReviews: {
        label: 'Pending reviews',
        note: 'Handle user review audits',
      },
      pendingPosts: {
        label: 'Pending posts',
        note: 'Handle community content audits',
      },
      pendingRefunds: {
        label: 'Pending refunds',
        note: 'Continue handling refunds in the orders view',
      },
    },
    recentShops: {
      eyebrow: 'Recent shops',
      heading: 'Keep track of what was just added.',
      viewAll: 'View all',
      empty: 'There are no shops in this region yet. Import a first batch of data.',
      openNow: 'Open now',
      closed: 'Closed',
    },
    recentBatches: {
      eyebrow: 'Recent batches',
      heading: 'Import results need to be explicit or failures get ignored.',
      viewAll: 'View batches',
      empty: 'There are no import batches in this region yet. Try importing a seed merchant package.',
      batchSummary: (success, failed, total) => `Success ${success} / Failed ${failed} / Total ${total}`,
      statusText: (status, fallback) => {
        if (status === 1) return 'Completed'
        if (status === 2) return 'Failed'
        if (status === 0) return 'Processing'
        return fallback || `Status ${status}`
      },
    },
    pendingAudit: {
      eyebrow: 'Pending audit breakdown',
      heading: 'Split counts by the current account permissions so inaccessible work does not pollute the totals.',
      empty: 'This account has no pending audits it can view.',
      bizTypeLabels: {
        deals: 'Deal audit',
        reviews: 'Review audit',
        posts: 'Post audit',
        shopChanges: 'Shop draft audit',
        reviewAppeals: 'Merchant review appeals',
        expertCertifications: 'Expert certifications',
        userAppeals: 'User ban appeals',
        verifiedMerchants: 'Verified merchants',
      },
      fallbackLabel: (bizType) => `Audit task ${bizType}`,
      detailsNote: (bizType) => `bizType=${bizType} · open the matching audit view`,
      countSummary: (count) => `${count} tasks`,
    },
  },
  auditLogs: {
    eyebrow: 'Audit Trail',
    heading: 'Audit Logs',
    description: 'Admin sign-ins, role changes, and audit actions all land here. Start with the logs instead of guessing what happened.',
    loadError: 'Failed to load audit logs.',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} log entries`,
    metaDescription: 'Filter across admin ID, action, target, and keyword.',
    labels: {
      adminId: 'Admin ID',
      action: 'Action',
      target: 'Target',
      keyword: 'Keyword',
    },
    placeholders: {
      adminId: 'For example: 1',
      action: 'For example: system.role_update',
      target: 'For example: role:7',
      keyword: 'Search details, IP, or account',
    },
    applyFilters: 'Apply filters',
    tableHeaders: {
      time: 'Time',
      operator: 'Operator',
      action: 'Action',
      target: 'Target',
      detail: 'Detail',
      ip: 'IP',
    },
    loadingRow: 'Loading audit logs...',
    empty: 'No audit logs match the current filters.',
    systemFallback: 'System',
    detailFallback: 'No details',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
  },
  adminOrders: {
    eyebrow: 'Orders & Reconciliation',
    heading: 'Orders and refunds',
    description: (region) => `Current region ${region}. This view supports refund arbitration, closing overdue unpaid orders, and reconciling payments that never called back.`,
    reconcileRunning: 'Running reconciliation...',
    reconcileRun: 'Run reconciliation',
    loadError: 'Failed to load order data.',
    auditReasonRequired: 'Refund arbitration requires a reason.',
    auditSubmitError: 'Failed to submit refund arbitration.',
    reconcileError: 'Failed to run reconciliation.',
    auditNotice: (orderNo, decision) => `Refund for order ${orderNo} was ${decision === 'approve' ? 'approved' : 'rejected'}.`,
    reconcileNotice: (closedOrders, restoredStockOrders, failedPayments) =>
      `Reconciliation finished: closed ${closedOrders} overdue unpaid orders, restored stock for ${restoredStockOrders} orders, and marked ${failedPayments} payment flows as failed.`,
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} orders`,
    metaDescription: 'Filter by merchant, shop, user, payment or refund status, order number, and date range.',
    filters: {
      merchantId: 'Merchant ID',
      shopId: 'Shop ID',
      userId: 'User ID',
      payStatus: 'Payment status',
      refundStatus: 'Refund status',
      orderNo: 'Order number',
      dateFrom: 'Start date',
      dateTo: 'End date',
    },
    placeholders: {
      merchantId: 'For example: 1001',
      shopId: 'For example: 10001',
      userId: 'For example: 9001',
      orderNo: 'For example: ADMIN-ORDER-001',
      auditReason: 'Enter the arbitration reason (required)',
    },
    payStatusOptions: {
      all: 'All',
      pending: 'Pending payment',
      paid: 'Paid',
      refunded: 'Refunded',
      partialRefund: 'Partially refunded',
    },
    refundStatusOptions: {
      all: 'All',
      pending: 'Pending',
      success: 'Refunded',
      rejected: 'Rejected',
    },
    applyFilters: 'Apply filters',
    tableHeaders: {
      time: 'Time',
      order: 'Order',
      merchantShop: 'Merchant / Shop',
      user: 'User',
      amount: 'Amount',
      payment: 'Payment',
      refund: 'Refund',
      actions: 'Actions',
    },
    dealFallback: (dealId) => `deal:${dealId}`,
    merchantFallback: (merchantId) => `merchant:${merchantId}`,
    shopFallback: (shopId) => `shop:${shopId}`,
    userFallback: (userId) => `user:${userId}`,
    amountSummary: (quantity, unitPrice) => `x${quantity} · Unit price ${unitPrice}`,
    paymentChannelFallback: '--',
    noRefundRequest: 'No refund request',
    noReason: 'No reason',
    payStatusText: (status, fallback) => {
      if (status === 1) return 'Paid'
      if (status === 2) return 'Refunded'
      if (status === 3) return 'Partially refunded'
      if (status === 0) return 'Pending payment'
      return fallback || `Status ${status}`
    },
    refundStatusText: (status, fallback) => {
      if (status === 1) return 'Refunded'
      if (status === 2) return 'Rejected'
      if (status === 0) return 'Pending'
      return fallback || `Status ${status}`
    },
    refundSummary: (statusText, reason) => `${statusText} · ${reason}`,
    noRefund: 'No refund',
    paidAt: (paidAt) => `Paid at: ${paidAt}`,
    auditRemarkLabel: (reason) => `Audit note: ${reason}`,
    refundArbitration: 'Refund arbitration',
    approveRefund: 'Approve refund',
    rejectRefund: 'Reject refund',
    noPendingRefund: 'No pending refund',
    loadingRow: 'Loading order data...',
    empty: 'No orders match the current filters.',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
  },
  privacyTasks: {
    eyebrow: 'Privacy Operations',
    heading: 'Privacy Tasks',
    description: 'This view covers data export and account deletion requests. Start with task status and timing instead of guessing at compliance flow.',
    loadError: 'Failed to load privacy tasks.',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} privacy tasks`,
    metaDescription: 'Filter across user, task type, status, and keyword.',
    labels: {
      userId: 'User ID',
      taskType: 'Task type',
      status: 'Status',
      keyword: 'Keyword',
    },
    placeholders: {
      userId: 'For example: 9001',
      keyword: 'Account, modules, reason, or failure',
    },
    taskTypeOptions: {
      all: 'All task types',
      export: 'Data export',
      delete: 'Account deletion',
    },
    statusOptions: {
      all: 'All statuses',
      exportPending: 'Pending',
      exportProcessing: 'In progress',
      exportReady: 'Ready to download',
      exportExpired: 'Expired',
      exportFailed: 'Failed',
      exportCancelled: 'Cancelled',
      deletePendingConfirm: 'Pending confirmation',
      deleteCoolingOff: 'Cooling-off period',
      deleteProcessing: 'In progress',
      deleteCompleted: 'Completed',
      deleteCancelled: 'Cancelled',
      deleteRejected: 'Rejected',
      mixed0: '0: pending / confirmation',
      mixed1: '1: in progress / cooling-off',
      mixed2: '2: ready / in progress',
      mixed3: '3: expired / completed',
      mixed4: '4: failed / cancelled',
      mixed5: '5: cancelled / rejected',
    },
    applyFilters: 'Apply filters',
    tableHeaders: {
      time: 'Time',
      task: 'Task',
      user: 'User',
      status: 'Status',
      keyInfo: 'Key details',
      deadline: 'Deadline',
    },
    loadingRow: 'Loading privacy tasks...',
    empty: 'No privacy tasks match the current filters.',
    taskTypeText: (taskType, fallback) => {
      if (taskType === 1) return 'Data export'
      if (taskType === 2) return 'Account deletion'
      return fallback || `Task type ${taskType}`
    },
    taskStatusText: (taskType, status, fallback) => {
      if (taskType === 1) {
        if (status === 0) return 'Pending'
        if (status === 1) return 'In progress'
        if (status === 2) return 'Ready to download'
        if (status === 3) return 'Expired'
        if (status === 4) return 'Failed'
        if (status === 5) return 'Cancelled'
      }
      if (taskType === 2) {
        if (status === 0) return 'Pending confirmation'
        if (status === 1) return 'Cooling-off period'
        if (status === 2) return 'In progress'
        if (status === 3) return 'Completed'
        if (status === 4) return 'Cancelled'
        if (status === 5) return 'Rejected'
      }
      return fallback || `Status ${status}`
    },
    allModules: 'All modules',
    noReason: 'No reason provided',
    deadlineFallback: '--',
    exportFilePending: 'File not generated yet',
    verificationMethod: (method) => `Verification: ${method}`,
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
  },
}

const STRINGS: Record<AdminLocaleTag, AdminStrings> = {
  'zh-CN': zhCnStrings,
  en: enStrings,
}

export function localeForRegion(region: Region): AdminLocaleTag {
  return region === 'EU' ? 'en' : 'zh-CN'
}

export function adminStringsForLocale(locale: AdminLocaleTag): AdminStrings {
  return STRINGS[locale]
}

export function adminStringsForRegion(region: Region): AdminStrings {
  return adminStringsForLocale(localeForRegion(region))
}

export function adminRouteTitleKey(pathKey: unknown): AdminRouteTitleKey {
  return typeof pathKey === 'string' ? pathKey as AdminRouteTitleKey : 'workbench'
}

export function adminRouteTitleKeyForPath(path: string): AdminRouteTitleKey | undefined {
  return ROUTE_TITLE_KEYS[path]
}

export function adminMenuLabel(
  strings: AdminStrings,
  item: { code?: string; path?: string; name?: string },
) {
  const groupKey = item.code ? MENU_GROUP_KEYS[item.code as keyof typeof MENU_GROUP_KEYS] : undefined
  if (groupKey) {
    return strings.menuGroups[groupKey]
  }

  const titleKey = item.path ? adminRouteTitleKeyForPath(item.path) : undefined
  if (titleKey) {
    return strings.routeTitles[titleKey]
  }

  return item.name || ''
}
