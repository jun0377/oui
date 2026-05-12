<template>
  <div class="server-section">
    <el-card class="mode-card mode-panel mode-panel-balance">
      <template #header>
        <div class="card-header">
          <div>
            <div class="mode-panel-title">负载均衡</div>
            <div class="mode-panel-subtitle">在多条链路之间按权重分摊业务流量,不需要服务器</div>
          </div>
        </div>
      </template>
      <div class="mode-panel-body">
        <div class="server-section aggregate-section balance-split">
          <div class="server-settings-card">
            <el-form label-width="120px" label-position="left" class="config-form">
              <div class="balance-section-title">权重分配</div>
              <div class="balance-section-subtitle">按权重分配流量</div>

              <div class="balance-links-list">
                <div v-for="(link, index) in links" :key="link.id" class="balance-link-card">
                  <div class="balance-link-card-header">
                    <div class="balance-link-summary">
                      <div class="balance-link-title">{{ link.name || `WAN${index}` }}</div>
                      <div class="balance-link-subtitle">{{ $t('接口') }}: {{ link.iface || '-' }}</div>
                    </div>
                    <el-form-item :label="$t('权重')" :label-width="36" class="balance-form-item balance-form-item-inline">
                      <el-input-number v-model="link.weight" :min="0" :max="10" :step="1" controls-position="right" />
                    </el-form-item>
                    <div class="balance-link-progress">
                      <div class="balance-link-progress-meta">
                        <span>{{ $t('占比') }}: {{ getLinkPreview(link.id).percent }}%</span>
                      </div>
                      <el-progress :percentage="getLinkPreview(link.id).percent" :stroke-width="8" />
                    </div>
                  </div>
                </div>
              </div>

              <el-form-item class="balance-actions" label-width="0">
                <el-button type="primary" @click="saveConfig">{{ $t('保存 & 应用') }}</el-button>
                <el-button @click="resetConfig">{{ $t('恢复默认') }}</el-button>
              </el-form-item>
            </el-form>
          </div>

          <div class="server-status-card">
            <div class="status-info">
              <div class="balance-preview">
                <div class="balance-section-title">分流预览</div>
                <div class="balance-section-subtitle">当前各接口上的实时连接数</div>

                <div class="balance-pie-stage">
                  <div class="balance-pie-wrap">
                    <div class="balance-pie-chart" :style="{ background: pieGradient }">
                      <div class="balance-pie-inner">
                        <div class="balance-pie-total">{{ totalConnections }}</div>
                        <div class="balance-pie-total-label">{{ $t('总连接数') }}</div>
                      </div>
                    </div>
                  </div>

                  <div
                    v-for="link in pieLabelLinks"
                    :key="link.id"
                    class="balance-pie-label"
                    :class="[
                      link.anchorClass,
                      { 'is-left': link.side === 'left', 'is-right': link.side === 'right' }
                    ]"
                    :style="{
                      left: `${link.labelX}px`,
                      top: `${link.labelY}px`
                    }"
                  >
                    <span
                      class="balance-pie-label-line"
                      :style="{
                        width: `${link.lineWidth}px`,
                        backgroundColor: link.color,
                        transform: `rotate(${link.lineAngle}deg)`,
                        transformOrigin: link.side === 'left' ? '100% 50%' : '0 50%'
                      }"
                    ></span>
                    <div class="balance-pie-label-text">
                      <div class="balance-pie-label-name">{{ link.name || '-' }}({{link.iface}})</div>
                      <div class="balance-pie-label-value">
                        连接数:{{ link.connections }}/占比:{{ link.sharePercent }}%
                      </div>
                    </div>
                  </div>
                </div>

                <div class="balance-pie-footer">

                  <div class="balance-pie-footer-legend">
                    <div v-for="link in pieLegendLinks" :key="link.id" class="balance-pie-footer-legend-item">
                      <span class="balance-pie-footer-dot" :style="{ backgroundColor: link.color }"></span>
                      <div class="balance-pie-footer-legend-text">
                        <div class="balance-pie-footer-legend-top">
                          <span class="balance-pie-footer-legend-name">{{ link.name || '-' }}({{ link.iface || '-' }})</span>
                        </div>
                        <div class="balance-pie-footer-legend-bottom">
                          <span class="balance-pie-footer-legend-value">{{ link.connections }}</span>
                          <span class="balance-pie-footer-legend-sep">·</span>
                          <span class="balance-pie-footer-legend-value">{{ link.sharePercent }}%</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
function normalizeChannelName(value) {
  return String(value || '').trim().toLowerCase()
}

function isSelectableChannel(value) {
  return /^(sim\d+|wan\d+)$/.test(value)
}

function getChannelSortKey(value) {
  const match = /^(sim|wan)(\d+)$/.exec(value)
  if (!match)
    return { group: 9, num: Number.MAX_SAFE_INTEGER, raw: value }
  const group = match[1] === 'sim' ? 0 : 1
  return { group, num: Number(match[2]), raw: value }
}

const cloneLinks = (links) => links.map(link => ({ ...link }))

export default {
  name: 'ModeBalance',
  props: {
    pageActive: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      links: [],
      savedLinks: [],
      nextId: 1,
      conntrackTotal: 0,
      conntrackByChannel: {},
      conntrackUpdatedAt: 0,
      conntrackTimer: null,
      stopped: true
    }
  },
  watch: {
    pageActive(value) {
      if (value)
        this.startAll()
      else
        this.stopAll()
    }
  },
  mounted() {
    this.startAll()
  },
  activated() {
    this.startAll()
  },
  deactivated() {
    this.stopAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  computed: {
    pieColors() {
      return ['#4f8df7', '#67c23a', '#e6a23c', '#f56c6c', '#909399', '#8b5cf6']
    },
    activeLinksCount() {
      return this.links.filter(link => link.enabled).length
    },
    totalWeight() {
      return this.links
        .filter(link => link.enabled)
        .reduce((sum, link) => sum + Number(link.weight || 0), 0)
    },
    previewLinks() {
      const previewLinks = this.links.map((link) => {
        const normalizedWeight = Math.max(0, Number(link.weight || 0))
        const percent = link.enabled && this.totalWeight > 0
          ? Math.round((normalizedWeight / this.totalWeight) * 100)
          : 0
        const connections = link.enabled
          ? Number(this.conntrackByChannel[link.name] || 0)
          : 0
        return {
          ...link,
          weight: normalizedWeight,
          percent,
          connections
        }
      })
      const maxConnections = Math.max(1, ...previewLinks.map(link => link.connections || 0))
      return previewLinks.map(link => ({
        ...link,
        connectionsPercent: link.enabled
          ? Math.round((link.connections / maxConnections) * 100)
          : 0
      }))
    },
    // 当前总连接数
    totalConnections() {
      return Number(this.conntrackTotal || 0)
    },
    pieLegendLinks() {
      return this.previewLinks.map((link, index) => ({
        ...link,
        color: this.pieColors[index % this.pieColors.length],
        sharePercent: this.totalConnections > 0
          ? Math.round((link.connections / this.totalConnections) * 100)
          : 0
      }))
    },
    pieLabelLinks() {
      const centerX = 170
      const centerY = 170
      const labelRadius = 120
      let current = 0
      return this.pieLegendLinks.map((link) => {
        const sweep = this.totalConnections > 0
          ? (link.connections / this.totalConnections) * 360
          : 0
        const midAngle = current + sweep / 2 - 90
        current += sweep
        const radians = (midAngle * Math.PI) / 180
        const anchorX = centerX + Math.cos(radians) * 94
        const anchorY = centerY + Math.sin(radians) * 94
        const labelX = centerX + Math.cos(radians) * labelRadius
        const labelY = centerY + Math.sin(radians) * labelRadius
        const side = Math.cos(radians) >= 0 ? 'right' : 'left'
        const deltaX = labelX - anchorX
        const deltaY = labelY - anchorY
        return {
          ...link,
          side,
          anchorClass: side === 'right' ? 'anchor-right' : 'anchor-left',
          labelX,
          labelY,
          lineWidth: Math.max(24, Math.round(Math.sqrt(deltaX ** 2 + deltaY ** 2))),
          lineAngle: Math.atan2(deltaY, deltaX) * 180 / Math.PI
        }
      })
    },
    pieGradient() {
      if (!this.totalConnections) {
        return 'conic-gradient(#e5e7eb 0 100%)'
      }
      let current = 0
      const stops = this.pieLegendLinks.map((link) => {
        const start = current
        const end = current + (link.connections / this.totalConnections) * 100
        current = end
        return `${link.color} ${start}% ${end}%`
      })
      return `conic-gradient(${stops.join(', ')})`
    }
  },
  methods: {
    formatTime(ts) {
      const date = ts ? new Date(ts) : null
      if (!date || Number.isNaN(date.getTime()))
        return '--'
      const hh = String(date.getHours()).padStart(2, '0')
      const mm = String(date.getMinutes()).padStart(2, '0')
      const ss = String(date.getSeconds()).padStart(2, '0')
      return `${hh}:${mm}:${ss}`
    },
    runAfterFirstFrame(fn) {
      if (typeof requestAnimationFrame === 'function') {
        requestAnimationFrame(() => requestAnimationFrame(() => fn()))
      } else {
        setTimeout(() => fn(), 0)
      }
    },
    startAll() {
      if (!this.stopped)
        return
      this.stopped = false
      this.runAfterFirstFrame(async() => {
        if (this.stopped)
          return
        await this.fetchAllChannels()
        if (this.stopped)
          return
        this.startConntrackPolling()
      })
    },
    stopAll() {
      this.stopped = true
      this.stopConntrackPolling()
    },
    startConntrackPolling() {
      this.stopConntrackPolling()
      this.refreshConntrackOnce()
      this.conntrackTimer = setInterval(() => {
        this.refreshConntrackOnce()
      }, 3000)
    },
    stopConntrackPolling() {
      if (this.conntrackTimer) {
        clearInterval(this.conntrackTimer)
        this.conntrackTimer = null
      }
    },
    async refreshConntrackOnce() {
      if (this.stopped)
        return

      try {
        const channels = this.links.map(link => link.name).filter(Boolean)
        const stats = await this.$oui.call('mode', 'getIfContrackCnt', { channels })
        if (this.stopped)
          return

        this.conntrackTotal = Number(stats && stats.total || 0)
        this.conntrackByChannel = (stats && stats.by_channel && typeof stats.by_channel === 'object')
          ? stats.by_channel
          : {}
        this.conntrackUpdatedAt = Date.now()

        console.log('连接数统计:', `total=${this.conntrackTotal}`, Object.entries(this.conntrackByChannel).map(([name, cnt]) => `${name}=${cnt}`).join(', '))
      } catch (_) {
      }
    },
    // 获取所有可用链路
    async fetchAllChannels() {
      if (this.stopped)
        return Promise.resolve()

      try {
        const [channels, savedWeights] = await Promise.all([
          this.$oui.call('mode', 'getAllChannel'),
          this.$oui.call('mode', 'getBalanceWeights')
        ])

        if (this.stopped)
          return

        const items = Array.isArray(channels) ? channels : []
        const normalized = items
          .map((item) => {
            if (typeof item === 'string') {
              return {
                name: normalizeChannelName(item),
                iface: ''
              }
            }
            return {
              name: normalizeChannelName(item && (item.name || item.value)),
              iface: String(item && item.iface || '')
            }
          })
          .filter(item => item.name)
          .filter(item => isSelectableChannel(item.name))

        const uniqMap = new Map()
        normalized.forEach((item) => {
          if (!uniqMap.has(item.name))
            uniqMap.set(item.name, item)
        })

        const uniq = Array.from(uniqMap.values())
        uniq.sort((a, b) => {
          const ka = getChannelSortKey(a.name)
          const kb = getChannelSortKey(b.name)
          if (ka.group !== kb.group)
            return ka.group - kb.group
          if (ka.num !== kb.num)
            return ka.num - kb.num
          return ka.raw.localeCompare(kb.raw)
        })

        this.links = uniq.map((item, index) => {
          const weight = (savedWeights && savedWeights[item.name]) !== undefined ? savedWeights[item.name] : 1
          return {
            id: index + 1,
            name: item.name,
            iface: item.iface || '--',
            weight: weight,
            enabled: true
          }
        })
        this.savedLinks = cloneLinks(this.links)
        this.nextId = this.links.length + 1

        console.log('获取链路权重:', this.links.map(l => `${l.name}: ${l.weight}`).join(', '))

      } catch (err) {
        console.error('Fetch channels or weights failed:', err)
      }
    },
    getLinkPreview(linkId) {
      return this.previewLinks.find(link => link.id === linkId) || { percent: 0 }
    },
    addLink() {
      this.links.push({
        id: this.nextId++,
        name: `wan${this.links.length}`,
        iface: '',
        weight: 0,
        enabled: true
      })
    },
    removeLink(index) {
      if (this.links.length <= 1)
        return
      this.links.splice(index, 1)
    },
    normalizeLinks() {
      this.links = this.links.map(link => ({
        ...link,
        name: String(link.name || '').trim(),
        iface: String(link.iface || '').trim(),
        weight: Math.max(0, Number(link.weight || 0)),
        enabled: Boolean(link.enabled)
      }))
    },
    // 保存配置
    saveConfig() {
      this.normalizeLinks()
      if (this.activeLinksCount === 0) {
        this.$message.warning(this.$t('请至少启用一条链路'))
        return
      }
      if (this.totalWeight <= 0) {
        this.$message.warning(this.$t('已启用链路的权重总和必须大于 0'))
        return
      }

      const weights = {}
      this.links.forEach(link => {
        if (link.enabled) {
          weights[link.name] = link.weight
        }
      })

      this.$oui.call('mode', 'setMode', { mode: 'balance' }).then(() => this.$oui.call('mode', 'setBalanceWeight', { weights })).then(() => {
        this.savedLinks = cloneLinks(this.links)
        this.$message({
          message: this.$t('保存成功'),
          type: 'success'
        })

        console.log('设置链路权重:', Object.entries(weights).map(([name, weight]) => `${name}: ${weight}`).join(', '))

      }).catch((err) => {
        this.$message.error(this.$t('保存失败: ') + err.message)
      })
    },
    // 恢复默认配置
    resetConfig() {
      this.links = cloneLinks(this.savedLinks)
      this.nextId = this.links.reduce((maxId, link) => Math.max(maxId, link.id), 0) + 1

      const weights = {}
      this.links.forEach(link => {
        if (link.enabled) {
          weights[link.name] = link.weight
        }
      })

      this.$oui.call('mode', 'setMode', { mode: 'balance' }).then(() => this.$oui.call('mode', 'setBalanceWeight', { weights })).then(() => {
        this.$message({
          message: this.$t('恢复成功'),
          type: 'success'
        })
        console.log('恢复链路权重:', Object.entries(weights).map(([name, weight]) => `${name}: ${weight}`).join(', '))
      }).catch((err) => {
        this.$message.error(this.$t('恢复失败: ') + err.message)
      })
    }
  }
}
</script>

<style scoped>
.server-section {
  width: 100%;
}

.mode-card {
  width: 100%;
}

.mode-panel {
  position: relative;
  border-radius: 16px;
  border: 1px solid var(--el-border-color);
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
  overflow: hidden;
}

.mode-panel::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.mode-panel-balance::before {
  background: #22c55e;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.mode-panel-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.mode-panel-subtitle {
  margin-top: 6px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
  line-height: 1.4;
}

.mode-panel-body {
  padding: 2px 0 0;
}

.server-settings-card,
.server-status-card {
  position: relative;
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 10px 26px rgba(15, 23, 42, 0.05);
  overflow: hidden;
  min-width: 0;
}

.server-settings-card::before,
.server-status-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: rgba(34, 197, 94, 0.35);
}

.config-form {
  width: 100%;
}

:deep(.mode-panel .el-card__header) {
  padding: 18px 18px 0;
  border-bottom: 0;
}

:deep(.mode-panel .el-card__body) {
  padding: 12px 18px 18px;
}

:deep(.config-form .el-form-item__label) {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-secondary);
}

:deep(.config-form .el-input__wrapper),
:deep(.config-form .el-input-number) {
  border-radius: 12px;
}

:deep(.balance-actions .el-form-item__content) {
  justify-content: center;
}

:deep(.balance-actions .el-button--primary) {
  border-radius: 12px;
  font-weight: 700;
  border: 1px solid rgba(22, 163, 74, 0.55);
  background: linear-gradient(180deg, #22c55e 0%, #16a34a 100%);
  box-shadow: 0 12px 24px rgba(34, 197, 94, 0.18);
}

:deep(.balance-actions .el-button--primary:hover) {
  box-shadow: 0 16px 28px rgba(34, 197, 94, 0.22);
}

:deep(.balance-actions .el-button) {
  border-radius: 12px;
  padding: 10px 18px;
  min-height: 40px;
  font-weight: 700;
}

.balance-split {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 18px;
  align-items: stretch;
}

.balance-split::after {
  display: none;
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: 50%;
  width: 1px;
  background: linear-gradient(
    180deg,
    rgba(148, 163, 184, 0) 0%,
    rgba(148, 163, 184, 0.45) 20%,
    rgba(148, 163, 184, 0.45) 80%,
    rgba(148, 163, 184, 0) 100%
  );
  border-radius: 999px;
  transform: translateX(-50%);
  pointer-events: none;
}

.balance-links-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin: 8px 0 18px;
}

.balance-section-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.balance-section-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.balance-links-list {
  display: grid;
  gap: 16px;
  margin-top: 16px;
}

.balance-link-card {
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

.balance-link-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 14px 30px rgba(15, 23, 42, 0.08);
}

.balance-link-card-header {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  gap: 80px;
}

.balance-link-summary {
  min-width: 0;
  flex: 0 0 140px;
}

.balance-link-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.balance-link-subtitle {
  margin-top: 4px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.balance-form-item {
  margin-bottom: 0;
}

.balance-form-item-inline {
  flex: 0 0 auto;
  margin-left: 0;
}

.balance-link-progress {
  flex: 1 1 auto;
  min-width: 180px;
}

.balance-link-progress-meta {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 6px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.balance-form-item-inline :deep(.el-form-item__label) {
  padding-right: 4px;
}

.balance-form-item-inline :deep(.el-input-number) {
  width: 96px;
}

.balance-actions {
  margin-top: 18px;
  margin-bottom: 0;
}

.balance-preview {
  margin-top: 0;
  padding-top: 0;
}

.balance-pie-stage {
  position: relative;
  width: 340px;
  height: 340px;
  margin-top: 16px;
  margin-left: auto;
  margin-right: auto;
}

.balance-pie-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
}

.balance-pie-chart {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 220px;
  height: 220px;
  border-radius: 50%;
}

.balance-pie-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 138px;
  height: 138px;
  border-radius: 50%;
  background: #fff;
  box-shadow: inset 0 0 0 1px var(--el-border-color-lighter);
}

.balance-pie-total {
  font-size: 28px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1;
}

.balance-pie-total-label {
  margin-top: 6px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.balance-pie-label {
  position: absolute;
  z-index: 2;
}

.balance-pie-label.anchor-right {
  transform: translate(0, -50%);
}

.balance-pie-label.anchor-left {
  transform: translate(-100%, -50%);
}

.balance-pie-label-line {
  position: absolute;
  top: 50%;
  height: 1px;
  opacity: 0.7;
}

.balance-pie-label.is-right .balance-pie-label-line {
  left: -26px;
}

.balance-pie-label.is-left .balance-pie-label-line {
  right: -26px;
}

.balance-pie-label-text {
  min-width: 72px;
}

.balance-pie-label-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.balance-pie-label-value {
  margin-top: 2px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.balance-pie-footer {
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px dashed rgba(148, 163, 184, 0.6);
}

.balance-pie-footer-meta {
  display: flex;
  flex-wrap: nowrap;
  justify-content: center;
  gap: 10px;
  overflow-x: auto;
}

.balance-pie-footer-chip {
  display: inline-flex;
  align-items: center;
  padding: 6px 10px;
  border-radius: 999px;
  background: rgba(148, 163, 184, 0.14);
  border: 1px solid rgba(148, 163, 184, 0.22);
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.balance-pie-footer-legend {
  margin-top: 14px;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  overflow-x: hidden;
}

.balance-pie-footer-legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.14);
  background: rgba(248, 250, 252, 0.6);
}

.balance-pie-footer-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  flex: 0 0 auto;
}

.balance-pie-footer-legend-name {
  font-size: 12px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.2;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 140px;
}

.balance-pie-footer-legend-text {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.balance-pie-footer-legend-top {
  display: flex;
  align-items: center;
  min-width: 0;
}

.balance-pie-footer-legend-bottom {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  line-height: 1.2;
  white-space: nowrap;
}

.balance-pie-footer-legend-value {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  line-height: 1.2;
  flex: 0 0 auto;
}

.balance-pie-footer-legend-sep {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  opacity: 0.7;
  flex: 0 0 auto;
}

@media (max-width: 768px) {
  .balance-split {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .balance-split::after {
    display: none;
  }

  .balance-pie-stage {
    width: 280px;
    height: 280px;
  }

  .balance-pie-footer-meta {
    justify-content: center;
  }

  .balance-links-header,
  .balance-link-card-header,
  .balance-pie-label-text {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (max-width: 720px) {
  :deep(.mode-panel .el-card__header) {
    padding: 16px 16px 0;
  }

  :deep(.mode-panel .el-card__body) {
    padding: 12px 16px 16px;
  }

  .server-settings-card,
  .server-status-card {
    padding: 16px;
  }
}
</style>
