import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { defineConfig, devices } from '@playwright/test'

const webPort = Number(process.env.PLAYWRIGHT_WEB_PORT ?? 15173)
const adminPort = Number(process.env.PLAYWRIGHT_ADMIN_PORT ?? 15174)
const backendPort = Number(process.env.PLAYWRIGHT_BACKEND_PORT ?? 18080)
const realBackend = process.env.PLAYWRIGHT_REAL_BACKEND === '1'
const externalServers = process.env.PLAYWRIGHT_EXTERNAL_SERVERS === '1'
const outputDir = process.env.PLAYWRIGHT_OUTPUT_DIR ?? 'test-results'
const browserExecutablePath = process.env.PLAYWRIGHT_EXECUTABLE_PATH
const browserChannel = process.env.PLAYWRIGHT_CHANNEL ?? 'chrome'
const webDir = fileURLToPath(new URL('.', import.meta.url))
const repoRoot = path.resolve(webDir, '..')
const backendDir = path.join(repoRoot, 'backend')
const backendBaseURL = `http://127.0.0.1:${backendPort}`
const backendCommand = `${process.platform === 'win32' ? 'mvnw.cmd' : './mvnw'} -q -DskipTests spring-boot:run "-Dspring-boot.run.profiles=h2" "-Dspring-boot.run.arguments=--server.port=${backendPort} --management.health.redis.enabled=false"`
const viteCliPath = './node_modules/vite/bin/vite.js'
const realBackendEnv = {
  ...process.env,
  VITE_PROXY_TARGET: backendBaseURL,
}

export default defineConfig({
  testDir: './e2e',
  outputDir,
  timeout: 30_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: `http://127.0.0.1:${webPort}`,
    trace: 'on-first-retry',
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
      url: `http://127.0.0.1:${adminPort}/login`,
      reuseExistingServer: false,
      timeout: 60_000,
      ...(realBackend ? { env: realBackendEnv } : {}),
    },
  ],
})
