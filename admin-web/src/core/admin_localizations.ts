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
    pointsProductManagement: string
    pointsExchangeManagement: string
    systemAdmins: string
    systemRoles: string
    systemUsers: string
    systemMerchants: string
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
  basicDataManagement: {
    eyebrow: (region: Region) => string
    heading: string
    description: string
    writable: string
    readOnly: string
    tabsAriaLabel: string
    tabs: {
      categories: string
      cities: string
      areas: string
    }
    loading: (region: Region) => string
    actions: {
      save: string
      edit: string
      enable: string
      disable: string
      delete: string
    }
    statusText: (status: number) => string
    category: {
      heading: string
      summary: (count: number) => string
      create: string
      labels: {
        parent: string
        name: string
        sort: string
      }
      root: string
      tableHeaders: {
        name: string
        parent: string
        sort: string
        status: string
        actions: string
      }
      empty: string
      createSuccess: string
      updateSuccess: string
      enableSuccess: string
      disableSuccess: string
      deleteSuccess: string
      deleteConfirm: (name: string) => string
      editTitle: string
    }
    city: {
      heading: string
      summary: (count: number) => string
      create: string
      labels: {
        code: string
        name: string
        sort: string
      }
      tableHeaders: {
        city: string
        code: string
        sort: string
        status: string
        actions: string
      }
      empty: string
      createSuccess: string
      updateSuccess: string
      enableSuccess: string
      disableSuccess: string
      deleteSuccess: string
      deleteConfirm: (name: string) => string
    }
    area: {
      heading: string
      summary: string
      create: string
      cityFilterLabel: string
      selectCity: string
      disabledSuffix: string
      labels: {
        city: string
        name: string
        sort: string
      }
      tableHeaders: {
        area: string
        city: string
        sort: string
        status: string
        actions: string
      }
      loading: string
      emptySelectCity: string
      empty: string
      createSuccess: string
      updateSuccess: string
      enableSuccess: string
      disableSuccess: string
      deleteSuccess: string
      deleteConfirm: (name: string) => string
    }
  }
  shopImport: {
    loadError: string
    importError: string
    invalidRecords: string
    importSuccess: (success: number, failed: number) => string
    eyebrow: string
    heading: string
    description: string
    resetExample: string
    importing: string
    startImport: string
    requestEyebrow: string
    requestHeading: (region: Region) => string
    requestNote: string
    labels: {
      fileName: string
      region: string
      records: string
    }
    fileNamePlaceholder: string
    recordsPlaceholder: string
    validIdsTitle: string
    validIds: (region: Region) => string
    resultEyebrow: string
    resultHeading: string
    resultCards: {
      total: string
      batch: (batchId: number) => string
      success: string
      failure: string
      noErrorFile: string
    }
    batchesEyebrow: string
    batchesHeading: string
    batchesSummary: (total: number) => string
    filters: {
      status: string
    }
    statusOptions: {
      all: string
      processing: string
      completed: string
      failed: string
    }
    applyFilters: string
    refresh: string
    tableHeaders: {
      batch: string
      fileName: string
      result: string
      status: string
      errorFile: string
    }
    loading: string
    empty: string
    resultSummary: (success: number, failed: number) => string
    statusText: (status: number, fallback?: string) => string
    previousPage: string
    page: (page: number) => string
    nextPage: string
  }
  shopManagement: {
    loadError: string
    initError: string
    detailLoadError: string
    saveError: string
    deleteError: string
    createSuccess: string
    updateSuccess: string
    deleteSuccess: string
    deleteConfirm: (shopName: string) => string
    validationErrors: {
      categoryCityAreaRequired: string
      basicsRequired: string
      coordinatesPairRequired: string
      latitudeRange: string
      longitudeRange: string
    }
    eyebrow: string
    heading: (region: Region) => string
    description: string
    refresh: string
    create: string
    filters: {
      eyebrow: string
      heading: string
      count: (start: number, end: number, total: number) => string
      emptyCount: string
      labels: {
        keyword: string
        city: string
        area: string
        category: string
      }
      placeholders: {
        keyword: string
      }
      options: {
        allCities: string
        allAreas: string
        allCategories: string
      }
      apply: string
      reset: string
    }
    tableHeaders: {
      shop: string
      merchant: string
      categoryRegion: string
      cityArea: string
      price: string
      status: string
      actions: string
    }
    listLoading: string
    listEmpty: string
    merchantFallback: string
    statusText: (status: number, fallback?: string) => string
    edit: string
    view: string
    delete: string
    deleting: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editor: {
      eyebrow: string
      heading: (shopId: number | null) => string
      loading: string
      regionNote: (region: Region) => string
      readOnly: string
      readOnlyMessage: string
      labels: {
        merchantId: string
        category: string
        city: string
        area: string
        name: string
        phone: string
        coverUrl: string
        pricePerCapita: string
        currency: string
        businessHours: string
        status: string
        address: string
        latitude: string
        longitude: string
        score: string
        tasteScore: string
        envScore: string
        serviceScore: string
        tags: string
        summary: string
        createdAt: string
        updatedAt: string
      }
      placeholders: {
        merchantId: string
        category: string
        city: string
        area: string
        name: string
        phone: string
        coverUrl: string
        businessHours: string
        address: string
        latitude: string
        longitude: string
        tags: string
        summary: string
      }
      statusOptions: {
        open: string
        closed: string
        offline: string
      }
      toggles: {
        hasDeal: string
        openNow: string
      }
      previewFallbacks: {
        alt: string
        title: string
        address: string
        businessHours: string
      }
      reset: string
      saving: string
      saveUpdate: string
      create: string
      demoMerchantIds: string
    }
  }
  userManagement: {
    loadError: string
    detailLoadError: string
    banReasonRequired: string
    banError: string
    unbanError: string
    bannedMessage: (userLabel: string) => string
    unbannedMessage: (userLabel: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    filters: {
      keyword: string
      userId: string
      status: string
      region: string
      keywordPlaceholder: string
      userIdPlaceholder: string
      statusOptions: {
        all: string
        active: string
        banned: string
        deleted: string
      }
      regionAll: string
      apply: string
    }
    tableHeaders: {
      user: string
      account: string
      regionLevel: string
      growthPoints: string
      status: string
      lastLogin: string
      actions: string
    }
    listLoading: string
    empty: string
    userFallback: (userId: number) => string
    userIdLabel: (userId: number) => string
    levelLabel: (level: number) => string
    statusText: (status: number, fallback?: string) => string
    neverLoggedIn: string
    detailAction: string
    banAction: string
    unbanAction: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    detailLoading: string
    detailEyebrow: string
    detailSummary: (account: string, region: string) => string
    signatureLabel: string
    banReasonLabel: string
    pendingAppeal: (count: number) => string
    goAppealAudit: string
    latestAppealLabel: string
    appealStatusText: (statusText: string) => string
    stats: {
      reviewCount: string
      postCount: string
      orderCount: string
      reservationCount: string
      favoriteCount: string
      activeSessions: string
      growthValue: string
      createdAt: string
    }
    close: string
    banEyebrow: string
    banDescription: string
    banReasonField: string
    banPlaceholder: string
    confirmBan: string
  }
  merchantManagement: {
    loadError: string
    detailLoadError: string
    disableReasonRequired: string
    disableError: string
    enableError: string
    disabledMessage: (merchant: string) => string
    enabledMessage: (merchant: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    filters: {
      keyword: string
      merchantId: string
      auditStatus: string
      status: string
      keywordPlaceholder: string
      merchantIdPlaceholder: string
      all: string
      pending: string
      approved: string
      rejected: string
      active: string
      disabled: string
      apply: string
    }
    tableHeaders: {
      merchant: string
      contact: string
      auditStatus: string
      accountStatus: string
      resources: string
      updatedAt: string
      actions: string
    }
    loading: string
    empty: string
    merchantFallback: (merchantId: number) => string
    merchantIdLabel: (merchantId: number) => string
    contactFallback: string
    resourceSummary: (shops: number, activeOperators: number, operators: number) => string
    detailAction: string
    disableAction: string
    enableAction: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    detailLoading: string
    detailEyebrow: string
    detailSummary: (account: string, region: string) => string
    detailFields: {
      auditStatus: string
      accountStatus: string
      shops: string
      operators: string
      activeOperators: string
      disableReason: string
      createdAt: string
      updatedAt: string
    }
    close: string
    disableEyebrow: string
    disableDescription: string
    disableReasonField: string
    disablePlaceholder: string
    confirmDisable: string
    staff: {
      action: string
      eyebrow: string
      heading: (merchant: string) => string
      description: string
      loadError: string
      detailLoadError: string
      disableReasonRequired: string
      disableError: string
      enableError: string
      disabledMessage: (operator: string) => string
      enabledMessage: (operator: string) => string
      metaLoading: string
      metaSummary: (total: number) => string
      filters: {
        keyword: string
        keywordPlaceholder: string
        status: string
        all: string
        active: string
        disabled: string
        apply: string
      }
      tableHeaders: {
        operator: string
        contact: string
        roles: string
        shopScope: string
        status: string
        actions: string
      }
      loading: string
      empty: string
      operatorFallback: (operatorId: number) => string
      operatorIdLabel: (operatorId: number) => string
      contactFallback: string
      rolesFallback: string
      allShops: string
      selectedShops: (shopIds: number[]) => string
      detailAction: string
      disableAction: string
      enableAction: string
      previousPage: string
      page: (page: number) => string
      nextPage: string
      detailLoading: string
      detailEyebrow: string
      detailSummary: (account: string) => string
      detailFields: {
        roles: string
        shopScope: string
        status: string
        disableReason: string
        createdAt: string
        updatedAt: string
      }
      close: string
      disableEyebrow: string
      disableDescription: string
      disableReasonField: string
      disablePlaceholder: string
      confirmDisable: string
    }
    history: {
      action: string
      eyebrow: string
      heading: (merchant: string) => string
      description: string
      loadError: string
      metaLoading: string
      metaSummary: (total: number) => string
      filters: {
        operatorId: string
        operatorIdPlaceholder: string
        action: string
        actionPlaceholder: string
        targetType: string
        keyword: string
        keywordPlaceholder: string
        allTargets: string
        targets: {
          staff: string
          shop: string
          shopChange: string
          deal: string
          order: string
          review: string
        }
        apply: string
      }
      tableHeaders: {
        time: string
        operator: string
        action: string
        target: string
        detail: string
      }
      loading: string
      empty: string
      operatorFallback: (operatorId: number) => string
      actionText: (action: string) => string
      targetText: (targetType: string, targetId: number) => string
      detailFallback: string
      previousPage: string
      page: (page: number) => string
      nextPage: string
      close: string
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
  reviewAudit: {
    loadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    resetRefresh: string
    tableHeaders: {
      task: string
      shop: string
      submitter: string
      status: string
      submittedAt: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    taskTypeLabel: string
    shopFallback: string
    submitterFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number | null) => string
    editorStatusFallback: string
    metaLabels: {
      shop: string
      submitter: string
      submittedAt: string
      updatedAt: string
    }
    updatedAtFallback: string
    summaryLabel: string
    summaryFallback: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    acting: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  postAudit: {
    loadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      author: string
      summary: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    authorFallback: string
    summaryFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    metaLabels: {
      post: string
      author: string
      region: string
      submittedAt: string
    }
    detailLabel: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  dealAudit: {
    loadError: string
    detailLoadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      merchant: string
      shop: string
      title: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    merchantFallback: string
    shopFallback: (shopId: number | null) => string
    shopIdLabel: (shopId: number) => string
    titleFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    metaLabels: {
      deal: string
      merchant: string
      shop: string
      region: string
      submittedAt: string
      bizType: string
    }
    detailLoading: string
    detailLabels: {
      price: string
      originalPrice: string
      stock: string
      validPeriod: string
      rules: string
      items: string
      coverAlt: string
    }
    unlimited: string
    noRules: string
    itemHeaders: {
      name: string
      quantity: string
      price: string
    }
    itemEmpty: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  shopChangeAudit: {
    loadError: string
    detailLoadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      merchant: string
      candidateShop: string
      summary: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    merchantFallback: string
    candidateShopFallback: string
    targetShopLabel: (shopId: number | null) => string
    summaryFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    metaLabels: {
      draft: string
      merchant: string
      candidateShop: string
      targetShop: string
      region: string
      submittedAt: string
    }
    detailSummaryLabel: string
    detailLoading: string
    detailLabels: {
      changeType: string
      phone: string
      pricePerCapita: string
      businessHours: string
      address: string
      tags: string
      gallery: string
      menu: string
    }
    changeTypeText: (changeType: number) => string
    emptyValue: string
    photoAlt: (index: number) => string
    emptyGallery: string
    dishHeaders: {
      name: string
      price: string
      recommendReason: string
    }
    dishRecommendFallback: string
    dishEmpty: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  reviewAppealAudit: {
    loadError: string
    actionError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      shop: string
      summary: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    shopFallback: string
    summaryFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    pageSummary: (page: number, total: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    editorSummaryLabel: string
    passRemarkLabel: string
    rejectReasonLabel: string
    pass: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  userAppealAudit: {
    loadError: string
    actionError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      user: string
      reason: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    userFallback: string
    reasonFallback: string
    statusText: (status: number, fallback?: string) => string
    view: string
    previousPage: string
    pageSummary: (page: number, total: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    detailLabels: {
      user: string
      reason: string
    }
    passRemarkLabel: string
    rejectReasonLabel: string
    pass: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  expertCertificationAudit: {
    loadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      applicant: string
      summary: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    applicantFallback: string
    summaryFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    metaLabels: {
      application: string
      applicant: string
      region: string
      submittedAt: string
    }
    summaryLabel: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  verifiedMerchantAudit: {
    loadError: string
    passError: string
    rejectError: string
    rejectReasonRequired: string
    passed: (taskId: number) => string
    rejected: (taskId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
      keyword: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    keywordPlaceholder: string
    applyFilters: string
    tableHeaders: {
      task: string
      applicant: string
      summary: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    taskLabel: (bizId: number) => string
    applicantFallback: string
    summaryFallback: string
    statusText: (status: number, fallback?: string) => string
    selected: string
    view: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    editorEyebrow: string
    editorHeading: (taskId: number) => string
    metaLabels: {
      application: string
      applicant: string
      region: string
      submittedAt: string
    }
    summaryLabel: string
    approveRemarkLabel: string
    approveRemarkPlaceholder: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    approve: string
    reject: string
    readOnly: string
    handled: string
    emptyState: string
  }
  merchantApplicationAudit: {
    loadError: string
    actionError: string
    rejectReasonRequired: string
    approvedMessage: (companyName: string) => string
    rejectedMessage: (companyName: string) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    refresh: string
    listEyebrow: string
    listHeading: string
    listSummary: (total: number) => string
    filters: {
      status: string
    }
    statusOptions: {
      all: string
      pending: string
      approved: string
      rejected: string
    }
    applyFilters: string
    tableHeaders: {
      merchant: string
      legal: string
      shopPhotos: string
      status: string
      actions: string
    }
    loading: string
    empty: string
    licenseLink: string
    shopPhotoAlt: (index: number) => string
    statusText: (status: number, fallback?: string) => string
    approve: string
    reject: string
    readOnly: string
    handled: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    rejectEyebrow: string
    rejectDescription: string
    rejectReasonLabel: string
    rejectReasonPlaceholder: string
    confirmReject: string
  }
  reportManagement: {
    loadError: string
    actionError: string
    upheldMessage: (reportId: number, contentHidden: boolean) => string
    dismissedMessage: (reportId: number) => string
    eyebrow: string
    heading: string
    description: (region: Region) => string
    filters: {
      reportType: string
      status: string
      keyword: string
    }
    reportTypeOptions: {
      all: string
      review: string
      post: string
      message: string
      reviewComment: string
      postComment: string
    }
    statusOptions: {
      all: string
      pending: string
      upheld: string
      dismissed: string
    }
    keywordPlaceholder: string
    query: string
    tableHeaders: {
      type: string
      summary: string
      reporter: string
      reason: string
      status: string
      time: string
    }
    loading: string
    empty: string
    reportTypeText: (reportType: string, fallback?: string) => string
    targetTypeText: (reportType: string, targetType?: number | null, fallback?: string) => string
    statusText: (status: number, fallback?: string) => string
    targetStatusText: (
      reportType: string,
      targetAuditStatus?: number | null,
      fallback?: string,
    ) => string
    detailEyebrow: string
    detailHeading: (reportType: string, reportId: number) => string
    detailLabels: {
      target: string
      author: string
      targetStatus: string
      reporter: string
      reason: string
      summary: string
      time: string
    }
    summaryFallback: string
    authorFallback: string
    targetStatusFallback: string
    remarkPlaceholder: string
    dismissAction: string
    upholdAction: string
    readOnly: string
    handled: string
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
    updateSuccess: string
    updateError: string
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
    edit: string
    editorEyebrow: string
    editorHeading: string
    editingEyebrow: string
    editingHeading: (version: number) => string
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
    updating: string
    saveEdit: string
    cancelEdit: string
    readOnly: string
  }
  growthConfigs: {
    loadError: string
    ruleUpdateError: string
    ruleCreateError: string
    ruleActionRequired: string
    levelUpdateError: string
    ruleUpdated: (action: string) => string
    ruleCreated: (action: string) => string
    levelUpdated: (level: number) => string
    eyebrow: string
    heading: string
    description: string
    rulesEyebrow: string
    rulesHeading: string
    createEyebrow: string
    createHeading: string
    levelsEyebrow: string
    levelsHeading: string
    newRuleLabels: {
      action: string
      actionName: string
      growthValue: string
      points: string
      dailyLimit: string
      enabled: string
    }
    actionPlaceholder: string
    createRule: string
    creating: string
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
  adminAccounts: {
    loadError: string
    saveError: string
    statusUpdateError: string
    resetPasswordError: string
    roleRequired: string
    regionRequired: string
    cityRequired: (region: Region) => string
    passwordMin: string
    resetPasswordMin: string
    statusConfirm: (name: string, action: 'enable' | 'disable') => string
    eyebrow: string
    heading: string
    description: string
    create: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaOperator: (name: string) => string
    tableHeaders: {
      account: string
      roles: string
      scope: string
      lastLogin: string
      status: string
      actions: string
    }
    roleFallback: string
    scopeAllCities: string
    scopeEntry: (region: Region, detail: string) => string
    neverLoggedIn: string
    statusText: (status: number) => string
    edit: string
    resetPassword: string
    enable: string
    disable: string
    selfDisableTitle: string
    empty: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
    formEyebrow: string
    formHeading: (editing: boolean) => string
    labels: {
      account: string
      password: string
      name: string
      roles: string
      regions: string
      cityScopes: string
    }
    scopeModeText: (mode: 'all' | 'cities' | 'shops') => string
    scopeModeOptions: {
      all: string
      cities: string
      shops: string
    }
    noCities: string
    noShops: string
    saving: string
    save: string
    resetEyebrow: string
    resetHeading: (name: string) => string
    resetLabel: string
    resetSubmit: string
  }
  adminRoles: {
    loadError: string
    saveError: string
    statusUpdateError: string
    deleteError: string
    permissionRequired: string
    statusConfirm: (name: string, action: 'enable' | 'disable') => string
    deleteConfirm: (name: string) => string
    eyebrow: string
    heading: string
    description: string
    create: string
    metaLoading: string
    metaSummary: (total: number) => string
    metaDescription: string
    tableHeaders: {
      role: string
      permissions: string
      admins: string
      status: string
      actions: string
    }
    statusText: (status: number) => string
    edit: string
    enable: string
    disable: string
    delete: string
    superAdminDisabledTitle: string
    empty: string
    formEyebrow: string
    formHeading: (editing: boolean, roleName?: string) => string
    labels: {
      code: string
      name: string
      description: string
    }
    permissionHeading: string
    permissionDescription: string
    permissionGroupLabels: {
      audit: string
      data: string
      operations: string
      system: string
    }
    saving: string
    save: string
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
  pointsProducts: {
    eyebrow: string
    heading: string
    description: (region: Region) => string
    create: string
    listEyebrow: string
    listHeading: string
    tableHeaders: {
      name: string
      points: string
      stock: string
      limit: string
      exchanged: string
      fulfillType: string
      status: string
      sort: string
      actions: string
    }
    loading: string
    empty: string
    statusText: (status: number) => string
    fulfillTypeText: (fulfillType: number, fallback?: string) => string
    soldOut: string
    unlimited: string
    edit: string
    enable: string
    disable: string
    delete: string
    deleteConfirm: (name: string) => string
    created: string
    updated: string
    enabled: string
    disabled: string
    deleted: string
    editorEyebrow: (editing: boolean) => string
    editorHeading: (editing: boolean) => string
    labels: {
      name: string
      coverImage: string
      description: string
      pointsPrice: string
      stock: string
      limitPerUser: string
      fulfillType: string
      sort: string
    }
    fulfillOptions: {
      auto: string
      manual: string
    }
    limitHint: string
    saving: string
    save: string
    readOnly: string
    loadError: string
    previousPage: string
    page: (page: number) => string
    nextPage: string
  }
  pointsExchanges: {
    eyebrow: string
    heading: string
    description: (region: Region) => string
    filters: {
      status: string
      keyword: string
    }
    keywordPlaceholder: string
    statusOptions: {
      all: string
      pending: string
      fulfilled: string
      cancelled: string
    }
    query: string
    tableHeaders: {
      id: string
      user: string
      product: string
      points: string
      status: string
      redeemCode: string
      remark: string
      time: string
      actions: string
    }
    loading: string
    empty: string
    statusText: (status: number, fallback?: string) => string
    fulfillAction: string
    cancelAction: string
    cancelConfirm: (id: number, points: number) => string
    redeemCodePlaceholder: string
    remarkPlaceholder: string
    fulfilledMessage: (id: number, redeemCode: string) => string
    cancelledMessage: (id: number, points: number) => string
    loadError: string
    actionError: string
    readOnly: string
    handled: string
    fallbackText: string
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
  '/operations/points-products': 'pointsProductManagement',
  '/operations/points-exchanges': 'pointsExchangeManagement',
  '/system/admins': 'systemAdmins',
  '/system/roles': 'systemRoles',
  '/system/users': 'systemUsers',
  '/system/merchants': 'systemMerchants',
  '/system/audit-logs': 'systemAuditLogs',
  '/system/privacy-tasks': 'systemPrivacyTasks',
}

const MENU_GROUP_KEYS = {
  data: 'data',
  audit: 'audit',
  operations: 'operations',
  system: 'system',
} as const

function zhAuditTaskStatusText(status: number, fallback?: string) {
  if (status === 0) return '待人审'
  if (status === 1) return '通过'
  if (status === 2) return '驳回'
  return fallback || `状态 ${status}`
}

function enAuditTaskStatusText(status: number, fallback?: string) {
  if (status === 0) return 'Pending review'
  if (status === 1) return 'Approved'
  if (status === 2) return 'Rejected'
  return fallback || `Status ${status}`
}

function zhMerchantApplicationStatusText(status: number, fallback?: string) {
  if (status === 0) return '待审核'
  if (status === 1) return '已通过'
  if (status === 2) return '已驳回'
  return fallback || `状态 ${status}`
}

function enMerchantApplicationStatusText(status: number, fallback?: string) {
  if (status === 0) return 'Pending review'
  if (status === 1) return 'Approved'
  if (status === 2) return 'Rejected'
  return fallback || `Status ${status}`
}

function zhReportTypeText(reportType: string, fallback?: string) {
  if (reportType === 'review') return '点评举报'
  if (reportType === 'post') return '帖子举报'
  if (reportType === 'message') return '私信举报'
  if (reportType === 'review_comment') return '点评评论举报'
  if (reportType === 'post_comment') return '帖子评论举报'
  return fallback || reportType
}

function enReportTypeText(reportType: string, fallback?: string) {
  if (reportType === 'review') return 'Review report'
  if (reportType === 'post') return 'Post report'
  if (reportType === 'message') return 'Message report'
  if (reportType === 'review_comment') return 'Review comment report'
  if (reportType === 'post_comment') return 'Post comment report'
  return fallback || reportType
}

function zhReportTargetTypeText(reportType: string, targetType?: number | null, fallback?: string) {
  if (reportType === 'review') return '点评'
  if (reportType === 'post') return '帖子'
  if (reportType === 'review_comment') return '点评评论'
  if (reportType === 'post_comment') return '帖子评论'
  if (reportType === 'message') {
    if (targetType === 1) return '消息'
    if (targetType === 2) return '会话'
    return '私信'
  }
  return fallback || reportType
}

function enReportTargetTypeText(reportType: string, targetType?: number | null, fallback?: string) {
  if (reportType === 'review') return 'Review'
  if (reportType === 'post') return 'Post'
  if (reportType === 'review_comment') return 'Review comment'
  if (reportType === 'post_comment') return 'Post comment'
  if (reportType === 'message') {
    if (targetType === 1) return 'Message'
    if (targetType === 2) return 'Conversation'
    return 'Direct message'
  }
  return fallback || reportType
}

function zhReportStatusText(status: number, fallback?: string) {
  if (status === 0) return '待处理'
  if (status === 1) return '已成立'
  if (status === 2) return '已驳回'
  return fallback || `状态 ${status}`
}

function enReportStatusText(status: number, fallback?: string) {
  if (status === 0) return 'Pending'
  if (status === 1) return 'Upheld'
  if (status === 2) return 'Dismissed'
  return fallback || `Status ${status}`
}

function zhReportTargetStatusText(
  reportType: string,
  targetAuditStatus?: number | null,
  fallback?: string,
) {
  if (reportType === 'message') return '私信'
  if (targetAuditStatus == null) return fallback || ''
  if (reportType === 'review_comment' || reportType === 'post_comment') {
    if (targetAuditStatus === 1) return '公开'
    if (targetAuditStatus === 2) return '已隐藏'
    return '待审'
  }
  if (targetAuditStatus === 1) return '公开'
  if (targetAuditStatus === 2) return '已隐藏/驳回'
  return '待审'
}

function enReportTargetStatusText(
  reportType: string,
  targetAuditStatus?: number | null,
  fallback?: string,
) {
  if (reportType === 'message') return 'Direct message'
  if (targetAuditStatus == null) return fallback || ''
  if (reportType === 'review_comment' || reportType === 'post_comment') {
    if (targetAuditStatus === 1) return 'Visible'
    if (targetAuditStatus === 2) return 'Hidden'
    return 'Pending review'
  }
  if (targetAuditStatus === 1) return 'Visible'
  if (targetAuditStatus === 2) return 'Hidden / rejected'
  return 'Pending review'
}

function zhEnabledStatusText(status: number) {
  return status === 1 ? '启用' : '停用'
}

function enEnabledStatusText(status: number) {
  return status === 1 ? 'Enabled' : 'Disabled'
}

function zhImportBatchStatusText(status: number, fallback?: string) {
  if (status === 1) return '完成'
  if (status === 2) return '失败'
  if (status === 0) return '处理中'
  return fallback || `状态 ${status}`
}

function enImportBatchStatusText(status: number, fallback?: string) {
  if (status === 1) return 'Completed'
  if (status === 2) return 'Failed'
  if (status === 0) return 'Processing'
  return fallback || `Status ${status}`
}

function zhShopStatusText(status: number, fallback?: string) {
  if (status === 0) return '下线'
  if (status === 2) return '停业'
  if (status === 1) return '营业'
  return fallback || `状态 ${status}`
}

function enShopStatusText(status: number, fallback?: string) {
  if (status === 0) return 'Offline'
  if (status === 2) return 'Closed'
  if (status === 1) return 'Open'
  return fallback || `Status ${status}`
}

function zhUserStatusText(status: number, fallback?: string) {
  if (status === 2) return '已封禁'
  if (status === 3) return '已注销'
  if (status === 1) return '正常'
  return fallback || `状态 ${status}`
}

function enUserStatusText(status: number, fallback?: string) {
  if (status === 2) return 'Banned'
  if (status === 3) return 'Deleted'
  if (status === 1) return 'Active'
  return fallback || `Status ${status}`
}

function zhAppealStatusText(statusText: string) {
  return statusText
}

function enAppealStatusText(statusText: string) {
  if (statusText === '待审核') return 'Pending review'
  if (statusText === '已通过') return 'Approved'
  if (statusText === '已驳回') return 'Rejected'
  return statusText
}

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
    pointsProductManagement: '积分商品',
    pointsExchangeManagement: '积分兑换',
    systemAdmins: '管理员账号',
    systemRoles: '角色与权限',
    systemUsers: '用户管理',
    systemMerchants: '商户账号',
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
      statusText: zhImportBatchStatusText,
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
  basicDataManagement: {
    eyebrow: (region) => `当前区域 ${region}`,
    heading: '基础数据',
    description: '维护分类、城市和商圈。停用项不会继续出现在 C 端筛选中，历史门店信息仍会保留。',
    writable: '可维护',
    readOnly: '只读',
    tabsAriaLabel: '基础数据类型',
    tabs: {
      categories: '分类',
      cities: '城市',
      areas: '商圈',
    },
    loading: (region) => `正在加载 ${region} 区域数据...`,
    actions: {
      save: '保存',
      edit: '编辑',
      enable: '启用',
      disable: '停用',
      delete: '删除',
    },
    statusText: zhEnabledStatusText,
    category: {
      heading: '分类',
      summary: (count) => `${count} 条，按父级与排序值展示`,
      create: '新增分类',
      labels: {
        parent: '父分类',
        name: '名称',
        sort: '排序',
      },
      root: '根分类',
      tableHeaders: {
        name: '名称',
        parent: '父级',
        sort: '排序',
        status: '状态',
        actions: '操作',
      },
      empty: '当前区域暂无分类',
      createSuccess: '分类已创建',
      updateSuccess: '分类已更新',
      enableSuccess: '分类已启用',
      disableSuccess: '分类已停用',
      deleteSuccess: '分类已删除',
      deleteConfirm: (name) => `确认删除分类「${name}」？被业务引用时服务端会拒绝。`,
      editTitle: '编辑分类',
    },
    city: {
      heading: '城市',
      summary: (count) => `${count} 条，城市编码在区域内唯一`,
      create: '新增城市',
      labels: {
        code: '编码',
        name: '名称',
        sort: '排序',
      },
      tableHeaders: {
        city: '城市',
        code: '编码',
        sort: '排序',
        status: '状态',
        actions: '操作',
      },
      empty: '当前区域暂无城市',
      createSuccess: '城市已创建',
      updateSuccess: '城市已更新',
      enableSuccess: '城市已启用',
      disableSuccess: '城市已停用',
      deleteSuccess: '城市已删除',
      deleteConfirm: (name) => `确认删除城市「${name}」？被业务引用时服务端会拒绝。`,
    },
    area: {
      heading: '商圈',
      summary: '先选择城市，再维护其下商圈',
      create: '新增商圈',
      cityFilterLabel: '城市',
      selectCity: '请选择城市',
      disabledSuffix: '（停用）',
      labels: {
        city: '城市',
        name: '名称',
        sort: '排序',
      },
      tableHeaders: {
        area: '商圈',
        city: '城市',
        sort: '排序',
        status: '状态',
        actions: '操作',
      },
      loading: '正在加载商圈...',
      emptySelectCity: '请选择城市',
      empty: '当前城市暂无商圈',
      createSuccess: '商圈已创建',
      updateSuccess: '商圈已更新',
      enableSuccess: '商圈已启用',
      disableSuccess: '商圈已停用',
      deleteSuccess: '商圈已删除',
      deleteConfirm: (name) => `确认删除商圈「${name}」？被业务引用时服务端会拒绝。`,
    },
  },
  shopImport: {
    loadError: '导入批次加载失败',
    importError: '导入失败',
    invalidRecords: '导入记录必须是非空 JSON 数组。',
    importSuccess: (success, failed) => `导入完成：成功 ${success}，失败 ${failed}。`,
    eyebrow: '种子导入',
    heading: '先让运营有办法造数，不然前台页面再漂亮也是空壳子。',
    description: '这版用 JSON 文本直连导入接口，目的很实在：先把批次、失败明细、回灌动作跑通。',
    resetExample: '恢复示例',
    importing: '导入中...',
    startImport: '开始导入',
    requestEyebrow: '导入请求',
    requestHeading: (region) => `当前区域 ${region} 的导入 payload，别靠脑补拼字段。`,
    requestNote: '把 `categoryId` 改成不存在的值，就能演示失败明细。',
    labels: {
      fileName: '文件名',
      region: '区域',
      records: '记录 JSON',
    },
    fileNamePlaceholder: 'seed-cn-shops.json',
    recordsPlaceholder: '请填写 JSON 数组',
    validIdsTitle: '当前区域有效示例 ID',
    validIds: (region) =>
      region === 'CN' ? '分类 `102`，城市 `1`，商圈 `11`。' : '分类 `201`，城市 `101`，商圈 `1011`。',
    resultEyebrow: '最近一次结果',
    resultHeading: '导入结果别藏着掖着，成功失败都摆出来。',
    resultCards: {
      total: '总记录',
      batch: (batchId) => `批次 #${batchId}`,
      success: '成功',
      failure: '失败',
      noErrorFile: '无错误文件',
    },
    batchesEyebrow: '导入批次',
    batchesHeading: '批次记录得能翻，运营回头查错不至于抓瞎。',
    batchesSummary: (total) => `当前区域共 ${total} 个批次`,
    filters: {
      status: '状态',
    },
    statusOptions: {
      all: '全部状态',
      processing: '处理中',
      completed: '完成',
      failed: '失败',
    },
    applyFilters: '应用筛选',
    refresh: '刷新',
    tableHeaders: {
      batch: '批次',
      fileName: '文件名',
      result: '结果',
      status: '状态',
      errorFile: '错误文件',
    },
    loading: '导入批次加载中...',
    empty: '还没有批次记录，先导一包再说。',
    resultSummary: (success, failed) => `成功 ${success} / 失败 ${failed}`,
    statusText: zhImportBatchStatusText,
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
  },
  shopManagement: {
    loadError: '门店列表加载失败',
    initError: '商户管理初始化失败',
    detailLoadError: '门店详情加载失败',
    saveError: '门店保存失败',
    deleteError: '门店删除失败',
    createSuccess: '门店创建成功。',
    updateSuccess: '门店更新成功。',
    deleteSuccess: '门店已删除。',
    deleteConfirm: (shopName) => `确认删除门店「${shopName}」？`,
    validationErrors: {
      categoryCityAreaRequired: '分类、城市、商圈得补齐，不然门店往哪儿挂？',
      basicsRequired: '名称、封面、地址、摘要这些基础字段别留空。',
      coordinatesPairRequired: '经纬度得成对填写，单独来一个没法定位。',
      latitudeRange: '纬度必须在 -90 到 90 之间。',
      longitudeRange: '经度必须在 -180 到 180 之间。',
    },
    eyebrow: '商户管理',
    heading: (region) => `区域 ${region} 的门店最小 CRUD 已经接上，先把数据盘清楚。`,
    description: '这里追求的是可操作、可验收，不是摆一堆按钮假装平台很大。',
    refresh: '刷新列表',
    create: '新建门店',
    filters: {
      eyebrow: '列表筛选',
      heading: '先把门店找得到、改得到，再谈后面的运营玩法。',
      count: (start, end, total) => `${start}-${end} / ${total}`,
      emptyCount: '0 / 0',
      labels: {
        keyword: '关键词',
        city: '城市',
        area: '商圈',
        category: '分类',
      },
      placeholders: {
        keyword: '店名 / 地址 / 商户名',
      },
      options: {
        allCities: '全部城市',
        allAreas: '全部商圈',
        allCategories: '全部分类',
      },
      apply: '应用筛选',
      reset: '重置',
    },
    tableHeaders: {
      shop: '门店',
      merchant: '商户',
      categoryRegion: '分类 / 区域',
      cityArea: '城市 / 商圈',
      price: '人均',
      status: '状态',
      actions: '操作',
    },
    listLoading: '门店列表加载中...',
    listEmpty: '当前筛选下没有门店，条件别拧巴得太狠。',
    merchantFallback: '未绑定商户',
    statusText: zhShopStatusText,
    edit: '编辑',
    view: '查看',
    delete: '删除',
    deleting: '删除中...',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editor: {
      eyebrow: '编辑器',
      heading: (shopId) => shopId ? `编辑门店 #${shopId}` : '新建门店',
      loading: '详情加载中...',
      regionNote: (region) => `区域 ${region}`,
      readOnly: '只读',
      readOnlyMessage: '当前账号仅可查看门店资料，无维护权限。',
      labels: {
        merchantId: '商户 ID',
        category: '分类',
        city: '城市',
        area: '商圈',
        name: '门店名称',
        phone: '联系电话',
        coverUrl: '封面图',
        pricePerCapita: '人均',
        currency: '币种',
        businessHours: '营业时间',
        status: '状态',
        address: '地址',
        latitude: '纬度',
        longitude: '经度',
        score: '综合评分',
        tasteScore: '口味',
        envScore: '环境',
        serviceScore: '服务',
        tags: '标签',
        summary: '摘要',
        createdAt: '创建时间',
        updatedAt: '更新时间',
      },
      placeholders: {
        merchantId: '可为空或填现有商户 ID',
        category: '请选择分类',
        city: '请选择城市',
        area: '请选择商圈',
        name: '例如：徐汇测试店',
        phone: '门店电话',
        coverUrl: 'https://...',
        businessHours: '10:00-21:00',
        address: '请填写完整地址',
        latitude: '例如 31.230416',
        longitude: '例如 121.473701',
        tags: '火锅, 聚餐, 夜宵',
        summary: '写清楚门店亮点，不要满屏废话。',
      },
      statusOptions: {
        open: '营业',
        closed: '停业',
        offline: '下线',
      },
      toggles: {
        hasDeal: '当前有优惠 / 团购',
        openNow: '当前展示为营业中',
      },
      previewFallbacks: {
        alt: '门店封面预览',
        title: '门店封面预览',
        address: '地址还没填，别急着说自己上线了。',
        businessHours: '营业时间待填',
      },
      reset: '重置表单',
      saving: '保存中...',
      saveUpdate: '保存修改',
      create: '创建门店',
      demoMerchantIds: '现成演示商户 ID：`CN` 可用 `1001 / 1002`，`EU` 可用 `2001 / 2002`。',
    },
  },
  userManagement: {
    loadError: '用户数据加载失败',
    detailLoadError: '用户详情加载失败',
    banReasonRequired: '封禁原因不能为空',
    banError: '封禁操作失败',
    unbanError: '解封操作失败',
    bannedMessage: (userLabel) => `用户 ${userLabel} 已封禁，全部登录态已失效。`,
    unbannedMessage: (userLabel) => `用户 ${userLabel} 已解封。`,
    eyebrow: '用户治理',
    heading: '用户管理',
    description: (region) =>
      `当前区域 ${region}。封禁会立即吊销该用户的全部登录态并拦截后续登录，动作会记录审计日志。`,
    refresh: '刷新列表',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 个用户`,
    metaDescription: '支持按昵称 / 邮箱 / 手机号关键词、用户 ID、账号状态和归属区域筛选。',
    filters: {
      keyword: '关键词',
      userId: '用户 ID',
      status: '账号状态',
      region: '归属区域',
      keywordPlaceholder: '昵称 / 邮箱 / 手机号',
      userIdPlaceholder: '例如 9001',
      statusOptions: {
        all: '全部',
        active: '正常',
        banned: '已封禁',
        deleted: '已注销',
      },
      regionAll: '全部',
      apply: '应用筛选',
    },
    tableHeaders: {
      user: '用户',
      account: '账号',
      regionLevel: '区域 / 等级',
      growthPoints: '成长值 / 积分',
      status: '状态',
      lastLogin: '最近登录',
      actions: '操作',
    },
    listLoading: '用户数据加载中...',
    empty: '当前筛选下没有用户。',
    userFallback: (userId) => `user:${userId}`,
    userIdLabel: (userId) => `ID ${userId}`,
    levelLabel: (level) => `Lv${level}`,
    statusText: zhUserStatusText,
    neverLoggedIn: '--',
    detailAction: '详情',
    banAction: '封禁',
    unbanAction: '解封',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    detailLoading: '用户详情加载中...',
    detailEyebrow: '用户详情',
    detailSummary: (account, region) => `${account} · 区域 ${region}`,
    signatureLabel: '签名',
    banReasonLabel: '封禁原因',
    pendingAppeal: (count) => `该用户有 ${count} 条待审封禁申诉。`,
    goAppealAudit: '去处理',
    latestAppealLabel: '最近一次封禁申诉',
    appealStatusText: zhAppealStatusText,
    stats: {
      reviewCount: '点评数',
      postCount: '帖子数',
      orderCount: '订单数',
      reservationCount: '预订数',
      favoriteCount: '收藏数',
      activeSessions: '活跃会话',
      growthValue: '成长值',
      createdAt: '注册时间',
    },
    close: '关闭',
    banEyebrow: '封禁用户',
    banDescription: '封禁后该用户全部登录态立即失效，密码和验证码登录都会被拦截。原因会记录进审计日志。',
    banReasonField: '封禁原因',
    banPlaceholder: '例如：发布垃圾广告',
    confirmBan: '确认封禁',
  },
  merchantManagement: {
    loadError: '商户账号加载失败',
    detailLoadError: '商户详情加载失败',
    disableReasonRequired: '停用原因不能为空',
    disableError: '停用商户失败',
    enableError: '恢复商户失败',
    disabledMessage: (merchant) => `商户 ${merchant} 已停用，全部商户端登录态已失效。`,
    enabledMessage: (merchant) => `商户 ${merchant} 已恢复。`,
    eyebrow: '商户治理',
    heading: '商户账号',
    description: (region) =>
      `当前区域 ${region}。停用会立即阻断该商户及其员工登录，所有处置动作均写入审计日志。`,
    refresh: '刷新列表',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 个商户`,
    metaDescription: '支持按账号、企业、联系人、手机号、商户 ID、审核状态和账号状态筛选。',
    filters: {
      keyword: '关键词',
      merchantId: '商户 ID',
      auditStatus: '资质审核',
      status: '账号状态',
      keywordPlaceholder: '账号 / 企业 / 联系人 / 手机号',
      merchantIdPlaceholder: '例如 1001',
      all: '全部',
      pending: '待审核',
      approved: '已通过',
      rejected: '已驳回',
      active: '正常',
      disabled: '已停用',
      apply: '应用筛选',
    },
    tableHeaders: {
      merchant: '商户',
      contact: '联系人',
      auditStatus: '资质审核',
      accountStatus: '账号状态',
      resources: '门店 / 员工',
      updatedAt: '更新时间',
      actions: '操作',
    },
    loading: '商户账号加载中...',
    empty: '当前筛选下没有商户。',
    merchantFallback: (merchantId) => `merchant:${merchantId}`,
    merchantIdLabel: (merchantId) => `ID ${merchantId}`,
    contactFallback: '--',
    resourceSummary: (shops, activeOperators, operators) => `${shops} 家门店 · ${activeOperators}/${operators} 个员工账号启用`,
    detailAction: '详情',
    disableAction: '停用',
    enableAction: '恢复',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    detailLoading: '商户详情加载中...',
    detailEyebrow: '商户详情',
    detailSummary: (account, region) => `${account} · 区域 ${region}`,
    detailFields: {
      auditStatus: '资质审核',
      accountStatus: '账号状态',
      shops: '门店数',
      operators: '员工账号',
      activeOperators: '启用员工',
      disableReason: '最近停用原因',
      createdAt: '注册时间',
      updatedAt: '更新时间',
    },
    close: '关闭',
    disableEyebrow: '停用商户',
    disableDescription: '停用后该商户及其全部员工的现有登录态立即失效，重新登录也会被拦截。',
    disableReasonField: '停用原因',
    disablePlaceholder: '例如：多次违反平台经营规则',
    confirmDisable: '确认停用',
    staff: {
      action: '员工账号',
      eyebrow: '员工治理',
      heading: (merchant) => `${merchant} · 员工账号`,
      description: '这里只展示员工账号，商户主账号不会出现在列表中，也不能从该入口停用。',
      loadError: '员工账号加载失败',
      detailLoadError: '员工详情加载失败',
      disableReasonRequired: '停用员工必须填写原因',
      disableError: '停用员工失败',
      enableError: '恢复员工失败',
      disabledMessage: (operator) => `员工 ${operator} 已停用，现有登录态已失效。`,
      enabledMessage: (operator) => `员工 ${operator} 已恢复。`,
      metaLoading: '加载中...',
      metaSummary: (total) => `共 ${total} 个员工账号`,
      filters: {
        keyword: '关键词',
        keywordPlaceholder: '账号 / 姓名 / 手机 / 邮箱',
        status: '账号状态',
        all: '全部',
        active: '正常',
        disabled: '已停用',
        apply: '应用筛选',
      },
      tableHeaders: {
        operator: '员工',
        contact: '联系方式',
        roles: '角色',
        shopScope: '门店范围',
        status: '状态',
        actions: '操作',
      },
      loading: '员工账号加载中...',
      empty: '该商户当前筛选下没有员工账号。',
      operatorFallback: (operatorId) => `operator:${operatorId}`,
      operatorIdLabel: (operatorId) => `ID ${operatorId}`,
      contactFallback: '--',
      rolesFallback: '未分配角色',
      allShops: '全部门店',
      selectedShops: (shopIds) => `指定门店：${shopIds.join(', ') || '--'}`,
      detailAction: '详情',
      disableAction: '停用',
      enableAction: '恢复',
      previousPage: '上一页',
      page: (page) => `第 ${page} 页`,
      nextPage: '下一页',
      detailLoading: '员工详情加载中...',
      detailEyebrow: '员工详情',
      detailSummary: (account) => `登录账号 ${account}`,
      detailFields: {
        roles: '角色',
        shopScope: '门店范围',
        status: '账号状态',
        disableReason: '最近停用原因',
        createdAt: '创建时间',
        updatedAt: '更新时间',
      },
      close: '关闭',
      disableEyebrow: '停用员工',
      disableDescription: '停用会让该员工的现有登录态立即失效并阻断重新登录，不影响商户主账号和其他员工。',
      disableReasonField: '停用原因',
      disablePlaceholder: '例如：超出授权门店操作',
      confirmDisable: '确认停用',
    },
    history: {
      action: '操作历史',
      eyebrow: '经营留痕',
      heading: (merchant) => `${merchant} · 操作历史`,
      description: '展示员工、门店草稿、团购、退款和点评经营动作，按日志 ID 倒序返回。',
      loadError: '商户操作历史加载失败',
      metaLoading: '加载中...',
      metaSummary: (total) => `共 ${total} 条操作记录`,
      filters: {
        operatorId: '操作人 ID',
        operatorIdPlaceholder: '例如 11001',
        action: '动作码',
        actionPlaceholder: '例如 staff_create',
        targetType: '目标类型',
        keyword: '关键词',
        keywordPlaceholder: '操作人账号 / 姓名 / 详情',
        allTargets: '全部',
        targets: {
          staff: '员工',
          shop: '门店',
          shopChange: '门店草稿',
          deal: '团购',
          order: '订单',
          review: '点评',
        },
        apply: '应用筛选',
      },
      tableHeaders: {
        time: '时间',
        operator: '操作人',
        action: '动作',
        target: '目标',
        detail: '详情',
      },
      loading: '操作历史加载中...',
      empty: '当前筛选下没有操作记录。',
      operatorFallback: (operatorId) => `operator:${operatorId}`,
      actionText: (action) => ({
        staff_create: '创建员工', staff_update: '更新员工', staff_status: '变更员工状态',
        shop_change_draft_create: '创建门店草稿', shop_change_submit: '提交门店草稿',
        shop_change_pass: '门店草稿通过', shop_change_reject: '门店草稿驳回',
        deal_create: '创建团购', deal_update: '更新团购', deal_on_shelf: '团购上架', deal_off_shelf: '团购下架',
        refund_approve: '同意退款', refund_reject: '驳回退款',
        review_reply_create: '创建点评回复', review_reply_update: '更新点评回复',
        review_appeal_draft_create: '创建点评申诉草稿', review_appeal_save: '保存点评申诉',
        review_appeal_submit: '提交点评申诉', review_appeal_pass: '点评申诉通过', review_appeal_reject: '点评申诉驳回',
      } as Record<string, string>)[action] ?? action,
      targetText: (targetType, targetId) => `${targetType || '--'}:${targetId}`,
      detailFallback: '--',
      previousPage: '上一页',
      page: (page) => `第 ${page} 页`,
      nextPage: '下一页',
      close: '关闭',
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
  reviewAudit: {
    loadError: '审核任务加载失败',
    passError: '审核通过失败',
    rejectError: '审核驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `任务 #${taskId} 已审核通过。`,
    rejected: (taskId) => `任务 #${taskId} 已驳回。`,
    eyebrow: '点评审核',
    heading: '先把待审点评捋顺，别让内容审核全靠数据库手改。',
    description: (region) => `当前区域 ${region} 的点评审核任务都在这儿，先保住最小闭环。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '先把待审任务抓出来，再谈审核效率。',
    listSummary: (total) => `当前共 ${total} 条点评审核任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '门店名 / 用户 / 点评内容',
    applyFilters: '应用筛选',
    resetRefresh: '重置刷新',
    tableHeaders: {
      task: '任务',
      shop: '门店',
      submitter: '提交人',
      status: '状态',
      submittedAt: '提交时间',
      actions: '操作',
    },
    loading: '点评审核任务加载中...',
    empty: '当前筛选下没有审核任务，别硬盯着空气发愣。',
    taskLabel: (bizId) => `点评 #${bizId}`,
    taskTypeLabel: '点评审核',
    shopFallback: '--',
    submitterFallback: '匿名',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => taskId ? `任务 #${taskId}` : '先选一条任务',
    editorStatusFallback: '暂无选中任务',
    metaLabels: {
      shop: '门店',
      submitter: '提交人',
      submittedAt: '提交时间',
      updatedAt: '最近处理',
    },
    updatedAtFallback: '--',
    summaryLabel: '点评摘要',
    summaryFallback: '当前没有可展示的点评摘要。',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选。比如：内容真实、表达完整。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填。别写成“自己体会”，那纯属摆烂。',
    acting: '处理中...',
    approve: '通过点评',
    reject: '驳回点评',
    readOnly: '当前账号只有查看权限，无法处理点评审核。',
    handled: '当前任务已经处理过了，只能查看结果。',
    emptyState: '当前筛选下没有选中的审核任务。先从左边挑一条，别对着空白面板发功。',
  },
  postAudit: {
    loadError: '帖子审核任务加载失败',
    passError: '帖子审核通过失败',
    rejectError: '帖子审核驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `帖子审核任务 #${taskId} 已通过。`,
    rejected: (taskId) => `帖子审核任务 #${taskId} 已驳回。`,
    eyebrow: '帖子审核',
    heading: '社区内容要过审，但别把审核做成数据库猜谜。',
    description: (region) => `当前区域 ${region}，这里只处理帖子任务；通过后公开，驳回原因会回到作者端。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '帖子审核与点评审核分开，别搅成一锅粥。',
    listSummary: (total) => `共 ${total} 条帖子任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '作者 / 内容摘要',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      author: '作者',
      summary: '内容摘要',
      status: '状态',
      actions: '操作',
    },
    loading: '帖子审核任务加载中...',
    empty: '当前没有帖子审核任务。',
    taskLabel: (bizId) => `帖子 #${bizId}`,
    authorFallback: '匿名',
    summaryFallback: '暂无摘要',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    metaLabels: {
      post: '帖子',
      author: '作者',
      region: '区域',
      submittedAt: '提交时间',
    },
    detailLabel: '帖子摘要',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选，记录通过依据。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填，作者端会看到这段原因。',
    approve: '通过帖子',
    reject: '驳回帖子',
    readOnly: '当前账号只有查看权限，无法处理帖子审核。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条帖子审核任务。',
  },
  dealAudit: {
    loadError: '团购审核任务加载失败',
    detailLoadError: '团购详情加载失败',
    passError: '团购审核通过失败',
    rejectError: '团购审核驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `团购审核任务 #${taskId} 已通过；商户仍需自行上架后才会公开销售。`,
    rejected: (taskId) => `团购审核任务 #${taskId} 已驳回。`,
    eyebrow: '团购审核',
    heading: '商户提交的团购，先审内容再放行。',
    description: (region) => `当前区域 ${region}。这里只处理 bizType=2 的团购/代金券审核；通过后仍由商户主动上架，不会自动开售。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '团购创建/编辑都会重新进入待审。',
    listSummary: (total) => `共 ${total} 条团购审核任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '商户名 / 门店名 / 团购标题',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      merchant: '商户',
      shop: '门店',
      title: '团购标题',
      status: '状态',
      actions: '操作',
    },
    loading: '团购审核任务加载中...',
    empty: '当前没有团购审核任务。',
    taskLabel: (bizId) => `团购 #${bizId}`,
    merchantFallback: '未知商户',
    shopFallback: (shopId) => `shop:${shopId || '-'}`,
    shopIdLabel: (shopId) => `门店 #${shopId}`,
    titleFallback: '暂无标题',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    metaLabels: {
      deal: '团购',
      merchant: '商户',
      shop: '门店',
      region: '区域',
      submittedAt: '提交时间',
      bizType: '业务类型',
    },
    detailLoading: '团购详情加载中...',
    detailLabels: {
      price: '售价',
      originalPrice: '原价',
      stock: '库存',
      validPeriod: '有效期',
      rules: '使用规则',
      items: '套餐明细',
      coverAlt: '团购封面',
    },
    unlimited: '不限',
    noRules: '暂无规则',
    itemHeaders: {
      name: '项目',
      quantity: '数量',
      price: '价格',
    },
    itemEmpty: '暂无套餐明细',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选，记录通过依据。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填，商户端会看到这段原因。',
    approve: '通过团购',
    reject: '驳回团购',
    readOnly: '当前账号仅可查看，无团购审核处理权限。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条团购审核任务。',
  },
  shopChangeAudit: {
    loadError: '门店草稿审核任务加载失败',
    detailLoadError: '门店草稿详情加载失败',
    passError: '门店草稿审核通过失败',
    rejectError: '门店草稿审核驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `门店草稿审核任务 #${taskId} 已通过，变更将应用到线上门店。`,
    rejected: (taskId) => `门店草稿审核任务 #${taskId} 已驳回。`,
    eyebrow: '门店草稿审核',
    heading: '商户改门店资料，先审再上线。',
    description: (region) => `当前区域 ${region}。这里只处理 bizType=5 的门店完整草稿；通过后整体应用基础资料、相册和菜单，驳回后商户可改草稿重提。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '新建门店和修改门店都走同一套草稿审核。',
    listSummary: (total) => `共 ${total} 条门店草稿任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '商户名 / 门店名 / 摘要',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      merchant: '商户',
      candidateShop: '候选门店',
      summary: '摘要',
      status: '状态',
      actions: '操作',
    },
    loading: '门店草稿审核任务加载中...',
    empty: '当前没有门店草稿审核任务。',
    taskLabel: (bizId) => `草稿 #${bizId}`,
    merchantFallback: '未知商户',
    candidateShopFallback: '未命名门店',
    targetShopLabel: (shopId) => shopId ? `#${shopId}` : '新建门店',
    summaryFallback: '暂无摘要',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    metaLabels: {
      draft: '草稿',
      merchant: '商户',
      candidateShop: '候选门店',
      targetShop: '目标门店',
      region: '区域',
      submittedAt: '提交时间',
    },
    detailSummaryLabel: '门店摘要',
    detailLoading: '门店草稿详情加载中...',
    detailLabels: {
      changeType: '类型',
      phone: '电话',
      pricePerCapita: '人均',
      businessHours: '营业时间',
      address: '地址',
      tags: '标签',
      gallery: '相册',
      menu: '菜单',
    },
    changeTypeText: (changeType) => changeType === 1 ? '新门店' : '修改门店',
    emptyValue: '-',
    photoAlt: (index) => `门店图片 ${index + 1}`,
    emptyGallery: '暂无相册',
    dishHeaders: {
      name: '菜品',
      price: '价格',
      recommendReason: '推荐理由',
    },
    dishRecommendFallback: '-',
    dishEmpty: '暂无菜单',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选，记录通过依据。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填，商户端会看到这段原因。',
    approve: '通过门店草稿',
    reject: '驳回门店草稿',
    readOnly: '当前账号只有查看权限，无法处理门店草稿。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条门店草稿审核任务。',
  },
  reviewAppealAudit: {
    loadError: '申诉任务加载失败',
    actionError: '审核失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `申诉任务 #${taskId} 已通过，点评已隐藏。`,
    rejected: (taskId) => `申诉任务 #${taskId} 已驳回。`,
    eyebrow: '商户点评申诉',
    heading: '恶意点评申诉单独审，别和普通点评混成一锅粥。',
    description: (region) => `当前区域 ${region}，审核通过后会隐藏点评并重算门店评分。`,
    refresh: '刷新',
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '商户名 / 门店名 / 申诉摘要',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      shop: '门店',
      summary: '申诉摘要',
      status: '状态',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '当前没有申诉任务。',
    taskLabel: (bizId) => `申诉 #${bizId}`,
    shopFallback: '--',
    summaryFallback: '暂无摘要',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    pageSummary: (page, total) => `第 ${page} 页 / 共 ${total} 条`,
    nextPage: '下一页',
    editorEyebrow: '申诉处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    editorSummaryLabel: '申诉摘要',
    passRemarkLabel: '通过备注',
    rejectReasonLabel: '驳回原因',
    pass: '通过申诉',
    reject: '驳回申诉',
    readOnly: '当前账号仅可查看，无申诉处理权限。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条申诉任务。',
  },
  userAppealAudit: {
    loadError: '申诉任务加载失败',
    actionError: '审核失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `申诉任务 #${taskId} 已通过，用户已自动解封。`,
    rejected: (taskId) => `申诉任务 #${taskId} 已驳回，用户保持封禁。`,
    eyebrow: '用户封禁申诉',
    heading: '误封要能翻案，恶意申诉也要拦得住。',
    description: (region) =>
      `当前区域 ${region}，通过申诉会立即解封该用户并写入审计日志；驳回后用户保持封禁，可补充材料重新申诉。`,
    refresh: '刷新',
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '用户昵称 / 账号 / 申诉理由',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      user: '申诉用户',
      reason: '申诉理由',
      status: '状态',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '当前没有封禁申诉任务。',
    taskLabel: (bizId) => `申诉 #${bizId}`,
    userFallback: '--',
    reasonFallback: '暂无理由',
    statusText: zhAuditTaskStatusText,
    view: '查看',
    previousPage: '上一页',
    pageSummary: (page, total) => `第 ${page} 页 / 共 ${total} 条`,
    nextPage: '下一页',
    editorEyebrow: '申诉处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    detailLabels: {
      user: '申诉用户',
      reason: '申诉理由',
    },
    passRemarkLabel: '通过备注（通过后立即解封）',
    rejectReasonLabel: '驳回原因（会展示给用户）',
    pass: '通过并解封',
    reject: '驳回申诉',
    readOnly: '当前账号只有查看权限，无法处理申诉。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条申诉任务。',
  },
  expertCertificationAudit: {
    loadError: '达人认证任务加载失败',
    passError: '达人认证通过失败',
    rejectError: '达人认证驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `达人认证任务 #${taskId} 已通过。`,
    rejected: (taskId) => `达人认证任务 #${taskId} 已驳回。`,
    eyebrow: '达人认证',
    heading: '达人认证必须后台审核，别让用户自己封自己。',
    description: (region) => `当前区域 ${region}，这里只处理达人认证申请；通过后公开资料和作者信息才会挂标。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '申请理由和提交人直接摊开看，别让审核员靠猜。',
    listSummary: (total) => `共 ${total} 条达人认证任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '申请人 / 申请摘要',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      applicant: '申请人',
      summary: '申请摘要',
      status: '状态',
      actions: '操作',
    },
    loading: '达人认证任务加载中...',
    empty: '当前没有达人认证任务。',
    taskLabel: (bizId) => `申请 #${bizId}`,
    applicantFallback: '匿名',
    summaryFallback: '暂无申请摘要',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    metaLabels: {
      application: '申请',
      applicant: '申请人',
      region: '区域',
      submittedAt: '提交时间',
    },
    summaryLabel: '申请摘要',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选，记录为什么给这人挂标。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填，用户端会看到这段原因。',
    approve: '通过认证',
    reject: '驳回申请',
    readOnly: '当前账号只有查看权限，无法处理认证。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条达人认证任务。',
  },
  verifiedMerchantAudit: {
    loadError: '认证商户任务加载失败',
    passError: '认证商户通过失败',
    rejectError: '认证商户驳回失败',
    rejectReasonRequired: '驳回原因不能为空。',
    passed: (taskId) => `认证商户任务 #${taskId} 已通过。`,
    rejected: (taskId) => `认证商户任务 #${taskId} 已驳回。`,
    eyebrow: '认证商户',
    heading: '认证商户必须后台审核，别让商户自己给自己挂标。',
    description: (region) => `当前区域 ${region}，这里只处理认证商户申请；通过后公开资料和作者信息才会挂标。`,
    refresh: '刷新任务',
    listEyebrow: '任务列表',
    listHeading: '认证理由和提交人直接摊开看，别让审核员靠猜。',
    listSummary: (total) => `共 ${total} 条认证商户任务`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    statusOptions: {
      all: '全部状态',
      pending: '待人审',
      approved: '通过',
      rejected: '驳回',
    },
    keywordPlaceholder: '申请人 / 申请摘要',
    applyFilters: '应用筛选',
    tableHeaders: {
      task: '任务',
      applicant: '申请人',
      summary: '申请摘要',
      status: '状态',
      actions: '操作',
    },
    loading: '认证商户任务加载中...',
    empty: '当前没有认证商户任务。',
    taskLabel: (bizId) => `申请 #${bizId}`,
    applicantFallback: '匿名',
    summaryFallback: '暂无申请摘要',
    statusText: zhAuditTaskStatusText,
    selected: '已选中',
    view: '查看',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    editorEyebrow: '任务处理',
    editorHeading: (taskId) => `任务 #${taskId}`,
    metaLabels: {
      application: '申请',
      applicant: '申请人',
      region: '区域',
      submittedAt: '提交时间',
    },
    summaryLabel: '申请摘要',
    approveRemarkLabel: '通过备注',
    approveRemarkPlaceholder: '可选，记录为什么给这家商户挂标。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '必填，商户端会看到这段原因。',
    approve: '通过认证',
    reject: '驳回申请',
    readOnly: '当前账号只有查看权限，无法处理认证。',
    handled: '当前任务已经处理，只保留查看。',
    emptyState: '请先选择一条认证商户任务。',
  },
  merchantApplicationAudit: {
    loadError: '商户资质申请加载失败',
    actionError: '资质审核失败',
    rejectReasonRequired: '驳回原因不能为空。',
    approvedMessage: (companyName) => `商户 ${companyName} 已通过资质审核。`,
    rejectedMessage: (companyName) => `商户 ${companyName} 已驳回。`,
    eyebrow: '商户准入',
    heading: '先看清资质，再放行经营权限。',
    description: (region) => `当前区域 ${region}。审核动作会同步商户状态并记录审计日志。`,
    refresh: '刷新申请',
    listEyebrow: '申请列表',
    listHeading: '材料、主体和区域放在一张桌上看。',
    listSummary: (total) => `共 ${total} 条`,
    filters: {
      status: '状态',
    },
    statusOptions: {
      all: '全部',
      pending: '待审核',
      approved: '已通过',
      rejected: '已驳回',
    },
    applyFilters: '应用筛选',
    tableHeaders: {
      merchant: '商户主体',
      legal: '法人/执照',
      shopPhotos: '门店照片',
      status: '状态',
      actions: '操作',
    },
    loading: '申请加载中...',
    empty: '当前没有资质申请。',
    licenseLink: '查看营业执照',
    shopPhotoAlt: (index) => `门店资质照片 ${index + 1}`,
    statusText: zhMerchantApplicationStatusText,
    approve: '通过申请',
    reject: '驳回申请',
    readOnly: '当前账号仅可查看，无商户准入审核权限。',
    handled: '已处理',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    rejectEyebrow: '驳回申请',
    rejectDescription: '原因会原样返回商户端，写人话，别写“资料不符”四个字就跑路。',
    rejectReasonLabel: '驳回原因',
    rejectReasonPlaceholder: '例如：执照主体与申请主体不一致。',
    confirmReject: '确认驳回',
  },
  reportManagement: {
    loadError: '举报列表加载失败',
    actionError: '处理失败',
    upheldMessage: (reportId, contentHidden) =>
      contentHidden ? `举报 #${reportId} 已成立，内容已隐藏。` : `举报 #${reportId} 已成立。`,
    dismissedMessage: (reportId) => `举报 #${reportId} 已驳回。`,
    eyebrow: '内容举报',
    heading: '点评、帖子、私信举报统一收口，别再让举报沉在业务表里。',
    description: (region) =>
      `当前区域 ${region}。点评/帖子按区域过滤；私信举报为全局队列。成立可隐藏公开内容，驳回仅关闭举报。`,
    filters: {
      reportType: '类型',
      status: '状态',
      keyword: '关键词',
    },
    reportTypeOptions: {
      all: '全部',
      review: '点评',
      post: '帖子',
      message: '私信',
      reviewComment: '点评评论',
      postComment: '帖子评论',
    },
    statusOptions: {
      all: '全部',
      pending: '待处理',
      upheld: '已成立',
      dismissed: '已驳回',
    },
    keywordPlaceholder: '举报人 / 原因 / 内容摘要',
    query: '查询',
    tableHeaders: {
      type: '类型',
      summary: '摘要',
      reporter: '举报人',
      reason: '原因',
      status: '状态',
      time: '时间',
    },
    loading: '加载中...',
    empty: '当前筛选下没有举报。',
    reportTypeText: zhReportTypeText,
    targetTypeText: zhReportTargetTypeText,
    statusText: zhReportStatusText,
    targetStatusText: zhReportTargetStatusText,
    detailEyebrow: '举报详情',
    detailHeading: (reportType, reportId) => `${reportType} #${reportId}`,
    detailLabels: {
      target: '目标',
      author: '作者',
      targetStatus: '目标状态',
      reporter: '举报人',
      reason: '原因',
      summary: '摘要',
      time: '时间',
    },
    summaryFallback: '—',
    authorFallback: '—',
    targetStatusFallback: '—',
    remarkPlaceholder: '处理备注（隐藏时建议填写）',
    dismissAction: '驳回举报',
    upholdAction: '成立并处理',
    readOnly: '当前账号仅可查看，无处理权限。',
    handled: '该举报已处理，无需再操作。',
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
    updateSuccess: '草稿已更新，仍需发布才会影响线上榜单。',
    updateError: '草稿更新失败',
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
    edit: '编辑草稿',
    editorEyebrow: '新草稿',
    editorHeading: '创建下一版本',
    editingEyebrow: '编辑草稿',
    editingHeading: (version) => `修改草稿 v${version}`,
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
    updating: '保存中...',
    saveEdit: '保存修改',
    cancelEdit: '取消编辑',
    readOnly: '当前账号仅可查看，无榜单配置权限。',
  },
  growthConfigs: {
    loadError: '配置加载失败',
    ruleUpdateError: '规则更新失败',
    ruleCreateError: '规则新增失败',
    ruleActionRequired: '行为码和行为名称都不能为空。',
    levelUpdateError: '等级更新失败',
    ruleUpdated: (action) => `${action} 已更新`,
    ruleCreated: (action) => `${action} 已新增`,
    levelUpdated: (level) => `Lv${level} 已更新`,
    eyebrow: '成长体系',
    heading: '奖励权重和等级门槛都从数据库读取。',
    description: '改完只影响之后的行为，历史流水不回写，账不能越改越玄学。',
    rulesEyebrow: '行为奖励',
    rulesHeading: '成长值 / 积分 / 每日上限',
    createEyebrow: '新增行为',
    createHeading: '登记新的成长行为',
    levelsEyebrow: '等级阈值',
    levelsHeading: 'Lv1-Lv8 配置',
    newRuleLabels: {
      action: '行为码',
      actionName: '行为名称',
      growthValue: '成长值',
      points: '积分',
      dailyLimit: '每日上限',
      enabled: '启用',
    },
    actionPlaceholder: '例如 check_in',
    createRule: '新增规则',
    creating: '新增中...',
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
  adminAccounts: {
    loadError: '管理员列表加载失败',
    saveError: '管理员保存失败',
    statusUpdateError: '管理员状态更新失败',
    resetPasswordError: '密码重置失败',
    roleRequired: '至少选择一个角色',
    regionRequired: '至少选择一个区域',
    cityRequired: (region) => `${region} 至少选择一个城市或门店`,
    passwordMin: '初始密码至少 8 位',
    resetPasswordMin: '新密码至少 8 位',
    statusConfirm: (name, action) => `确认${action === 'disable' ? '停用' : '启用'}管理员「${name}」吗？`,
    eyebrow: '系统权限',
    heading: '管理员账号',
    description: '账号、角色、区域与城市范围由服务端实时读取，停用后旧会话会在下一次请求失效。',
    create: '新建管理员',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 个管理员`,
    metaOperator: (name) => `当前操作者：${name}`,
    tableHeaders: {
      account: '账号',
      roles: '角色',
      scope: '区域 / 城市',
      lastLogin: '最近登录',
      status: '状态',
      actions: '操作',
    },
    roleFallback: '--',
    scopeAllCities: '全部城市',
    scopeEntry: (region, detail) => `${region}: ${detail}`,
    neverLoggedIn: '从未登录',
    statusText: (status) => {
      if (status === 1) return '启用'
      if (status === 2) return '已停用'
      return `状态 ${status}`
    },
    edit: '编辑',
    resetPassword: '重置密码',
    enable: '启用',
    disable: '停用',
    selfDisableTitle: '当前账号不能停用自己',
    empty: '暂无管理员账号',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
    formEyebrow: '账号表单',
    formHeading: (editing) => editing ? '编辑管理员' : '新建管理员',
    labels: {
      account: '登录账号',
      password: '初始密码',
      name: '显示名称',
      roles: '角色',
      regions: '区域范围',
      cityScopes: '城市范围',
    },
    scopeModeText: (mode) => {
      if (mode === 'all') return '全部城市'
      if (mode === 'shops') return '指定门店'
      return '指定城市'
    },
    scopeModeOptions: {
      all: '全部城市',
      cities: '指定城市',
      shops: '指定门店',
    },
    noCities: '当前区域没有可分配城市。',
    noShops: '当前区域没有可分配门店。',
    saving: '保存中...',
    save: '保存管理员',
    resetEyebrow: '密码重置',
    resetHeading: (name) => `重置 ${name} 的密码`,
    resetLabel: '新密码',
    resetSubmit: '确认重置',
  },
  adminRoles: {
    loadError: '角色与权限加载失败',
    saveError: '角色保存失败',
    statusUpdateError: '角色状态更新失败',
    deleteError: '角色删除失败',
    permissionRequired: '至少选择一个权限',
    statusConfirm: (name, action) => `确认${action === 'disable' ? '停用' : '启用'}角色「${name}」吗？`,
    deleteConfirm: (name) => `确认删除角色「${name}」吗？该操作不能撤销。`,
    eyebrow: '权限注册表',
    heading: '角色与权限',
    description: '权限点由代码与数据库种子共同维护；角色可授权，权限码本身不允许在页面里随手造。',
    create: '新建角色',
    metaLoading: '加载中...',
    metaSummary: (total) => `共 ${total} 个角色`,
    metaDescription: '内置角色保留稳定编码，自定义角色可删除。',
    tableHeaders: {
      role: '角色',
      permissions: '权限数',
      admins: '管理员引用',
      status: '状态',
      actions: '操作',
    },
    statusText: (status) => {
      if (status === 1) return '启用'
      if (status === 2) return '已停用'
      return `状态 ${status}`
    },
    edit: '编辑',
    enable: '启用',
    disable: '停用',
    delete: '删除',
    superAdminDisabledTitle: '超级管理员角色不可停用',
    empty: '暂无角色',
    formEyebrow: '角色编辑',
    formHeading: (editing, roleName) => editing ? (roleName ? `编辑 ${roleName}` : '编辑角色') : '新建角色',
    labels: {
      code: '角色编码',
      name: '角色名称',
      description: '说明',
    },
    permissionHeading: '权限集合',
    permissionDescription: '超级管理员权限集合固定，其他角色按业务域最小授权。',
    permissionGroupLabels: {
      audit: '审核中心',
      data: '数据管理',
      operations: '运营配置',
      system: '系统管理',
    },
    saving: '保存中...',
    save: '保存角色',
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
  pointsProducts: {
    eyebrow: 'Points Mall',
    heading: '积分商品',
    description: (region) => `${region === 'EU' ? '欧洲区' : '中国区'}积分商城的上架商品。改价、改库存都会立刻影响用户端兑换。`,
    create: '新增商品',
    listEyebrow: 'Product List',
    listHeading: '商品列表',
    tableHeaders: {
      name: '商品',
      points: '所需积分',
      stock: '库存',
      limit: '每人限兑',
      exchanged: '已兑换',
      fulfillType: '发放方式',
      status: '状态',
      sort: '排序',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '暂无积分商品',
    statusText: (status) => (status === 1 ? '已上架' : '已下架'),
    fulfillTypeText: (fulfillType, fallback) => {
      if (fulfillType === 1) return '自动发码'
      if (fulfillType === 2) return '人工发放'
      return fallback || `方式 ${fulfillType}`
    },
    soldOut: '已兑完',
    unlimited: '不限',
    edit: '编辑',
    enable: '上架',
    disable: '下架',
    delete: '删除',
    deleteConfirm: (name) => `确认删除积分商品「${name}」？已产生的兑换记录不会被删除。`,
    created: '积分商品已创建',
    updated: '积分商品已更新',
    enabled: '积分商品已上架',
    disabled: '积分商品已下架',
    deleted: '积分商品已删除',
    editorEyebrow: (editing) => (editing ? 'Edit Product' : 'New Product'),
    editorHeading: (editing) => (editing ? '编辑积分商品' : '新增积分商品'),
    labels: {
      name: '商品名称',
      coverImage: '封面图',
      description: '商品说明',
      pointsPrice: '所需积分',
      stock: '库存',
      limitPerUser: '每人限兑',
      fulfillType: '发放方式',
      sort: '排序',
    },
    fulfillOptions: {
      auto: '自动发码',
      manual: '人工发放',
    },
    limitHint: '填 0 表示不限制每人兑换次数。',
    saving: '保存中...',
    save: '保存商品',
    readOnly: '当前账号只有只读权限，无法维护积分商品。',
    loadError: '积分商品加载失败',
    previousPage: '上一页',
    page: (page) => `第 ${page} 页`,
    nextPage: '下一页',
  },
  pointsExchanges: {
    eyebrow: 'Points Fulfilment',
    heading: '积分兑换记录',
    description: (region) => `${region === 'EU' ? '欧洲区' : '中国区'}用户的积分兑换单。人工发放的单子需要在这里补兑换码。`,
    filters: {
      status: '状态',
      keyword: '关键词',
    },
    keywordPlaceholder: '用户昵称 / 商品名 / 兑换码',
    statusOptions: {
      all: '全部',
      pending: '待发放',
      fulfilled: '已发放',
      cancelled: '已取消',
    },
    query: '查询',
    tableHeaders: {
      id: '兑换单',
      user: '用户',
      product: '商品',
      points: '消耗积分',
      status: '状态',
      redeemCode: '兑换码',
      remark: '备注',
      time: '创建时间',
      actions: '操作',
    },
    loading: '加载中...',
    empty: '暂无兑换记录',
    statusText: (status, fallback) => {
      if (status === 0) return '待发放'
      if (status === 1) return '已发放'
      if (status === 2) return '已取消'
      return fallback || `状态 ${status}`
    },
    fulfillAction: '确认发放',
    cancelAction: '取消并退积分',
    cancelConfirm: (id, points) => `确认取消兑换单 #${id}？将退回 ${points} 积分并恢复库存。`,
    redeemCodePlaceholder: '兑换码（人工发放必填）',
    remarkPlaceholder: '备注（选填）',
    fulfilledMessage: (id, redeemCode) =>
      redeemCode ? `兑换单 #${id} 已发放，兑换码 ${redeemCode}` : `兑换单 #${id} 已发放`,
    cancelledMessage: (id, points) => `兑换单 #${id} 已取消，已退回 ${points} 积分`,
    loadError: '兑换记录加载失败',
    actionError: '操作失败',
    readOnly: '当前账号只有只读权限，无法处理兑换单。',
    handled: '该兑换单已处理完成。',
    fallbackText: '--',
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
    pointsProductManagement: 'Points Products',
    pointsExchangeManagement: 'Points Redemptions',
    systemAdmins: 'Admin Accounts',
    systemRoles: 'Roles & Permissions',
    systemUsers: 'User Management',
    systemMerchants: 'Merchant Accounts',
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
      statusText: enImportBatchStatusText,
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
  basicDataManagement: {
    eyebrow: (region) => `Current region ${region}`,
    heading: 'Basic Data',
    description:
      'Maintain categories, cities, and areas. Disabled entries stop appearing in consumer filters, while historical shop data stays intact.',
    writable: 'Writable',
    readOnly: 'Read-only',
    tabsAriaLabel: 'Basic data types',
    tabs: {
      categories: 'Categories',
      cities: 'Cities',
      areas: 'Areas',
    },
    loading: (region) => `Loading data for region ${region}...`,
    actions: {
      save: 'Save',
      edit: 'Edit',
      enable: 'Enable',
      disable: 'Disable',
      delete: 'Delete',
    },
    statusText: enEnabledStatusText,
    category: {
      heading: 'Categories',
      summary: (count) => `${count} entries, grouped by parent and sort order`,
      create: 'New category',
      labels: {
        parent: 'Parent category',
        name: 'Name',
        sort: 'Sort',
      },
      root: 'Root category',
      tableHeaders: {
        name: 'Name',
        parent: 'Parent',
        sort: 'Sort',
        status: 'Status',
        actions: 'Actions',
      },
      empty: 'No categories exist for this region.',
      createSuccess: 'Category created.',
      updateSuccess: 'Category updated.',
      enableSuccess: 'Category enabled.',
      disableSuccess: 'Category disabled.',
      deleteSuccess: 'Category deleted.',
      deleteConfirm: (name) =>
        `Delete category "${name}"? The server will reject it if business data still references it.`,
      editTitle: 'Edit category',
    },
    city: {
      heading: 'Cities',
      summary: (count) => `${count} entries, with codes unique inside the current region`,
      create: 'New city',
      labels: {
        code: 'Code',
        name: 'Name',
        sort: 'Sort',
      },
      tableHeaders: {
        city: 'City',
        code: 'Code',
        sort: 'Sort',
        status: 'Status',
        actions: 'Actions',
      },
      empty: 'No cities exist for this region.',
      createSuccess: 'City created.',
      updateSuccess: 'City updated.',
      enableSuccess: 'City enabled.',
      disableSuccess: 'City disabled.',
      deleteSuccess: 'City deleted.',
      deleteConfirm: (name) =>
        `Delete city "${name}"? The server will reject it if business data still references it.`,
    },
    area: {
      heading: 'Areas',
      summary: 'Select a city first, then maintain the areas underneath it.',
      create: 'New area',
      cityFilterLabel: 'City',
      selectCity: 'Select a city',
      disabledSuffix: ' (disabled)',
      labels: {
        city: 'City',
        name: 'Name',
        sort: 'Sort',
      },
      tableHeaders: {
        area: 'Area',
        city: 'City',
        sort: 'Sort',
        status: 'Status',
        actions: 'Actions',
      },
      loading: 'Loading areas...',
      emptySelectCity: 'Select a city first.',
      empty: 'No areas exist for the selected city.',
      createSuccess: 'Area created.',
      updateSuccess: 'Area updated.',
      enableSuccess: 'Area enabled.',
      disableSuccess: 'Area disabled.',
      deleteSuccess: 'Area deleted.',
      deleteConfirm: (name) =>
        `Delete area "${name}"? The server will reject it if business data still references it.`,
    },
  },
  shopImport: {
    loadError: 'Failed to load import batches.',
    importError: 'Failed to import shops.',
    invalidRecords: 'Import records must be a non-empty JSON array.',
    importSuccess: (success, failed) => `Import complete: ${success} succeeded, ${failed} failed.`,
    eyebrow: 'Seed Imports',
    heading: 'Operations need a way to generate data, or the frontend is just an empty shell.',
    description:
      'This version sends JSON text directly to the import API so the batch flow, failure details, and replay loop are all working first.',
    resetExample: 'Restore example',
    importing: 'Importing...',
    startImport: 'Start import',
    requestEyebrow: 'Import request',
    requestHeading: (region) =>
      `Use an explicit import payload for region ${region}. Do not guess the fields.`,
    requestNote: 'Change `categoryId` to a missing value if you want to demonstrate failure details.',
    labels: {
      fileName: 'File name',
      region: 'Region',
      records: 'Record JSON',
    },
    fileNamePlaceholder: 'seed-cn-shops.json',
    recordsPlaceholder: 'Enter a JSON array',
    validIdsTitle: 'Valid sample IDs for the current region',
    validIds: (region) =>
      region === 'CN'
        ? 'Category `102`, city `1`, area `11`.'
        : 'Category `201`, city `101`, area `1011`.',
    resultEyebrow: 'Latest result',
    resultHeading: 'Import results must stay visible so both success and failure are obvious.',
    resultCards: {
      total: 'Total records',
      batch: (batchId) => `Batch #${batchId}`,
      success: 'Succeeded',
      failure: 'Failed',
      noErrorFile: 'No error file',
    },
    batchesEyebrow: 'Import batches',
    batchesHeading: 'Batch history must be easy to scan when operations comes back to investigate.',
    batchesSummary: (total) => `${total} batches in the current region`,
    filters: {
      status: 'Status',
    },
    statusOptions: {
      all: 'All statuses',
      processing: 'Processing',
      completed: 'Completed',
      failed: 'Failed',
    },
    applyFilters: 'Apply filters',
    refresh: 'Refresh',
    tableHeaders: {
      batch: 'Batch',
      fileName: 'File name',
      result: 'Result',
      status: 'Status',
      errorFile: 'Error file',
    },
    loading: 'Loading import batches...',
    empty: 'There are no import batches yet. Start one first.',
    resultSummary: (success, failed) => `Success ${success} / Failed ${failed}`,
    statusText: enImportBatchStatusText,
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
  },
  shopManagement: {
    loadError: 'Failed to load shops.',
    initError: 'Failed to initialize shop management.',
    detailLoadError: 'Failed to load shop details.',
    saveError: 'Failed to save the shop.',
    deleteError: 'Failed to delete the shop.',
    createSuccess: 'Shop created.',
    updateSuccess: 'Shop updated.',
    deleteSuccess: 'Shop deleted.',
    deleteConfirm: (shopName) => `Delete shop "${shopName}"?`,
    validationErrors: {
      categoryCityAreaRequired: 'Category, city, and area are required before a shop can be saved.',
      basicsRequired: 'Name, cover, address, and summary are required.',
      coordinatesPairRequired: 'Latitude and longitude must be provided together.',
      latitudeRange: 'Latitude must be between -90 and 90.',
      longitudeRange: 'Longitude must be between -180 and 180.',
    },
    eyebrow: 'Shop Management',
    heading: (region) =>
      `The minimum shop CRUD for region ${region} is wired up. Get the data inventory in order first.`,
    description:
      'This page is meant to be operable and testable, not padded with decorative buttons that pretend the platform is bigger than it is.',
    refresh: 'Refresh list',
    create: 'New shop',
    filters: {
      eyebrow: 'List filters',
      heading: 'Make shops easy to find and edit before layering on operations.',
      count: (start, end, total) => `${start}-${end} / ${total}`,
      emptyCount: '0 / 0',
      labels: {
        keyword: 'Keyword',
        city: 'City',
        area: 'Area',
        category: 'Category',
      },
      placeholders: {
        keyword: 'Shop / address / merchant',
      },
      options: {
        allCities: 'All cities',
        allAreas: 'All areas',
        allCategories: 'All categories',
      },
      apply: 'Apply filters',
      reset: 'Reset',
    },
    tableHeaders: {
      shop: 'Shop',
      merchant: 'Merchant',
      categoryRegion: 'Category / region',
      cityArea: 'City / area',
      price: 'Per-capita',
      status: 'Status',
      actions: 'Actions',
    },
    listLoading: 'Loading shops...',
    listEmpty: 'No shops match the current filters.',
    merchantFallback: 'Unassigned merchant',
    statusText: enShopStatusText,
    edit: 'Edit',
    view: 'View',
    delete: 'Delete',
    deleting: 'Deleting...',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editor: {
      eyebrow: 'Editor',
      heading: (shopId) => shopId ? `Edit shop #${shopId}` : 'New shop',
      loading: 'Loading details...',
      regionNote: (region) => `Region ${region}`,
      readOnly: 'Read-only',
      readOnlyMessage: 'This account is read-only and cannot maintain shop data.',
      labels: {
        merchantId: 'Merchant ID',
        category: 'Category',
        city: 'City',
        area: 'Area',
        name: 'Shop name',
        phone: 'Phone',
        coverUrl: 'Cover image',
        pricePerCapita: 'Per-capita',
        currency: 'Currency',
        businessHours: 'Business hours',
        status: 'Status',
        address: 'Address',
        latitude: 'Latitude',
        longitude: 'Longitude',
        score: 'Overall score',
        tasteScore: 'Taste',
        envScore: 'Environment',
        serviceScore: 'Service',
        tags: 'Tags',
        summary: 'Summary',
        createdAt: 'Created at',
        updatedAt: 'Updated at',
      },
      placeholders: {
        merchantId: 'Optional. Use an existing merchant ID if needed',
        category: 'Select a category',
        city: 'Select a city',
        area: 'Select an area',
        name: 'For example: Le Marais test shop',
        phone: 'Shop phone',
        coverUrl: 'https://...',
        businessHours: '10:00-21:00',
        address: 'Enter the full address',
        latitude: 'For example 48.856613',
        longitude: 'For example 2.352222',
        tags: 'Bistro, Dinner, Late night',
        summary: 'Describe the shop highlights clearly.',
      },
      statusOptions: {
        open: 'Open',
        closed: 'Closed',
        offline: 'Offline',
      },
      toggles: {
        hasDeal: 'Has active deals',
        openNow: 'Show as open now',
      },
      previewFallbacks: {
        alt: 'Shop cover preview',
        title: 'Shop cover preview',
        address: 'Address is still empty.',
        businessHours: 'Business hours pending',
      },
      reset: 'Reset form',
      saving: 'Saving...',
      saveUpdate: 'Save changes',
      create: 'Create shop',
      demoMerchantIds: 'Demo merchant IDs: `CN` can use `1001 / 1002`, `EU` can use `2001 / 2002`.',
    },
  },
  userManagement: {
    loadError: 'Failed to load users.',
    detailLoadError: 'Failed to load user details.',
    banReasonRequired: 'A ban reason is required.',
    banError: 'Failed to ban the user.',
    unbanError: 'Failed to unban the user.',
    bannedMessage: (userLabel) => `User ${userLabel} has been banned. All sessions were revoked.`,
    unbannedMessage: (userLabel) => `User ${userLabel} has been unbanned.`,
    eyebrow: 'User Governance',
    heading: 'User Management',
    description: (region) =>
      `Current region ${region}. Banning immediately revokes all active sessions and blocks future sign-ins. Every action is written to the audit log.`,
    refresh: 'Refresh list',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} users`,
    metaDescription: 'Filter by nickname, email, phone, user ID, account status, and preferred region.',
    filters: {
      keyword: 'Keyword',
      userId: 'User ID',
      status: 'Account status',
      region: 'Preferred region',
      keywordPlaceholder: 'Nickname / email / phone',
      userIdPlaceholder: 'For example 9001',
      statusOptions: {
        all: 'All',
        active: 'Active',
        banned: 'Banned',
        deleted: 'Deleted',
      },
      regionAll: 'All',
      apply: 'Apply filters',
    },
    tableHeaders: {
      user: 'User',
      account: 'Account',
      regionLevel: 'Region / level',
      growthPoints: 'Growth / points',
      status: 'Status',
      lastLogin: 'Last login',
      actions: 'Actions',
    },
    listLoading: 'Loading users...',
    empty: 'No users match the current filters.',
    userFallback: (userId) => `user:${userId}`,
    userIdLabel: (userId) => `ID ${userId}`,
    levelLabel: (level) => `Lv${level}`,
    statusText: enUserStatusText,
    neverLoggedIn: 'Never signed in',
    detailAction: 'Details',
    banAction: 'Ban',
    unbanAction: 'Unban',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    detailLoading: 'Loading user details...',
    detailEyebrow: 'User Details',
    detailSummary: (account, region) => `${account} · Region ${region}`,
    signatureLabel: 'Signature',
    banReasonLabel: 'Ban reason',
    pendingAppeal: (count) => `${count} pending ban appeal tasks.`,
    goAppealAudit: 'Handle appeals',
    latestAppealLabel: 'Latest ban appeal',
    appealStatusText: enAppealStatusText,
    stats: {
      reviewCount: 'Reviews',
      postCount: 'Posts',
      orderCount: 'Orders',
      reservationCount: 'Reservations',
      favoriteCount: 'Favorites',
      activeSessions: 'Active sessions',
      growthValue: 'Growth value',
      createdAt: 'Created at',
    },
    close: 'Close',
    banEyebrow: 'Ban User',
    banDescription:
      'Banning immediately invalidates all active sessions and blocks password and OTP sign-ins. The reason is written to the audit log.',
    banReasonField: 'Ban reason',
    banPlaceholder: 'For example: Posting spam ads',
    confirmBan: 'Confirm ban',
  },
  merchantManagement: {
    loadError: 'Failed to load merchant accounts.',
    detailLoadError: 'Failed to load merchant details.',
    disableReasonRequired: 'A disable reason is required.',
    disableError: 'Failed to disable the merchant.',
    enableError: 'Failed to restore the merchant.',
    disabledMessage: (merchant) => `Merchant ${merchant} was disabled. All merchant sessions were revoked.`,
    enabledMessage: (merchant) => `Merchant ${merchant} was restored.`,
    eyebrow: 'Merchant Governance',
    heading: 'Merchant Accounts',
    description: (region) =>
      `Current region ${region}. Disabling blocks the merchant and all staff sign-ins immediately. Every action is written to the audit log.`,
    refresh: 'Refresh list',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} merchants`,
    metaDescription: 'Filter by account, company, contact, phone, merchant ID, audit status, and account status.',
    filters: {
      keyword: 'Keyword',
      merchantId: 'Merchant ID',
      auditStatus: 'Application status',
      status: 'Account status',
      keywordPlaceholder: 'Account / company / contact / phone',
      merchantIdPlaceholder: 'For example 1001',
      all: 'All',
      pending: 'Pending',
      approved: 'Approved',
      rejected: 'Rejected',
      active: 'Active',
      disabled: 'Disabled',
      apply: 'Apply filters',
    },
    tableHeaders: {
      merchant: 'Merchant',
      contact: 'Contact',
      auditStatus: 'Application',
      accountStatus: 'Account',
      resources: 'Shops / staff',
      updatedAt: 'Updated',
      actions: 'Actions',
    },
    loading: 'Loading merchant accounts...',
    empty: 'No merchants match the current filters.',
    merchantFallback: (merchantId) => `merchant:${merchantId}`,
    merchantIdLabel: (merchantId) => `ID ${merchantId}`,
    contactFallback: '--',
    resourceSummary: (shops, activeOperators, operators) => `${shops} shops · ${activeOperators}/${operators} staff accounts active`,
    detailAction: 'Details',
    disableAction: 'Disable',
    enableAction: 'Restore',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    detailLoading: 'Loading merchant details...',
    detailEyebrow: 'Merchant Details',
    detailSummary: (account, region) => `${account} · Region ${region}`,
    detailFields: {
      auditStatus: 'Application status',
      accountStatus: 'Account status',
      shops: 'Shops',
      operators: 'Staff accounts',
      activeOperators: 'Active staff',
      disableReason: 'Latest disable reason',
      createdAt: 'Created at',
      updatedAt: 'Updated at',
    },
    close: 'Close',
    disableEyebrow: 'Disable Merchant',
    disableDescription: 'All existing merchant and staff sessions are revoked immediately and subsequent sign-ins are blocked.',
    disableReasonField: 'Disable reason',
    disablePlaceholder: 'For example: Repeated violations of platform rules',
    confirmDisable: 'Confirm disable',
    staff: {
      action: 'Staff accounts',
      eyebrow: 'Staff Governance',
      heading: (merchant) => `${merchant} · Staff Accounts`,
      description: 'Only staff accounts appear here. The merchant owner account is excluded and cannot be disabled from this view.',
      loadError: 'Failed to load staff accounts.',
      detailLoadError: 'Failed to load staff details.',
      disableReasonRequired: 'A staff disable reason is required.',
      disableError: 'Failed to disable the staff account.',
      enableError: 'Failed to restore the staff account.',
      disabledMessage: (operator) => `Staff account ${operator} was disabled. Its active sessions were revoked.`,
      enabledMessage: (operator) => `Staff account ${operator} was restored.`,
      metaLoading: 'Loading...',
      metaSummary: (total) => `${total} staff accounts`,
      filters: {
        keyword: 'Keyword',
        keywordPlaceholder: 'Account / name / phone / email',
        status: 'Account status',
        all: 'All',
        active: 'Active',
        disabled: 'Disabled',
        apply: 'Apply filters',
      },
      tableHeaders: {
        operator: 'Staff',
        contact: 'Contact',
        roles: 'Roles',
        shopScope: 'Shop scope',
        status: 'Status',
        actions: 'Actions',
      },
      loading: 'Loading staff accounts...',
      empty: 'No staff accounts match the current filters.',
      operatorFallback: (operatorId) => `operator:${operatorId}`,
      operatorIdLabel: (operatorId) => `ID ${operatorId}`,
      contactFallback: '--',
      rolesFallback: 'No assigned roles',
      allShops: 'All shops',
      selectedShops: (shopIds) => `Selected shops: ${shopIds.join(', ') || '--'}`,
      detailAction: 'Details',
      disableAction: 'Disable',
      enableAction: 'Restore',
      previousPage: 'Previous',
      page: (page) => `Page ${page}`,
      nextPage: 'Next',
      detailLoading: 'Loading staff details...',
      detailEyebrow: 'Staff Details',
      detailSummary: (account) => `Sign-in account ${account}`,
      detailFields: {
        roles: 'Roles',
        shopScope: 'Shop scope',
        status: 'Account status',
        disableReason: 'Latest disable reason',
        createdAt: 'Created at',
        updatedAt: 'Updated at',
      },
      close: 'Close',
      disableEyebrow: 'Disable Staff Account',
      disableDescription: 'The staff member is signed out immediately and cannot sign in again. The owner and other staff accounts are unaffected.',
      disableReasonField: 'Disable reason',
      disablePlaceholder: 'For example: Actions outside the assigned shop scope',
      confirmDisable: 'Confirm disable',
    },
    history: {
      action: 'Operation history',
      eyebrow: 'Operations Trail',
      heading: (merchant) => `${merchant} · Operation History`,
      description: 'Tracks staff, shop draft, deal, refund, and review operations in descending log order.',
      loadError: 'Failed to load merchant operation history.',
      metaLoading: 'Loading...',
      metaSummary: (total) => `${total} operation records`,
      filters: {
        operatorId: 'Operator ID',
        operatorIdPlaceholder: 'For example 11001',
        action: 'Action code',
        actionPlaceholder: 'For example staff_create',
        targetType: 'Target type',
        keyword: 'Keyword',
        keywordPlaceholder: 'Operator account / name / detail',
        allTargets: 'All',
        targets: {
          staff: 'Staff',
          shop: 'Shop',
          shopChange: 'Shop draft',
          deal: 'Deal',
          order: 'Order',
          review: 'Review',
        },
        apply: 'Apply filters',
      },
      tableHeaders: {
        time: 'Time',
        operator: 'Operator',
        action: 'Action',
        target: 'Target',
        detail: 'Detail',
      },
      loading: 'Loading operation history...',
      empty: 'No operation records match the current filters.',
      operatorFallback: (operatorId) => `operator:${operatorId}`,
      actionText: (action) => ({
        staff_create: 'Created staff', staff_update: 'Updated staff', staff_status: 'Changed staff status',
        shop_change_draft_create: 'Created shop draft', shop_change_submit: 'Submitted shop draft',
        shop_change_pass: 'Approved shop draft', shop_change_reject: 'Rejected shop draft',
        deal_create: 'Created deal', deal_update: 'Updated deal', deal_on_shelf: 'Published deal', deal_off_shelf: 'Unpublished deal',
        refund_approve: 'Approved refund', refund_reject: 'Rejected refund',
        review_reply_create: 'Created review reply', review_reply_update: 'Updated review reply',
        review_appeal_draft_create: 'Created review appeal draft', review_appeal_save: 'Saved review appeal',
        review_appeal_submit: 'Submitted review appeal', review_appeal_pass: 'Approved review appeal', review_appeal_reject: 'Rejected review appeal',
      } as Record<string, string>)[action] ?? action,
      targetText: (targetType, targetId) => `${targetType || '--'}:${targetId}`,
      detailFallback: '--',
      previousPage: 'Previous',
      page: (page) => `Page ${page}`,
      nextPage: 'Next',
      close: 'Close',
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
  reviewAudit: {
    loadError: 'Failed to load review audit tasks.',
    passError: 'Failed to approve the review.',
    rejectError: 'Failed to reject the review.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Task #${taskId} approved.`,
    rejected: (taskId) => `Task #${taskId} rejected.`,
    eyebrow: 'Review Audit',
    heading: 'Clear the pending review queue instead of relying on database edits for moderation.',
    description: (region) => `Review audit tasks for region ${region} are handled here so the minimum moderation loop stays intact.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'Pull the pending work into view before talking about review throughput.',
    listSummary: (total) => `${total} review audit tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Shop / user / review content',
    applyFilters: 'Apply filters',
    resetRefresh: 'Reset + refresh',
    tableHeaders: {
      task: 'Task',
      shop: 'Shop',
      submitter: 'Submitted by',
      status: 'Status',
      submittedAt: 'Submitted at',
      actions: 'Actions',
    },
    loading: 'Loading review audit tasks...',
    empty: 'No review audit tasks match the current filters.',
    taskLabel: (bizId) => `Review #${bizId}`,
    taskTypeLabel: 'Review audit',
    shopFallback: '--',
    submitterFallback: 'Anonymous',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => taskId ? `Task #${taskId}` : 'Select a task first',
    editorStatusFallback: 'No task selected',
    metaLabels: {
      shop: 'Shop',
      submitter: 'Submitted by',
      submittedAt: 'Submitted at',
      updatedAt: 'Last handled',
    },
    updatedAtFallback: '--',
    summaryLabel: 'Review summary',
    summaryFallback: 'No review summary is available for display.',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. For example: authentic content with complete context.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. Do not make the author guess what went wrong.',
    acting: 'Processing...',
    approve: 'Approve review',
    reject: 'Reject review',
    readOnly: 'This account is read-only and cannot process review audits.',
    handled: 'This task has already been handled. View only.',
    emptyState: 'No task is selected under the current filters. Pick one from the left panel first.',
  },
  postAudit: {
    loadError: 'Failed to load post audit tasks.',
    passError: 'Failed to approve the post.',
    rejectError: 'Failed to reject the post.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Post audit task #${taskId} approved.`,
    rejected: (taskId) => `Post audit task #${taskId} rejected.`,
    eyebrow: 'Post Audit',
    heading: 'Community posts need review, but moderation should not feel like database guesswork.',
    description: (region) => `Current region ${region}. This queue only handles post tasks. Approved posts go public, and rejection reasons are returned to the author.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'Keep post moderation separate from review moderation instead of mixing the two queues.',
    listSummary: (total) => `${total} post tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Author / content summary',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      author: 'Author',
      summary: 'Content summary',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading post audit tasks...',
    empty: 'No post audit tasks.',
    taskLabel: (bizId) => `Post #${bizId}`,
    authorFallback: 'Anonymous',
    summaryFallback: 'No summary',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => `Task #${taskId}`,
    metaLabels: {
      post: 'Post',
      author: 'Author',
      region: 'Region',
      submittedAt: 'Submitted at',
    },
    detailLabel: 'Post summary',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. Record the approval basis.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. The author sees this explanation.',
    approve: 'Approve post',
    reject: 'Reject post',
    readOnly: 'This account is read-only and cannot process post audits.',
    handled: 'This task has already been handled. View only.',
    emptyState: 'Select a post audit task first.',
  },
  dealAudit: {
    loadError: 'Failed to load deal audit tasks.',
    detailLoadError: 'Failed to load the deal details.',
    passError: 'Failed to approve the deal.',
    rejectError: 'Failed to reject the deal.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Deal audit task #${taskId} approved. The merchant still needs to publish it manually before it goes live.`,
    rejected: (taskId) => `Deal audit task #${taskId} rejected.`,
    eyebrow: 'Deal Audit',
    heading: 'Review merchant-submitted deals before they are allowed through.',
    description: (region) => `Current region ${region}. This queue only handles bizType=2 deal and voucher audits. Even after approval, merchants still publish them manually.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'Creating or editing a deal pushes it back into review.',
    listSummary: (total) => `${total} deal audit tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Merchant / shop / deal title',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      merchant: 'Merchant',
      shop: 'Shop',
      title: 'Deal title',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading deal audit tasks...',
    empty: 'No deal audit tasks.',
    taskLabel: (bizId) => `Deal #${bizId}`,
    merchantFallback: 'Unknown merchant',
    shopFallback: (shopId) => `shop:${shopId || '-'}`,
    shopIdLabel: (shopId) => `Shop #${shopId}`,
    titleFallback: 'No title',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => `Task #${taskId}`,
    metaLabels: {
      deal: 'Deal',
      merchant: 'Merchant',
      shop: 'Shop',
      region: 'Region',
      submittedAt: 'Submitted at',
      bizType: 'Business type',
    },
    detailLoading: 'Loading deal details...',
    detailLabels: {
      price: 'Price',
      originalPrice: 'Original price',
      stock: 'Stock',
      validPeriod: 'Validity period',
      rules: 'Usage rules',
      items: 'Package items',
      coverAlt: 'Deal cover',
    },
    unlimited: 'Unlimited',
    noRules: 'No rules',
    itemHeaders: {
      name: 'Item',
      quantity: 'Quantity',
      price: 'Price',
    },
    itemEmpty: 'No package items.',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. Record the approval basis.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. The merchant sees this explanation.',
    approve: 'Approve deal',
    reject: 'Reject deal',
    readOnly: 'This account is read-only and cannot process deal audits.',
    handled: 'This task has already been handled. View only.',
    emptyState: 'Select a deal audit task first.',
  },
  shopChangeAudit: {
    loadError: 'Failed to load shop draft audit tasks.',
    detailLoadError: 'Failed to load the shop draft details.',
    passError: 'Failed to approve the shop draft.',
    rejectError: 'Failed to reject the shop draft.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Shop draft audit task #${taskId} approved. The changes will be applied to the live shop.`,
    rejected: (taskId) => `Shop draft audit task #${taskId} rejected.`,
    eyebrow: 'Shop Draft Audit',
    heading: 'Review merchant shop changes before they go live.',
    description: (region) => `Current region ${region}. This queue only handles bizType=5 full shop drafts. Approval applies the base profile, gallery, and menu together; rejection sends the draft back for revision.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'New shops and edited shops both pass through the same draft review flow.',
    listSummary: (total) => `${total} shop draft tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Merchant / shop / summary',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      merchant: 'Merchant',
      candidateShop: 'Candidate shop',
      summary: 'Summary',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading shop draft audit tasks...',
    empty: 'No shop draft audit tasks.',
    taskLabel: (bizId) => `Draft #${bizId}`,
    merchantFallback: 'Unknown merchant',
    candidateShopFallback: 'Untitled shop',
    targetShopLabel: (shopId) => shopId ? `#${shopId}` : 'New shop',
    summaryFallback: 'No summary',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => `Task #${taskId}`,
    metaLabels: {
      draft: 'Draft',
      merchant: 'Merchant',
      candidateShop: 'Candidate shop',
      targetShop: 'Target shop',
      region: 'Region',
      submittedAt: 'Submitted at',
    },
    detailSummaryLabel: 'Shop summary',
    detailLoading: 'Loading shop draft details...',
    detailLabels: {
      changeType: 'Change type',
      phone: 'Phone',
      pricePerCapita: 'Per-capita price',
      businessHours: 'Business hours',
      address: 'Address',
      tags: 'Tags',
      gallery: 'Gallery',
      menu: 'Menu',
    },
    changeTypeText: (changeType) => changeType === 1 ? 'New shop' : 'Existing shop update',
    emptyValue: '-',
    photoAlt: (index) => `Shop photo ${index + 1}`,
    emptyGallery: 'No gallery yet.',
    dishHeaders: {
      name: 'Dish',
      price: 'Price',
      recommendReason: 'Recommendation',
    },
    dishRecommendFallback: '-',
    dishEmpty: 'No menu yet.',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. Record the approval basis.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. The merchant sees this explanation.',
    approve: 'Approve shop draft',
    reject: 'Reject shop draft',
    readOnly: 'This account is read-only and cannot process shop drafts.',
    handled: 'This task has already been handled. View only.',
    emptyState: 'Select a shop draft audit task first.',
  },
  reviewAppealAudit: {
    loadError: 'Failed to load appeal tasks.',
    actionError: 'Failed to process the appeal.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Appeal task #${taskId} approved. The review has been hidden.`,
    rejected: (taskId) => `Appeal task #${taskId} rejected.`,
    eyebrow: 'Merchant Review Appeals',
    heading: 'Handle malicious-review appeals separately instead of mixing them into standard review moderation.',
    description: (region) => `Current region ${region}. Approving an appeal hides the review and recalculates the shop score.`,
    refresh: 'Refresh',
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Merchant / shop / appeal summary',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      shop: 'Shop',
      summary: 'Appeal summary',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'No appeal tasks.',
    taskLabel: (bizId) => `Appeal #${bizId}`,
    shopFallback: '--',
    summaryFallback: 'No summary',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    pageSummary: (page, total) => `Page ${page} / ${total} total`,
    nextPage: 'Next',
    editorEyebrow: 'Appeal Review',
    editorHeading: (taskId) => `Task #${taskId}`,
    editorSummaryLabel: 'Appeal summary',
    passRemarkLabel: 'Approval note',
    rejectReasonLabel: 'Rejection reason',
    pass: 'Approve appeal',
    reject: 'Reject appeal',
    readOnly: 'This account can only view appeals.',
    handled: 'This task has already been processed. View only.',
    emptyState: 'Select an appeal task first.',
  },
  userAppealAudit: {
    loadError: 'Failed to load appeal tasks.',
    actionError: 'Failed to process the appeal.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Appeal task #${taskId} approved. The user was unbanned automatically.`,
    rejected: (taskId) => `Appeal task #${taskId} rejected. The ban stays in place.`,
    eyebrow: 'User Ban Appeals',
    heading: 'Reversible mistakes need a path back, and abusive appeals still need to be blocked.',
    description: (region) =>
      `Current region ${region}. Approving an appeal unbans the user immediately and writes an audit log. Rejections keep the ban in place until new evidence arrives.`,
    refresh: 'Refresh',
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Nickname / account / appeal reason',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      user: 'Appeal user',
      reason: 'Appeal reason',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'No ban appeal tasks.',
    taskLabel: (bizId) => `Appeal #${bizId}`,
    userFallback: '--',
    reasonFallback: 'No reason provided',
    statusText: enAuditTaskStatusText,
    view: 'View',
    previousPage: 'Previous',
    pageSummary: (page, total) => `Page ${page} / ${total} total`,
    nextPage: 'Next',
    editorEyebrow: 'Appeal Review',
    editorHeading: (taskId) => `Task #${taskId}`,
    detailLabels: {
      user: 'Appeal user',
      reason: 'Appeal reason',
    },
    passRemarkLabel: 'Approval note (unbans immediately)',
    rejectReasonLabel: 'Rejection reason (shown to the user)',
    pass: 'Approve and unban',
    reject: 'Reject appeal',
    readOnly: 'This account is read-only and cannot process appeals.',
    handled: 'This task has already been processed. View only.',
    emptyState: 'Select an appeal task first.',
  },
  expertCertificationAudit: {
    loadError: 'Failed to load expert certification tasks.',
    passError: 'Failed to approve the certification.',
    rejectError: 'Failed to reject the certification.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Expert certification task #${taskId} approved.`,
    rejected: (taskId) => `Expert certification task #${taskId} rejected.`,
    eyebrow: 'Expert Certifications',
    heading: 'Expert badges require admin review. Do not let users certify themselves.',
    description: (region) =>
      `Current region ${region}. This queue only handles expert certification applications. Approved tasks publish the badge in public profiles and author cards.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'Put the applicant and summary in front of the reviewer instead of making them guess.',
    listSummary: (total) => `${total} expert certification tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Applicant / application summary',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      applicant: 'Applicant',
      summary: 'Application summary',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading expert certification tasks...',
    empty: 'No expert certification tasks.',
    taskLabel: (bizId) => `Application #${bizId}`,
    applicantFallback: 'Anonymous',
    summaryFallback: 'No application summary',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => `Task #${taskId}`,
    metaLabels: {
      application: 'Application',
      applicant: 'Applicant',
      region: 'Region',
      submittedAt: 'Submitted at',
    },
    summaryLabel: 'Application summary',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. Explain why the badge is being granted.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. This text is shown to the applicant.',
    approve: 'Approve certification',
    reject: 'Reject application',
    readOnly: 'This account is read-only and cannot process certifications.',
    handled: 'This task has already been processed. View only.',
    emptyState: 'Select an expert certification task first.',
  },
  verifiedMerchantAudit: {
    loadError: 'Failed to load verified merchant tasks.',
    passError: 'Failed to approve the verification.',
    rejectError: 'Failed to reject the verification.',
    rejectReasonRequired: 'A rejection reason is required.',
    passed: (taskId) => `Verified merchant task #${taskId} approved.`,
    rejected: (taskId) => `Verified merchant task #${taskId} rejected.`,
    eyebrow: 'Verified Merchants',
    heading: 'Verified merchant badges require admin review. Do not let merchants certify themselves.',
    description: (region) =>
      `Current region ${region}. This queue only handles verified merchant applications. Approved tasks publish the badge in merchant-facing public surfaces.`,
    refresh: 'Refresh tasks',
    listEyebrow: 'Task list',
    listHeading: 'Keep the applicant and summary side by side so the reviewer is not guessing.',
    listSummary: (total) => `${total} verified merchant tasks`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    keywordPlaceholder: 'Applicant / application summary',
    applyFilters: 'Apply filters',
    tableHeaders: {
      task: 'Task',
      applicant: 'Applicant',
      summary: 'Application summary',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading verified merchant tasks...',
    empty: 'No verified merchant tasks.',
    taskLabel: (bizId) => `Application #${bizId}`,
    applicantFallback: 'Anonymous',
    summaryFallback: 'No application summary',
    statusText: enAuditTaskStatusText,
    selected: 'Selected',
    view: 'View',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    editorEyebrow: 'Task Handling',
    editorHeading: (taskId) => `Task #${taskId}`,
    metaLabels: {
      application: 'Application',
      applicant: 'Applicant',
      region: 'Region',
      submittedAt: 'Submitted at',
    },
    summaryLabel: 'Application summary',
    approveRemarkLabel: 'Approval note',
    approveRemarkPlaceholder: 'Optional. Explain why the verification is being granted.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder: 'Required. This text is shown to the merchant.',
    approve: 'Approve verification',
    reject: 'Reject application',
    readOnly: 'This account is read-only and cannot process merchant verification tasks.',
    handled: 'This task has already been processed. View only.',
    emptyState: 'Select a verified merchant task first.',
  },
  merchantApplicationAudit: {
    loadError: 'Failed to load merchant applications.',
    actionError: 'Failed to process the merchant application.',
    rejectReasonRequired: 'A rejection reason is required.',
    approvedMessage: (companyName) => `Merchant application for ${companyName} approved.`,
    rejectedMessage: (companyName) => `Merchant application for ${companyName} rejected.`,
    eyebrow: 'Merchant Applications',
    heading: 'Review qualifications before opening merchant operating access.',
    description: (region) =>
      `Current region ${region}. Decisions update merchant status and write an audit log.`,
    refresh: 'Refresh applications',
    listEyebrow: 'Application queue',
    listHeading: 'Keep the entity, license, and shop photos in one place for review.',
    listSummary: (total) => `${total} applications`,
    filters: {
      status: 'Status',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending review',
      approved: 'Approved',
      rejected: 'Rejected',
    },
    applyFilters: 'Apply filters',
    tableHeaders: {
      merchant: 'Merchant entity',
      legal: 'Legal person / license',
      shopPhotos: 'Shop photos',
      status: 'Status',
      actions: 'Actions',
    },
    loading: 'Loading merchant applications...',
    empty: 'No merchant applications.',
    licenseLink: 'View business license',
    shopPhotoAlt: (index) => `Shop qualification photo ${index + 1}`,
    statusText: enMerchantApplicationStatusText,
    approve: 'Approve application',
    reject: 'Reject application',
    readOnly: 'This account is read-only and cannot process merchant applications.',
    handled: 'Processed',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    rejectEyebrow: 'Reject application',
    rejectDescription:
      'This reason is returned to the merchant verbatim. Be specific about what is missing or inconsistent.',
    rejectReasonLabel: 'Rejection reason',
    rejectReasonPlaceholder:
      'For example: The business license entity does not match the application.',
    confirmReject: 'Confirm rejection',
  },
  reportManagement: {
    loadError: 'Failed to load reports.',
    actionError: 'Failed to process the report.',
    upheldMessage: (reportId, contentHidden) =>
      contentHidden ? `Report #${reportId} upheld and content hidden.` : `Report #${reportId} upheld.`,
    dismissedMessage: (reportId) => `Report #${reportId} dismissed.`,
    eyebrow: 'Content Reports',
    heading: 'Keep review, post, and message reports in one queue instead of burying them in product tables.',
    description: (region) =>
      `Current region ${region}. Review and post reports are region-scoped; message reports stay global. Upholding a report can hide public content, while dismissal only closes the case.`,
    filters: {
      reportType: 'Type',
      status: 'Status',
      keyword: 'Keyword',
    },
    reportTypeOptions: {
      all: 'All types',
      review: 'Review',
      post: 'Post',
      message: 'Message',
      reviewComment: 'Review comment',
      postComment: 'Post comment',
    },
    statusOptions: {
      all: 'All statuses',
      pending: 'Pending',
      upheld: 'Upheld',
      dismissed: 'Dismissed',
    },
    keywordPlaceholder: 'Reporter / reason / content summary',
    query: 'Search',
    tableHeaders: {
      type: 'Type',
      summary: 'Summary',
      reporter: 'Reporter',
      reason: 'Reason',
      status: 'Status',
      time: 'Submitted at',
    },
    loading: 'Loading reports...',
    empty: 'No reports match the current filters.',
    reportTypeText: enReportTypeText,
    targetTypeText: enReportTargetTypeText,
    statusText: enReportStatusText,
    targetStatusText: enReportTargetStatusText,
    detailEyebrow: 'Report details',
    detailHeading: (reportType, reportId) => `${reportType} #${reportId}`,
    detailLabels: {
      target: 'Target',
      author: 'Author',
      targetStatus: 'Target status',
      reporter: 'Reporter',
      reason: 'Reason',
      summary: 'Summary',
      time: 'Submitted at',
    },
    summaryFallback: '—',
    authorFallback: '—',
    targetStatusFallback: '—',
    remarkPlaceholder: 'Resolution note (recommended when hiding content)',
    dismissAction: 'Dismiss report',
    upholdAction: 'Uphold and process',
    readOnly: 'This account is read-only and cannot process reports.',
    handled: 'This report has already been processed.',
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
    updateSuccess: 'Draft updated. It still needs publishing before the live ranking changes.',
    updateError: 'Failed to update the rule draft.',
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
    edit: 'Edit draft',
    editorEyebrow: 'New draft',
    editorHeading: 'Create the next version',
    editingEyebrow: 'Edit draft',
    editingHeading: (version) => `Editing draft v${version}`,
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
    updating: 'Saving...',
    saveEdit: 'Save changes',
    cancelEdit: 'Cancel editing',
    readOnly: 'This account can view ranking history but cannot edit ranking rules.',
  },
  growthConfigs: {
    loadError: 'Failed to load the growth configuration.',
    ruleUpdateError: 'Failed to update the growth rule.',
    ruleCreateError: 'Failed to create the growth rule.',
    ruleActionRequired: 'Both the action code and the action name are required.',
    levelUpdateError: 'Failed to update the level.',
    ruleUpdated: (action) => `${action} updated.`,
    ruleCreated: (action) => `${action} created.`,
    levelUpdated: (level) => `Lv${level} updated.`,
    eyebrow: 'Growth program',
    heading: 'Reward weights and level thresholds come straight from the database.',
    description: 'Changes affect future actions only. Historical ledgers are not rewritten.',
    rulesEyebrow: 'Action rewards',
    rulesHeading: 'Growth, points, and daily caps',
    createEyebrow: 'New action',
    createHeading: 'Register a new growth action',
    levelsEyebrow: 'Level thresholds',
    levelsHeading: 'Lv1-Lv8 configuration',
    newRuleLabels: {
      action: 'Action code',
      actionName: 'Action name',
      growthValue: 'Growth',
      points: 'Points',
      dailyLimit: 'Daily limit',
      enabled: 'Enabled',
    },
    actionPlaceholder: 'e.g. check_in',
    createRule: 'Create rule',
    creating: 'Creating...',
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
  adminAccounts: {
    loadError: 'Failed to load admin accounts.',
    saveError: 'Failed to save the admin account.',
    statusUpdateError: 'Failed to update the admin status.',
    resetPasswordError: 'Failed to reset the password.',
    roleRequired: 'Select at least one role.',
    regionRequired: 'Select at least one region.',
    cityRequired: (region) => `Select at least one city or shop for ${region}.`,
    passwordMin: 'The initial password must be at least 8 characters.',
    resetPasswordMin: 'The new password must be at least 8 characters.',
    statusConfirm: (name, action) => `Are you sure you want to ${action === 'disable' ? 'disable' : 'enable'} admin "${name}"?`,
    eyebrow: 'System Access',
    heading: 'Admin accounts',
    description: 'Accounts, roles, regional scope, and city scope are read live from the server. Once disabled, stale sessions fail on the next request.',
    create: 'New admin',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} admins`,
    metaOperator: (name) => `Current operator: ${name}`,
    tableHeaders: {
      account: 'Account',
      roles: 'Roles',
      scope: 'Region / city',
      lastLogin: 'Last login',
      status: 'Status',
      actions: 'Actions',
    },
    roleFallback: '--',
    scopeAllCities: 'All cities',
    scopeEntry: (region, detail) => `${region}: ${detail}`,
    neverLoggedIn: 'Never signed in',
    statusText: (status) => {
      if (status === 1) return 'Enabled'
      if (status === 2) return 'Disabled'
      return `Status ${status}`
    },
    edit: 'Edit',
    resetPassword: 'Reset password',
    enable: 'Enable',
    disable: 'Disable',
    selfDisableTitle: 'You cannot disable your own account',
    empty: 'No admin accounts.',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
    formEyebrow: 'Account Form',
    formHeading: (editing) => editing ? 'Edit admin' : 'New admin',
    labels: {
      account: 'Sign-in account',
      password: 'Initial password',
      name: 'Display name',
      roles: 'Roles',
      regions: 'Region scope',
      cityScopes: 'City scope',
    },
    scopeModeText: (mode) => {
      if (mode === 'all') return 'All cities'
      if (mode === 'shops') return 'Specific shops'
      return 'Specific cities'
    },
    scopeModeOptions: {
      all: 'All cities',
      cities: 'Specific cities',
      shops: 'Specific shops',
    },
    noCities: 'No assignable cities are available for this region.',
    noShops: 'No assignable shops are available for this region.',
    saving: 'Saving...',
    save: 'Save admin',
    resetEyebrow: 'Password Reset',
    resetHeading: (name) => `Reset password for ${name}`,
    resetLabel: 'New password',
    resetSubmit: 'Confirm reset',
  },
  adminRoles: {
    loadError: 'Failed to load roles and permissions.',
    saveError: 'Failed to save the role.',
    statusUpdateError: 'Failed to update the role status.',
    deleteError: 'Failed to delete the role.',
    permissionRequired: 'Select at least one permission.',
    statusConfirm: (name, action) => `Are you sure you want to ${action === 'disable' ? 'disable' : 'enable'} role "${name}"?`,
    deleteConfirm: (name) => `Delete role "${name}"? This action cannot be undone.`,
    eyebrow: 'Permission Registry',
    heading: 'Roles & permissions',
    description: 'Permission entries are maintained by code and seed data. Roles can grant them, but permission codes themselves are not created from this page.',
    create: 'New role',
    metaLoading: 'Loading...',
    metaSummary: (total) => `${total} roles`,
    metaDescription: 'Built-in roles keep stable codes. Custom roles can be removed.',
    tableHeaders: {
      role: 'Role',
      permissions: 'Permissions',
      admins: 'Assigned admins',
      status: 'Status',
      actions: 'Actions',
    },
    statusText: (status) => {
      if (status === 1) return 'Enabled'
      if (status === 2) return 'Disabled'
      return `Status ${status}`
    },
    edit: 'Edit',
    enable: 'Enable',
    disable: 'Disable',
    delete: 'Delete',
    superAdminDisabledTitle: 'The super admin role cannot be disabled',
    empty: 'No roles.',
    formEyebrow: 'Role Editor',
    formHeading: (editing, roleName) => editing ? `Edit ${roleName ?? 'role'}` : 'New role',
    labels: {
      code: 'Role code',
      name: 'Role name',
      description: 'Description',
    },
    permissionHeading: 'Permission set',
    permissionDescription: 'The super admin permission set is fixed. Other roles should receive the minimum access needed for their domain.',
    permissionGroupLabels: {
      audit: 'Audit center',
      data: 'Data management',
      operations: 'Operations config',
      system: 'System management',
    },
    saving: 'Saving...',
    save: 'Save role',
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
  pointsProducts: {
    eyebrow: 'Points Mall',
    heading: 'Points Products',
    description: (region) =>
      `Products listed in the ${region === 'EU' ? 'Europe' : 'Mainland China'} points mall. Price and stock changes take effect for shoppers immediately.`,
    create: 'New product',
    listEyebrow: 'Product List',
    listHeading: 'Products',
    tableHeaders: {
      name: 'Product',
      points: 'Points',
      stock: 'Stock',
      limit: 'Per-user limit',
      exchanged: 'Redeemed',
      fulfillType: 'Fulfilment',
      status: 'Status',
      sort: 'Sort',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'No points products yet.',
    statusText: (status) => (status === 1 ? 'Listed' : 'Unlisted'),
    fulfillTypeText: (fulfillType, fallback) => {
      if (fulfillType === 1) return 'Auto code'
      if (fulfillType === 2) return 'Manual'
      return fallback || `Type ${fulfillType}`
    },
    soldOut: 'Sold out',
    unlimited: 'Unlimited',
    edit: 'Edit',
    enable: 'List',
    disable: 'Unlist',
    delete: 'Delete',
    deleteConfirm: (name) => `Delete points product "${name}"? Existing redemptions are kept.`,
    created: 'Points product created.',
    updated: 'Points product updated.',
    enabled: 'Points product listed.',
    disabled: 'Points product unlisted.',
    deleted: 'Points product deleted.',
    editorEyebrow: (editing) => (editing ? 'Edit Product' : 'New Product'),
    editorHeading: (editing) => (editing ? 'Edit points product' : 'New points product'),
    labels: {
      name: 'Name',
      coverImage: 'Cover image',
      description: 'Description',
      pointsPrice: 'Points price',
      stock: 'Stock',
      limitPerUser: 'Per-user limit',
      fulfillType: 'Fulfilment',
      sort: 'Sort',
    },
    fulfillOptions: {
      auto: 'Auto code',
      manual: 'Manual',
    },
    limitHint: 'Use 0 for no per-user redemption limit.',
    saving: 'Saving...',
    save: 'Save product',
    readOnly: 'This account is read-only and cannot maintain points products.',
    loadError: 'Failed to load points products.',
    previousPage: 'Previous',
    page: (page) => `Page ${page}`,
    nextPage: 'Next',
  },
  pointsExchanges: {
    eyebrow: 'Points Fulfilment',
    heading: 'Points Redemptions',
    description: (region) =>
      `Redemption orders from ${region === 'EU' ? 'Europe' : 'Mainland China'} users. Manual orders need a redeem code entered here.`,
    filters: {
      status: 'Status',
      keyword: 'Keyword',
    },
    keywordPlaceholder: 'Nickname / product / redeem code',
    statusOptions: {
      all: 'All',
      pending: 'Pending',
      fulfilled: 'Fulfilled',
      cancelled: 'Cancelled',
    },
    query: 'Search',
    tableHeaders: {
      id: 'Order',
      user: 'User',
      product: 'Product',
      points: 'Points spent',
      status: 'Status',
      redeemCode: 'Redeem code',
      remark: 'Remark',
      time: 'Created',
      actions: 'Actions',
    },
    loading: 'Loading...',
    empty: 'No redemptions yet.',
    statusText: (status, fallback) => {
      if (status === 0) return 'Pending'
      if (status === 1) return 'Fulfilled'
      if (status === 2) return 'Cancelled'
      return fallback || `Status ${status}`
    },
    fulfillAction: 'Fulfil',
    cancelAction: 'Cancel and refund',
    cancelConfirm: (id, points) =>
      `Cancel redemption #${id}? ${points} points will be refunded and stock restored.`,
    redeemCodePlaceholder: 'Redeem code (required for manual fulfilment)',
    remarkPlaceholder: 'Remark (optional)',
    fulfilledMessage: (id, redeemCode) =>
      redeemCode ? `Redemption #${id} fulfilled with code ${redeemCode}.` : `Redemption #${id} fulfilled.`,
    cancelledMessage: (id, points) => `Redemption #${id} cancelled, ${points} points refunded.`,
    loadError: 'Failed to load redemptions.',
    actionError: 'Action failed.',
    readOnly: 'This account is read-only and cannot process redemptions.',
    handled: 'This redemption has already been processed.',
    fallbackText: '--',
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
