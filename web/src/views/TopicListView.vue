<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchHotTopics, fetchTopics, type PublicTopic } from '@/services/topic'

const topics = ref<PublicTopic[]>([])
const mode = ref<'recommended' | 'hot'>('recommended')
const loading = ref(false)
const error = ref('')

async function load(nextMode: 'recommended' | 'hot') {
  mode.value = nextMode
  loading.value = true
  error.value = ''
  try {
    topics.value = (nextMode === 'hot' ? await fetchHotTopics() : await fetchTopics('recommended')).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '话题加载失败'
  } finally {
    loading.value = false
  }
}

onMounted(() => load('recommended'))
</script>

<template>
  <section class="page-section topic-index">
    <header class="topic-hero">
      <div>
        <p class="eyebrow">CITY TOPIC INDEX · 只读</p>
        <h1>城市里正在被反复谈起的事。</h1>
        <p>推荐是编辑选择，热榜按最近 7 天公开帖子、点赞与评论计算。参与关注和发帖请使用 APP。</p>
      </div>
      <div class="mode-switch" aria-label="话题榜单切换">
        <button type="button" :class="{ active: mode === 'recommended' }" @click="load('recommended')">编辑推荐</button>
        <button type="button" :class="{ active: mode === 'hot' }" @click="load('hot')">最近 7 天热榜</button>
      </div>
    </header>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="loading" class="feedback">正在整理当前区域的话题...</p>

    <div v-else class="topic-ledger">
      <RouterLink
        v-for="(topic, index) in topics"
        :key="topic.id"
        :to="`/topics/${topic.id}`"
        class="topic-entry"
      >
        <div class="entry-rank">{{ mode === 'hot' ? `TOP ${index + 1}` : String(index + 1).padStart(2, '0') }}</div>
        <div class="entry-main">
          <div class="entry-title-row">
            <h2>{{ topic.name }}</h2>
            <span v-if="topic.recommended" class="recommend-mark">编辑推荐</span>
          </div>
          <p class="composition">{{ topic.postCount7d }} 帖 · {{ topic.likeCount7d }} 赞 · {{ topic.commentCount7d }} 评论</p>
          <p class="audience">{{ topic.followerCount }} 人关注 · {{ topic.postCount }} 篇公开帖子</p>
        </div>
        <strong class="heat">热度 {{ topic.hotScore }}</strong>
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.topic-index { --topic-ink:#17201c; --topic-paper:#f2eee3; --topic-accent:#c6532e; color:var(--topic-ink); -webkit-font-smoothing:antialiased; }
.topic-hero { display:grid; grid-template-columns:minmax(0,1.4fr) minmax(300px,.6fr); gap:36px; align-items:end; padding:38px; border-radius:32px; background:linear-gradient(110deg,rgba(198,83,46,.16),transparent 52%),repeating-linear-gradient(90deg,transparent 0 55px,rgba(23,32,28,.04) 56px),var(--topic-paper); box-shadow:0 0 0 1px rgba(0,0,0,.055),0 20px 48px rgba(42,35,24,.09); }
.topic-hero h1 { max-width:760px; margin:0; font-family:"Noto Serif SC","Source Han Serif SC",serif; font-size:clamp(36px,5vw,62px); line-height:1.08; letter-spacing:-.05em; text-wrap:balance; }
.topic-hero p:not(.eyebrow) { max-width:720px; color:#5f6961; text-wrap:pretty; }
.mode-switch { display:grid; grid-template-columns:1fr 1fr; gap:7px; padding:7px; border-radius:18px; background:rgba(255,255,255,.68); box-shadow:0 0 0 1px rgba(0,0,0,.06); }
.mode-switch button { min-height:44px; border:0; border-radius:11px; background:transparent; cursor:pointer; font-weight:900; color:#667068; transition-property:scale,background-color,color,box-shadow; transition-duration:150ms; transition-timing-function:ease-out; }
.mode-switch button.active { background:var(--topic-ink); color:#fff; box-shadow:0 6px 16px rgba(23,32,28,.2); }
.mode-switch button:active { scale:.96; }
.topic-ledger { display:grid; gap:12px; margin-top:24px; }
.topic-entry { display:grid; grid-template-columns:86px minmax(0,1fr) auto; gap:22px; align-items:center; padding:22px; border-radius:22px; color:inherit; text-decoration:none; background:#fff; box-shadow:0 0 0 1px rgba(0,0,0,.055),0 1px 2px -1px rgba(0,0,0,.08),0 12px 30px rgba(28,38,32,.06); transition-property:transform,box-shadow; transition-duration:180ms; transition-timing-function:ease-out; }
.topic-entry:hover { transform:translateY(-3px); box-shadow:0 0 0 1px rgba(0,0,0,.08),0 18px 38px rgba(28,38,32,.1); }
.entry-rank { font-variant-numeric:tabular-nums; color:var(--topic-accent); font-size:13px; font-weight:950; letter-spacing:.09em; }
.entry-title-row { display:flex; gap:10px; align-items:center; flex-wrap:wrap; }
.entry-title-row h2 { margin:0; font-family:"Noto Serif SC","Source Han Serif SC",serif; font-size:27px; }
.recommend-mark { padding:5px 8px; border-radius:999px; background:#f5dfb5; color:#70420c; font-size:11px; font-weight:900; }
.composition,.audience { margin:7px 0 0; font-variant-numeric:tabular-nums; }
.composition { color:#355c48; font-weight:800; }
.audience { color:#7a837c; font-size:13px; }
.heat { color:var(--topic-accent); font-variant-numeric:tabular-nums; white-space:nowrap; }
@media(max-width:800px){.topic-hero{grid-template-columns:1fr;padding:26px}.topic-entry{grid-template-columns:62px 1fr}.heat{grid-column:2}.mode-switch{max-width:420px}}
@media(max-width:520px){.topic-entry{grid-template-columns:1fr}.entry-rank,.heat{grid-column:1}.topic-hero h1{font-size:38px}}
</style>
