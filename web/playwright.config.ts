import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { defineConfig, devices } from '@playwright/test'

const webPort = Number(process.env.PLAYWRIGHT_WEB_PORT ?? 15173)
const adminPort = Number(process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174)
const merchantPort = Number(process.env.PLAYWRIGHT_MERCHANT_PORT ?? 15175)
const backendPort = Number(process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080)
const realBackend = process.env.PLAYWRIGHT_REAL_BACKEND === '1'
const externalServers = process.env.PLAYWRIGHT_EXTERNAL_SERVERS === '1'
const remoteAcceptance = process.env.PLAYWRIGHT_REMOTE_ACCEPTANCE === '1'
const outputDir = process.env.PLAYWRIGHT_OUTPUT_DIR ?? 'test-results'
const browserExecutablePath = process.env.PLAYWRIGHT_EXECUTABLE_PATH
const browserChannel = process.env.PLAYWRIGHT_CHANNEL ?? 'chrome'
const webDir = fileURLToPath(new URL('.', import.meta.url))
const repoRoot = path.resolve(webDir, '..')
const backendDir = path.join(repoRoot, 'backend')
const normalizeBaseURL = (value: string | undefined, fallback: string) => (value?.trim() || fallback).replace(/\/+$/, '')
const webBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_WEB_BASE_URL, `http://127.0.0.1:${webPort}`)
const adminBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_ADMIN_BASE_URL, `http://127.0.0.1:${adminPort}`)
const merchantBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_MERCHANT_BASE_URL, `http://127.0.0.1:${merchantPort}`)
const backendBaseURL = normalizeBaseURL(process.env.PLAYWRIGHT_BACKEND_BASE_URL, `http://127.0.0.1:${backendPort}`)
const backendCommand = `${process.platform === 'win32' ? 'mvnw.cmd' : './mvnw'} -q -DskipTests spring-boot:run "-Dspring-boot.run.profiles=h2,local" "-Dspring-boot.run.arguments=--server.port=${backendPort} --management.health.redis.enabled=false"`
const viteCliPath = './node_modules/vite/bin/vite.js'
const realBackendEnv = {
  ...process.env,
  VITE_PROXY_TARGET: backendBaseURL,
}

export default defineConfig({
  testDir: './e2e',
  outputDir,
  timeout: remoteAcceptance ? 60_000 : 30_000,
  expect: {
    timeout: remoteAcceptance ? 15_000 : 10_000,
  },
  fullyParallel: false,
  retries: remoteAcceptance ? 0 : (process.env.CI ? 1 : 0),
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: webBaseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    ...devices['Desktop Chrome'],
    ...(browserExecutablePath
      ? { launchOptions: { executablePath: browserExecutablePath } }
      : { channel: browserChannel }),
  },
  projects: [
    {
      name: 'chromium',
    },
  ],
  webServer: externalServers ? [] : [
    ...(realBackend
      ? [
          {
            command: backendCommand,
            cwd: backendDir,
            url: `${backendBaseURL}/actuator/health`,
            reuseExistingServer: false,
            timeout: 120_000,
          },
        ]
      : []),
    {
      command: `node ${viteCliPath} --host 127.0.0.1 --port ${webPort} --strictPort`,
      cwd: webDir,
      url: `http://127.0.0.1:${webPort}/`,
      reuseExistingServer: false,
      timeout: 60_000,
      ...(realBackend ? { env: realBackendEnv } : {}),
    },
    {
      command: `node ${viteCliPath} --host 127.0.0.1 --port ${adminPort} --strictPort`,
      cwd: path.join(repoRoot, 'admin-web'),
      url: `${adminBaseURL}/login`,
      reuseExistingServer: false,
      timeout: 60_000,
      ...(realBackend ? { env: realBackendEnv } : {}),
    },
    ...(realBackend ? [{
      command: `node ${viteCliPath} --host 127.0.0.1 --port ${merchantPort} --strictPort`,
      cwd: path.join(repoRoot, 'merchant-web'),
      url: `${merchantBaseURL}/login`,
      reuseExistingServer: false,
      timeout: 60_000,
      env: realBackendEnv,
    }] : []),
  ],
})
