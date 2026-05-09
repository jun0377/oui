<template>
  <div class="server-section">
    <el-card class="mode-card mode-panel">
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
                      <el-input-number v-model="link.weight" :min="0" :max="100" :step="1" controls-position="right" />
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

              <el-form-item class="balance-actions">
                <el-button type="primary" @click="saveConfig">{{ $t('保存 & 应用') }}</el-button>
                <el-button @click="resetConfig">{{ $t('重置') }}</el-button>
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
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
const createDefaultLinks = () => ([
  { id: 1, name: 'wan0', iface: 'eth1', weight: 50, enabled: true },
  { id: 2, name: 'wan1', iface: 'eth2', weight: 50, enabled: true }
])

const cloneLinks = (links) => links.map(link => ({ ...link }))

export default {
  name: 'ModeBalance',
  data() {
    const links = createDefaultLinks()
    return {
      links,
      savedLinks: cloneLinks(links),
      nextId: links.length + 1,
      demoPulse: 0,
      demoTimer: null
    }
  },
  mounted() {
    this.startDemoTicker()
  },
  beforeUnmount() {
    this.stopDemoTicker()
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
        const baseConnections = link.enabled ? Math.max(1, Math.round(percent * 1.2)) : 0
        const jitter = link.enabled ? ((this.demoPulse + link.id * 3) % 5) : 0
        const connections = baseConnections + jitter
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
    totalConnections() {
      return this.previewLinks.reduce((sum, link) => sum + Number(link.connections || 0), 0)
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
    getLinkPreview(linkId) {
      return this.previewLinks.find(link => link.id === linkId) || { percent: 0 }
    },
    startDemoTicker() {
      this.stopDemoTicker()
      this.demoTimer = setInterval(() => {
        this.demoPulse = (this.demoPulse + 1) % 10000
      }, 2000)
    },
    stopDemoTicker() {
      if (this.demoTimer) {
        clearInterval(this.demoTimer)
        this.demoTimer = null
      }
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
      this.savedLinks = cloneLinks(this.links)
      this.$message({
        message: this.$t('已保存当前权重配置(UI示意, 未接入后台)'),
        type: 'success'
      })
    },
    resetConfig() {
      this.links = cloneLinks(this.savedLinks)
      this.nextId = this.links.reduce((maxId, link) => Math.max(maxId, link.id), 0) + 1
    }
  }
}
</script>

<style scoped>
.balance-split {
  position: relative;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  align-items: start;
}

.balance-split::after {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: 50%;
  width: 1px;
  background: var(--el-border-color-lighter);
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

@media (max-width: 768px) {
  .balance-split {
    grid-template-columns: 1fr;
  }

  .balance-split::after {
    display: none;
  }

  .balance-pie-stage {
    width: 280px;
    height: 280px;
  }

  .balance-links-header,
  .balance-link-card-header,
  .balance-pie-label-text {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
