<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchHotTopics, fetchTopics, type PublicTopic } from '@/services/topic'
import { absoluteSeoUrl, useSeoMeta } from '@/composables/useSeoMeta'
import { useAppContext } from '@/composables/useAppContext'
import { communityStringsForRegion, localizeWebCommunityError } from '@/core/web_community_localizations'

const topics = ref<PublicTopic[]>([])
const mode = ref<'recommended' | 'hot'>('recommended')
const loading = ref(false)
const error = ref('')
const { state: appState } = useAppContext()
const copy = computed(() => communityStringsForRegion(appState.region))
let requestSequence = 0

useSeoMeta(() => ({
  title: copy.value.topics.seoTitle,
  description: copy.value.topics.seoDescription(mode.value === 'hot'),
  canonical: '/topics',
  jsonLd: {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: copy.value.topics.seoTitle,
    description: copy.value.topics.schemaDescription,
    url: absoluteSeoUrl('/topics'),
    mainEntity: {
      '@type': 'ItemList',
      itemListElement: topics.value.map((topic, index) => ({
        '@type': 'ListItem',
        position: index + 1,
        name: topic.name,
        url: absoluteSeoUrl(`/topics/${topic.id}`),
        description: copy.value.topics.audience(topic.followerCount, topic.postCount),
      })),
    },
  },
}))

async function load(nextMode: 'recommended' | 'hot') {
  const request = ++requestSequence
  mode.value = nextMode
  loading.value = true
  error.value = ''
  topics.value = []
  try {
    const page = nextMode === 'hot' ? await fetchHotTopics() : await fetchTopics('recommended')
    if (request !== requestSequence) return
    topics.value = page.list
  } catch (cause) {
    if (request === requestSequence) {
      error.value = localizeWebCommunityError(copy.value, cause, copy.value.topics.loadFailed)
    }
  } finally {
    if (request === requestSequence) loading.value = false
  }
}

watch(
  () => appState.region,
  () => void load(mode.value),
  { immediate: true },
)
</script>

<template>
  <section class="page-section topic-index">
    <header class="topic-hero">
      <div>
        <p class="eyebrow">{{ copy.topics.eyebrow }}</p>
        <h1>{{ copy.topics.title }}</h1>
        <p>{{ copy.topics.summary }}</p>
      </div>
      <div class="mode-switch" :aria-label="copy.topics.switchAria">
        <button type="button" :class="{ active: mode === 'recommended' }" @click="load('recommended')">{{ copy.topics.recommended }}</button>
        <button type="button" :class="{ active: mode === 'hot' }" @click="load('hot')">{{ copy.topics.hot }}</button>
      </div>
    </header>

    <p v-if="error" class="feedback is-error">{{ error }}</p>
    <p v-if="loading" class="feedback">{{ copy.topics.loading }}</p>

    <div v-else class="topic-ledger">
      <RouterLink
        v-for="(topic, index) in topics"
        :key="topic.id"
        :to="`/topics/${topic.id}`"
        class="topic-entry"
      >
        <div class="entry-rank">{{ mode === 'hot' ? copy.topics.top(index + 1) : copy.topics.rank(index + 1) }}</div>
        <div class="entry-main">
          <div class="entry-title-row">
            <h2>{{ topic.name }}</h2>
            <span v-if="topic.recommended" class="recommend-mark">{{ copy.topics.recommendedMark }}</span>
          </div>
          <p class="composition">{{ copy.topics.composition(topic.postCount7d, topic.likeCount7d, topic.commentCount7d) }}</p>
          <p class="audience">{{ copy.topics.audience(topic.followerCount, topic.postCount) }}</p>
        </div>
        <strong class="heat">{{ copy.topics.heat(topic.hotScore) }}</strong>
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
