import type { MerchantRegion } from '@/composables/useMerchantSession'

export type MerchantLocaleTag = 'zh-CN' | 'en'

export interface MerchantStrings {
  tag: MerchantLocaleTag
  brand: string
  common: {
    requestFailed: string
    loading: string
    refresh: string
    cancel: string
    regionLabel: (region: MerchantRegion) => string
  }
  routeTitles: {
    workbench: string
    login: string
    register: string
    settlement: string
    dashboard: string
    shops: string
    reservations: string
    reservationSlots: string
    deals: string
    orders: string
    coupons: string
    reviews: string
    verified: string
    staffs: string
  }
  shell: {
    workbenchEyebrow: string
    currentPageEyebrow: string
    logout: string
  }
  auth: {
    loginHeading: string
    accountLabel: string
    passwordLabel: string
    loginError: string
    loginSubmitting: string
    loginButton: string
    loginSwitchLabel: string
    loginSwitchAction: string
    onboardingEyebrow: string
    registerHeroTitle: string
    registerHeroDescription: string
    registerSteps: [string, string, string]
    registerHeadingEyebrow: string
    registerHeading: string
    registerDescription: string
    regionLabel: string
    euRegionOption: string
    cnRegionOption: string
    registerError: string
    registerSubmitting: string
    registerButton: string
    registerSwitchLabel: string
    registerSwitchAction: string
    companyLabel: string
    contactNameLabel: string
    contactPhoneLabel: string
  }
  settlement: {
    eyebrow: string
    heading: string
    description: string
    loadError: string
    submitError: string
    loadingStatus: string
    pendingEyebrow: string
    pendingHeading: string
    pendingSubmittedAt: (submittedAt?: string) => string
    approvedEyebrow: string
    approvedHeading: string
    approvedDescription: string
    openWorkbench: string
    firstSubmitEyebrow: string
    firstSubmitHeading: string
    resubmitEyebrow: string
    resubmitHeading: string
    rejectReasonLabel: string
    licenseUrlLabel: string
    legalPersonLabel: string
    shopPhotoUrlsLabel: string
    submitReview: string
    submitting: string
    fallbackPendingStatusText: string
  }
  dashboard: {
    eyebrow: string
    merchantFallbackName: string
    dateRange: (dateFrom: unknown, dateTo: unknown) => string
    loadError: string
    missingPermission: (permission: string) => string
    metrics: {
      views: { label: string; note: string }
      paidOrders: { label: string; note: string }
      paidAmount: { label: string; note: string }
      verifiedCoupons: { label: string; note: string }
      rating: { label: string; note: string }
      reviewCount: { label: string; note: string }
    }
    todosHeading: string
    todoAction: string
    todoLabels: {
      pendingReservations: string
      confirmedReservations: string
      pendingRefunds: string
      pendingDeals: string
      rejectedDeals: string
      pendingShopChanges: string
      rejectedShopChanges: string
    }
    quickLinksHeading: string
    quickLinkEnter: string
    quickLinkNotes: {
      reservations: string
      orders: string
      coupons: string
      deals: string
      shops: string
      staffs: string
    }
  }
  reservations: {
    loadError: string
    actionError: string
    rejectReasonRequired: string
    successRejected: (reservationNo: string) => string
    successConfirmed: (reservationNo: string) => string
    successArrived: (reservationNo: string) => string
    successNoShow: (reservationNo: string) => string
    statusLabel: string
    statusOptions: {
      all: string
      pending: string
      confirmed: string
      arrived: string
      userCancelled: string
      merchantRejected: string
      noShow: string
    }
    summary: string
    headers: {
      reservationNo: string
      shop: string
      time: string
      contact: string
      status: string
      actions: string
    }
    peopleCount: (count: number) => string
    rejectPlaceholder: string
    confirm: string
    reject: string
    arrive: string
    noShow: string
    noAction: string
    empty: string
  }
  orders: {
    loadError: string
    auditError: string
    auditReasonRequired: string
    refundStatusLabel: string
    refundStatusOptions: {
      all: string
      pending: string
      success: string
      rejected: string
    }
    summary: string
    headers: {
      orderNo: string
      shop: string
      amount: string
      payment: string
      refund: string
      audit: string
    }
    noRefund: string
    auditPlaceholder: string
    approve: string
    reject: string
    noAction: string
    empty: string
  }
  coupons: {
    eyebrow: string
    heading: string
    description: string
    missingPermission: (permission: string) => string
    codeRequired: string
    verifyError: string
    verifySuccess: (code: string) => string
    codeLabel: string
    codePlaceholder: string
    verifying: string
    verify: string
    latestResultHeading: string
    dealFallback: (dealId: number) => string
    shopFallback: (shopId: number) => string
    fieldLabels: {
      code: string
      shop: string
      status: string
      verifiedAt: string
      expireAt: string
    }
    historyHeaders: {
      code: string
      deal: string
      shop: string
      status: string
      verifiedAt: string
    }
    statusText: (status: number, fallback?: string) => string
  }
  reviews: {
    summary: string
    loadError: string
    replyRequired: string
    replyError: string
    appealMinLength: string
    appealError: string
    headers: {
      user: string
      score: string
      content: string
      reply: string
      appeal: string
    }
    replyPlaceholder: string
    saveReply: string
    noReply: string
    appealPlaceholder: string
    submitAppeal: string
    noAppeal: string
    empty: string
    appealStatusText: (status: number, fallback?: string) => string
  }
  reservationSlots: {
    filters: {
      shop: string
      allShops: string
      startDate: string
      endDate: string
      status: string
      all: string
      enabled: string
      disabled: string
    }
    create: string
    summary: string
    missingPermission: (permission: string) => string
    successCreated: string
    successUpdated: string
    successEnabled: string
    successDisabled: string
    tableHeaders: {
      shop: string
      date: string
      slot: string
      capacity: string
      confirmMode: string
      status: string
      actions: string
    }
    capacitySummary: (reserved: number, capacity: number, remaining: number) => string
    confirmModeLabel: (confirmMode: number) => string
    confirmModeSummary: (confirmMode: number, cancelBeforeMinutes: number) => string
    statusText: (enabled: boolean) => string
    edit: string
    enable: string
    disable: string
    empty: string
    editorTitles: {
      create: string
      edit: string
    }
    editorLabels: {
      shop: string
      date: string
      start: string
      end: string
      capacity: string
      confirmMode: string
      cancelBefore: string
      enabled: string
    }
    saving: string
    save: string
  }
}

export type MerchantRouteTitleKey = keyof MerchantStrings['routeTitles']

const zhCnStrings: MerchantStrings = {
  tag: 'zh-CN',
  brand: '大众点评',
  common: {
    requestFailed: '请求失败',
    loading: '加载中...',
    refresh: '刷新',
    cancel: '取消',
    regionLabel: (region) => region === 'EU' ? '欧洲区' : '国内区',
  },
  routeTitles: {
    workbench: '商户工作台',
    login: '商户登录',
    register: '商户入驻',
    settlement: '经营资质',
    dashboard: '经营概览',
    shops: '门店管理',
    reservations: '预订处理',
    reservationSlots: '预订时段',
    deals: '团购管理',
    orders: '订单退款',
    coupons: '券码核销',
    reviews: '点评经营',
    verified: '认证商户',
    staffs: '员工管理',
  },
  shell: {
    workbenchEyebrow: '商户工作台',
    currentPageEyebrow: '当前页面',
    logout: '退出',
  },
  auth: {
    loginHeading: '登录经营后台',
    accountLabel: '账号',
    passwordLabel: '密码',
    loginError: '登录失败',
    loginSubmitting: '登录中...',
    loginButton: '登录',
    loginSwitchLabel: '还没有商户账号？',
    loginSwitchAction: '开始入驻',
    onboardingEyebrow: 'Merchant onboarding',
    registerHeroTitle: '把店开起来，别先被表格劝退。',
    registerHeroDescription: '注册主账号后直接提交经营资质。审核通过前不会开放经营数据，流程清楚，权限也不串门。',
    registerSteps: ['创建商户主体', '提交执照与门店照片', '审核通过后配置员工'],
    registerHeadingEyebrow: '商户入驻',
    registerHeading: '创建主账号',
    registerDescription: '这个账号拥有员工和门店权限管理能力，请使用长期可控的邮箱或手机号。',
    regionLabel: '经营区域',
    euRegionOption: '欧洲区 EU',
    cnRegionOption: '国内区 CN',
    registerError: '注册失败',
    registerSubmitting: '正在创建...',
    registerButton: '创建账号并提交资质',
    registerSwitchLabel: '已经有账号？',
    registerSwitchAction: '返回登录',
    companyLabel: '企业或个体名称',
    contactNameLabel: '联系人',
    contactPhoneLabel: '联系电话',
  },
  settlement: {
    eyebrow: 'Business verification',
    heading: '经营资质档案',
    description: '审核通过前，公开业务数据不会被新账号修改。先把材料交齐，再进经营台狠狠干活。',
    loadError: '资质状态加载失败',
    submitError: '资质提交失败',
    loadingStatus: '资质状态加载中...',
    pendingEyebrow: '审核中',
    pendingHeading: '资料已经进入审核队列',
    pendingSubmittedAt: (submittedAt) => `提交时间：${submittedAt || '刚刚提交'}。审核完成后重新进入此页即可查看结果。`,
    approvedEyebrow: '审核通过',
    approvedHeading: '经营工作台已经开放',
    approvedDescription: '现在可以维护门店、团购、预订、员工和点评经营。',
    openWorkbench: '进入经营工作台',
    firstSubmitEyebrow: '首次提交',
    firstSubmitHeading: '填写经营资质',
    resubmitEyebrow: '重新提交',
    resubmitHeading: '根据驳回意见更新材料',
    rejectReasonLabel: '驳回原因：',
    licenseUrlLabel: '营业执照图片 URL',
    legalPersonLabel: '法人或经营者姓名',
    shopPhotoUrlsLabel: '门店照片 URL（每行一张，最多 12 张）',
    submitReview: '提交审核',
    submitting: '提交中...',
    fallbackPendingStatusText: '待审核',
  },
  dashboard: {
    eyebrow: 'Merchant dashboard',
    merchantFallbackName: '商户',
    dateRange: (dateFrom, dateTo) => `统计区间：${String(dateFrom || '-')} ~ ${String(dateTo || '-')}`,
    loadError: '加载失败',
    missingPermission: (permission) => `当前账号缺少 \`${permission}\` 权限。`,
    metrics: {
      views: { label: '浏览量', note: '统计周期内门店浏览' },
      paidOrders: { label: '支付订单', note: '已支付订单数' },
      paidAmount: { label: '支付金额', note: '已支付订单金额' },
      verifiedCoupons: { label: '核销券', note: '到店核销成功券数' },
      rating: { label: '评分', note: '门店平均评分' },
      reviewCount: { label: '点评数', note: '累计公开点评' },
    },
    todosHeading: '待办与状态',
    todoAction: '去处理',
    todoLabels: {
      pendingReservations: '待确认预订',
      confirmedReservations: '已确认预订',
      pendingRefunds: '待处理退款',
      pendingDeals: '待审团购',
      rejectedDeals: '被驳回团购',
      pendingShopChanges: '待审门店草稿',
      rejectedShopChanges: '被驳回门店草稿',
    },
    quickLinksHeading: '快捷入口',
    quickLinkEnter: '进入',
    quickLinkNotes: {
      reservations: '确认、拒绝、到店、爽约',
      orders: '处理用户退款申请',
      coupons: '到店录码核销',
      deals: '创建/编辑并提交审核',
      shops: '新建/修改门店资料',
      staffs: '角色与门店范围',
    },
  },
  reservations: {
    loadError: '预订加载失败',
    actionError: '预订操作失败',
    rejectReasonRequired: '请填写拒绝原因',
    successRejected: (reservationNo) => `预订 ${reservationNo} 已拒绝`,
    successConfirmed: (reservationNo) => `预订 ${reservationNo} 已确认`,
    successArrived: (reservationNo) => `预订 ${reservationNo} 已确认到店`,
    successNoShow: (reservationNo) => `预订 ${reservationNo} 已标记爽约`,
    statusLabel: '状态',
    statusOptions: {
      all: '全部',
      pending: '待确认',
      confirmed: '已确认',
      arrived: '已到店',
      userCancelled: '用户取消',
      merchantRejected: '商户拒绝',
      noShow: '爽约',
    },
    summary: '默认看待确认；已确认预订可继续做到店确认或标记爽约。',
    headers: {
      reservationNo: '预订号',
      shop: '门店',
      time: '时间',
      contact: '联系人',
      status: '状态',
      actions: '操作',
    },
    peopleCount: (count) => `${count} 人`,
    rejectPlaceholder: '填写拒绝原因',
    confirm: '确认',
    reject: '拒绝',
    arrive: '确认到店',
    noShow: '标记爽约',
    noAction: '无需处理',
    empty: '当前筛选下没有预订。',
  },
  orders: {
    loadError: '订单加载失败',
    auditError: '退款审核失败',
    auditReasonRequired: '请填写退款审核原因',
    refundStatusLabel: '退款状态',
    refundStatusOptions: {
      all: '全部',
      pending: '申请中',
      success: '退款成功',
      rejected: '已驳回',
    },
    summary: '默认看“申请中”的退款；可切换查看历史审核结果。',
    headers: {
      orderNo: '订单号',
      shop: '门店',
      amount: '金额',
      payment: '支付',
      refund: '退款',
      audit: '审核',
    },
    noRefund: '无退款申请',
    auditPlaceholder: '填写审核原因',
    approve: '通过退款',
    reject: '驳回',
    noAction: '无需处理',
    empty: '当前筛选下没有订单。',
  },
  coupons: {
    eyebrow: 'Coupon verify',
    heading: '到店券码核销',
    description: '录入顾客出示的券码；成功后券状态变为已使用，重复核销会被拒绝。',
    missingPermission: (permission) => `当前账号缺少 \`${permission}\` 权限，不能核销券码。`,
    codeRequired: '请输入券码',
    verifyError: '券码核销失败',
    verifySuccess: (code) => `券码 ${code} 已核销成功`,
    codeLabel: '券码',
    codePlaceholder: '例如 VERIFYME001',
    verifying: '核销中...',
    verify: '确认核销',
    latestResultHeading: '最近一次核销',
    dealFallback: (dealId) => `deal:${dealId}`,
    shopFallback: (shopId) => `shop:${shopId}`,
    fieldLabels: {
      code: '券码：',
      shop: '门店：',
      status: '状态：',
      verifiedAt: '核销时间：',
      expireAt: '有效期至：',
    },
    historyHeaders: {
      code: '券码',
      deal: '团购',
      shop: '门店',
      status: '状态',
      verifiedAt: '核销时间',
    },
    statusText: (status, fallback) => {
      if (status === 2) return '已使用'
      if (status === 3) return '已过期'
      if (status === 4) return '已退款'
      if (status === 1) return '待使用'
      return fallback || `状态 ${status}`
    },
  },
  reviews: {
    summary: '回复可持续维护；申诉提交审核后转为只读状态。',
    loadError: '点评加载失败',
    replyRequired: '商家回复不能为空',
    replyError: '回复失败',
    appealMinLength: '申诉理由至少 10 个字。',
    appealError: '申诉失败',
    headers: {
      user: '用户',
      score: '评分',
      content: '内容',
      reply: '商家回复',
      appeal: '点评申诉',
    },
    replyPlaceholder: '输入公开回复',
    saveReply: '保存回复',
    noReply: '暂无回复',
    appealPlaceholder: '至少 10 个字，说明恶意或失实点',
    submitAppeal: '提交申诉',
    noAppeal: '暂无申诉',
    empty: '当前筛选下没有点评。',
    appealStatusText: (status, fallback) => {
      if (status === 1) return '待审核'
      if (status === 2) return '已通过'
      if (status === 3) return '已驳回'
      if (status === 4) return '已失效'
      if (status === 0) return '草稿'
      return fallback || `状态 ${status}`
    },
  },
  reservationSlots: {
    filters: {
      shop: '门店',
      allShops: '全部门店',
      startDate: '开始日期',
      endDate: '结束日期',
      status: '状态',
      all: '全部',
      enabled: '启用',
      disabled: '停用',
    },
    create: '新建时段',
    summary: '配置门店可订时段：容量、自动/人工确认、取消截止分钟数。停用后 C 端不可再订该时段。',
    missingPermission: (permission) => `当前账号缺少 \`${permission}\` 权限。`,
    successCreated: '时段已创建',
    successUpdated: '时段已更新',
    successEnabled: '时段已启用',
    successDisabled: '时段已停用',
    tableHeaders: {
      shop: '门店',
      date: '日期',
      slot: '时段',
      capacity: '容量',
      confirmMode: '确认方式',
      status: '状态',
      actions: '操作',
    },
    capacitySummary: (reserved, capacity, remaining) => `${reserved}/${capacity}（余 ${remaining}）`,
    confirmModeLabel: (confirmMode) => confirmMode === 1 ? '自动确认' : '人工确认',
    confirmModeSummary: (confirmMode, cancelBeforeMinutes) =>
      `${confirmMode === 1 ? '自动确认' : '人工确认'} · 取消前 ${cancelBeforeMinutes} 分`,
    statusText: (enabled) => enabled ? '启用' : '停用',
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    empty: '当前筛选下没有时段。',
    editorTitles: {
      create: '新建时段',
      edit: '编辑时段',
    },
    editorLabels: {
      shop: '门店',
      date: '日期',
      start: '开始',
      end: '结束',
      capacity: '容量',
      confirmMode: '确认方式',
      cancelBefore: '取消截止(分钟)',
      enabled: '启用',
    },
    saving: '保存中...',
    save: '保存时段',
  },
}

const enStrings: MerchantStrings = {
  tag: 'en',
  brand: 'Dazhong Dianping',
  common: {
    requestFailed: 'Request failed.',
    loading: 'Loading...',
    refresh: 'Refresh',
    cancel: 'Cancel',
    regionLabel: (region) => region === 'EU' ? 'Europe' : 'Mainland China',
  },
  routeTitles: {
    workbench: 'Merchant Console',
    login: 'Merchant Login',
    register: 'Merchant Onboarding',
    settlement: 'Business Verification',
    dashboard: 'Overview',
    shops: 'Shop Management',
    reservations: 'Reservations',
    reservationSlots: 'Reservation Slots',
    deals: 'Deals',
    orders: 'Orders & Refunds',
    coupons: 'Coupon Verification',
    reviews: 'Review Operations',
    verified: 'Verified Merchant',
    staffs: 'Staff Management',
  },
  shell: {
    workbenchEyebrow: 'Merchant Console',
    currentPageEyebrow: 'Current Page',
    logout: 'Sign out',
  },
  auth: {
    loginHeading: 'Sign in to the merchant console',
    accountLabel: 'Account',
    passwordLabel: 'Password',
    loginError: 'Sign-in failed.',
    loginSubmitting: 'Signing in...',
    loginButton: 'Sign in',
    loginSwitchLabel: 'No merchant account yet?',
    loginSwitchAction: 'Start onboarding',
    onboardingEyebrow: 'Merchant onboarding',
    registerHeroTitle: 'Open the storefront without getting buried in forms.',
    registerHeroDescription: 'Create the primary account and submit the operating documents right away. Business data stays locked until approval so the workflow is clear and permissions stay scoped.',
    registerSteps: ['Create the merchant entity', 'Upload the license and shop photos', 'Add staff after approval'],
    registerHeadingEyebrow: 'Merchant onboarding',
    registerHeading: 'Create the primary account',
    registerDescription: 'This account controls staff and shop permissions, so use a long-term email address or phone number.',
    regionLabel: 'Operating region',
    euRegionOption: 'Europe EU',
    cnRegionOption: 'Mainland China CN',
    registerError: 'Registration failed.',
    registerSubmitting: 'Creating account...',
    registerButton: 'Create account and submit verification',
    registerSwitchLabel: 'Already have an account?',
    registerSwitchAction: 'Back to sign in',
    companyLabel: 'Company or business name',
    contactNameLabel: 'Contact name',
    contactPhoneLabel: 'Contact phone',
  },
  settlement: {
    eyebrow: 'Business verification',
    heading: 'Business verification record',
    description: 'Before approval, public operating data stays locked for the new account. Submit the materials first, then move into the merchant console.',
    loadError: 'Failed to load verification status.',
    submitError: 'Failed to submit verification.',
    loadingStatus: 'Loading verification status...',
    pendingEyebrow: 'Under review',
    pendingHeading: 'Your documents are already in the review queue',
    pendingSubmittedAt: (submittedAt) => `Submitted: ${submittedAt || 'just now'}. Reopen this page after the review finishes to see the result.`,
    approvedEyebrow: 'Approved',
    approvedHeading: 'The merchant console is now available',
    approvedDescription: 'You can now manage shops, deals, reservations, staff, and reviews.',
    openWorkbench: 'Open merchant console',
    firstSubmitEyebrow: 'First submission',
    firstSubmitHeading: 'Fill in business verification details',
    resubmitEyebrow: 'Resubmit',
    resubmitHeading: 'Update the materials based on the rejection note',
    rejectReasonLabel: 'Rejection reason:',
    licenseUrlLabel: 'Business license image URL',
    legalPersonLabel: 'Legal representative or operator name',
    shopPhotoUrlsLabel: 'Shop photo URLs (one per line, up to 12)',
    submitReview: 'Submit for review',
    submitting: 'Submitting...',
    fallbackPendingStatusText: 'Pending review',
  },
  dashboard: {
    eyebrow: 'Merchant dashboard',
    merchantFallbackName: 'Merchant',
    dateRange: (dateFrom, dateTo) => `Reporting period: ${String(dateFrom || '-')} to ${String(dateTo || '-')}`,
    loadError: 'Failed to load dashboard data.',
    missingPermission: (permission) => `This account does not have the \`${permission}\` permission.`,
    metrics: {
      views: { label: 'Views', note: 'Shop page views during the selected period' },
      paidOrders: { label: 'Paid orders', note: 'Number of paid orders' },
      paidAmount: { label: 'Paid amount', note: 'Total paid order amount' },
      verifiedCoupons: { label: 'Verified coupons', note: 'Coupons successfully redeemed in store' },
      rating: { label: 'Rating', note: 'Average shop rating' },
      reviewCount: { label: 'Reviews', note: 'Public review count' },
    },
    todosHeading: 'To-dos & status',
    todoAction: 'Review',
    todoLabels: {
      pendingReservations: 'Pending reservations',
      confirmedReservations: 'Confirmed reservations',
      pendingRefunds: 'Pending refunds',
      pendingDeals: 'Pending deals',
      rejectedDeals: 'Rejected deals',
      pendingShopChanges: 'Pending shop drafts',
      rejectedShopChanges: 'Rejected shop drafts',
    },
    quickLinksHeading: 'Quick links',
    quickLinkEnter: 'Open',
    quickLinkNotes: {
      reservations: 'Confirm, reject, mark arrival, or no-show.',
      orders: 'Review customer refund requests.',
      coupons: 'Verify in-store coupon codes.',
      deals: 'Create, edit, and resubmit deals.',
      shops: 'Create or revise shop information.',
      staffs: 'Manage roles and shop scope.',
    },
  },
  reservations: {
    loadError: 'Failed to load reservations.',
    actionError: 'Failed to update the reservation.',
    rejectReasonRequired: 'Enter a rejection reason.',
    successRejected: (reservationNo) => `Reservation ${reservationNo} rejected.`,
    successConfirmed: (reservationNo) => `Reservation ${reservationNo} confirmed.`,
    successArrived: (reservationNo) => `Reservation ${reservationNo} marked as arrived.`,
    successNoShow: (reservationNo) => `Reservation ${reservationNo} marked as no-show.`,
    statusLabel: 'Status',
    statusOptions: {
      all: 'All',
      pending: 'Pending confirmation',
      confirmed: 'Confirmed',
      arrived: 'Arrived',
      userCancelled: 'Cancelled by customer',
      merchantRejected: 'Rejected by merchant',
      noShow: 'No-show',
    },
    summary: 'Pending reservations are shown by default. Confirmed bookings can still be marked as arrived or no-show.',
    headers: {
      reservationNo: 'Reservation',
      shop: 'Shop',
      time: 'Time',
      contact: 'Contact',
      status: 'Status',
      actions: 'Actions',
    },
    peopleCount: (count) => `${count} guests`,
    rejectPlaceholder: 'Enter rejection reason',
    confirm: 'Confirm',
    reject: 'Reject',
    arrive: 'Mark arrived',
    noShow: 'Mark no-show',
    noAction: 'No action required',
    empty: 'No reservations match the current filter.',
  },
  orders: {
    loadError: 'Failed to load orders.',
    auditError: 'Failed to audit the refund.',
    auditReasonRequired: 'Enter a refund audit reason.',
    refundStatusLabel: 'Refund status',
    refundStatusOptions: {
      all: 'All',
      pending: 'Pending',
      success: 'Refunded',
      rejected: 'Rejected',
    },
    summary: 'Pending refund requests are shown by default. Switch filters to review earlier decisions.',
    headers: {
      orderNo: 'Order',
      shop: 'Shop',
      amount: 'Amount',
      payment: 'Payment',
      refund: 'Refund',
      audit: 'Audit',
    },
    noRefund: 'No refund request',
    auditPlaceholder: 'Enter audit reason',
    approve: 'Approve refund',
    reject: 'Reject',
    noAction: 'No action required',
    empty: 'No orders match the current filter.',
  },
  coupons: {
    eyebrow: 'Coupon verification',
    heading: 'Verify in-store coupon codes',
    description: 'Enter the code shown by the customer. Successful verification marks the coupon as used, and duplicate verification attempts are rejected.',
    missingPermission: (permission) => `This account does not have the \`${permission}\` permission and cannot verify coupons.`,
    codeRequired: 'Enter a coupon code.',
    verifyError: 'Failed to verify the coupon.',
    verifySuccess: (code) => `Coupon ${code} verified successfully.`,
    codeLabel: 'Coupon code',
    codePlaceholder: 'For example: VERIFYME001',
    verifying: 'Verifying...',
    verify: 'Verify coupon',
    latestResultHeading: 'Latest verification',
    dealFallback: (dealId) => `deal:${dealId}`,
    shopFallback: (shopId) => `shop:${shopId}`,
    fieldLabels: {
      code: 'Code:',
      shop: 'Shop:',
      status: 'Status:',
      verifiedAt: 'Verified at:',
      expireAt: 'Valid until:',
    },
    historyHeaders: {
      code: 'Code',
      deal: 'Deal',
      shop: 'Shop',
      status: 'Status',
      verifiedAt: 'Verified at',
    },
    statusText: (status, fallback) => {
      if (status === 2) return 'Used'
      if (status === 3) return 'Expired'
      if (status === 4) return 'Refunded'
      if (status === 1) return 'Unused'
      return fallback || `Status ${status}`
    },
  },
  reviews: {
    summary: 'Replies stay editable. Appeals become read-only after submission for review.',
    loadError: 'Failed to load reviews.',
    replyRequired: 'Merchant reply cannot be empty.',
    replyError: 'Failed to save the reply.',
    appealMinLength: 'Appeal reason must be at least 10 characters.',
    appealError: 'Failed to submit the appeal.',
    headers: {
      user: 'User',
      score: 'Score',
      content: 'Content',
      reply: 'Merchant reply',
      appeal: 'Review appeal',
    },
    replyPlaceholder: 'Enter a public reply',
    saveReply: 'Save reply',
    noReply: 'No reply yet',
    appealPlaceholder: 'At least 10 characters explaining why the review is malicious or inaccurate',
    submitAppeal: 'Submit appeal',
    noAppeal: 'No appeal',
    empty: 'No reviews match the current filter.',
    appealStatusText: (status, fallback) => {
      if (status === 1) return 'Pending review'
      if (status === 2) return 'Approved'
      if (status === 3) return 'Rejected'
      if (status === 4) return 'Invalidated'
      if (status === 0) return 'Draft'
      return fallback || `Status ${status}`
    },
  },
  reservationSlots: {
    filters: {
      shop: 'Shop',
      allShops: 'All shops',
      startDate: 'Start date',
      endDate: 'End date',
      status: 'Status',
      all: 'All',
      enabled: 'Enabled',
      disabled: 'Disabled',
    },
    create: 'New slot',
    summary: 'Configure bookable shop slots: capacity, automatic or manual confirmation, and the cancellation cutoff. Disabled slots are no longer bookable on the consumer side.',
    missingPermission: (permission) => `This account does not have the \`${permission}\` permission.`,
    successCreated: 'Slot created.',
    successUpdated: 'Slot updated.',
    successEnabled: 'Slot enabled.',
    successDisabled: 'Slot disabled.',
    tableHeaders: {
      shop: 'Shop',
      date: 'Date',
      slot: 'Slot',
      capacity: 'Capacity',
      confirmMode: 'Confirmation',
      status: 'Status',
      actions: 'Actions',
    },
    capacitySummary: (reserved, capacity, remaining) => `${reserved}/${capacity} (${remaining} remaining)`,
    confirmModeLabel: (confirmMode) => confirmMode === 1 ? 'Auto-confirm' : 'Manual confirmation',
    confirmModeSummary: (confirmMode, cancelBeforeMinutes) =>
      `${confirmMode === 1 ? 'Auto-confirm' : 'Manual confirmation'} · cancel ${cancelBeforeMinutes} min before`,
    statusText: (enabled) => enabled ? 'Enabled' : 'Disabled',
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    empty: 'No slots match the current filter.',
    editorTitles: {
      create: 'New slot',
      edit: 'Edit slot',
    },
    editorLabels: {
      shop: 'Shop',
      date: 'Date',
      start: 'Start',
      end: 'End',
      capacity: 'Capacity',
      confirmMode: 'Confirmation',
      cancelBefore: 'Cancel cutoff (minutes)',
      enabled: 'Enabled',
    },
    saving: 'Saving...',
    save: 'Save slot',
  },
}

const STRINGS: Record<MerchantLocaleTag, MerchantStrings> = {
  'zh-CN': zhCnStrings,
  en: enStrings,
}

export function localeForRegion(region: MerchantRegion): MerchantLocaleTag {
  return region === 'EU' ? 'en' : 'zh-CN'
}

export function merchantStringsForLocale(locale: MerchantLocaleTag): MerchantStrings {
  return STRINGS[locale]
}

export function merchantStringsForRegion(region: MerchantRegion): MerchantStrings {
  return merchantStringsForLocale(localeForRegion(region))
}
