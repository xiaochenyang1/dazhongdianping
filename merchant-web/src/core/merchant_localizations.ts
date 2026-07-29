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
