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
  staffManagement: {
    eyebrow: string
    heading: string
    description: string
    create: string
    loadError: string
    scopedShopRequired: string
    roleRequired: string
    saveError: string
    statusError: string
    loading: string
    tableHeaders: {
      staff: string
      roles: string
      shopScope: string
      status: string
      actions: string
    }
    allShops: string
    scopedShops: (count: number) => string
    statusText: (status: number) => string
    edit: string
    enable: string
    disable: string
    empty: string
    dialogEyebrow: {
      create: string
      edit: string
    }
    dialogTitle: {
      create: string
      edit: string
    }
    close: string
    labels: {
      account: string
      password: string
      name: string
      email: string
      phone: string
      roles: string
      shopScope: string
      manageableShops: string
      allShops: string
      selectedShops: string
    }
    saving: string
    save: string
  }
  verifiedMerchant: {
    eyebrow: string
    heading: string
    description: string
    loadError: string
    reasonRequired: string
    submitError: string
    submitSuccess: string
    loading: string
    badgeLabel: string
    statusText: (status: number, fallback?: string) => string
    approvedEyebrow: string
    approvedHeading: string
    approvedDescription: (auditedAt?: string) => string
    effectiveStart: (effectiveStartAt: string) => string
    pendingEyebrow: string
    pendingHeading: string
    pendingDescription: (submittedAt?: string) => string
    reasonLabel: string
    rejectedEyebrow: string
    rejectedHeading: string
    rejectReasonLabel: string
    missingReason: string
    auditedAt: (auditedAt: string) => string
    applyHeading: string
    reapplyHeading: string
    labels: {
      reason: string
      evidenceUrls: string
    }
    placeholders: {
      reason: string
      evidenceUrls: string
    }
    submitting: string
    submit: string
  }
  deals: {
    eyebrow: string
    heading: string
    description: string
    detailLoadError: string
    validations: {
      shopRequired: string
      titleRequired: string
      coverImageRequired: string
      pricePositive: string
      originalPricePositive: string
      stockMin: string
      itemNameRequired: (index: number) => string
      itemQuantityInvalid: (index: number) => string
      itemPriceInvalid: (index: number) => string
    }
    loadError: string
    createNotice: string
    updateNotice: string
    saveError: string
    enabledNotice: string
    disabledNotice: string
    toggleError: string
    filterLabel: string
    filterOptions: {
      pendingOrRejected: string
      all: string
      pending: string
      approved: string
      rejected: string
    }
    create: string
    missingPermission: (permission: string) => string
    formTitles: {
      create: string
      edit: (dealId: number) => string
    }
    rejectReasonSummary: (reason: string) => string
    missingRejectReason: string
    labels: {
      shop: string
      type: string
      title: string
      coverImage: string
      price: string
      originalPrice: string
      currency: string
      stock: string
      validStart: string
      validEnd: string
      rules: string
    }
    placeholders: {
      selectShop: string
      title: string
      rules: string
      itemName: string
      itemQuantity: string
      itemPrice: string
      itemSort: string
    }
    typeOptions: {
      packageDeal: string
      voucher: string
    }
    itemSectionHeading: string
    addItem: string
    deleteItem: string
    submitting: string
    submitCreate: string
    submitUpdate: string
    tableHeaders: {
      deal: string
      shop: string
      price: string
      audit: string
      availability: string
      actions: string
    }
    stockSummary: (stock: number, soldCount: number) => string
    auditStatusText: (status: number, fallback?: string) => string
    rejectReasonLabel: string
    liveStatusText: (status: number, fallback?: string) => string
    goLive: string
    takeDown: string
    edit: string
    readOnly: string
    empty: string
  }
  shopDrafts: {
    eyebrow: string
    heading: string
    description: string
    loadError: string
    draftLoadError: string
    newDraftNotice: string
    newDraftError: string
    updateDraftOpened: string
    currentDraftStatus: (statusText: string) => string
    updateDraftError: string
    validations: {
      categoryRequired: string
      cityRequired: string
      areaRequired: string
      nameRequired: string
      coverUrlRequired: string
      priceInvalid: string
      addressRequired: string
      businessHoursRequired: string
      summaryRequired: string
      latitudeInvalid: string
      longitudeInvalid: string
      photoUrlRequired: (index: number) => string
      photoRequired: string
      coverPhotoMismatch: string
      dishNameRequired: (index: number) => string
      dishPriceInvalid: (index: number) => string
      noActiveDraft: string
    }
    saveNotice: string
    saveError: string
    submitNotice: string
    submitError: string
    areasLoadError: string
    filterLabel: string
    filterOptions: {
      pendingOrRejected: string
      all: string
      draft: string
      pending: string
      approved: string
      rejected: string
    }
    create: string
    missingPermission: (permission: string) => string
    loading: string
    liveTableHeaders: {
      shop: string
      region: string
      city: string
      score: string
      status: string
      actions: string
    }
    liveShopStatusText: (openNow: boolean | null | undefined, fallback?: string) => string
    createUpdateDraft: string
    readOnly: string
    noLiveShops: string
    draftListHeading: string
    draftTableHeaders: {
      draft: string
      type: string
      targetShop: string
      status: string
      actions: string
    }
    draftFallbackName: (draftId: number) => string
    changeTypeText: (changeType: number) => string
    draftStatusText: (status: number, fallback?: string) => string
    rejectReasonLabel: string
    open: string
    editorTitle: (draftId: number) => string
    editorSubtitle: (changeType: number, targetShopId: number, statusText: string) => string
    editorRejectSummary: (reason: string) => string
    collapseEditor: string
    labels: {
      category: string
      city: string
      area: string
      openStatus: string
      name: string
      coverUrl: string
      phone: string
      pricePerCapita: string
      currency: string
      businessHours: string
      address: string
      latitude: string
      longitude: string
      tags: string
      summary: string
    }
    placeholders: {
      selectCategory: string
      selectCity: string
      selectArea: string
      tags: string
      photoUrl: string
      sort: string
      dishName: string
      dishPrice: string
      dishReason: string
    }
    openStatusOptions: {
      open: string
      closed: string
    }
    photoSectionHeading: string
    addPhoto: string
    photoTypeOptions: {
      cover: string
      environment: string
      dish: string
    }
    dishSectionHeading: string
    addDish: string
    delete: string
    saving: string
    saveDraft: string
    submitReview: string
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
  staffManagement: {
    eyebrow: 'Access control',
    heading: '员工与门店权限',
    description: '账号能干什么、能碰哪家店，在这里说清楚，别靠口头传功。',
    create: '新增员工',
    loadError: '员工数据加载失败',
    scopedShopRequired: '指定门店范围时至少选择一家门店',
    roleRequired: '至少选择一个员工角色',
    saveError: '员工保存失败',
    statusError: '员工状态更新失败',
    loading: '员工数据加载中...',
    tableHeaders: {
      staff: '员工',
      roles: '角色',
      shopScope: '门店范围',
      status: '状态',
      actions: '操作',
    },
    allShops: '全部门店',
    scopedShops: (count) => `${count} 家指定门店`,
    statusText: (status) => status === 1 ? '启用' : '停用',
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    empty: '还没有员工账号。',
    dialogEyebrow: {
      create: 'New staff',
      edit: 'Edit staff',
    },
    dialogTitle: {
      create: '创建员工账号',
      edit: '编辑员工权限',
    },
    close: '关闭',
    labels: {
      account: '登录账号',
      password: '初始密码',
      name: '员工姓名',
      email: '邮箱',
      phone: '联系电话',
      roles: '角色',
      shopScope: '门店范围',
      manageableShops: '可管理门店',
      allShops: '全部门店',
      selectedShops: '指定门店',
    },
    saving: '保存中...',
    save: '保存员工',
  },
  verifiedMerchant: {
    eyebrow: 'Verified merchant',
    heading: '认证商户',
    description: '资质审核通过后，可额外申请公开“认证商户”标识。待审或已通过时不可重复提交，驳回后可重提。',
    loadError: '认证商户状态加载失败',
    reasonRequired: '请填写认证申请理由',
    submitError: '认证商户申请提交失败',
    submitSuccess: '认证商户申请已提交，等待管理端审核。',
    loading: '认证状态加载中...',
    badgeLabel: '认证商户',
    statusText: (status, fallback) => {
      if (status === 1) return '待审核'
      if (status === 2) return '已通过'
      if (status === 3) return '已驳回'
      if (status === 0) return '未申请'
      return fallback || `状态 ${status}`
    },
    approvedEyebrow: '审核结果 · 已通过',
    approvedHeading: '当前门店可展示',
    approvedDescription: (auditedAt) => `通过时间：${auditedAt || '—'}。公开门店详情、列表与搜索结果会同步挂标。`,
    effectiveStart: (effectiveStartAt) => `生效开始：${effectiveStartAt}`,
    pendingEyebrow: '审核中',
    pendingHeading: '认证申请已进入审核队列',
    pendingDescription: (submittedAt) => `提交时间：${submittedAt || '刚刚提交'}。通过后会在门店详情公开挂标。`,
    reasonLabel: '申请理由：',
    rejectedEyebrow: '审核结果 · 已驳回',
    rejectedHeading: '请根据驳回原因修改后重提',
    rejectReasonLabel: '驳回原因：',
    missingReason: '未填写',
    auditedAt: (auditedAt) => `审核时间：${auditedAt}`,
    applyHeading: '提交认证申请',
    reapplyHeading: '重新提交认证申请',
    labels: {
      reason: '申请理由',
      evidenceUrls: '证明材料链接（可选，每行一个）',
    },
    placeholders: {
      reason: '说明经营合规、服务承诺或可核验材料',
      evidenceUrls: 'https://...',
    },
    submitting: '提交中...',
    submit: '提交认证申请',
  },
  deals: {
    eyebrow: 'Deal management',
    heading: '团购创建与编辑',
    description: '默认看待审/被驳回；创建/编辑后会回到待审下架，审核通过后才能上架销售。',
    detailLoadError: '团购详情加载失败',
    validations: {
      shopRequired: '请选择门店',
      titleRequired: '请填写团购标题',
      coverImageRequired: '请填写封面图 URL',
      pricePositive: '售价必须大于 0',
      originalPricePositive: '原价必须大于 0',
      stockMin: '库存不能小于 -1',
      itemNameRequired: (index) => `第 ${index} 个套餐项名称不能为空`,
      itemQuantityInvalid: (index) => `第 ${index} 个套餐项数量无效`,
      itemPriceInvalid: (index) => `第 ${index} 个套餐项价格无效`,
    },
    loadError: '团购加载失败',
    createNotice: '团购已创建并提交审核',
    updateNotice: '团购已更新并重新提交审核',
    saveError: '团购保存失败',
    enabledNotice: '团购已上架',
    disabledNotice: '团购已下架',
    toggleError: '上下架失败',
    filterLabel: '审核状态',
    filterOptions: {
      pendingOrRejected: '待审/被驳回',
      all: '全部',
      pending: '待审',
      approved: '已通过',
      rejected: '已驳回',
    },
    create: '新建团购',
    missingPermission: (permission) => `当前账号缺少 \`${permission}\` 权限，只能查看列表。`,
    formTitles: {
      create: '新建团购',
      edit: (dealId) => `编辑团购 #${dealId}`,
    },
    rejectReasonSummary: (reason) => `最近驳回原因：${reason}。修改后保存会重新提交审核。`,
    missingRejectReason: '未填写',
    labels: {
      shop: '门店',
      type: '类型',
      title: '标题',
      coverImage: '封面图 URL',
      price: '售价',
      originalPrice: '原价',
      currency: '币种',
      stock: '库存（-1 不限）',
      validStart: '有效开始',
      validEnd: '有效结束',
      rules: '使用规则',
    },
    placeholders: {
      selectShop: '请选择门店',
      title: '例如 双人午市套餐',
      rules: '周末通用；需提前预约...',
      itemName: '项目名称',
      itemQuantity: '数量',
      itemPrice: '价格',
      itemSort: '排序',
    },
    typeOptions: {
      packageDeal: '团购套餐',
      voucher: '代金券',
    },
    itemSectionHeading: '套餐明细',
    addItem: '添加明细',
    deleteItem: '删除',
    submitting: '提交中...',
    submitCreate: '创建并提交审核',
    submitUpdate: '保存并重新提交',
    tableHeaders: {
      deal: '套餐',
      shop: '门店',
      price: '价格',
      audit: '审核',
      availability: '上下架',
      actions: '操作',
    },
    stockSummary: (stock, soldCount) => `库存 ${stock} · 已售 ${soldCount}`,
    auditStatusText: (status, fallback) => {
      if (status === 1) return '已通过'
      if (status === 2) return '已驳回'
      if (status === 0) return '待审核'
      return fallback || `状态 ${status}`
    },
    rejectReasonLabel: '驳回原因：',
    liveStatusText: (status, fallback) => {
      if (status === 1) return '已上架'
      if (status === 0) return '已下架'
      return fallback || `状态 ${status}`
    },
    goLive: '上架',
    takeDown: '下架',
    edit: '编辑',
    readOnly: '只读',
    empty: '还没有团购，先建一个吧。',
  },
  shopDrafts: {
    eyebrow: 'Shop drafts',
    heading: '门店与草稿审核',
    description: '默认看待审/被驳回草稿；先建草稿，再改基础资料/相册/菜单，提交审核前线上门店数据不会变。',
    loadError: '门店数据加载失败',
    draftLoadError: '草稿加载失败',
    newDraftNotice: '新门店草稿已创建',
    newDraftError: '创建草稿失败',
    updateDraftOpened: '已打开门店修改草稿',
    currentDraftStatus: (statusText) => `当前草稿状态：${statusText}`,
    updateDraftError: '创建修改草稿失败',
    validations: {
      categoryRequired: '请选择分类',
      cityRequired: '请选择城市',
      areaRequired: '请选择商圈',
      nameRequired: '请填写门店名称',
      coverUrlRequired: '请填写封面图 URL',
      priceInvalid: '人均价格无效',
      addressRequired: '请填写地址',
      businessHoursRequired: '请填写营业时间',
      summaryRequired: '请填写门店简介',
      latitudeInvalid: '纬度无效',
      longitudeInvalid: '经度无效',
      photoUrlRequired: (index) => `第 ${index} 张图片地址不能为空`,
      photoRequired: '至少上传 1 张门店图片',
      coverPhotoMismatch: '封面图必须同时出现在相册中，且 photoType=1',
      dishNameRequired: (index) => `第 ${index} 个菜品名称不能为空`,
      dishPriceInvalid: (index) => `第 ${index} 个菜品价格无效`,
      noActiveDraft: '没有可保存的草稿',
    },
    saveNotice: '草稿已保存（基础资料 / 相册 / 菜单）',
    saveError: '草稿保存失败',
    submitNotice: '门店变更已提交审核，审核通过前不会改动线上门店',
    submitError: '提交审核失败',
    areasLoadError: '商圈加载失败',
    filterLabel: '草稿状态',
    filterOptions: {
      pendingOrRejected: '待审/被驳回',
      all: '全部',
      draft: '草稿',
      pending: '待审',
      approved: '已通过',
      rejected: '已驳回',
    },
    create: '新建门店草稿',
    missingPermission: (permission) => `当前账号缺少 \`${permission}\` 权限，只能查看线上门店。`,
    loading: '加载中...',
    liveTableHeaders: {
      shop: '门店',
      region: '区域',
      city: '城市',
      score: '评分',
      status: '状态',
      actions: '操作',
    },
    liveShopStatusText: (openNow, fallback) => {
      if (openNow === true) return '营业中'
      if (openNow === false) return '休息中'
      return fallback || '-'
    },
    createUpdateDraft: '修改草稿',
    readOnly: '只读',
    noLiveShops: '当前还没有线上门店，可先新建门店草稿。',
    draftListHeading: '草稿列表',
    draftTableHeaders: {
      draft: '草稿',
      type: '类型',
      targetShop: '目标门店',
      status: '状态',
      actions: '操作',
    },
    draftFallbackName: (draftId) => `草稿 #${draftId}`,
    changeTypeText: (changeType) => changeType === 1 ? '新门店' : '修改门店',
    draftStatusText: (status, fallback) => {
      if (status === 1) return '待审核'
      if (status === 2) return '已通过'
      if (status === 3) return '已驳回'
      if (status === 4) return '已失效'
      if (status === 0) return '草稿'
      return fallback || `状态 ${status}`
    },
    rejectReasonLabel: '驳回：',
    open: '打开',
    editorTitle: (draftId) => `编辑草稿 #${draftId}`,
    editorSubtitle: (changeType, targetShopId, statusText) =>
      `${changeType === 1 ? '新门店草稿' : `修改门店 #${targetShopId}`} · ${statusText}`,
    editorRejectSummary: (reason) => `驳回原因：${reason}。修改后可重新保存并提交审核。`,
    collapseEditor: '收起编辑器',
    labels: {
      category: '分类',
      city: '城市',
      area: '商圈',
      openStatus: '营业状态',
      name: '门店名称',
      coverUrl: '封面图 URL',
      phone: '电话',
      pricePerCapita: '人均价格',
      currency: '币种',
      businessHours: '营业时间',
      address: '地址',
      latitude: '纬度',
      longitude: '经度',
      tags: '标签（逗号分隔）',
      summary: '简介',
    },
    placeholders: {
      selectCategory: '请选择分类',
      selectCity: '请选择城市',
      selectArea: '请选择商圈',
      tags: 'Chinese,Spicy',
      photoUrl: '图片 URL',
      sort: '排序',
      dishName: '菜品名',
      dishPrice: '价格',
      dishReason: '推荐理由',
    },
    openStatusOptions: {
      open: '营业中',
      closed: '休息中',
    },
    photoSectionHeading: '相册（1-20，封面必须 photoType=1）',
    addPhoto: '添加图片',
    photoTypeOptions: {
      cover: '封面',
      environment: '环境',
      dish: '菜品',
    },
    dishSectionHeading: '菜单（最多 100）',
    addDish: '添加菜品',
    delete: '删除',
    saving: '保存中...',
    saveDraft: '保存草稿',
    submitReview: '提交审核',
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
  staffManagement: {
    eyebrow: 'Access control',
    heading: 'Staff & shop permissions',
    description: 'Define exactly what each account can do and which shops it can access. Do not leave this to informal handoffs.',
    create: 'Add staff',
    loadError: 'Failed to load staff data.',
    scopedShopRequired: 'Select at least one shop when using scoped shop access.',
    roleRequired: 'Select at least one staff role.',
    saveError: 'Failed to save the staff account.',
    statusError: 'Failed to update the staff status.',
    loading: 'Loading staff data...',
    tableHeaders: {
      staff: 'Staff',
      roles: 'Roles',
      shopScope: 'Shop scope',
      status: 'Status',
      actions: 'Actions',
    },
    allShops: 'All shops',
    scopedShops: (count) => `${count} scoped shops`,
    statusText: (status) => status === 1 ? 'Enabled' : 'Disabled',
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    empty: 'No staff accounts yet.',
    dialogEyebrow: {
      create: 'New staff',
      edit: 'Edit staff',
    },
    dialogTitle: {
      create: 'Create staff account',
      edit: 'Edit staff permissions',
    },
    close: 'Close',
    labels: {
      account: 'Account',
      password: 'Initial password',
      name: 'Staff name',
      email: 'Email',
      phone: 'Phone',
      roles: 'Roles',
      shopScope: 'Shop scope',
      manageableShops: 'Managed shops',
      allShops: 'All shops',
      selectedShops: 'Selected shops',
    },
    saving: 'Saving...',
    save: 'Save staff',
  },
  verifiedMerchant: {
    eyebrow: 'Verified merchant',
    heading: 'Verified merchant',
    description: 'After business verification is approved, you can additionally apply for the public "Verified Merchant" badge. Pending or approved applications cannot be submitted again, while rejected ones can be resubmitted.',
    loadError: 'Failed to load the verified merchant status.',
    reasonRequired: 'Enter the reason for this verified merchant application.',
    submitError: 'Failed to submit the verified merchant application.',
    submitSuccess: 'Verified merchant application submitted. Awaiting review.',
    loading: 'Loading verification status...',
    badgeLabel: 'Verified Merchant',
    statusText: (status, fallback) => {
      if (status === 1) return 'Pending review'
      if (status === 2) return 'Approved'
      if (status === 3) return 'Rejected'
      if (status === 0) return 'Not applied'
      return fallback || `Status ${status}`
    },
    approvedEyebrow: 'Review result · approved',
    approvedHeading: 'This shop can now display',
    approvedDescription: (auditedAt) => `Approved at: ${auditedAt || '—'}. The badge will appear on public shop details, listings, and search results.`,
    effectiveStart: (effectiveStartAt) => `Effective from: ${effectiveStartAt}`,
    pendingEyebrow: 'Under review',
    pendingHeading: 'The verified merchant application is already in the review queue',
    pendingDescription: (submittedAt) => `Submitted: ${submittedAt || 'just now'}. The badge will appear on the public shop detail page after approval.`,
    reasonLabel: 'Reason:',
    rejectedEyebrow: 'Review result · rejected',
    rejectedHeading: 'Update the application based on the rejection reason and resubmit',
    rejectReasonLabel: 'Rejection reason:',
    missingReason: 'Not provided',
    auditedAt: (auditedAt) => `Reviewed at: ${auditedAt}`,
    applyHeading: 'Submit verified merchant application',
    reapplyHeading: 'Resubmit verified merchant application',
    labels: {
      reason: 'Application reason',
      evidenceUrls: 'Evidence links (optional, one per line)',
    },
    placeholders: {
      reason: 'Explain compliance, service commitments, or verifiable proof',
      evidenceUrls: 'https://...',
    },
    submitting: 'Submitting...',
    submit: 'Submit verified merchant application',
  },
  deals: {
    eyebrow: 'Deal management',
    heading: 'Create and edit deals',
    description: 'Pending and rejected deals are shown by default. Creating or editing a deal sends it back to pending review in the offline state until approval.',
    detailLoadError: 'Failed to load deal details.',
    validations: {
      shopRequired: 'Select a shop.',
      titleRequired: 'Enter a deal title.',
      coverImageRequired: 'Enter a cover image URL.',
      pricePositive: 'Sale price must be greater than 0.',
      originalPricePositive: 'Original price must be greater than 0.',
      stockMin: 'Stock cannot be lower than -1.',
      itemNameRequired: (index) => `Item ${index} must have a name.`,
      itemQuantityInvalid: (index) => `Item ${index} has an invalid quantity.`,
      itemPriceInvalid: (index) => `Item ${index} has an invalid price.`,
    },
    loadError: 'Failed to load deals.',
    createNotice: 'Deal created and submitted for review.',
    updateNotice: 'Deal updated and resubmitted for review.',
    saveError: 'Failed to save the deal.',
    enabledNotice: 'Deal is now live.',
    disabledNotice: 'Deal has been taken down.',
    toggleError: 'Failed to update the live status.',
    filterLabel: 'Audit status',
    filterOptions: {
      pendingOrRejected: 'Pending or rejected',
      all: 'All',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    create: 'New deal',
    missingPermission: (permission) => `This account does not have the \`${permission}\` permission and can only view the list.`,
    formTitles: {
      create: 'New deal',
      edit: (dealId) => `Edit deal #${dealId}`,
    },
    rejectReasonSummary: (reason) => `Latest rejection reason: ${reason}. Saving will resubmit the deal for review.`,
    missingRejectReason: 'Not provided',
    labels: {
      shop: 'Shop',
      type: 'Type',
      title: 'Title',
      coverImage: 'Cover image URL',
      price: 'Sale price',
      originalPrice: 'Original price',
      currency: 'Currency',
      stock: 'Stock (-1 for unlimited)',
      validStart: 'Valid from',
      validEnd: 'Valid until',
      rules: 'Usage rules',
    },
    placeholders: {
      selectShop: 'Select a shop',
      title: 'For example: Lunch set for two',
      rules: 'Valid on weekends; reservation required...',
      itemName: 'Item name',
      itemQuantity: 'Quantity',
      itemPrice: 'Price',
      itemSort: 'Sort order',
    },
    typeOptions: {
      packageDeal: 'Set meal',
      voucher: 'Voucher',
    },
    itemSectionHeading: 'Package items',
    addItem: 'Add item',
    deleteItem: 'Delete',
    submitting: 'Submitting...',
    submitCreate: 'Create and submit',
    submitUpdate: 'Save and resubmit',
    tableHeaders: {
      deal: 'Deal',
      shop: 'Shop',
      price: 'Price',
      audit: 'Audit',
      availability: 'Live status',
      actions: 'Actions',
    },
    stockSummary: (stock, soldCount) => `Stock ${stock} · Sold ${soldCount}`,
    auditStatusText: (status, fallback) => {
      if (status === 1) return 'Approved'
      if (status === 2) return 'Rejected'
      if (status === 0) return 'Pending review'
      return fallback || `Status ${status}`
    },
    rejectReasonLabel: 'Rejection reason:',
    liveStatusText: (status, fallback) => {
      if (status === 1) return 'Live'
      if (status === 0) return 'Offline'
      return fallback || `Status ${status}`
    },
    goLive: 'Put live',
    takeDown: 'Take down',
    edit: 'Edit',
    readOnly: 'Read-only',
    empty: 'No deals yet. Create the first one.',
  },
  shopDrafts: {
    eyebrow: 'Shop drafts',
    heading: 'Shop drafts and audit flow',
    description: 'Pending and rejected drafts are shown by default. Create a draft first, then update base information, gallery, and menu. Live shop data stays unchanged until approval.',
    loadError: 'Failed to load shop data.',
    draftLoadError: 'Failed to load the draft.',
    newDraftNotice: 'New shop draft created.',
    newDraftError: 'Failed to create a new draft.',
    updateDraftOpened: 'Opened the shop update draft.',
    currentDraftStatus: (statusText) => `Current draft status: ${statusText}`,
    updateDraftError: 'Failed to create an update draft.',
    validations: {
      categoryRequired: 'Select a category.',
      cityRequired: 'Select a city.',
      areaRequired: 'Select an area.',
      nameRequired: 'Enter the shop name.',
      coverUrlRequired: 'Enter a cover image URL.',
      priceInvalid: 'Price per capita is invalid.',
      addressRequired: 'Enter the address.',
      businessHoursRequired: 'Enter business hours.',
      summaryRequired: 'Enter the shop summary.',
      latitudeInvalid: 'Latitude is invalid.',
      longitudeInvalid: 'Longitude is invalid.',
      photoUrlRequired: (index) => `Photo ${index} must include an image URL.`,
      photoRequired: 'Upload at least one shop photo.',
      coverPhotoMismatch: 'The cover image must also appear in the gallery with photoType=1.',
      dishNameRequired: (index) => `Dish ${index} must have a name.`,
      dishPriceInvalid: (index) => `Dish ${index} has an invalid price.`,
      noActiveDraft: 'There is no active draft to save.',
    },
    saveNotice: 'Draft saved (base information, gallery, and menu).',
    saveError: 'Failed to save the draft.',
    submitNotice: 'Shop changes submitted for review. The live shop stays unchanged until approval.',
    submitError: 'Failed to submit the draft for review.',
    areasLoadError: 'Failed to load areas.',
    filterLabel: 'Draft status',
    filterOptions: {
      pendingOrRejected: 'Pending or rejected',
      all: 'All',
      draft: 'Draft',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    create: 'New shop draft',
    missingPermission: (permission) => `This account does not have the \`${permission}\` permission and can only view live shops.`,
    loading: 'Loading...',
    liveTableHeaders: {
      shop: 'Shop',
      region: 'Region',
      city: 'City',
      score: 'Score',
      status: 'Status',
      actions: 'Actions',
    },
    liveShopStatusText: (openNow, fallback) => {
      if (openNow === true) return 'Open now'
      if (openNow === false) return 'Closed'
      return fallback || '-'
    },
    createUpdateDraft: 'Create update draft',
    readOnly: 'Read-only',
    noLiveShops: 'There are no live shops yet. Start by creating a new shop draft.',
    draftListHeading: 'Draft list',
    draftTableHeaders: {
      draft: 'Draft',
      type: 'Type',
      targetShop: 'Target shop',
      status: 'Status',
      actions: 'Actions',
    },
    draftFallbackName: (draftId) => `Draft #${draftId}`,
    changeTypeText: (changeType) => changeType === 1 ? 'New shop' : 'Update shop',
    draftStatusText: (status, fallback) => {
      if (status === 1) return 'Pending review'
      if (status === 2) return 'Approved'
      if (status === 3) return 'Rejected'
      if (status === 4) return 'Invalidated'
      if (status === 0) return 'Draft'
      return fallback || `Status ${status}`
    },
    rejectReasonLabel: 'Rejected:',
    open: 'Open',
    editorTitle: (draftId) => `Edit draft #${draftId}`,
    editorSubtitle: (changeType, targetShopId, statusText) =>
      `${changeType === 1 ? 'New shop draft' : `Update shop #${targetShopId}`} · ${statusText}`,
    editorRejectSummary: (reason) => `Rejection reason: ${reason}. Update the draft and save or resubmit it.`,
    collapseEditor: 'Collapse editor',
    labels: {
      category: 'Category',
      city: 'City',
      area: 'Area',
      openStatus: 'Operating status',
      name: 'Shop name',
      coverUrl: 'Cover image URL',
      phone: 'Phone',
      pricePerCapita: 'Price per capita',
      currency: 'Currency',
      businessHours: 'Business hours',
      address: 'Address',
      latitude: 'Latitude',
      longitude: 'Longitude',
      tags: 'Tags (comma-separated)',
      summary: 'Summary',
    },
    placeholders: {
      selectCategory: 'Select a category',
      selectCity: 'Select a city',
      selectArea: 'Select an area',
      tags: 'Chinese,Spicy',
      photoUrl: 'Image URL',
      sort: 'Sort order',
      dishName: 'Dish name',
      dishPrice: 'Price',
      dishReason: 'Recommendation',
    },
    openStatusOptions: {
      open: 'Open now',
      closed: 'Closed',
    },
    photoSectionHeading: 'Gallery (1-20 images, and the cover must use photoType=1)',
    addPhoto: 'Add image',
    photoTypeOptions: {
      cover: 'Cover',
      environment: 'Environment',
      dish: 'Dish',
    },
    dishSectionHeading: 'Menu (up to 100 items)',
    addDish: 'Add dish',
    delete: 'Delete',
    saving: 'Saving...',
    saveDraft: 'Save draft',
    submitReview: 'Submit for review',
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
