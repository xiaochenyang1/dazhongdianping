import type { Region } from '@/types/browse'
import { formatEnglishCount } from './web_count_localizations'

const zhCnStrings = {
  tag: 'zh-CN' as const,
  expertApprovedBanner: '平台已通过你的本地达人认证，公开资料现可展示达人标识。',
  expertRejectedBanner: '平台未通过你的本地达人认证，请查看驳回原因后重新申请。',
  email: '邮箱', phone: '手机号', reviewing: '审核中', certified: '已认证', resubmitExpert: '重新提交申请', submitExpert: '提交达人申请',
  hasPasswordHint: '当前账号已经有密码，修改时需要验证旧密码。', noPasswordHint: '当前账号还没有密码，可以直接设置新密码。',
  loadFailed: '资料加载失败', saveFailed: '资料保存失败', saved: '资料已更新。',
  fillTarget: (target: string) => `请先填写${target}。`, codeSent: (target: string, seconds: number) => `${target}验证码已发送，${seconds} 秒后可重发。`,
  mockCode: (code: string) => `本地 mock 验证码：${code}`, sendCodeFailed: '验证码发送失败', fillAccountAndCode: (target: string) => `请填写${target}和验证码。`,
  bound: (target: string) => `${target}已绑定成功。`, bindFailed: '账号绑定失败', passwordRequired: '请填写新密码和确认密码。',
  passwordsMismatch: '两次输入的新密码不一致。', passwordUpdated: '密码已经更新。', passwordFailed: '密码更新失败',
  expertAlreadyApproved: '你已经是认证达人，无需重复申请。', expertPending: '当前申请还在审核中，请勿重复提交。', expertReasonRequired: '请填写申请理由。',
  expertSubmitted: '达人认证申请已提交，请等待审核。', expertUpdated: '达人认证状态已更新。', expertFailed: '达人认证申请提交失败',
  heroEyebrow: '我的资料', heroTitle: '管理个人资料、账号绑定和登录密码。', heroSummary: '所有修改都会经过后端校验，并同步到当前账号。', loading: '资料加载中...',
  basicProfile: '基础资料', basicProfileTitle: '更新公开资料与个人偏好。', nickname: '昵称', avatarUrl: '头像 URL', gender: '性别', genderUnknown: '未知', genderMale: '男', genderFemale: '女',
  preferredRegion: '偏好区域', signature: '签名', signaturePlaceholder: '写点能代表你的话。', unbound: '未绑定', accountStats: '等级 / 积分 / 成长值',
  stats: (level: number, points: number, growth: number) => `Lv.${level} · ${points} 积分 · ${growth} 成长值`, saving: '保存中...', saveProfile: '保存资料', growthHistory: '查看成长值流水', privacyCenter: '进入隐私中心',
  accountSecurity: '账户安全', accountSecurityTitle: '管理账号绑定与登录密码。', accountBinding: '绑定账号', accountBindingTitle: '邮箱和手机号均可绑定或换绑。', bindType: '绑定类型', verificationCode: '验证码', codePlaceholder: '输入验证码', sending: '发送中...', sendCode: '发送验证码', binding: '绑定中...', confirmBind: '确认绑定',
  changePassword: '修改密码', changePasswordTitle: '验证旧密码后设置新密码；未设置密码的账号可直接补充。', oldPassword: '旧密码', oldPasswordPlaceholder: '已有密码时填写', newPassword: '新密码', newPasswordPlaceholder: '设置新密码', confirmPassword: '确认新密码', confirmPasswordPlaceholder: '再次输入新密码', updatePassword: '更新密码',
  expertCertification: '达人认证', expertCertificationTitle: '提交本地达人申请，通过审核后展示公开标识。', currentStatus: '当前状态', currentStatusTitle: '只有已通过且有效的认证会展示在公开资料中。',
  expertStatus: (status: number) => ({ 0: '未申请', 1: '待审核', 2: '已通过', 3: '已驳回' } as Record<number, string>)[status] || '未知状态',
  publicBadge: '公开标识', badgeHidden: '未公开展示', submittedAt: '提交时间', notSubmitted: '还没提交', reviewedAt: '审核时间', unavailable: '暂无', rejectReason: '驳回原因', applicationReason: '申请理由',
  reasonPlaceholder: '说明你在本地区的内容贡献、探店经验或持续输出计划。', submitting: '提交中...',
  errorTranslations: {} as Record<string, string>,
}

const enStrings = {
  tag: 'en' as const,
  expertApprovedBanner: 'Your local expert certification was approved. Your public profile can now show the badge.',
  expertRejectedBanner: 'Your local expert certification was rejected. Review the reason and resubmit.',
  email: 'Email', phone: 'Phone', reviewing: 'Under review', certified: 'Certified', resubmitExpert: 'Resubmit application', submitExpert: 'Apply for expert status',
  hasPasswordHint: 'This account already has a password. Changing it requires the current one.', noPasswordHint: 'This account has no password yet. You can set a new one directly.',
  loadFailed: 'Could not load account profile', saveFailed: 'Could not save profile', saved: 'Profile updated.',
  fillTarget: (target: string) => `Enter ${target.toLowerCase()} first.`, codeSent: (target: string, seconds: number) => `${target} code sent. You can resend in ${formatEnglishCount(seconds, 'second')}.`,
  mockCode: (code: string) => `Local test code: ${code}`, sendCodeFailed: 'Could not send the verification code', fillAccountAndCode: (target: string) => `Enter the ${target.toLowerCase()} and verification code.`,
  bound: (target: string) => `${target} bound successfully.`, bindFailed: 'Could not bind the account', passwordRequired: 'Enter and confirm the new password.',
  passwordsMismatch: 'New passwords do not match.', passwordUpdated: 'Password updated.', passwordFailed: 'Could not update the password',
  expertAlreadyApproved: 'You are already a certified local expert.', expertPending: 'Your application is already under review.', expertReasonRequired: 'Enter an application reason.',
  expertSubmitted: 'Local expert application submitted for review.', expertUpdated: 'Local expert certification updated.', expertFailed: 'Could not submit the expert application',
  heroEyebrow: 'My profile', heroTitle: 'Manage your profile, linked accounts and password.', heroSummary: 'Changes are validated by the backend and applied to your current account.', loading: 'Loading profile...',
  basicProfile: 'Basic profile', basicProfileTitle: 'Update your public profile and preferences.', nickname: 'Nickname', avatarUrl: 'Avatar URL', gender: 'Gender', genderUnknown: 'Unknown', genderMale: 'Male', genderFemale: 'Female',
  preferredRegion: 'Preferred region', signature: 'Bio', signaturePlaceholder: 'Add a short public bio.', unbound: 'Not bound', accountStats: 'Level / points / growth',
  stats: (level: number, points: number, growth: number) => `Lv.${level} · ${formatEnglishCount(points, 'point')} · ${growth} growth`, saving: 'Saving...', saveProfile: 'Save profile', growthHistory: 'View growth history', privacyCenter: 'Open privacy centre',
  accountSecurity: 'Account security', accountSecurityTitle: 'Manage linked accounts and your login password.', accountBinding: 'Account binding', accountBindingTitle: 'Bind or replace an email address or phone number.', bindType: 'Binding type', verificationCode: 'Verification code', codePlaceholder: 'Enter verification code', sending: 'Sending...', sendCode: 'Send code', binding: 'Binding...', confirmBind: 'Confirm binding',
  changePassword: 'Change password', changePasswordTitle: 'Verify the current password, or set one directly if the account has none.', oldPassword: 'Current password', oldPasswordPlaceholder: 'Required when a password exists', newPassword: 'New password', newPasswordPlaceholder: 'Set a new password', confirmPassword: 'Confirm new password', confirmPasswordPlaceholder: 'Enter the new password again', updatePassword: 'Update password',
  expertCertification: 'Local expert certification', expertCertificationTitle: 'Apply for a public local expert badge through moderation.', currentStatus: 'Current status', currentStatusTitle: 'Only approved and active certifications appear on public profiles.',
  expertStatus: (status: number) => ({ 0: 'Not applied', 1: 'Pending review', 2: 'Approved', 3: 'Rejected' } as Record<number, string>)[status] || 'Unknown status',
  publicBadge: 'Public badge', badgeHidden: 'Not publicly displayed', submittedAt: 'Submitted', notSubmitted: 'Not submitted', reviewedAt: 'Reviewed', unavailable: 'Not available', rejectReason: 'Rejection reason', applicationReason: 'Application reason',
  reasonPlaceholder: 'Describe your local content work, exploration experience or ongoing plans.', submitting: 'Submitting...',
  errorTranslations: {
    '用户登录状态不存在': 'Your session has expired. Sign in again.',
    '旧密码错误': 'The current password is incorrect.',
    '新密码不能与旧密码相同': 'The new password must be different from the current password.',
    '申请理由不能为空': 'Enter an application reason.',
  } as Record<string, string>,
}

export type WebProfileStrings = typeof zhCnStrings | typeof enStrings
const STRINGS: Record<Region, WebProfileStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function profileStringsForRegion(region: Region) { return STRINGS[region] }

export function localizeWebProfileError(strings: WebProfileStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN') return error.message || fallback
  return strings.errorTranslations[error.message.trim()] || (HAN_TEXT.test(error.message) ? fallback : error.message || fallback)
}
