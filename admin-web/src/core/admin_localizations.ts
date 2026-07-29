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
  circles: {
    loadError: string
    saveError: string
    toggleError: string
    eyebrow: string
    heading: string
    description: string
    keywordPlaceholder: string
    statusOptions: {
      all: string
      enabled: string
      disabled: string
    }
    query: string
    editorPlaceholders: {
      name: string
      description: string
      coverUrl: string
      sort: string
    }
    saveUpdate: string
    create: string
    emptyDescription: string
    statusText: (status: number) => string
    summary: (memberCount: number, postCount: number, sort: number) => string
    edit: string
    enable: string
    disable: string
  }
  hotWords: {
    created: string
    updated: string
    enabled: string
    disabled: string
    deleted: string
    deleteConfirm: (keyword: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    create: string
    listEyebrow: string
    listHeading: string
    tableHeaders: {
      keyword: string
      sort: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    statusText: (enabled: boolean) => string
    edit: string
    enable: string
    disable: string
    delete: string
    editorEyebrow: (editing: boolean) => string
    editorHeading: (editing: boolean) => string
    labels: {
      keyword: string
      sort: string
    }
    saving: string
    save: string
  }
  sensitiveWords: {
    created: string
    updated: string
    enabled: string
    disabled: string
    deleted: string
    deleteConfirm: (word: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    create: string
    listEyebrow: string
    listHeading: string
    tableHeaders: {
      word: string
      remark: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    remarkFallback: string
    statusText: (enabled: boolean) => string
    edit: string
    enable: string
    disable: string
    delete: string
    editorEyebrow: (editing: boolean) => string
    editorHeading: (editing: boolean) => string
    labels: {
      word: string
      remark: string
    }
    saving: string
    save: string
  }
  rankConfigs: {
    loadError: string
    weightSumError: string
    createSuccess: string
    createError: string
    publishSuccess: (rankId: number, itemCount: number) => string
    publishError: string
    rollbackSuccess: (rankId: number) => string
    rollbackError: string
    eyebrow: string
    heading: string
    description: string
    historyEyebrow: string
    historyHeading: (region: Region) => string
    loading: string
    tableHeaders: {
      type: string
      scope: string
      version: string
      status: string
      actions: string
    }
    scopeSummary: (cityId: number, categoryId: number) => string
    rankTypeText: (rankType: number, fallback?: string) => string
    statusText: (status: number, fallback?: string) => string
    publish: string
    rollback: string
    editorEyebrow: string
    editorHeading: string
    labels: {
      rankType: string
      calcCycle: string
      cityId: string
      categoryId: string
      scoreWeight: string
      reviewWeight: string
      dealWeight: string
      minScore: string
      minReviewCount: string
    }
    rankTypeOptions: {
      mustEat: string
      review: string
      hot: string
    }
    calcCycleOptions: {
      day: string
      week: string
      month: string
      quarter: string
    }
    saving: string
    saveDraft: string
    readOnly: string
  }
  growthConfigs: {
    loadError: string
    ruleUpdateError: string
    levelUpdateError: string
    ruleUpdated: (action: string) => string
    levelUpdated: (level: number) => string
    eyebrow: string
    heading: string
    description: string
    rulesEyebrow: string
    rulesHeading: string
    levelsEyebrow: string
    levelsHeading: string
    ruleHeaders: {
      action: string
      growthValue: string
      points: string
      dailyLimit: string
      enabled: string
      actions: string
    }
    levelHeaders: {
      level: string
      name: string
      minGrowth: string
      enabled: string
      actions: string
    }
    actionText: (action: string, fallback?: string) => string
    levelLabel: (level: number) => string
    save: string
  }
  topics: {
    loadError: string
    actionError: string
    invalidMergeTarget: string
    renamed: string
    recommendationEnabled: string
    recommendationDisabled: string
    blocked: string
    restored: string
    merged: string
    recalculated: (region: Region, calculatedAt: string) => string
    headerEyebrow: (region: Region) => string
    heading: string
    description: string
    recalculate: string
    filters: {
      keyword: string
      status: string
      recommended: string
    }
    keywordPlaceholder: string
    statusOptions: {
      all: string
      live: string
      blocked: string
    }
    recommendationOptions: {
      all: string
      recommended: string
      notRecommended: string
    }
    query: string
    loading: string
    statusChipText: (status: number) => string
    recommendedChip: string
    mergedTo: (topicId: number) => string
    metricLabels: {
      hotScore: string
      posts: string
      followers: string
    }
    activitySummary: (posts: number, likes: number, comments: number) => string
    calculatedAt: (value: string) => string
    noSnapshot: string
    pinLabel: string
    rename: string
    recommend: string
    cancelRecommend: string
    block: string
    restore: string
    merge: string
    renameEyebrow: string
    renameHeading: string
    renameSave: string
    mergeEyebrow: string
    mergeHeading: (sourceName: string) => string
    mergeDescription: string
    mergeTargetPlaceholder: string
    mergeConfirm: string
    mergeConfirmPrompt: (sourceName: string, targetName: string) => string
  }
  banners: {
    created: string
    updated: string
    enabled: string
    disabled: string
    deleted: string
    deleteConfirm: (title: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    create: string
    filterEyebrow: string
    filterHeading: string
    filterCityLabel: string
    filterCityAll: string
    filterHelpLabel: string
    filterHelpText: string
    loading: string
    applyFilter: string
    listEyebrow: string
    listHeading: string
    tableHeaders: {
      scope: string
      title: string
      link: string
      sort: string
      status: string
      actions: string
    }
    empty: string
    scopeText: (cityId: number | null, cityName: string) => string
    subtitleFallback: string
    statusText: (enabled: boolean) => string
    edit: string
    enable: string
    disable: string
    delete: string
    editorEyebrow: (editing: boolean) => string
    editorHeading: (editing: boolean) => string
    labels: {
      cityScope: string
      sort: string
      title: string
      subtitle: string
      imageUrl: string
      linkUrl: string
    }
    cityScopeAll: string
    saving: string
    save: string
  }
  operationActivities: {
    created: string
    updated: string
    statusUpdated: string
    deleted: string
    itemCreated: string
    itemUpdated: string
    itemEnabled: string
    itemDisabled: string
    itemDeleted: string
    jsonParseError: (label: string) => string
    jsonObjectError: (label: string) => string
    externalUrlRequired: string
    deleteActivityConfirm: (name: string) => string
    deleteItemConfirm: (title: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    create: string
    filtersEyebrow: string
    filtersHeading: string
    filterLabels: {
      city: string
      status: string
    }
    filterOptions: {
      allCities: string
      allStatuses: string
    }
    loading: string
    applyFilters: string
    listEyebrow: string
    listHeading: string
    tableHeaders: {
      scopeCode: string
      activity: string
      delivery: string
      items: string
      status: string
      actions: string
    }
    empty: string
    scopeText: (cityId: number, cityName: string) => string
    channelText: (channel: number, fallback?: string) => string
    typeText: (type: number, fallback?: string) => string
    activityStatusText: (status: number, fallback?: string) => string
    itemStatusText: (status: number, fallback?: string) => string
    startFallback: string
    endFallback: string
    manageItems: string
    edit: string
    changeStatus: string
    delete: string
    activityEditorEyebrow: (editing: boolean) => string
    activityEditorHeading: (editing: boolean) => string
    activityLabels: {
      cityScope: string
      channel: string
      type: string
      startAt: string
      name: string
      code: string
      cover: string
      landingUrl: string
      endAt: string
      rule: string
    }
    activityPlaceholders: {
      startAt: string
      endAt: string
      rule: string
    }
    saving: string
    saveActivity: string
    itemsEyebrow: string
    itemsHeading: (activityName: string | null) => string
    itemsDescription: (scopeText: string, statusText: string) => string
    createItem: string
    noActivitySelected: string
    itemTableHeaders: {
      resource: string
      copy: string
      sort: string
      status: string
      actions: string
    }
    itemsLoading: string
    itemEmpty: string
    targetTypeText: (targetType: number, fallback?: string) => string
    targetFallback: (targetId: number) => string
    subtitleFallback: string
    itemEditorEyebrow: (editing: boolean) => string
    itemEditorHeading: (activityName: string, editing: boolean) => string
    itemLabels: {
      targetType: string
      targetId: string
      title: string
      subtitle: string
      image: string
      sort: string
      badge: string
      trackCode: string
      url: string
    }
    itemUrlPlaceholder: string
    saveItem: string
    statusOptions: {
      draft: string
      scheduled: string
      live: string
      offline: string
      ended: string
    }
    channelOptions: {
      home: string
      search: string
      channel: string
      activityPage: string
      community: string
    }
    typeOptions: {
      campaign: string
      festival: string
      newcomer: string
      merchantSupport: string
      contentTopic: string
    }
    targetTypeOptions: {
      shop: string
      deal: string
      post: string
      rank: string
      topic: string
      external: string
    }
    itemEnable: string
    itemDisable: string
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
  circles: {
    loadError: '圈子加载失败',
    saveError: '保存失败',
    toggleError: '状态更新失败',
    eyebrow: '社区运营',
    heading: '官方圈子',
    description: '当前区域独立维护，停用后禁止新加入和发帖。',
    keywordPlaceholder: '搜索圈子',
    statusOptions: {
      all: '全部状态',
      enabled: '启用',
      disabled: '停用',
    },
    query: '查询',
    editorPlaceholders: {
      name: '圈子名称',
      description: '圈子简介',
      coverUrl: '封面地址（可空）',
      sort: '排序',
    },
    saveUpdate: '保存修改',
    create: '创建圈子',
    emptyDescription: '暂无简介',
    statusText: (status) => status === 1 ? '启用' : '停用',
    summary: (memberCount, postCount, sort) => `成员 ${memberCount} · 帖子 ${postCount} · 排序 ${sort}`,
    edit: '编辑',
    enable: '启用',
    disable: '停用',
  },
  hotWords: {
    created: '热词已创建',
    updated: '热词已更新',
    enabled: '热词已启用',
    disabled: '热词已停用',
    deleted: '热词已删除',
    deleteConfirm: (keyword) => `确认删除热词「${keyword}」？删除后公开端可能回退到统计结果。`,
    eyebrow: '搜索运营',
    heading: '热词走真表，别再让 fallback 统计冒充运营决定。',
    description: (region) => `当前区域 ${region}。只要存在启用热词，公开端 /search/hot 就优先按这里的排序返回；删空后才回退到分类和标签统计。`,
    create: '新建热词',
    listEyebrow: '热词列表',
    listHeading: '排序越小越靠前，停用后公开端会立刻忽略这条配置',
    tableHeaders: {
      keyword: '关键词',
      sort: '排序',
      status: '状态',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '当前区域还没有配置热词，会回退到统计结果。',
    statusText: (enabled) => enabled ? '启用' : '停用',
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    delete: '删除',
    editorEyebrow: (editing) => editing ? '编辑热词' : '新建热词',
    editorHeading: (editing) => editing ? '改完即影响公开搜索面板' : '新建后会按排序进入公开端热词列表',
    labels: {
      keyword: '关键词',
      sort: '排序',
    },
    saving: '保存中...',
    save: '保存热词',
  },
  sensitiveWords: {
    created: '敏感词已创建',
    updated: '敏感词已更新',
    enabled: '敏感词已启用',
    disabled: '敏感词已停用',
    deleted: '敏感词已删除',
    deleteConfirm: (word) => `确认删除敏感词「${word}」？删除后对应拦截会立即失效。`,
    eyebrow: '内容治理',
    heading: '敏感词库先把机审底座立住，再谈第三方审核。',
    description: (region) => `当前区域 ${region}。启用词会对点评、帖子、评论和私信写入做包含匹配拦截；停用或删除后立即失效。`,
    create: '新建敏感词',
    listEyebrow: '词库列表',
    listHeading: '按区域维护，写入侧实时按启用词拦截',
    tableHeaders: {
      word: '敏感词',
      remark: '备注',
      status: '状态',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '当前区域还没有敏感词。',
    remarkFallback: '—',
    statusText: (enabled) => enabled ? '启用' : '停用',
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    delete: '删除',
    editorEyebrow: (editing) => editing ? '编辑敏感词' : '新建敏感词',
    editorHeading: (editing) => editing ? '改完立即影响当前区域拦截' : '新建后默认启用并参与拦截',
    labels: {
      word: '敏感词',
      remark: '备注',
    },
    saving: '保存中...',
    save: '保存敏感词',
  },
  rankConfigs: {
    loadError: '榜单规则加载失败',
    weightSumError: '三个权重之和必须等于 1。',
    createSuccess: '新规则草稿已创建，未发布前不会影响线上榜单。',
    createError: '规则创建失败',
    publishSuccess: (rankId, itemCount) => `发布成功：榜单 #${rankId}，共 ${itemCount} 家门店。`,
    publishError: '发布失败',
    rollbackSuccess: (rankId) => `已按历史规则生成新版本并发布，榜单 #${rankId}。`,
    rollbackError: '回滚失败',
    eyebrow: '榜单运营',
    heading: '规则先存草稿，发布成功后再切榜单快照。',
    description: '重算翻车会保留旧榜单，不能让运营手一抖前台就黑屏。',
    historyEyebrow: '规则版本',
    historyHeading: (region) => `区域 ${region} 的历史版本`,
    loading: '加载中...',
    tableHeaders: {
      type: '类型',
      scope: '作用域',
      version: '版本',
      status: '状态',
      actions: '操作',
    },
    scopeSummary: (cityId, categoryId) => `城市 ${cityId} / 分类 ${categoryId}`,
    rankTypeText: (rankType, fallback) => {
      if (rankType === 1) return '必吃榜'
      if (rankType === 2) return '好评榜'
      if (rankType === 3) return '热门榜'
      return fallback || `榜单 ${rankType}`
    },
    statusText: (status, fallback) => {
      if (status === 1) return '已发布'
      if (status === 2) return '已归档'
      if (status === 0) return '草稿'
      return fallback || `状态 ${status}`
    },
    publish: '发布',
    rollback: '回滚到此规则',
    editorEyebrow: '新草稿',
    editorHeading: '创建下一版本',
    labels: {
      rankType: '榜单类型',
      calcCycle: '计算周期',
      cityId: '城市 ID',
      categoryId: '分类 ID',
      scoreWeight: '评分权重',
      reviewWeight: '点评量权重',
      dealWeight: '优惠权重',
      minScore: '最低评分',
      minReviewCount: '最低点评量',
    },
    rankTypeOptions: {
      mustEat: '必吃榜',
      review: '好评榜',
      hot: '热门榜',
    },
    calcCycleOptions: {
      day: '日',
      week: '周',
      month: '月',
      quarter: '季',
    },
    saving: '创建中...',
    saveDraft: '保存草稿',
    readOnly: '当前账号仅可查看，无榜单配置权限。',
  },
  growthConfigs: {
    loadError: '配置加载失败',
    ruleUpdateError: '规则更新失败',
    levelUpdateError: '等级更新失败',
    ruleUpdated: (action) => `${action} 已更新`,
    levelUpdated: (level) => `Lv${level} 已更新`,
    eyebrow: '成长体系',
    heading: '奖励权重和等级门槛都从数据库读取。',
    description: '改完只影响之后的行为，历史流水不回写，账不能越改越玄学。',
    rulesEyebrow: '行为奖励',
    rulesHeading: '成长值 / 积分 / 每日上限',
    levelsEyebrow: '等级阈值',
    levelsHeading: 'Lv1-Lv8 配置',
    ruleHeaders: {
      action: '行为',
      growthValue: '成长值',
      points: '积分',
      dailyLimit: '每日上限',
      enabled: '启用',
      actions: '操作',
    },
    levelHeaders: {
      level: '等级',
      name: '名称',
      minGrowth: '最低成长值',
      enabled: '启用',
      actions: '操作',
    },
    actionText: (action, fallback) => {
      if (action === 'review_create') return '发布点评'
      if (action === 'review_liked') return '点评获赞'
      if (action === 'review_image') return '带图点评'
      if (action === 'order_complete') return '完成订单'
      if (action === 'favorite_shop') return '收藏门店'
      return fallback || action
    },
    levelLabel: (level) => `Lv${level}`,
    save: '保存',
  },
  topics: {
    loadError: '话题加载失败',
    actionError: '操作失败',
    invalidMergeTarget: '请选择有效的合并目标',
    renamed: '话题名称已更新',
    recommendationEnabled: '推荐与置顶排序已更新',
    recommendationDisabled: '已取消推荐',
    blocked: '话题已屏蔽',
    restored: '话题已恢复',
    merged: '话题合并完成，关系与热榜已重算',
    recalculated: (region, calculatedAt) => `${region} 热榜已重算：${calculatedAt}`,
    headerEyebrow: (region) => `话题运营 · 当前区域 ${region}`,
    heading: '话题治理作战台',
    description: '推荐负责发现，置顶负责秩序，合并负责收拾重复命名留下的烂摊子。',
    recalculate: '重算热榜',
    filters: {
      keyword: '关键词',
      status: '状态',
      recommended: '运营推荐',
    },
    keywordPlaceholder: '名称精确定位',
    statusOptions: {
      all: '全部状态',
      live: '正常',
      blocked: '屏蔽',
    },
    recommendationOptions: {
      all: '全部',
      recommended: '已推荐',
      notRecommended: '未推荐',
    },
    query: '执行筛选',
    loading: '正在读取区域话题...',
    statusChipText: (status) => status === 1 ? '正常' : status === 2 ? '屏蔽' : `状态 ${status}`,
    recommendedChip: '推荐',
    mergedTo: (topicId) => `已合并至 #${topicId}`,
    metricLabels: {
      hotScore: '热度',
      posts: '帖子',
      followers: '关注',
    },
    activitySummary: (posts, likes, comments) => `${posts} 帖 · ${likes} 赞 · ${comments} 评论`,
    calculatedAt: (value) => `最近计算 ${value}`,
    noSnapshot: '尚未生成快照',
    pinLabel: '置顶排序',
    rename: '编辑名称',
    recommend: '推荐并置顶',
    cancelRecommend: '取消推荐',
    block: '屏蔽',
    restore: '恢复',
    merge: '合并话题',
    renameEyebrow: '编辑话题',
    renameHeading: '修改公开名称',
    renameSave: '保存名称',
    mergeEyebrow: '不可逆合并',
    mergeHeading: (sourceName) => `合并「${sourceName}」`,
    mergeDescription: '源帖子与关注关系会去重迁移，源话题随后屏蔽。这个动作不可逆。',
    mergeTargetPlaceholder: '选择目标话题',
    mergeConfirm: '确认不可逆合并',
    mergeConfirmPrompt: (sourceName, targetName) =>
      `将「${sourceName}」合并到「${targetName}」。帖子与关注会迁移，源话题将被屏蔽；该操作不可逆。`,
  },
  banners: {
    created: 'Banner 已创建',
    updated: 'Banner 已更新',
    enabled: 'Banner 已启用',
    disabled: 'Banner 已停用',
    deleted: 'Banner 已删除',
    deleteConfirm: (title) => `确认删除 Banner「${title}」？删除后首页会立即下线。`,
    eyebrow: '首页运营',
    heading: 'Banner 走真表，别再改种子 SQL 冒充运营配置。',
    description: (region) => `当前区域 ${region}。不筛城市时展示当前区域全部 Banner；按城市筛选时会同时展示区域通用和城市专属 Banner，便于对照 C 端首页结果。`,
    create: '新建 Banner',
    filterEyebrow: '展示范围',
    filterHeading: '先按城市看当前首页会吃到哪些 Banner',
    filterCityLabel: '城市筛选',
    filterCityAll: '全部 Banner（含区域通用和城市专属）',
    filterHelpLabel: '说明',
    filterHelpText: '`linkUrl` 当前只支持站内相对路径，例如 `/shops?cityId=101`。',
    loading: '加载中...',
    applyFilter: '查看当前城市效果',
    listEyebrow: 'Banner 列表',
    listHeading: '排序越小越靠前，停用后公开首页立即不再返回',
    tableHeaders: {
      scope: '范围',
      title: '标题',
      link: '落点',
      sort: '排序',
      status: '状态',
      actions: '操作',
    },
    empty: '当前没有 Banner。',
    scopeText: (cityId, cityName) => {
      if (cityId == null || cityId === 0) return '区域通用'
      return cityName || `城市 #${cityId}`
    },
    subtitleFallback: '无副标题',
    statusText: (enabled) => enabled ? '启用' : '停用',
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    delete: '删除',
    editorEyebrow: (editing) => editing ? '编辑 Banner' : '新建 Banner',
    editorHeading: (editing) => editing ? '改完立即影响后续返回结果' : '新建后按排序插入首页返回序列',
    labels: {
      cityScope: '城市范围',
      sort: '排序',
      title: '标题',
      subtitle: '副标题',
      imageUrl: '图片 URL',
      linkUrl: '站内落点',
    },
    cityScopeAll: '区域通用',
    saving: '保存中...',
    save: '保存 Banner',
  },
  operationActivities: {
    created: '活动已创建',
    updated: '活动已更新',
    statusUpdated: '活动状态已更新',
    deleted: '活动已删除',
    itemCreated: '资源项已创建',
    itemUpdated: '资源项已更新',
    itemEnabled: '资源项已启用',
    itemDisabled: '资源项已停用',
    itemDeleted: '资源项已删除',
    jsonParseError: (label) => `${label} 必须是合法 JSON`,
    jsonObjectError: (label) => `${label} 必须是 JSON 对象`,
    externalUrlRequired: '外链资源必须填写 URL',
    deleteActivityConfirm: (name) => `确认删除活动「${name}」？活动主体和资源项会一起删除。`,
    deleteItemConfirm: (title) => `确认删除资源项「${title}」？删除后活动页会立刻少一块内容。`,
    eyebrow: '活动运营',
    heading: '活动主体和挂载资源走真表，别再拿文档目标态当已上线。',
    description: (region) => `当前区域 ${region}。活动主体负责范围、时间和投放规则；资源项负责挂店铺、团购、帖子、榜单、话题或外链，两个层面都在这里收口。`,
    create: '新建活动',
    filtersEyebrow: '筛选范围',
    filtersHeading: '先按城市和状态看当前活动池，再决定挂什么资源',
    filterLabels: {
      city: '城市筛选',
      status: '状态筛选',
    },
    filterOptions: {
      allCities: '全部活动（含区域通用）',
      allStatuses: '全部状态',
    },
    loading: '加载中...',
    applyFilters: '应用筛选',
    listEyebrow: '活动列表',
    listHeading: '主体管范围和时间，资源项数量能直接看出这个活动是不是空壳',
    tableHeaders: {
      scopeCode: '范围 / 编码',
      activity: '活动信息',
      delivery: '投放',
      items: '资源项',
      status: '状态',
      actions: '操作',
    },
    empty: '当前筛选下没有活动。',
    scopeText: (cityId, cityName) => {
      if (cityId === 0) return '区域通用'
      return cityName || `城市 #${cityId}`
    },
    channelText: (channel, fallback) => {
      if (channel === 1) return '首页'
      if (channel === 2) return '搜索'
      if (channel === 3) return '频道'
      if (channel === 4) return '活动页'
      if (channel === 5) return '社区'
      return fallback || `频道 ${channel}`
    },
    typeText: (type, fallback) => {
      if (type === 1) return '专题活动'
      if (type === 2) return '节日活动'
      if (type === 3) return '新客活动'
      if (type === 4) return '商户扶持'
      if (type === 5) return '内容话题'
      return fallback || `类型 ${type}`
    },
    activityStatusText: (status, fallback) => {
      if (status === 0) return '草稿'
      if (status === 1) return '待上线'
      if (status === 2) return '上线中'
      if (status === 3) return '已下线'
      if (status === 4) return '已结束'
      return fallback || `状态 ${status}`
    },
    itemStatusText: (status, fallback) => {
      if (status === 1) return '启用'
      if (status === 2) return '停用'
      return fallback || `状态 ${status}`
    },
    startFallback: '未设开始时间',
    endFallback: '未设结束时间',
    manageItems: '管资源',
    edit: '编辑',
    changeStatus: '改状态',
    delete: '删除',
    activityEditorEyebrow: (editing) => editing ? '编辑活动主体' : '新建活动主体',
    activityEditorHeading: (editing) => editing ? '改范围、时间和规则，资源项不会被重置' : '先建主体，再去挂店铺、团购、榜单或外链',
    activityLabels: {
      cityScope: '城市范围',
      channel: '投放频道',
      type: '活动类型',
      startAt: '开始时间',
      name: '活动名称',
      code: '活动编码',
      cover: '封面 URL',
      landingUrl: '落地地址',
      endAt: '结束时间',
      rule: '规则 JSON',
    },
    activityPlaceholders: {
      startAt: '2026-09-01 00:00:00',
      endAt: '2026-09-30 23:59:59',
      rule: '{"audience":["student"],"sort":"manual"}',
    },
    saving: '保存中...',
    saveActivity: '保存活动',
    itemsEyebrow: '资源项管理',
    itemsHeading: (activityName) => activityName ? `给「${activityName}」挂资源` : '先选中一个活动，再管理资源项',
    itemsDescription: (scopeText, statusText) => `当前范围 ${scopeText}，状态 ${statusText}，可以混挂店铺、团购、帖子、榜单、话题和外链。`,
    createItem: '新增资源项',
    noActivitySelected: '当前筛选下还没有活动可管理资源项。',
    itemTableHeaders: {
      resource: '资源',
      copy: '展示文案',
      sort: '排序',
      status: '状态',
      actions: '操作',
    },
    itemsLoading: '加载中...',
    itemEmpty: '这个活动还没有资源项。',
    targetTypeText: (targetType, fallback) => {
      if (targetType === 1) return '店铺'
      if (targetType === 2) return '团购'
      if (targetType === 3) return '帖子'
      if (targetType === 4) return '榜单'
      if (targetType === 5) return '话题'
      if (targetType === 6) return '外链'
      return fallback || `资源 ${targetType}`
    },
    targetFallback: (targetId) => `目标 #${targetId}`,
    subtitleFallback: '无副标题',
    itemEditorEyebrow: (editing) => editing ? '编辑资源项' : '新建资源项',
    itemEditorHeading: (activityName, editing) => editing ? '改目标或文案后，活动位展示会立即跟着变' : `把资源挂到「${activityName}」底下`,
    itemLabels: {
      targetType: '资源类型',
      targetId: '目标 ID',
      title: '标题',
      subtitle: '副标题',
      image: '图片 URL',
      sort: '排序',
      badge: '角标',
      trackCode: '埋点编码',
      url: '外链 URL',
    },
    itemUrlPlaceholder: 'targetType=6 时必填',
    saveItem: '保存资源项',
    statusOptions: {
      draft: '草稿',
      scheduled: '待上线',
      live: '上线中',
      offline: '已下线',
      ended: '已结束',
    },
    channelOptions: {
      home: '首页',
      search: '搜索',
      channel: '频道',
      activityPage: '活动页',
      community: '社区',
    },
    typeOptions: {
      campaign: '专题活动',
      festival: '节日活动',
      newcomer: '新客活动',
      merchantSupport: '商户扶持',
      contentTopic: '内容话题',
    },
    targetTypeOptions: {
      shop: '店铺',
      deal: '团购',
      post: '帖子',
      rank: '榜单',
      topic: '话题',
      external: '外链',
    },
    itemEnable: '启用',
    itemDisable: '停用',
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
  circles: {
    loadError: 'Failed to load circles.',
    saveError: 'Failed to save the circle.',
    toggleError: 'Failed to update the circle status.',
    eyebrow: 'Community operations',
    heading: 'Official circles',
    description: 'Each region maintains its own circles. Once disabled, new joins and posting are blocked.',
    keywordPlaceholder: 'Search circles',
    statusOptions: {
      all: 'All statuses',
      enabled: 'Enabled',
      disabled: 'Disabled',
    },
    query: 'Search',
    editorPlaceholders: {
      name: 'Circle name',
      description: 'Circle summary',
      coverUrl: 'Cover URL (optional)',
      sort: 'Sort order',
    },
    saveUpdate: 'Save changes',
    create: 'Create circle',
    emptyDescription: 'No description yet',
    statusText: (status) => status === 1 ? 'Enabled' : 'Disabled',
    summary: (memberCount, postCount, sort) => `Members ${memberCount} · Posts ${postCount} · Sort ${sort}`,
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
  },
  hotWords: {
    created: 'Hot keyword created.',
    updated: 'Hot keyword updated.',
    enabled: 'Hot keyword enabled.',
    disabled: 'Hot keyword disabled.',
    deleted: 'Hot keyword deleted.',
    deleteConfirm: (keyword) => `Delete hot keyword "${keyword}"? Public search may fall back to derived statistics after removal.`,
    eyebrow: 'Search operations',
    heading: 'Use a real hot-keyword table instead of pretending fallback statistics are an operations strategy.',
    description: (region) => `Current region ${region}. As long as enabled hot keywords exist, public /search/hot results follow this ordering first. Only an empty list falls back to category and tag statistics.`,
    create: 'New hot keyword',
    listEyebrow: 'Hot keywords',
    listHeading: 'Lower sort values rank first, and disabling a keyword removes it from public search immediately.',
    tableHeaders: {
      keyword: 'Keyword',
      sort: 'Sort',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'There are no configured hot keywords for this region. Public search will fall back to derived results.',
    statusText: (enabled) => enabled ? 'Enabled' : 'Disabled',
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    delete: 'Delete',
    editorEyebrow: (editing) => editing ? 'Edit hot keyword' : 'New hot keyword',
    editorHeading: (editing) => editing ? 'Changes affect the public search panel immediately.' : 'New keywords enter the public hot-keyword list by sort order.',
    labels: {
      keyword: 'Keyword',
      sort: 'Sort',
    },
    saving: 'Saving...',
    save: 'Save hot keyword',
  },
  sensitiveWords: {
    created: 'Sensitive word created.',
    updated: 'Sensitive word updated.',
    enabled: 'Sensitive word enabled.',
    disabled: 'Sensitive word disabled.',
    deleted: 'Sensitive word deleted.',
    deleteConfirm: (word) => `Delete sensitive word "${word}"? The corresponding block rule stops applying immediately.`,
    eyebrow: 'Content governance',
    heading: 'Stand up the sensitive-word base layer first, then talk about third-party moderation.',
    description: (region) => `Current region ${region}. Enabled words block writes by substring match across reviews, posts, comments, and direct messages. Disabling or deleting a word takes effect immediately.`,
    create: 'New sensitive word',
    listEyebrow: 'Word list',
    listHeading: 'Managed by region, enforced immediately on the write path for enabled words.',
    tableHeaders: {
      word: 'Sensitive word',
      remark: 'Remark',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'There are no sensitive words for this region yet.',
    remarkFallback: '—',
    statusText: (enabled) => enabled ? 'Enabled' : 'Disabled',
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    delete: 'Delete',
    editorEyebrow: (editing) => editing ? 'Edit sensitive word' : 'New sensitive word',
    editorHeading: (editing) => editing ? 'Changes affect interception in this region immediately.' : 'New entries are enabled by default and participate in interception immediately.',
    labels: {
      word: 'Sensitive word',
      remark: 'Remark',
    },
    saving: 'Saving...',
    save: 'Save sensitive word',
  },
  rankConfigs: {
    loadError: 'Failed to load ranking rules.',
    weightSumError: 'The three weight values must add up to 1.',
    createSuccess: 'New rule draft created. It will not affect the live ranking until published.',
    createError: 'Failed to create the rule draft.',
    publishSuccess: (rankId, itemCount) => `Published successfully: ranking #${rankId} with ${itemCount} shops.`,
    publishError: 'Failed to publish the ranking.',
    rollbackSuccess: (rankId) => `A new version was generated from the historical rule and published as ranking #${rankId}.`,
    rollbackError: 'Failed to roll back the ranking rule.',
    eyebrow: 'Ranking operations',
    heading: 'Save rules as drafts first, then switch the ranking snapshot only after a successful publish.',
    description: 'If recalculation fails, the previous ranking stays live. One shaky click should not black out the public feed.',
    historyEyebrow: 'Rule history',
    historyHeading: (region) => `Historical versions for region ${region}`,
    loading: 'Loading...',
    tableHeaders: {
      type: 'Type',
      scope: 'Scope',
      version: 'Version',
      status: 'Status',
      actions: 'Actions',
    },
    scopeSummary: (cityId, categoryId) => `City ${cityId} / Category ${categoryId}`,
    rankTypeText: (rankType, fallback) => {
      if (rankType === 1) return 'Must-eat'
      if (rankType === 2) return 'Top rated'
      if (rankType === 3) return 'Popular'
      return fallback || `Ranking ${rankType}`
    },
    statusText: (status, fallback) => {
      if (status === 1) return 'Published'
      if (status === 2) return 'Archived'
      if (status === 0) return 'Draft'
      return fallback || `Status ${status}`
    },
    publish: 'Publish',
    rollback: 'Rollback to this rule',
    editorEyebrow: 'New draft',
    editorHeading: 'Create the next version',
    labels: {
      rankType: 'Ranking type',
      calcCycle: 'Calculation cycle',
      cityId: 'City ID',
      categoryId: 'Category ID',
      scoreWeight: 'Score weight',
      reviewWeight: 'Review-count weight',
      dealWeight: 'Deal weight',
      minScore: 'Minimum score',
      minReviewCount: 'Minimum review count',
    },
    rankTypeOptions: {
      mustEat: 'Must-eat',
      review: 'Top rated',
      hot: 'Popular',
    },
    calcCycleOptions: {
      day: 'Day',
      week: 'Week',
      month: 'Month',
      quarter: 'Quarter',
    },
    saving: 'Creating...',
    saveDraft: 'Save draft',
    readOnly: 'This account can view ranking history but cannot edit ranking rules.',
  },
  growthConfigs: {
    loadError: 'Failed to load the growth configuration.',
    ruleUpdateError: 'Failed to update the growth rule.',
    levelUpdateError: 'Failed to update the level.',
    ruleUpdated: (action) => `${action} updated.`,
    levelUpdated: (level) => `Lv${level} updated.`,
    eyebrow: 'Growth program',
    heading: 'Reward weights and level thresholds come straight from the database.',
    description: 'Changes affect future actions only. Historical ledgers are not rewritten.',
    rulesEyebrow: 'Action rewards',
    rulesHeading: 'Growth, points, and daily caps',
    levelsEyebrow: 'Level thresholds',
    levelsHeading: 'Lv1-Lv8 configuration',
    ruleHeaders: {
      action: 'Action',
      growthValue: 'Growth',
      points: 'Points',
      dailyLimit: 'Daily limit',
      enabled: 'Enabled',
      actions: 'Actions',
    },
    levelHeaders: {
      level: 'Level',
      name: 'Name',
      minGrowth: 'Minimum growth',
      enabled: 'Enabled',
      actions: 'Actions',
    },
    actionText: (action, fallback) => {
      if (action === 'review_create') return 'Review published'
      if (action === 'review_liked') return 'Review liked'
      if (action === 'review_image') return 'Photo review'
      if (action === 'order_complete') return 'Order completed'
      if (action === 'favorite_shop') return 'Shop favorited'
      return fallback || action
    },
    levelLabel: (level) => `Lv${level}`,
    save: 'Save',
  },
  topics: {
    loadError: 'Failed to load topics.',
    actionError: 'Action failed.',
    invalidMergeTarget: 'Select a valid merge target.',
    renamed: 'Topic name updated.',
    recommendationEnabled: 'Recommendation and pin order updated.',
    recommendationDisabled: 'Recommendation removed.',
    blocked: 'Topic blocked.',
    restored: 'Topic restored.',
    merged: 'Topic merge completed. Relationships and hot ranking were recalculated.',
    recalculated: (region, calculatedAt) => `${region} hot ranking recalculated: ${calculatedAt}`,
    headerEyebrow: (region) => `Topic operations · Current region ${region}`,
    heading: 'Topic governance console',
    description: 'Recommendations drive discovery, pinned sort enforces order, and merges clean up the duplicate-name mess.',
    recalculate: 'Recalculate hot ranking',
    filters: {
      keyword: 'Keyword',
      status: 'Status',
      recommended: 'Recommendation',
    },
    keywordPlaceholder: 'Find by exact name',
    statusOptions: {
      all: 'All statuses',
      live: 'Live',
      blocked: 'Blocked',
    },
    recommendationOptions: {
      all: 'All',
      recommended: 'Recommended',
      notRecommended: 'Not recommended',
    },
    query: 'Run filters',
    loading: 'Loading topics for this region...',
    statusChipText: (status) => status === 1 ? 'Live' : status === 2 ? 'Blocked' : `Status ${status}`,
    recommendedChip: 'Recommended',
    mergedTo: (topicId) => `Merged into #${topicId}`,
    metricLabels: {
      hotScore: 'Hot score',
      posts: 'Posts',
      followers: 'Followers',
    },
    activitySummary: (posts, likes, comments) => `${posts} posts · ${likes} likes · ${comments} comments`,
    calculatedAt: (value) => `Last calculated ${value}`,
    noSnapshot: 'No snapshot yet',
    pinLabel: 'Pinned sort',
    rename: 'Rename',
    recommend: 'Recommend + pin',
    cancelRecommend: 'Remove recommendation',
    block: 'Block',
    restore: 'Restore',
    merge: 'Merge topic',
    renameEyebrow: 'Rename topic',
    renameHeading: 'Change public name',
    renameSave: 'Save name',
    mergeEyebrow: 'Irreversible merge',
    mergeHeading: (sourceName) => `Merge "${sourceName}"`,
    mergeDescription: 'Posts and follows move over after deduplication, then the source topic is blocked. This action cannot be undone.',
    mergeTargetPlaceholder: 'Select target topic',
    mergeConfirm: 'Confirm irreversible merge',
    mergeConfirmPrompt: (sourceName, targetName) =>
      `Merge "${sourceName}" into "${targetName}". Posts and follows will move, the source topic will be blocked, and this action cannot be undone.`,
  },
  banners: {
    created: 'Banner created.',
    updated: 'Banner updated.',
    enabled: 'Banner enabled.',
    disabled: 'Banner disabled.',
    deleted: 'Banner deleted.',
    deleteConfirm: (title) => `Delete banner "${title}"? It will disappear from the homepage immediately.`,
    eyebrow: 'Homepage operations',
    heading: 'Use a real banner table instead of pretending seed SQL is operations config.',
    description: (region) => `Current region ${region}. Without a city filter you see every banner in the region. With one, you see both region-wide and city-specific banners so the public homepage result is easy to compare.`,
    create: 'New banner',
    filterEyebrow: 'Display scope',
    filterHeading: 'Filter by city first so you can see which banners the homepage will actually receive.',
    filterCityLabel: 'City filter',
    filterCityAll: 'All banners (region-wide + city-specific)',
    filterHelpLabel: 'Note',
    filterHelpText: '`linkUrl` currently supports only in-app relative paths, for example `/shops?cityId=101`.',
    loading: 'Loading...',
    applyFilter: 'Preview current city output',
    listEyebrow: 'Banner list',
    listHeading: 'Lower sort values rank first, and disabling a banner removes it from the public homepage immediately.',
    tableHeaders: {
      scope: 'Scope',
      title: 'Title',
      link: 'Destination',
      sort: 'Sort',
      status: 'Status',
      actions: 'Actions',
    },
    empty: 'There are no banners right now.',
    scopeText: (cityId, cityName) => {
      if (cityId == null || cityId === 0) return 'Region-wide'
      return cityName || `City #${cityId}`
    },
    subtitleFallback: 'No subtitle',
    statusText: (enabled) => enabled ? 'Enabled' : 'Disabled',
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    delete: 'Delete',
    editorEyebrow: (editing) => editing ? 'Edit banner' : 'New banner',
    editorHeading: (editing) => editing ? 'Changes affect subsequent API results immediately.' : 'New banners are inserted into the homepage sequence by sort order.',
    labels: {
      cityScope: 'Scope',
      sort: 'Sort',
      title: 'Title',
      subtitle: 'Subtitle',
      imageUrl: 'Image URL',
      linkUrl: 'In-app destination',
    },
    cityScopeAll: 'Region-wide',
    saving: 'Saving...',
    save: 'Save banner',
  },
  operationActivities: {
    created: 'Activity created.',
    updated: 'Activity updated.',
    statusUpdated: 'Activity status updated.',
    deleted: 'Activity deleted.',
    itemCreated: 'Item created.',
    itemUpdated: 'Item updated.',
    itemEnabled: 'Item enabled.',
    itemDisabled: 'Item disabled.',
    itemDeleted: 'Item deleted.',
    jsonParseError: (label) => `${label} must be valid JSON.`,
    jsonObjectError: (label) => `${label} must be a JSON object.`,
    externalUrlRequired: 'External-link resources must include a URL.',
    deleteActivityConfirm: (name) => `Delete activity "${name}"? The shell and all mounted items will be removed together.`,
    deleteItemConfirm: (title) => `Delete item "${title}"? The activity page will lose that slot immediately.`,
    eyebrow: 'Activity operations',
    heading: 'Store activity shells and mounted resources in real tables instead of pretending the target-state doc is already live.',
    description: (region) => `Current region ${region}. Activity shells define scope, timing, and delivery rules. Items attach shops, deals, posts, rankings, topics, or external links. Both layers are managed here.`,
    create: 'New activity',
    filtersEyebrow: 'Filters',
    filtersHeading: 'Filter by city and status first, then decide which resources to mount.',
    filterLabels: {
      city: 'City filter',
      status: 'Status filter',
    },
    filterOptions: {
      allCities: 'All activities (including region-wide)',
      allStatuses: 'All statuses',
    },
    loading: 'Loading...',
    applyFilters: 'Apply filters',
    listEyebrow: 'Activity list',
    listHeading: 'The shell defines scope and timing. The item count tells you immediately whether the activity is empty.',
    tableHeaders: {
      scopeCode: 'Scope / code',
      activity: 'Activity',
      delivery: 'Delivery',
      items: 'Items',
      status: 'Status',
      actions: 'Actions',
    },
    empty: 'No activities match the current filters.',
    scopeText: (cityId, cityName) => {
      if (cityId === 0) return 'Region-wide'
      return cityName || `City #${cityId}`
    },
    channelText: (channel, fallback) => {
      if (channel === 1) return 'Home'
      if (channel === 2) return 'Search'
      if (channel === 3) return 'Channel'
      if (channel === 4) return 'Activity page'
      if (channel === 5) return 'Community'
      return fallback || `Channel ${channel}`
    },
    typeText: (type, fallback) => {
      if (type === 1) return 'Campaign'
      if (type === 2) return 'Festival'
      if (type === 3) return 'Newcomer'
      if (type === 4) return 'Merchant support'
      if (type === 5) return 'Content topic'
      return fallback || `Type ${type}`
    },
    activityStatusText: (status, fallback) => {
      if (status === 0) return 'Draft'
      if (status === 1) return 'Scheduled'
      if (status === 2) return 'Live'
      if (status === 3) return 'Offline'
      if (status === 4) return 'Ended'
      return fallback || `Status ${status}`
    },
    itemStatusText: (status, fallback) => {
      if (status === 1) return 'Enabled'
      if (status === 2) return 'Disabled'
      return fallback || `Status ${status}`
    },
    startFallback: 'No start time',
    endFallback: 'No end time',
    manageItems: 'Manage items',
    edit: 'Edit',
    changeStatus: 'Update status',
    delete: 'Delete',
    activityEditorEyebrow: (editing) => editing ? 'Edit activity shell' : 'New activity shell',
    activityEditorHeading: (editing) => editing ? 'Update scope, timing, or rules without resetting mounted items.' : 'Create the shell first, then attach shops, deals, rankings, or links.',
    activityLabels: {
      cityScope: 'Scope',
      channel: 'Delivery channel',
      type: 'Activity type',
      startAt: 'Start time',
      name: 'Activity name',
      code: 'Activity code',
      cover: 'Cover URL',
      landingUrl: 'Landing URL',
      endAt: 'End time',
      rule: 'Rule JSON',
    },
    activityPlaceholders: {
      startAt: '2026-09-01 00:00:00',
      endAt: '2026-09-30 23:59:59',
      rule: '{"audience":["student"],"sort":"manual"}',
    },
    saving: 'Saving...',
    saveActivity: 'Save activity',
    itemsEyebrow: 'Item management',
    itemsHeading: (activityName) => activityName ? `Mounted items for "${activityName}"` : 'Select an activity before managing its items.',
    itemsDescription: (scopeText, statusText) => `Current scope ${scopeText}, status ${statusText}. You can mix shops, deals, posts, rankings, topics, and external links in one activity.`,
    createItem: 'New item',
    noActivitySelected: 'There is no activity selected under the current filters.',
    itemTableHeaders: {
      resource: 'Resource',
      copy: 'Copy',
      sort: 'Sort',
      status: 'Status',
      actions: 'Actions',
    },
    itemsLoading: 'Loading...',
    itemEmpty: 'This activity has no items yet.',
    targetTypeText: (targetType, fallback) => {
      if (targetType === 1) return 'Shop'
      if (targetType === 2) return 'Deal'
      if (targetType === 3) return 'Post'
      if (targetType === 4) return 'Ranking'
      if (targetType === 5) return 'Topic'
      if (targetType === 6) return 'External link'
      return fallback || `Resource ${targetType}`
    },
    targetFallback: (targetId) => `Target #${targetId}`,
    subtitleFallback: 'No subtitle',
    itemEditorEyebrow: (editing) => editing ? 'Edit item' : 'New item',
    itemEditorHeading: (activityName, editing) => editing ? 'Changing the target or copy updates the slot output immediately.' : `Attach a resource under "${activityName}"`,
    itemLabels: {
      targetType: 'Resource type',
      targetId: 'Target ID',
      title: 'Title',
      subtitle: 'Subtitle',
      image: 'Image URL',
      sort: 'Sort',
      badge: 'Badge',
      trackCode: 'Track code',
      url: 'External URL',
    },
    itemUrlPlaceholder: 'Required when targetType=6',
    saveItem: 'Save item',
    statusOptions: {
      draft: 'Draft',
      scheduled: 'Scheduled',
      live: 'Live',
      offline: 'Offline',
      ended: 'Ended',
    },
    channelOptions: {
      home: 'Home',
      search: 'Search',
      channel: 'Channel',
      activityPage: 'Activity page',
      community: 'Community',
    },
    typeOptions: {
      campaign: 'Campaign',
      festival: 'Festival',
      newcomer: 'Newcomer',
      merchantSupport: 'Merchant support',
      contentTopic: 'Content topic',
    },
    targetTypeOptions: {
      shop: 'Shop',
      deal: 'Deal',
      post: 'Post',
      rank: 'Ranking',
      topic: 'Topic',
      external: 'External link',
    },
    itemEnable: 'Enable',
    itemDisable: 'Disable',
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
