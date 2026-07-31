import type { Region } from '@/types/browse'

export interface WebCommunityStrings {
  tag: 'zh-CN' | 'en'
  feed: {
    loadFailed: string; seoTitle: string; seoDescription: string; eyebrow: string; title: string; summary: string
    appGuidance: string; groups: string; topics: string; likes: string; comments: string
  }
  circles: {
    loadFailed: string; seoTitle: string; seoDescription: string; detailSeoTitle: string; detailSeoDescription: string
    eyebrow: string; title: string; summary: string; official: string
    counts: (members: number, posts: number) => string; likes: string; comments: string
  }
}

const zhCn: WebCommunityStrings = {
  tag: 'zh-CN',
  feed: {
    loadFailed: '社区加载失败', seoTitle: '华人社区', seoDescription: '只读浏览欧洲华人攻略、探店和生活经验。',
    eyebrow: 'Community · 只读版', title: '欧洲华人的生活经验，不该散落在聊天记录里。',
    summary: 'PC 端负责浏览和搜索收录；发布、点赞、关注与私信留在 APP。',
    appGuidance: '下载 APP 参与互动、发布攻略和管理自己的帖子。', groups: '浏览官方圈子', topics: '查看话题广场与热榜', likes: '喜欢', comments: '评论',
  },
  circles: {
    loadFailed: '圈子加载失败', seoTitle: '官方圈子', seoDescription: '只读浏览当前区域官方社区圈子。',
    detailSeoTitle: '圈子详情', detailSeoDescription: '查看官方圈子资料和公开帖子。', eyebrow: 'Official Groups · 只读',
    title: '找到在同一座城市生活的人。', summary: '官方圈子按当前区域展示，加入和发布请使用 APP。', official: '官方圈子',
    counts: (members, posts) => `${members} 位成员 · ${posts} 篇帖子`, likes: '喜欢', comments: '评论',
  },
}

const en: WebCommunityStrings = {
  tag: 'en',
  feed: {
    loadFailed: 'Could not load the community feed', seoTitle: 'Community', seoDescription: 'Browse public local guides, reviews and practical community posts.',
    eyebrow: 'Community · Read only', title: 'Local knowledge, collected in one public community.',
    summary: 'Browse and search on the web. Use the app to publish, like, follow or send messages.',
    appGuidance: 'Use the app to join conversations, publish guides and manage your posts.', groups: 'Browse official groups', topics: 'Explore topics and trends', likes: 'likes', comments: 'comments',
  },
  circles: {
    loadFailed: 'Could not load groups', seoTitle: 'Official groups', seoDescription: 'Browse official community groups in the current region.',
    detailSeoTitle: 'Group details', detailSeoDescription: 'View official group information and public posts.', eyebrow: 'Official groups · Read only',
    title: 'Meet people living in the same city.', summary: 'Groups are scoped to your region. Use the app to join or publish.', official: 'Official group',
    counts: (members, posts) => `${members} ${members === 1 ? 'member' : 'members'} · ${posts} ${posts === 1 ? 'post' : 'posts'}`, likes: 'likes', comments: 'comments',
  },
}

const STRINGS: Record<Region, WebCommunityStrings> = { CN: zhCn, EU: en }
export const communityStringsForRegion = (region: Region) => STRINGS[region]
export function localizeWebCommunityError(strings: WebCommunityStrings, error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN' || !/\p{Script=Han}/u.test(error.message)) return error.message || fallback
  return fallback
}
