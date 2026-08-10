<template>
  <div class="management-page">
    <el-card class="management-panel">
      <div class="management-panel-body">
        <el-tabs v-model="activeTab" type="border-card" class="management-tabs">

          <!-- Tab 1: 概览 -->
          <el-tab-pane :label="$t('概览')" name="overview">
            <div class="overview-grid">
              <div class="mgmt-metric-card is-accent-blue">
                <div class="mgmt-metric-head">
                  <div class="mgmt-metric-title">{{ $t('平台地址') }}</div>
                  <el-tag type="info">IP:Port</el-tag>
                </div>
                <div class="mgmt-metric-value">{{ overview.serverIP || '--' }}</div>
                <div class="mgmt-metric-subtitle">{{ $t('管理平台服务端地址') }}</div>
              </div>

              <div class="mgmt-metric-card is-accent-green">
                <div class="mgmt-metric-head">
                  <div class="mgmt-metric-title">{{ $t('连接状态') }}</div>
                  <el-tag :type="overview.connected ? 'success' : 'danger'">
                    {{ overview.connected ? $t('已连接') : $t('未连接') }}
                  </el-tag>
                </div>
                <div class="mgmt-metric-value">{{ overview.connected ? $t('在线') : $t('离线') }}</div>
                <div class="mgmt-metric-subtitle">{{ $t('延时') }}: {{ overview.latency ?? '--' }} ms</div>
              </div>

              <div class="mgmt-metric-card is-accent-amber">
                <div class="mgmt-metric-head">
                  <div class="mgmt-metric-title">{{ $t('允许上报') }}</div>
                  <el-tag :type="settings.reportEnabled ? 'success' : 'danger'">
                    {{ settings.reportEnabled ? $t('允许') : $t('禁止') }}
                  </el-tag>
                </div>
                <div class="mgmt-metric-value">{{ settings.reportEnabled ? $t('允许') : $t('禁止') }}</div>
                <div v-if="settings.reportEnabled" class="mgmt-metric-subtitle">
                  <span>{{ $t('上报状态:') }}</span>
                  <span class="report-state report-state-active">{{ $t(overview.reportState) }}</span>
                </div>
                <div v-else class="mgmt-metric-subtitle">{{ $t('数据上报已关闭') }}</div>
              </div>
            </div>

            <div class="announce-card">
              <div class="mgmt-metric-head">
                <div class="mgmt-metric-title">{{ $t('服务器公告') }}</div>
                <el-tag type="info">{{ announcements.length }}</el-tag>
              </div>
              <ul v-if="announcements.length" class="announce-list">
                <li v-for="item in announcements" :key="item.id" class="announce-item">
                  <span class="announce-date">{{ item.time }}</span>
                  <span class="announce-text">{{ item.content }}</span>
                </li>
              </ul>
              <div v-else class="announce-empty">{{ $t('暂无公告') }}</div>
            </div>
          </el-tab-pane>

          <!-- Tab 2: 设置 -->
          <el-tab-pane :label="$t('设置')" name="settings">
            <div class="settings-content">
              <el-form class="mgmt-settings-form" label-width="120px" label-position="top">
                <div class="mgmt-form-row">
                  <el-form-item :label="$t('管理平台IP')" class="mgmt-form-row-ip">
                    <el-input
                      v-model="settings.serverIP"
                      :placeholder="$t('请输入管理平台IP地址')"
                    />
                  </el-form-item>

                  <el-form-item :label="$t('端口')" class="mgmt-form-row-port">
                    <el-input-number
                      v-model="settings.serverPort"
                      :min="1"
                      :max="65535"
                      :placeholder="$t('请输入端口号')"
                      :controls="false"
                      class="mgmt-full-width"
                    />
                  </el-form-item>
                </div>

                <el-form-item :label="$t('数据上报时间间隔(秒)')" class="mgmt-form-inline">
                  <div class="mgmt-form-inline-body">
                    <el-select
                      v-model="settings.interval"
                      :placeholder="$t('单位: 秒')"
                      :disabled="!settings.reportEnabled"
                      class="mgmt-full-width"
                    >
                      <el-option
                        v-for="opt in intervalOptions"
                        :key="opt"
                        :label="opt + ' ' + $t('秒')"
                        :value="opt"
                      />
                    </el-select>
                    <el-tooltip
                      :content="settings.reportEnabled ? $t('当前允许数据上报') : $t('当前禁止数据上报')"
                      placement="top"
                    >
                      <el-button
                        :type="settings.reportEnabled ? 'primary' : 'danger'"
                        plain
                        class="mgmt-report-toggle"
                        @click="settings.reportEnabled = !settings.reportEnabled"
                      >
                        {{ settings.reportEnabled ? $t('禁止数据上报') : $t('允许数据上报') }}
                      </el-button>
                    </el-tooltip>
                  </div>
                </el-form-item>
              </el-form>
            </div>

            <div class="mgmt-settings-actions">
              <el-button type="primary" class="mgmt-action-button">{{ $t('保存 & 应用') }}</el-button>
              <el-button class="mgmt-action-button">{{ $t('恢复默认') }}</el-button>
            </div>
          </el-tab-pane>

          <!-- Tab 3: 详细日志 -->
          <el-tab-pane :label="$t('详细日志')" name="logs">
            <div class="logs-card">
              <div class="mgmt-metric-head">
                <div class="mgmt-metric-title">{{ $t('详细日志') }}</div>
                <el-tag type="info">{{ logs.length }}</el-tag>
              </div>
              <ul v-if="logs.length" class="log-list">
                <li v-for="item in logs" :key="item.id" class="log-item">
                  <el-tag :type="getLogTagType(item.level)" size="small" class="log-level">{{ item.level }}</el-tag>
                  <span class="log-time">{{ item.time }}</span>
                  <span class="log-message">{{ item.message }}</span>
                </li>
              </ul>
              <div v-else class="announce-empty">{{ $t('暂无日志') }}</div>
            </div>
          </el-tab-pane>

        </el-tabs>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'Management',
  data() {
    return {
      activeTab: 'overview',
      // 模拟数据: 用于调试, 接入后台逻辑后移除
      overview: {
        serverIP: '192.168.1.100:8080',
        connected: true,
        latency: 23,
        reportState: '上报中'
      },
      settings: {
        serverIP: '192.168.1.100',
        serverPort: 8080,
        interval: 5,
        reportEnabled: true
      },
      intervalOptions: [1, 5, 10, 15, 30, 60],
      // 模拟公告: 用于调试, 接入后台逻辑后移除
      announcements: [
        { id: 1, time: '2026-08-09 09:00', content: '系统将于 2026-08-12 02:00 进行例行维护，届时数据上报可能短暂中断。' },
        { id: 2, time: '2026-08-01 15:30', content: '管理平台升级至 v2.4.0，新增设备分组管理功能。' }
      ],
      // 模拟日志: 用于调试, 接入后台逻辑后移除
      logs: [
        { id: 1, time: '2026-08-10 10:32:15', level: 'info', message: '数据上报成功' },
        { id: 2, time: '2026-08-10 10:31:20', level: 'warn', message: '连接延时偏高 (85ms)' },
        { id: 3, time: '2026-08-10 10:30:05', level: 'error', message: '数据上报失败, 重试中' }
      ]
    }
  },
  methods: {
    getLogTagType(level) {
      switch (String(level).toLowerCase()) {
      case 'info': return 'info'
      case 'warn':
      case 'warning': return 'warning'
      case 'error':
      case 'fatal': return 'danger'
      default: return 'info'
      }
    }
  }
}
</script>

<style>
.management-page {
  width: 100%;
}

.management-panel {
  width: 100%;
  border-radius: 12px;
  border: 0;
  box-shadow: none;
}

.management-panel-body {
  padding: 6px 4px;
}

.management-tabs {
  border-radius: 12px;
  overflow: hidden;
}

.management-tabs :deep(.el-tabs__header) {
  background-color: var(--el-fill-color-light);
}

.management-tabs :deep(.el-tabs__item) {
  font-weight: 600;
  font-size: 14px;
}

/* ---- 概览: 指标卡片网格 ---- */
.overview-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  align-content: stretch;
}

.mgmt-metric-card {
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  padding: 18px;
  min-height: 160px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.mgmt-metric-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.mgmt-metric-card.is-accent-blue::before { background: #3b82f6; }
.mgmt-metric-card.is-accent-green::before { background: #22c55e; }
.mgmt-metric-card.is-accent-cyan::before { background: #06b6d4; }
.mgmt-metric-card.is-accent-amber::before { background: #f59e0b; }
.mgmt-metric-card.is-accent-violet::before { background: #8b5cf6; }

.mgmt-metric-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.mgmt-metric-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.mgmt-metric-value {
  margin: 14px 0 6px;
  font-size: 28px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.1;
  word-break: break-word;
}

.mgmt-metric-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.report-state {
  margin-left: 4px;
  font-weight: 600;
}

.report-state-active {
  color: var(--el-color-success);
}

/* ---- 服务器公告 ---- */
.announce-card {
  display: flex;
  flex-direction: column;
  padding: 18px;
  margin-top: 16px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.announce-list {
  list-style: none;
  margin: 12px 0 0;
  padding: 0;
}

.announce-item {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 10px 0;
  font-size: 13px;
  color: var(--el-text-color-primary);
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.announce-item:last-child {
  border-bottom: 0;
}

.announce-date {
  flex-shrink: 0;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.announce-text {
  line-height: 1.5;
  word-break: break-word;
}

.announce-empty {
  margin-top: 12px;
  padding: 16px 0;
  text-align: center;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

/* ---- 详细日志 ---- */
.logs-card {
  display: flex;
  flex-direction: column;
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.log-list {
  list-style: none;
  margin: 12px 0 0;
  padding: 0;
  max-height: 420px;
  overflow-y: auto;
}

.log-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  font-size: 13px;
  color: var(--el-text-color-primary);
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.log-item:last-child {
  border-bottom: 0;
}

.log-level {
  flex-shrink: 0;
  width: 52px;
  justify-content: center;
  text-transform: uppercase;
}

.log-time {
  flex-shrink: 0;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.log-message {
  flex: 1;
  line-height: 1.5;
  word-break: break-word;
}

/* ---- 设置表单 ---- */
.settings-content {
  display: flex;
  flex-direction: column;
  max-width: 560px;
}

.mgmt-settings-form {
  display: grid;
  gap: 6px 16px;
  margin-top: 18px;
}

.mgmt-form-row {
  display: grid;
  grid-template-columns: 1fr 200px;
  gap: 16px;
}

.mgmt-settings-form :deep(.el-form-item) {
  margin-bottom: 14px;
}

.mgmt-settings-form :deep(.el-form-item__label) {
  padding-bottom: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.4;
}

/* 同行显示的 form-item: label 与输入框水平排列 */
.mgmt-form-inline {
  align-items: center;
}

.mgmt-form-inline :deep(.el-form-item__label) {
  width: 120px;
  padding-bottom: 0;
  justify-content: flex-end;
}

.mgmt-form-inline-body {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 12px;
}

.mgmt-form-inline-body .el-input-number,
.mgmt-form-inline-body .el-select {
  max-width: 200px;
  flex: 1;
}

.mgmt-form-inline-body .mgmt-form-hint {
  margin-top: 0;
  white-space: nowrap;
}

.mgmt-report-toggle {
  flex-shrink: 0;
  border-radius: 12px;
}

.mgmt-settings-form :deep(.el-input__wrapper) {
  border-radius: 12px;
  background: #f8fafc;
}

.mgmt-settings-form :deep(.el-input-number) {
  width: 100%;
}

.mgmt-full-width {
  width: 100%;
}

.mgmt-form-hint {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.mgmt-settings-actions {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 8px;
  padding-top: 16px;
  border-top: 1px solid rgba(148, 163, 184, 0.16);
}

.mgmt-action-button {
  min-width: 120px;
  border-radius: 12px;
}

/* ---- 响应式 ---- */
@media (max-width: 1024px) {
  .overview-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .overview-grid {
    grid-template-columns: 1fr;
  }

  .mgmt-metric-card {
    min-height: auto;
  }

  .mgmt-form-row {
    grid-template-columns: 1fr;
  }

  .mgmt-settings-actions {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>

<i18n src="./locale.json"/>
