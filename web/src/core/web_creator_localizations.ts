import type { Region } from '@/types/browse'
const zh = {
  eyebrow: '创作者', title: '创作者任务', summary: '领取任务，提交本人已发布的点评或帖子，审核通过后发放积分。',
  loading: '加载中…', empty: '暂时没有任务。', loadFailed: '任务加载失败', points: '积分', claim: '领取',
  submit: '提交成果', claimed: '已领取', done: '已发放积分', pending: '待审核', rejected: '已驳回，可修改后重新提交',
  refresh: '刷新', previous: '上一页', next: '下一页', cancel: '取消',
  evidenceType: '成果类型', review: '点评', post: '帖子', evidence: '选择已发布的作品', choose: '请选择作品',
  noEvidence: '没有可提交的已发布作品，请先发布点评或帖子并等待内容审核通过。', more: '加载更多作品',
  note: '成果说明（选填）', chooseRequired: '请选择一份已发布的作品',
}
const en: typeof zh = {
  eyebrow: 'Creator', title: 'Creator tasks', summary: 'Claim a task and submit your published review or post. Points are awarded after approval.',
  loading: 'Loading…', empty: 'No tasks yet.', loadFailed: 'Could not load tasks', points: 'points', claim: 'Claim',
  submit: 'Submit work', claimed: 'Claimed', done: 'Points awarded', pending: 'Awaiting review', rejected: 'Rejected — you can revise and resubmit',
  refresh: 'Refresh', previous: 'Previous', next: 'Next', cancel: 'Cancel',
  evidenceType: 'Work type', review: 'Review', post: 'Post', evidence: 'Choose your published work', choose: 'Choose work',
  noEvidence: 'No published work is available. Publish a review or post and wait for content approval first.', more: 'Load more work',
  note: 'Submission note (optional)', chooseRequired: 'Choose published work to submit',
}
export function creatorStringsForRegion(region: Region) { return region === 'EU' ? en : zh }
