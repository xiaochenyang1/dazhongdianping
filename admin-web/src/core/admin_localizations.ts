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
