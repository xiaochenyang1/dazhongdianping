import type { Region } from '@/types/browse'
import type { AuthMode } from '@/types/auth'
import { localeForRegion } from '@/core/web_localizations'

export interface AuthModeCopy {
  mode: AuthMode
  label: string
  eyebrow: string
  detail: string
  footer: string
}

export interface WebAuthStrings {
  tag: 'zh-CN' | 'en'
  accountTypes: Array<{ value: 'email' | 'phone'; label: string }>
  modes: AuthModeCopy[]
  appealMode: AuthModeCopy
  panelTitles: Record<AuthMode, string>
  text: Record<string, string>
  panelSummary: (redirected: boolean) => string
  stageHeadline: (redirected: boolean) => string
  stageSummary: (redirectTo: string | null) => string
  resumeFacts: (redirectTo: string | null, region: Region, device: string) => Array<{ label: string; value: string }>
  servicePromises: (redirected: boolean, region: Region) => Array<{ title: string; detail: string }>
  stageFacts: (mode: string, redirectTo: string | null, region: Region) => Array<{ label: string; value: string }>
  bannedDescription: (account: string) => string
  codeSent: (seconds: number) => string
  mockCode: (code: string) => string
  appealSubmitted: (id: number) => string
  appealRefreshed: (id: number) => string
  appealStatusLabel: (status: number, fallback: string) => string
}

const zhCnStrings: WebAuthStrings = {
  tag: 'zh-CN',
  accountTypes: [
    { value: 'email', label: '邮箱' },
    { value: 'phone', label: '手机号' },
  ],
  modes: [
    {
      mode: 'password',
      label: '密码登录',
      eyebrow: '熟悉账号',
      detail: '已有密码的账号直接从这里进入，最快恢复收藏、点评和互动任务。',
      footer: '输入密码后立刻恢复当前动作，适合回流用户。',
    },
    {
      mode: 'code',
      label: '验证码登录',
      eyebrow: '快速校验',
      detail: '适合临时登录和跨设备兜底，本地环境会直接回显 mock 验证码。',
      footer: '完成轻量验证后继续原来的页面和操作。',
    },
    {
      mode: 'register',
      label: '注册账号',
      eyebrow: '首次使用',
      detail: '创建账号后即可继续写点评、互动和维护资料。',
      footer: '注册完成即进入登录态，不需要再次登录。',
    },
    {
      mode: 'reset',
      label: '重置密码',
      eyebrow: '账号恢复',
      detail: '忘记密码时先完成身份验证，再设置新的登录密码。',
      footer: '重置完成后会切回密码登录。',
    },
  ],
  appealMode: {
    mode: 'appeal',
    label: '封禁申诉',
    eyebrow: '账号救济',
    detail: '账号被封禁后可提交申诉，审核通过会自动解封。',
    footer: '提交后可使用新的验证码查询审核进度。',
  },
  panelTitles: {
    password: '先完成账号登录',
    code: '验证码登录',
    register: '注册新账号',
    reset: '找回密码',
    appeal: '封禁申诉',
  },
  text: {
    brandMark: '礼',
    brandEyebrow: '账号服务',
    brandTitle: '登录礼宾台',
    signal: '安全验证',
    userCenter: '用户中心',
    resumeTagRedirect: '拦截恢复',
    resumeTagDefault: '登录提示',
    resumeTitleRedirect: '这次操作已经为你保留',
    resumeTitleDefault: '账号链路已经准备就绪',
    bannerTagRedirect: '继续任务',
    bannerTagDefault: '账号引导',
    bannedAction: '提交封禁申诉',
    accountOrPhoneLabel: '邮箱 / 手机号',
    accountPlaceholder: 'user@example.com / +8613800000000',
    passwordLabel: '密码',
    passwordPlaceholder: '输入登录密码',
    passwordSupport: '已有密码可直接登录，完成后会恢复刚才的页面和操作。',
    signingIn: '登录中...',
    signIn: '登录',
    accountTypeLabel: '账号类型',
    accountLabel: '账号',
    codeAccountPlaceholder: '收验证码的账号',
    verificationCodeLabel: '验证码',
    verificationCodePlaceholder: '输入验证码',
    sending: '发送中...',
    sendCode: '发验证码',
    codeSupport: '本地环境会直接回显 mock 验证码。',
    codeSignIn: '验证码登录',
    registerAccountPlaceholder: '用于注册的新账号',
    nicknameLabel: '昵称',
    nicknamePlaceholder: '不填则使用系统默认昵称',
    registerPasswordPlaceholder: '设置登录密码',
    registerSupport: '注册完成后会直接进入登录态。',
    registering: '注册中...',
    registerAndSignIn: '注册并登录',
    resetAccountPlaceholder: '找回密码的账号',
    newPasswordLabel: '新密码',
    newPasswordPlaceholder: '设置新密码',
    resetSupport: '重置成功后会回到密码登录。',
    resetting: '重置中...',
    resetPassword: '重置密码',
    bannedAccountLabel: '被封禁的账号',
    bannedAccountPlaceholder: '被封禁的邮箱 / 手机号',
    appealReasonLabel: '申诉理由',
    appealReasonPlaceholder: '说明你认为误封的原因（10-500 字），运营会人工复核。',
    appealSupport: '提交和查询进度共用验证码入口；审核通过后账号会自动解封。',
    submitting: '提交中...',
    submitAppeal: '提交申诉',
    querying: '查询中...',
    queryAppeal: '查询申诉进度',
    appealLabel: '申诉',
    banReasonLabel: '封禁原因：',
    appealReasonDisplayLabel: '申诉理由：',
    rejectReasonLabel: '驳回原因：',
    appealApproved: '申诉已通过，账号已解封，回到密码登录即可正常进入。',
    backToPassword: '回到密码登录',
    submittedAtLabel: '提交于',
    reviewedAtLabel: '审核于',
    codeAccountRequired: '先把账号填上，再点发验证码。',
    sendCodeFailed: '验证码发送失败',
    passwordLoginFailed: '密码登录失败',
    codeLoginFailed: '验证码登录失败',
    registerFailed: '注册失败',
    passwordResetSuccess: '密码已重置，回到密码登录即可继续。',
    passwordResetFailed: '重置密码失败',
    appealCredentialsRequired: '先填好账号和验证码，再提交申诉。',
    appealReasonTooShort: '申诉理由至少写 10 个字，把误封的情况说清楚。',
    appealSubmitFailed: '申诉提交失败',
    appealQueryCredentialsRequired: '查询进度也需要账号和一条新的验证码。',
    appealQueryFailed: '申诉进度查询失败',
    accountUnbanned: '账号已解封，直接用密码登录即可。',
  },
  panelSummary: (redirected) => redirected
    ? '刚才的动作已经保留，登录后会自动返回原页面继续。'
    : '可在同一入口完成登录、注册、验证码验证和密码重置。',
  stageHeadline: (redirected) => redirected ? '登录后直接续上当前任务' : '完成账号验证后继续',
  stageSummary: (redirectTo) => redirectTo
    ? `目标路径 ${redirectTo} 已记录，登录后会自动跳回。`
    : '验证码会发送到填写的邮箱或手机号。',
  resumeFacts: (redirectTo, region, device) => [
    { label: redirectTo ? '恢复目标' : '运行环境', value: redirectTo ?? '账号安全验证' },
    { label: '当前区域', value: region },
    { label: '设备识别', value: device },
  ],
  servicePromises: (redirected, region) => [
    {
      title: '动作恢复',
      detail: redirected ? '登录后自动恢复刚才的收藏、点评或互动动作。' : '账号验证和页面浏览在同一弹层中完成。',
    },
    { title: '验证码安全', detail: '验证码仅用于本次账号验证，请勿转发。' },
    { title: '区域一致', detail: `当前沿用 ${region} 区域视角，业务数据不会串区。` },
  ],
  stageFacts: (mode, redirectTo, region) => [
    { label: '当前方式', value: mode },
    { label: redirectTo ? '恢复路径' : '当前提示', value: redirectTo ?? '验证码可直接联调' },
    { label: '会话区域', value: region },
  ],
  bannedDescription: (account) => `账号 ${account} 当前处于封禁状态。如果你认为是误封，可以提交申诉，审核通过后会自动解封。`,
  codeSent: (seconds) => `验证码已发送，${seconds} 秒后可重发。`,
  mockCode: (code) => `本地 mock 验证码：${code}`,
  appealSubmitted: (id) => `申诉 #${id} 已提交，审核结果会同步到这里。`,
  appealRefreshed: (id) => `已刷新申诉 #${id} 的最新进度。`,
  appealStatusLabel: (status, fallback) => ({ 0: '待审核', 1: '已通过', 2: '已驳回' })[status] ?? fallback,
}

const enStrings: WebAuthStrings = {
  tag: 'en',
  accountTypes: [
    { value: 'email', label: 'Email' },
    { value: 'phone', label: 'Phone' },
  ],
  modes: [
    {
      mode: 'password',
      label: 'Password sign-in',
      eyebrow: 'Existing account',
      detail: 'Sign in with an existing password and resume saved actions immediately.',
      footer: 'Use your password to return to the page or action you started.',
    },
    {
      mode: 'code',
      label: 'Verification code',
      eyebrow: 'Quick verification',
      detail: 'Use a one-time code when signing in on a new device or without a password.',
      footer: 'Complete the one-time verification and continue where you left off.',
    },
    {
      mode: 'register',
      label: 'Create account',
      eyebrow: 'First visit',
      detail: 'Create an account to write reviews, interact and manage your profile.',
      footer: 'Registration signs you in automatically.',
    },
    {
      mode: 'reset',
      label: 'Reset password',
      eyebrow: 'Account recovery',
      detail: 'Verify your account and choose a new sign-in password.',
      footer: 'After resetting, return to password sign-in.',
    },
  ],
  appealMode: {
    mode: 'appeal',
    label: 'Ban appeal',
    eyebrow: 'Account appeal',
    detail: 'Submit an appeal for a banned account. Approval restores sign-in automatically.',
    footer: 'Use a new verification code whenever you check the appeal status.',
  },
  panelTitles: {
    password: 'Sign in to continue',
    code: 'Sign in with a code',
    register: 'Create a new account',
    reset: 'Recover your account',
    appeal: 'Appeal an account ban',
  },
  text: {
    brandMark: 'ID',
    brandEyebrow: 'Account services',
    brandTitle: 'Sign-in concierge',
    signal: 'Secure verification',
    userCenter: 'Account centre',
    resumeTagRedirect: 'Resume action',
    resumeTagDefault: 'Sign-in guide',
    resumeTitleRedirect: 'Your action has been saved',
    resumeTitleDefault: 'Account access is ready',
    bannerTagRedirect: 'Continue task',
    bannerTagDefault: 'Account guide',
    bannedAction: 'Submit ban appeal',
    accountOrPhoneLabel: 'Email or phone',
    accountPlaceholder: 'user@example.com / +447000000000',
    passwordLabel: 'Password',
    passwordPlaceholder: 'Enter your password',
    passwordSupport: 'Sign in and return to the page or action you started.',
    signingIn: 'Signing in...',
    signIn: 'Sign in',
    accountTypeLabel: 'Account type',
    accountLabel: 'Account',
    codeAccountPlaceholder: 'Account receiving the code',
    verificationCodeLabel: 'Verification code',
    verificationCodePlaceholder: 'Enter verification code',
    sending: 'Sending...',
    sendCode: 'Send code',
    codeSupport: 'Local environments display the mock verification code here.',
    codeSignIn: 'Sign in with code',
    registerAccountPlaceholder: 'New email or phone number',
    nicknameLabel: 'Display name',
    nicknamePlaceholder: 'Optional; a default name will be created',
    registerPasswordPlaceholder: 'Create a password',
    registerSupport: 'Registration signs you in automatically.',
    registering: 'Creating account...',
    registerAndSignIn: 'Create account and sign in',
    resetAccountPlaceholder: 'Account to recover',
    newPasswordLabel: 'New password',
    newPasswordPlaceholder: 'Create a new password',
    resetSupport: 'After resetting, return to password sign-in.',
    resetting: 'Resetting...',
    resetPassword: 'Reset password',
    bannedAccountLabel: 'Banned account',
    bannedAccountPlaceholder: 'Banned email or phone number',
    appealReasonLabel: 'Appeal reason',
    appealReasonPlaceholder: 'Explain why the ban should be reviewed (10-500 characters).',
    appealSupport: 'Submitting and checking status both require a verification code.',
    submitting: 'Submitting...',
    submitAppeal: 'Submit appeal',
    querying: 'Checking...',
    queryAppeal: 'Check appeal status',
    appealLabel: 'Appeal',
    banReasonLabel: 'Ban reason: ',
    appealReasonDisplayLabel: 'Appeal reason: ',
    rejectReasonLabel: 'Rejection reason: ',
    appealApproved: 'The appeal was approved and the account is unbanned. Return to password sign-in.',
    backToPassword: 'Back to password sign-in',
    submittedAtLabel: 'Submitted',
    reviewedAtLabel: 'Reviewed',
    codeAccountRequired: 'Enter the account before requesting a verification code.',
    sendCodeFailed: 'Could not send the verification code',
    passwordLoginFailed: 'Password sign-in failed',
    codeLoginFailed: 'Code sign-in failed',
    registerFailed: 'Could not create the account',
    passwordResetSuccess: 'Password reset complete. Sign in with the new password.',
    passwordResetFailed: 'Could not reset the password',
    appealCredentialsRequired: 'Enter the account and verification code before submitting the appeal.',
    appealReasonTooShort: 'Write at least 10 characters explaining why the ban should be reviewed.',
    appealSubmitFailed: 'Could not submit the appeal',
    appealQueryCredentialsRequired: 'Enter the account and a new verification code to check the appeal.',
    appealQueryFailed: 'Could not check the appeal status',
    accountUnbanned: 'The account is unbanned. Sign in with the password.',
  },
  panelSummary: (redirected) => redirected
    ? 'The action you started is saved. Sign in to return and continue automatically.'
    : 'Sign in, register, verify or recover your account from one place.',
  stageHeadline: (redirected) => redirected ? 'Sign in and resume your task' : 'Verify your account to continue',
  stageSummary: (redirectTo) => redirectTo
    ? `We saved ${redirectTo} and will return there after sign-in.`
    : 'The verification code will be sent to the email or phone number you enter.',
  resumeFacts: (redirectTo, region, device) => [
    { label: redirectTo ? 'Return to' : 'Flow', value: redirectTo ?? 'Secure account verification' },
    { label: 'Region', value: region },
    { label: 'Device', value: device },
  ],
  servicePromises: (redirected, region) => [
    {
      title: 'Resume actions',
      detail: redirected ? 'Return to the saved review, favourite or interaction after sign-in.' : 'Complete account verification without leaving the current page.',
    },
    { title: 'Secure codes', detail: 'Verification codes are only for this request. Do not share them.' },
    { title: 'Region consistency', detail: `The session remains in the ${region} region so data stays isolated.` },
  ],
  stageFacts: (mode, redirectTo, region) => [
    { label: 'Method', value: mode },
    { label: redirectTo ? 'Return path' : 'Status', value: redirectTo ?? 'Verification code ready' },
    { label: 'Session region', value: region },
  ],
  bannedDescription: (account) => `${account} is currently banned. Submit an appeal if you believe the ban should be reviewed; approval restores sign-in automatically.`,
  codeSent: (seconds) => `Verification code sent. You can request another in ${seconds} seconds.`,
  mockCode: (code) => `Local mock verification code: ${code}`,
  appealSubmitted: (id) => `Appeal #${id} was submitted. The latest result will appear here.`,
  appealRefreshed: (id) => `Appeal #${id} status refreshed.`,
  appealStatusLabel: (status, fallback) => ({ 0: 'Pending review', 1: 'Approved', 2: 'Rejected' })[status] ?? fallback,
}

export function authStringsForRegion(region: Region): WebAuthStrings {
  return localeForRegion(region) === 'en' ? enStrings : zhCnStrings
}

const ENGLISH_ERROR_BY_MESSAGE: Record<string, string> = {
  '账号已注册': 'This account is already registered.',
  '验证码无效或已过期': 'The verification code is invalid or expired.',
  '账号或密码错误': 'The account or password is incorrect.',
  '账号已被封禁，暂时无法登录': 'This account is banned and cannot sign in right now.',
  '账号已被封禁': 'This account is banned and cannot sign in right now.',
  '登录已失效，请重新登录': 'Your session expired. Sign in again.',
  '用户登录状态不存在': 'Your sign-in session is no longer available.',
  '验证码发送通道尚未配置': 'Verification code delivery is not configured.',
  '验证码校验通道尚未配置': 'Verification code validation is not configured.',
  '账号不存在': 'This account could not be found.',
  '账号未被封禁，无需申诉': 'This account is not banned and does not need an appeal.',
  '已有申诉正在处理中，请耐心等待审核结果': 'An appeal is already under review. Wait for the current result.',
  '该账号暂无申诉记录': 'No appeal record was found for this account.',
  '申诉状态已变化，请刷新后重试': 'The appeal status changed. Refresh and try again.',
  '邮箱格式不合法': 'The email address format is invalid.',
  '手机号格式不合法': 'The phone number format is invalid.',
}

export function localizeWebAuthError(
  strings: WebAuthStrings,
  error: unknown,
  fallback: string,
) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  const traceMatch = error.message.match(/\s*(\[traceId:\s*[^\]]+\])\s*$/)
  const trace = traceMatch?.[1]
  const message = trace ? error.message.slice(0, traceMatch.index).trim() : error.message.trim()
  const localized = ENGLISH_ERROR_BY_MESSAGE[message]
    ?? (/\p{Script=Han}/u.test(message) ? fallback : message)
  return trace ? `${localized} ${trace}` : localized
}
