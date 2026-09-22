<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import { qaStringsForRegion } from '@/core/web_qa_localizations'
import { answerQuestion, askQuestion, fetchAnswers, fetchQuestions } from '@/services/qa'
import type { ShopAnswer, ShopQuestion } from '@/types/qa'

const props = defineProps<{ shopId: number }>()

const { state: appState } = useAppContext()
const { state: sessionState, openAuthDialog } = useUserSession()
const copy = computed(() => qaStringsForRegion(appState.region))

const questions = ref<ShopQuestion[]>([])
const errorMessage = ref('')
const askDraft = ref('')
const asking = ref(false)
const expanded = reactive<Record<number, boolean>>({})
const answers = reactive<Record<number, ShopAnswer[]>>({})
const answerDrafts = reactive<Record<number, string>>({})

const loggedIn = computed(() => !!sessionState.accessToken)

async function load() {
  errorMessage.value = ''
  try {
    questions.value = (await fetchQuestions(props.shopId)).list
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.loadFailed
  }
}

async function ask() {
  if (!loggedIn.value) {
    openAuthDialog({ mode: 'password', redirectTo: `/shops/${props.shopId}` })
    return
  }
  const content = askDraft.value.trim()
  if (!content || asking.value) return
  asking.value = true
  errorMessage.value = ''
  try {
    await askQuestion(props.shopId, content)
    askDraft.value = ''
    await load()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.askFailed
  } finally {
    asking.value = false
  }
}

async function toggleAnswers(question: ShopQuestion) {
  const open = !expanded[question.id]
  expanded[question.id] = open
  if (open && !answers[question.id]) {
    try {
      answers[question.id] = await fetchAnswers(props.shopId, question.id)
    } catch {
      answers[question.id] = []
    }
  }
}

async function submitAnswer(question: ShopQuestion) {
  if (!loggedIn.value) {
    openAuthDialog({ mode: 'password', redirectTo: `/shops/${props.shopId}` })
    return
  }
  const content = (answerDrafts[question.id] ?? '').trim()
  if (!content) return
  try {
    const answer = await answerQuestion(props.shopId, question.id, content)
    answers[question.id] = [...(answers[question.id] ?? []), answer]
    answerDrafts[question.id] = ''
    question.answerCount += 1
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : copy.value.answerFailed
  }
}

watch([() => props.shopId, () => appState.region], load, { immediate: true })
</script>

<template>
  <section class="qa-section">
    <h2>{{ copy.title }}</h2>

    <div class="qa-ask">
      <textarea v-model="askDraft" rows="2" :placeholder="copy.askPlaceholder" data-testid="qa-ask-input" />
      <button type="button" :disabled="asking" data-testid="qa-ask-submit" @click="ask">{{ copy.ask }}</button>
    </div>
    <p v-if="!loggedIn" class="qa-hint">{{ copy.loginToAsk }}</p>
    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>

    <p v-if="questions.length === 0" class="feedback">{{ copy.empty }}</p>
    <ul v-else class="qa-list">
      <li v-for="q in questions" :key="q.id" class="qa-item" :data-testid="`qa-item-${q.id}`">
        <p class="qa-item__q">{{ q.content }}</p>
        <p v-if="q.latestAnswer" class="qa-item__latest">{{ q.latestAnswer }}</p>
        <div class="qa-item__foot">
          <button type="button" class="link" :data-testid="`qa-toggle-${q.id}`" @click="toggleAnswers(q)">
            {{ expanded[q.id] ? copy.hideAnswers : copy.answerCount(q.answerCount) }}
          </button>
        </div>
        <div v-if="expanded[q.id]" class="qa-answers">
          <p v-if="(answers[q.id] ?? []).length === 0" class="feedback">{{ copy.noAnswers }}</p>
          <ul v-else>
            <li v-for="a in answers[q.id]" :key="a.id" class="qa-answer">
              <span class="qa-answer__who">{{ a.userNickname }}</span>
              <span class="qa-answer__text">{{ a.content }}</span>
            </li>
          </ul>
          <div class="qa-answer-box">
            <textarea v-model="answerDrafts[q.id]" rows="1" :placeholder="copy.answerPlaceholder" :data-testid="`qa-answer-input-${q.id}`" />
            <button type="button" :data-testid="`qa-answer-submit-${q.id}`" @click="submitAnswer(q)">{{ copy.answer }}</button>
          </div>
        </div>
      </li>
    </ul>
  </section>
</template>
