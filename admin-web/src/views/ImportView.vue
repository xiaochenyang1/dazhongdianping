<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useAdminSession } from '@/composables/useAdminSession'
import { importShops, listImportBatches } from '@/services/admin'
import type {
  AdminImportBatch,
  AdminImportRecord,
  AdminImportResult,
  PageResult,
  Region,
} from '@/types/admin'

interface BatchFilters {
  status: string
  page: number
  pageSize: number
}

const { state } = useAdminSession()

const importing = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const lastResult = ref<AdminImportResult | null>(null)
const batchesPage = ref<PageResult<AdminImportBatch> | null>(null)

const form = reactive({
  fileName: defaultFileName(state.region),
  recordsText: buildExampleText(state.region),
})

const batchFilters = reactive<BatchFilters>({
  status: '',
  page: 1,
  pageSize: 10,
})

function defaultFileName(region: Region) {
  return `seed-${region.toLowerCase()}-shops.json`
}

function buildExampleRecord(region: Region): AdminImportRecord {
  if (region === 'EU') {
    return {
      merchantAccount: 'seed-eu-import-001@example.com',
      companyName: 'Paris Seed Import SARL',
      contactName: 'Lina',
      contactPhone: '+33111112222',
      shopName: '巴黎导入测试川菜馆',
      categoryId: 201,
      cityId: 101,
      areaId: 1011,
      address: '18 Rue du Temple, Paris',
      latitude: 48.85837,
      longitude: 2.35717,
      phone: '+33155556666',
      businessHours: '11:30-22:00',
      pricePerCapita: 34,
      coverUrl: 'https://placehold.co/1200x720/1d4ed8/f8fafc?text=EU+Import',
      summary: '给欧洲区演示导入链路用的样例门店。',
      score: 4.4,
      tasteScore: 4.5,
      envScore: 4.2,
      serviceScore: 4.3,
      currency: 'EUR',
      hasDeal: true,
      openNow: true,
      tags: ['Chinese', 'Import', 'Paris'],
    }
  }

  return {
    merchantAccount: 'seed-cn-import-001@example.com',
    companyName: '上海导入测试餐饮',
    contactName: '王磊',
    contactPhone: '13811112222',
    shopName: '上海导入测试火锅店',
    categoryId: 102,
    cityId: 1,
    areaId: 11,
    address: '上海市徐汇区测试导入路18号',
    latitude: 31.18826,
    longitude: 121.43687,
    phone: '021-61234567',
    businessHours: '10:00-22:00',
    pricePerCapita: 126,
    coverUrl: 'https://placehold.co/1200x720/f97316/f8fafc?text=CN+Import',
    summary: '给国内区演示导入链路用的样例门店。',
    score: 4.5,
    tasteScore: 4.6,
    envScore: 4.3,
    serviceScore: 4.4,
    currency: 'CNY',
    hasDeal: true,
    openNow: true,
    tags: ['导入', '火锅', '聚餐'],
  }
}

function buildExampleText(region: Region) {
  return JSON.stringify([buildExampleRecord(region)], null, 2)
}

function resetExample() {
  form.fileName = defaultFileName(state.region)
  form.recordsText = buildExampleText(state.region)
  lastResult.value = null
}

async function loadBatches() {
  loading.value = true
  errorMessage.value = ''

  try {
    batchesPage.value = await listImportBatches({
      region: state.region,
      status: batchFilters.status ? Number(batchFilters.status) : undefined,
      page: batchFilters.page,
      pageSize: batchFilters.pageSize,
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '导入批次加载失败'
  } finally {
    loading.value = false
  }
}

async function submitImport() {
  importing.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const parsed = JSON.parse(form.recordsText) as AdminImportRecord[]
    if (!Array.isArray(parsed) || parsed.length === 0) {
      throw new Error('导入记录必须是非空 JSON 数组。')
    }

    const result = await importShops({
      fileName: form.fileName.trim() || defaultFileName(state.region),
      region: state.region,
      records: parsed,
    })

    lastResult.value = result
    successMessage.value = `导入完成：成功 ${result.success}，失败 ${result.failed}。`
    batchFilters.page = 1
    await loadBatches()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '导入失败'
  } finally {
    importing.value = false
  }
}

function applyBatchFilter() {
  batchFilters.page = 1
  void loadBatches()
}

function goPrevPage() {
  if (!batchesPage.value || batchesPage.value.page <= 1) {
    return
  }

  batchFilters.page -= 1
  void loadBatches()
}

function goNextPage() {
  if (!batchesPage.value?.hasMore) {
    return
  }

  batchFilters.page += 1
  void loadBatches()
}

watch(
  () => state.region,
  () => {
    errorMessage.value = ''
    successMessage.value = ''
    batchFilters.status = ''
    batchFilters.page = 1
    resetExample()
    void loadBatches()
  },
  { immediate: true },
)
</script>

<template>
  <section class="page-section">
    <div class="page-header">
      <div>
        <p class="eyebrow">种子导入</p>
        <h1>先让运营有办法造数，不然前台页面再漂亮也是空壳子。</h1>
        <p>这版用 JSON 文本直连导入接口，目的很实在：先把批次、失败明细、回灌动作跑通。</p>
      </div>

      <div class="header-actions">
        <button type="button" class="secondary-button" @click="resetExample">恢复示例</button>
        <button type="button" class="primary-button" :disabled="importing" @click="submitImport">
          {{ importing ? '导入中...' : '开始导入' }}
        </button>
      </div>
    </div>

    <p v-if="errorMessage" class="feedback is-error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="feedback is-success">{{ successMessage }}</p>

    <div class="two-column-layout">
      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">导入请求</p>
            <h2>当前区域 {{ state.region }} 的导入 payload，别靠脑补拼字段。</h2>
          </div>
          <span class="inline-note">把 `categoryId` 改成不存在的值，就能演示失败明细。</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>文件名</span>
            <input v-model="form.fileName" type="text" placeholder="seed-cn-shops.json" />
          </label>

          <label class="field">
            <span>区域</span>
            <input :value="state.region" type="text" readonly />
          </label>
        </div>

        <label class="field field--full">
          <span>记录 JSON</span>
          <textarea
            v-model="form.recordsText"
            rows="18"
            spellcheck="false"
            placeholder="请填写 JSON 数组"
          />
        </label>

        <div class="hint-card">
          <strong>当前区域有效示例 ID</strong>
          <p v-if="state.region === 'CN'">分类 `102`，城市 `1`，商圈 `11`。</p>
          <p v-else>分类 `201`，城市 `101`，商圈 `1011`。</p>
        </div>

        <section v-if="lastResult" class="result-panel">
          <div class="section-headline">
            <div>
              <p class="eyebrow">最近一次结果</p>
              <h2>导入结果别藏着掖着，成功失败都摆出来。</h2>
            </div>
          </div>

          <div class="stat-grid stat-grid--compact">
            <article class="stat-card">
              <p>总记录</p>
              <strong>{{ lastResult.total }}</strong>
              <span>批次 #{{ lastResult.batchId }}</span>
            </article>
            <article class="stat-card">
              <p>成功</p>
              <strong>{{ lastResult.success }}</strong>
              <span>{{ lastResult.statusText }}</span>
            </article>
            <article class="stat-card">
              <p>失败</p>
              <strong>{{ lastResult.failed }}</strong>
              <span>{{ lastResult.errorFile || '无错误文件' }}</span>
            </article>
          </div>

          <ul v-if="lastResult.errorMessages.length > 0" class="error-list">
            <li v-for="message in lastResult.errorMessages" :key="message">{{ message }}</li>
          </ul>
        </section>
      </section>

      <section class="content-card">
        <div class="section-headline">
          <div>
            <p class="eyebrow">导入批次</p>
            <h2>批次记录得能翻，运营回头查错不至于抓瞎。</h2>
          </div>
          <span class="inline-note">当前区域共 {{ batchesPage?.total ?? 0 }} 个批次</span>
        </div>

        <div class="toolbar-grid toolbar-grid--filters">
          <label class="field">
            <span>状态</span>
            <select v-model="batchFilters.status">
              <option value="">全部状态</option>
              <option value="0">处理中</option>
              <option value="1">完成</option>
              <option value="2">失败</option>
            </select>
          </label>

          <div class="toolbar-actions">
            <button type="button" class="primary-button" @click="applyBatchFilter">应用筛选</button>
            <button type="button" class="ghost-button" @click="loadBatches">刷新</button>
          </div>
        </div>

        <div class="table-shell">
          <table class="data-table">
            <thead>
              <tr>
                <th>批次</th>
                <th>文件名</th>
                <th>结果</th>
                <th>状态</th>
                <th>错误文件</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="loading">
                <td colspan="5" class="table-empty">导入批次加载中...</td>
              </tr>
              <tr v-else-if="!batchesPage || batchesPage.list.length === 0">
                <td colspan="5" class="table-empty">还没有批次记录，先导一包再说。</td>
              </tr>
              <tr v-for="batch in batchesPage?.list" :key="batch.id">
                <td>#{{ batch.id }}<p>{{ batch.createdAt }}</p></td>
                <td>{{ batch.fileName }}</td>
                <td>成功 {{ batch.success }} / 失败 {{ batch.failed }}</td>
                <td>
                  <span
                    class="status-pill"
                    :class="batch.failed === 0 ? 'status-pill--good' : batch.success > 0 ? 'status-pill--warn' : 'status-pill--muted'"
                  >
                    {{ batch.statusText }}
                  </span>
                </td>
                <td>
                  <code class="code-box">{{ batch.errorFile || '--' }}</code>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pager">
          <button type="button" class="ghost-button" :disabled="(batchesPage?.page ?? 1) <= 1" @click="goPrevPage">
            上一页
          </button>
          <span>第 {{ batchesPage?.page ?? 1 }} 页</span>
          <button type="button" class="ghost-button" :disabled="!batchesPage?.hasMore" @click="goNextPage">
            下一页
          </button>
        </div>
      </section>
    </div>
  </section>
</template>
