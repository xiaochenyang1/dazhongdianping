import type { Region } from '@/types/admin'

const zh = {
  title: '创作者任务', summary: '核对用户提交的作品与领取时的任务要求，通过审核后发放积分。',
  reviews: '成果审核', tasks: '任务配置', refresh: '刷新', loading: '加载中…', failed: '加载或操作失败，请重试。',
  all: '全部状态', statuses: { 1: '已领取', 2: '已发放积分', 3: '待审核', 4: '已驳回' } as Record<number, string>,
  emptyClaims: '暂无符合条件的成果。', emptyTasks: '暂无任务。', select: '查看成果', selectHelp: '选择一份成果，核对作品后进行审核。',
  requirements: '领取时的任务要求', customer: '用户', points: '积分', submission: '成果说明', work: '提交的作品',
  review: '点评', post: '帖子', unavailable: '作品已删除或不再公开，无法通过审核。请填写原因驳回。',
  notSubmitted: '用户尚未提交成果。', note: '审核说明（驳回时必填）', noteRequired: '请填写驳回原因。',
  approve: '通过并发放积分', reject: '驳回', approved: '审核通过，积分已发放。', rejected: '已驳回，用户可以修改后重新提交。',
  previous: '上一页', next: '下一页', taskTitle: '任务标题', description: '任务要求', reward: '奖励积分',
  status: '状态', enabled: '进行中', disabled: '已下线', edit: '编辑', newTask: '新建任务', save: '保存任务', saved: '任务已保存。',
  invalid: '请填写任务标题和有效的非负整数积分。', frozen: '修改只影响以后领取的任务，已领取的要求与奖励保持不变。',
  shop: '关联门店', score: '评分', submittedAt: '提交时间', image: '作品图片', result: '审核结果',
}
const en: typeof zh = {
  title: 'Creator tasks', summary: 'Compare submitted work with the claimed task requirements. Award points only after approval.',
  reviews: 'Review submissions', tasks: 'Manage tasks', refresh: 'Refresh', loading: 'Loading…', failed: 'Could not complete the request. Please retry.',
  all: 'All statuses', statuses: { 1: 'Claimed', 2: 'Points awarded', 3: 'Awaiting review', 4: 'Rejected' },
  emptyClaims: 'No matching submissions.', emptyTasks: 'No tasks yet.', select: 'View submission', selectHelp: 'Select a submission and inspect the work before reviewing it.',
  requirements: 'Requirements when claimed', customer: 'User', points: 'points', submission: 'Submission note', work: 'Submitted work',
  review: 'Review', post: 'Post', unavailable: 'This work was deleted or is no longer public. Reject it with a reason.',
  notSubmitted: 'No work has been submitted yet.', note: 'Review note (required for rejection)', noteRequired: 'Enter a reason for rejection.',
  approve: 'Approve and award points', reject: 'Reject', approved: 'Approved. Points have been awarded.', rejected: 'Rejected. The user can revise and resubmit.',
  previous: 'Previous', next: 'Next', taskTitle: 'Task title', description: 'Task requirements', reward: 'Reward points',
  status: 'Status', enabled: 'Open', disabled: 'Closed', edit: 'Edit', newTask: 'New task', save: 'Save task', saved: 'Task saved.',
  invalid: 'Enter a title and a valid non-negative integer reward.', frozen: 'Changes apply to future claims. Existing claims keep their requirements and rewards.',
  shop: 'Linked shop', score: 'Rating', submittedAt: 'Submitted at', image: 'Work image', result: 'Review result',
}

export function adminCreatorStrings(region: Region) { return region === 'EU' ? en : zh }
