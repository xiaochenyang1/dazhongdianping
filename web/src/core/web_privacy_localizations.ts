import type { Region } from '@/types/browse'
import type { PrivacyExportModule } from '@/types/privacy'
import { formatEnglishCount } from './web_count_localizations'

interface ModuleText { label: string; description: string }

const zhModules: Record<PrivacyExportModule, ModuleText> = {
  account: { label: '账号数据', description: '资料、绑定账号、成长值流水和搜索历史。' },
  reviews: { label: '点评数据', description: '我发布过的点评、评分、审核状态和互动计数。' },
  orders: { label: '订单数据', description: '团购订单、金额、支付状态和创建时间。' },
  posts: { label: '帖子数据', description: '我发布过的帖子、图片、话题、审核状态和互动计数。' },
  reservations: { label: '预订数据', description: '预订门店、到店时间、联系人和状态。' },
  favorites: { label: '收藏数据', description: '收藏对象、门店快照和收藏时间。' },
  browse_history: { label: '浏览足迹', description: '最近浏览过的门店、查看次数和最近访问时间。' },
  follows: { label: '关注关系', description: '我关注的人、关注我的人和关系建立时间。' },
  messages: { label: '私信数据', description: '会话成员、文本消息、已读时间、举报和拉黑关系。' },
  circles: { label: '圈子关系', description: '已加入的官方圈子、成员身份和加入时间。' },
  topics: { label: '话题关系', description: '已关注的话题、关注时间和当前公开状态。' },
}

const enModules: Record<PrivacyExportModule, ModuleText> = {
  account: { label: 'Account data', description: 'Profile, linked accounts, growth history and search history.' },
  reviews: { label: 'Review data', description: 'Your reviews, ratings, moderation status and interaction counts.' },
  orders: { label: 'Order data', description: 'Offer orders, amounts, payment status and creation dates.' },
  posts: { label: 'Post data', description: 'Your posts, images, topics, moderation status and interaction counts.' },
  reservations: { label: 'Booking data', description: 'Places, booking times, contact details and status.' },
  favorites: { label: 'Saved items', description: 'Saved targets, place snapshots and save dates.' },
  browse_history: { label: 'Browsing history', description: 'Recently viewed places, view counts and latest visits.' },
  follows: { label: 'Connections', description: 'People you follow, followers and connection dates.' },
  messages: { label: 'Direct messages', description: 'Conversation members, messages, read dates, reports and blocks.' },
  circles: { label: 'Group memberships', description: 'Official groups, membership roles and join dates.' },
  topics: { label: 'Followed topics', description: 'Followed topics, follow dates and current public status.' },
}

const zhCnStrings = {
  tag: 'zh-CN' as const, modules: zhModules,
  policyAccepted: '协议同意记录已留痕。', policyFailed: '协议留痕失败', deviceDeactivated: '设备已停用并清除推送 token。', deviceFailed: '停用设备失败',
  policyName: (type: number) => ({ 1: '隐私政策', 2: '用户协议', 3: 'Cookie/营销告知' } as Record<number, string>)[type] || '未知协议',
  platformName: (platform: number) => ({ 1: 'iOS', 2: 'Android', 3: 'Web' } as Record<number, string>)[platform] || '未知设备',
  deviceStatus: (status: number) => ({ 1: '启用', 2: '已停用', 3: '已登出' } as Record<number, string>)[status] || '未知状态',
  exportStatus: (status: number) => ({ 0: '待处理', 1: '处理中', 2: '可下载', 3: '已过期', 4: '失败', 5: '已取消' } as Record<number, string>)[status] || '未知状态',
  deleteStatus: (status: number) => ({ 0: '待确认', 1: '冷静期中', 2: '处理中', 3: '已完成', 4: '已取消', 5: '已驳回' } as Record<number, string>)[status] || '未知状态',
  loadFailed: '隐私中心加载失败', selectModule: '至少选择一个导出模块。', exportCreated: '数据导出任务已创建，文件准备好后可直接下载。', exportFailed: '创建导出任务失败',
  downloadStarted: (id: number) => `导出任务 #${id} 已开始下载。`, downloadFailed: '下载导出文件失败', accountRequired: '先选择或填写当前已绑定账号。',
  deleteCodeSent: (seconds: number) => `注销验证码已发送，${seconds} 秒后可重发。`, mockCode: (code: string) => `本地 mock 验证码：${code}`, deleteCodeFailed: '注销验证码发送失败',
  accountReasonRequired: '校验账号和删除原因都得填。', codeRequired: '验证码还没填。', passwordRequired: '登录密码还没填。',
  deleteSubmitted: '删除申请已进入冷静期，到期前可以撤销。', deleteSubmitFailed: '提交删除申请失败', deleteCancelled: '删除申请已撤销，账号会继续保留。', deleteCancelFailed: '撤销删除申请失败',
  heroEyebrow: '隐私中心', heroTitle: '管理数据导出、协议记录、设备和账号删除。', heroSummary: '查看任务状态、文件期限和账号删除冷静期。',
  dataExport: '数据导出', dailyLimit: (count: number | string) => `每天最多 ${count} 次`, retention: (hours: number | string) => `文件保留 ${hours} 小时`,
  accountDeletion: '账号删除', coolingOff: (days: number | string) => `${days} 天冷静期`, deleteRule: '到期前可以撤销；到期后账号与个人数据会按规则处理。', loading: '隐私规则和任务加载中...',
  exportTitle: '先选范围，再生成有有效期的 ZIP。', authenticatedDownload: '认证下载', creating: '创建中...', createExport: '创建导出任务', task: (id: number) => `任务 #${id}`,
  unspecifiedModules: '未指定模块', createdAt: '创建于', expiresAt: '到期', format: '格式', downloading: '下载中...', downloadZip: '下载 ZIP', noExports: '还没有导出任务。',
  agreements: '协议留痕', agreementsTitle: '查看并记录已同意的协议版本。', traceable: '可追溯', recording: '记录中...', confirmPrivacy: '确认隐私政策', confirmAgreement: '确认用户协议', unknownClient: '未知客户端', noAgreements: '还没有协议同意记录。',
  devices: '设备管理', devicesTitle: '查看并管理登录过的设备。', proactiveDeactivate: '主动停用', lastActive: '最近活跃', deactivating: '停用中...', deactivate: '停用设备', noDevices: '还没有登记设备。',
  deletionTitle: '删除账号前请确认验证方式、冷静期和处理后果。', revocable: '可撤销冷静期', deleteTask: (id: number) => `删除任务 #${id}`, reason: '原因', deadline: '冷静期截止', cancelling: '撤销中...', cancelDelete: '撤销删除申请',
  verifyCode: '验证码校验', verifyPassword: '密码校验', boundAccount: '当前已绑定账号', deleteReason: '删除原因', reasonPlaceholder: '请说明删除原因', verificationCode: '验证码', codePlaceholder: '输入注销验证码', sending: '发送中...', sendDeleteCode: '发送注销验证码', loginPassword: '登录密码', passwordPlaceholder: '输入当前登录密码',
  deleteIntro: (days: number | string) => `提交后进入 ${days} 天冷静期；到期处理后当前登录态会失效，账号不能再登录。`, submitting: '提交中...', submitDelete: '提交删除申请', unavailable: '—',
  errorTranslations: {} as Record<string, string>,
}

const enStrings = {
  tag: 'en' as const, modules: enModules,
  policyAccepted: 'Agreement acceptance recorded.', policyFailed: 'Could not record agreement acceptance', deviceDeactivated: 'Device deactivated and push token removed.', deviceFailed: 'Could not deactivate the device',
  policyName: (type: number) => ({ 1: 'Privacy policy', 2: 'User agreement', 3: 'Cookie / marketing notice' } as Record<number, string>)[type] || 'Unknown agreement',
  platformName: (platform: number) => ({ 1: 'iOS', 2: 'Android', 3: 'Web' } as Record<number, string>)[platform] || 'Unknown device',
  deviceStatus: (status: number) => ({ 1: 'Active', 2: 'Deactivated', 3: 'Signed out' } as Record<number, string>)[status] || 'Unknown status',
  exportStatus: (status: number) => ({ 0: 'Pending', 1: 'Processing', 2: 'Ready to download', 3: 'Expired', 4: 'Failed', 5: 'Cancelled' } as Record<number, string>)[status] || 'Unknown status',
  deleteStatus: (status: number) => ({ 0: 'Pending confirmation', 1: 'Cooling-off period', 2: 'Processing', 3: 'Completed', 4: 'Cancelled', 5: 'Rejected' } as Record<number, string>)[status] || 'Unknown status',
  loadFailed: 'Could not load the privacy centre', selectModule: 'Select at least one export module.', exportCreated: 'Export task created. Download it when the file is ready.', exportFailed: 'Could not create the export task',
  downloadStarted: (id: number) => `Export task #${id} started downloading.`, downloadFailed: 'Could not download the export file', accountRequired: 'Select a currently linked account first.',
  deleteCodeSent: (seconds: number) => `Deletion code sent. You can resend in ${formatEnglishCount(seconds, 'second')}.`, mockCode: (code: string) => `Local test code: ${code}`, deleteCodeFailed: 'Could not send the deletion code',
  accountReasonRequired: 'Enter a verification account and deletion reason.', codeRequired: 'Enter the verification code.', passwordRequired: 'Enter your login password.',
  deleteSubmitted: 'Deletion request submitted. You can cancel it during the cooling-off period.', deleteSubmitFailed: 'Could not submit the deletion request', deleteCancelled: 'Deletion request cancelled. Your account will remain active.', deleteCancelFailed: 'Could not cancel the deletion request',
  heroEyebrow: 'Privacy centre', heroTitle: 'Manage exports, agreements, devices and account deletion.', heroSummary: 'Review task status, file retention and the account deletion cooling-off period.',
  dataExport: 'Data export', dailyLimit: (count: number | string) => `Up to ${formatEnglishCount(count, 'time')} per day`, retention: (hours: number | string) => `Files kept for ${formatEnglishCount(hours, 'hour')}`,
  accountDeletion: 'Account deletion', coolingOff: (days: number | string) => `${days}-day cooling-off`, deleteRule: 'Cancel before the deadline. After it, the account and personal data are processed under the deletion rules.', loading: 'Loading privacy rules and tasks...',
  exportTitle: 'Choose the scope and generate a time-limited ZIP.', authenticatedDownload: 'Authenticated download', creating: 'Creating...', createExport: 'Create export task', task: (id: number) => `Task #${id}`,
  unspecifiedModules: 'No modules specified', createdAt: 'Created', expiresAt: 'Expires', format: 'Format', downloading: 'Downloading...', downloadZip: 'Download ZIP', noExports: 'No export tasks yet.',
  agreements: 'Agreement records', agreementsTitle: 'Review and record accepted agreement versions.', traceable: 'Traceable', recording: 'Recording...', confirmPrivacy: 'Confirm privacy policy', confirmAgreement: 'Confirm user agreement', unknownClient: 'Unknown client', noAgreements: 'No agreement acceptance records yet.',
  devices: 'Device management', devicesTitle: 'Review and manage devices used to sign in.', proactiveDeactivate: 'Manual deactivation', lastActive: 'Last active', deactivating: 'Deactivating...', deactivate: 'Deactivate device', noDevices: 'No registered devices yet.',
  deletionTitle: 'Confirm verification, cooling-off period and consequences before deleting your account.', revocable: 'Revocable cooling-off period', deleteTask: (id: number) => `Delete task #${id}`, reason: 'Reason', deadline: 'Cooling-off ends', cancelling: 'Cancelling...', cancelDelete: 'Cancel deletion request',
  verifyCode: 'Verify with code', verifyPassword: 'Verify with password', boundAccount: 'Currently linked account', deleteReason: 'Deletion reason', reasonPlaceholder: 'Explain why you want to delete the account', verificationCode: 'Verification code', codePlaceholder: 'Enter deletion code', sending: 'Sending...', sendDeleteCode: 'Send deletion code', loginPassword: 'Login password', passwordPlaceholder: 'Enter your current login password',
  deleteIntro: (days: number | string) => `Submission starts a ${days}-day cooling-off period. After processing, the current session ends and the account can no longer sign in.`, submitting: 'Submitting...', submitDelete: 'Submit deletion request', unavailable: '—',
  errorTranslations: { '用户登录状态不存在': 'Your session has expired. Sign in again.' } as Record<string, string>,
}

export type WebPrivacyStrings = typeof zhCnStrings | typeof enStrings
const STRINGS: Record<Region, WebPrivacyStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function privacyStringsForRegion(region: Region) { return STRINGS[region] }
export function localizeWebPrivacyError(strings: WebPrivacyStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  return strings.errorTranslations[error.message.trim()] || (HAN_TEXT.test(error.message) ? fallback : error.message || fallback)
}
