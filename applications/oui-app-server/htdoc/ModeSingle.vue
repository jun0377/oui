<template>
  <div class="server-section">
    <el-card class="mode-card mode-panel mode-panel-single">
      <template #header>
        <div class="card-header">
          <div>
            <div class="mode-panel-title">单卡模式</div>
            <div class="mode-panel-subtitle">强制选择一条链路作为当前业务出口,即使该链路异常也不会自动切换</div>
          </div>
        </div>
      </template>
      <div class="mode-panel-body">
        <div class="mode-inline">
          <span class="mode-inline-label">链路选择</span>
          <el-radio-group v-model="singleModeLink" class="mode-group" @change="handleSingleModeLinkChange">
            <el-radio-button v-for="item in linkOptions" :key="item.value" :value="item.value">
              <div class="mode-option-text">
                <div class="mode-option-label">{{ item.label }}</div>
                <div class="mode-option-iface">{{ item.iface || '--' }}</div>
              </div>
            </el-radio-button>
          </el-radio-group>
        </div>
        <div class="mode-inline mode-actions-row">
          <span class="mode-inline-label"></span>
          <div class="mode-actions">
            <el-button type="primary" @click="confirmSaveSingleMode">保存 &amp; 应用</el-button>
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
// 只获取sim* / wan* 命名的链路
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

const realtimeLinkDefs = []

export default {
  name: 'ModeSingle',
  props: {
    pageActive: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      linkOptions: [],
      singleModeLink: '',
      realtimeLinks: [],
      stopped: true,
      pollTimer: null,
      pollIntervalMs: 5000
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
    if (this.pageActive)
      this.startAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  methods: {
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
        await Promise.allSettled([this.fetchAllChannels(), this.fetchSingleModeLink()])
        if (this.stopped)
          return
        this.ensureSelectedChannel()
        await this.refreshOnce()
        this.startPolling()
      })
    },
    stopAll() {
      this.stopped = true
      this.stopPolling()
    },
    normalizeSingleModeLinkKey(value) {
      const raw = normalizeChannelName(value)
      if (!raw)
        return ''
      const compact = raw.replace(/[\s_-]/g, '')
      return isSelectableChannel(compact) ? compact : ''
    },
    fetchSingleModeLink() {
      if (this.stopped)
        return Promise.resolve()
      return this.$oui.call('mode', 'getSingleChannel').then((channel) => {
        if (this.stopped)
          return
        const normalized = this.normalizeSingleModeLinkKey(channel)
        if (!normalized)
          return
        if (this.singleModeLink === normalized)
          return
        this.singleModeLink = normalized
      }).catch(() => {})
    },
    // 获取所有可用链路
    fetchAllChannels() {
      if (this.stopped)
        return Promise.resolve()
      return this.$oui.call('mode', 'getAllChannel').then((channels) => {
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
        this.linkOptions = uniq.map(item => ({
          value: item.name,
          label: item.name.toUpperCase(),
          iface: item.iface || '--'
        }))
      }).catch(() => {})
    },
    ensureSelectedChannel() {
      if (this.stopped)
        return
      const values = this.linkOptions.map(item => item.value)
      if (!values.length)
        return
      if (!this.singleModeLink || !values.includes(this.singleModeLink))
        this.singleModeLink = values[0]
    },
    startPolling() {
      if (this.stopped)
        return
      this.stopPolling()
      this.pollTimer = setTimeout(async() => {
        await this.refreshOnce()
        this.startPolling()
      }, this.pollIntervalMs)
    },
    stopPolling() {
      if (this.pollTimer) {
        clearTimeout(this.pollTimer)
        this.pollTimer = null
      }
    },
    async refreshOnce() {
      if (this.stopped)
        return
    },
    handleSingleModeLinkChange() {
      return
    },
    normalizeSingleChannel(value) {
      const raw = String(value || '').trim().toLowerCase()
      if (!raw)
        return 'sim1'
      return raw
    },
    // 保存到uci配置文件
    saveSingleMode() {
      this.$oui.call('mode', 'setMode', { mode: 'single' })
      this.$oui.call('mode', 'setSingleChannel', { channel: this.normalizeSingleChannel(this.singleModeLink) })
      console.log('工作模式: 单卡模式 单卡链路:', this.singleModeLink)
      this.$message({
        message: this.$t('保存成功'),
        type: 'success'
      })
    },
    // 单卡模式二次确认
    confirmSaveSingleMode() {
      const message = `确认保存并应用当前出口链路：${this.singleModeLink}？`
      const title = '提示'
      if (typeof this.$confirm === 'function') {
        this.$confirm(message, title, {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          this.saveSingleMode()
        }).catch(() => {})
        return
      }
      if (typeof window !== 'undefined' && typeof window.confirm === 'function') {
        if (window.confirm(message))
          this.saveSingleMode()
      }
    },
    fetchSimRealtimeLink(linkDef) {
      return Promise.allSettled([
        this.$oui.call('sim', 'getStatus', { index: linkDef.index }),
        this.$oui.call('sim', 'getInterfaceStatus', { index: linkDef.index })
      ]).then(([statusResult, interfaceResult]) => {
        if (this.stopped)
          return
        const link = this.findRealtimeLink(linkDef.key)
        if (!link)
          return

        const statusData = this.parseRpcJson(statusResult.status === 'fulfilled' ? statusResult.value : null)
        const interfaceData = this.parseRpcJson(interfaceResult.status === 'fulfilled' ? interfaceResult.value : null)
        const ip = interfaceData.ip || '-'
        const gateway = interfaceData.gateway || '-'
        const rat = statusData && statusData.monsc && statusData.monsc.rat ? statusData.monsc.rat : '-'
        const operator = statusData && statusData.operator_name ? statusData.operator_name : ''
        const simState = statusData && statusData.sim ? String(statusData.sim) : ''

        link.interfaceName = interfaceData.device || interfaceData.ifname || interfaceData.name || `sim${linkDef.index + 1}`
        link.ip = ip
        link.gateway = gateway
        link.protocol = rat
        link.rxBytes = this.normalizeRealtimeNumber(interfaceData.rxBytes)
        link.txBytes = this.normalizeRealtimeNumber(interfaceData.txBytes)
        link.online = ip !== '-' || gateway !== '-' || (simState && simState !== 'nosim')
        link.detail = [operator, simState].filter(Boolean).join(' / ') || '未检测到链路信息'
        link.updatedAt = this.getNowTimeText()
      }).catch(() => {
        const link = this.findRealtimeLink(linkDef.key)
        if (!link)
          return
        link.online = false
        link.detail = '链路状态读取失败'
      })
    },
    fetchWanRealtimeLinks() {
      return this.$oui.call('network', 'get_wan_networks').then((response) => {
        if (this.stopped)
          return
        const networks = response && response.networks
        const items = Array.isArray(networks) ? networks : []
        realtimeLinkDefs
          .filter(link => link.type === 'wan')
          .forEach((linkDef, orderIndex) => {
            const link = this.findRealtimeLink(linkDef.key)
            if (!link)
              return
            const net = items[orderIndex] || {}
            const ipv4 = Array.isArray(net['ipv4-address']) ? net['ipv4-address'][0] : null
            const routes = Array.isArray(net.route) ? net.route : []
            const defaultRoute = routes.find(route => route.target === '0.0.0.0' && route.mask === 0)
            link.interfaceName = net.device || net.l3_device || net.interface || net.ifname || link.title
            link.ip = ipv4 && ipv4.address ? `${ipv4.address}/${ipv4.mask}` : '-'
            link.gateway = defaultRoute && defaultRoute.nexthop ? defaultRoute.nexthop : '-'
            link.protocol = net.proto || '-'
            link.rxBytes = null
            link.txBytes = null
            link.online = Boolean(net.up || (ipv4 && ipv4.address))
            link.detail = net.proto ? `协议 ${net.proto}` : '未检测到 WAN 状态'
            link.updatedAt = this.getNowTimeText()
          })
      }).catch(() => {
        realtimeLinkDefs
          .filter(link => link.type === 'wan')
          .forEach((linkDef) => {
            const link = this.findRealtimeLink(linkDef.key)
            if (!link)
              return
            link.online = false
            link.detail = 'WAN 状态读取失败'
          })
      })
    },
    findRealtimeLink(key) {
      return this.realtimeLinks.find(link => link.key === key)
    },
    parseRpcJson(value) {
      if (!value)
        return {}
      if (typeof value === 'string') {
        try {
          return JSON.parse(value)
        } catch {
          return {}
        }
      }
      return value
    },
    normalizeRealtimeNumber(value) {
      const num = Number(value)
      return Number.isFinite(num) ? num : null
    },
    formatRealtimeBytes(value) {
      if (value === null || value === undefined || value === '')
        return '-'
      const num = Number(value)
      if (!Number.isFinite(num))
        return '-'
      if (num < 1024)
        return `${num.toFixed(0)} B`
      if (num < 1024 * 1024)
        return `${(num / 1024).toFixed(1)} KB`
      if (num < 1024 * 1024 * 1024)
        return `${(num / 1024 / 1024).toFixed(1)} MB`
      return `${(num / 1024 / 1024 / 1024).toFixed(2)} GB`
    },
    getNowTimeText() {
      return new Date().toLocaleTimeString('zh-CN', { hour12: false })
    },
    isRealtimeLinkOnline(link) {
      return Boolean(link && link.online)
    },
    getRealtimeLinkRole(link) {
      if (this.singleModeLink === link.key)
        return '当前业务出口'
      return this.isRealtimeLinkOnline(link) ? '可用备用链路' : '待机/未连接'
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

.mode-panel-single::before {
  background: #3b82f6;
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

.mode-inline {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 2px;
}

.mode-inline + .mode-inline {
  border-top: 1px dashed rgba(148, 163, 184, 0.35);
}

.mode-inline-label {
  width: 80px;
  flex: 0 0 auto;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-secondary);
}

.mode-group {
  flex: 1 1 auto;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  padding: 10px;
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.28);
  background: rgba(248, 251, 255, 0.8);
}

.mode-actions-row .mode-inline-label {
  visibility: hidden;
}

.mode-actions {
  flex: 1 1 auto;
  display: flex;
  justify-content: flex-start;
}

.mode-option-text {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  text-align: center;
  line-height: 1.2;
}

.mode-option-label {
  font-size: 13px;
  font-weight: 700;
}

.mode-option-iface {
  font-size: 11px;
  font-weight: 600;
  color: var(--el-text-color-secondary);
}

:deep(.mode-panel .el-card__header) {
  padding: 18px 18px 0;
  border-bottom: 0;
}

:deep(.mode-panel .el-card__body) {
  padding: 12px 18px 18px;
}

:deep(.mode-group .el-radio-button) {
  margin: 0;
}

:deep(.mode-group .el-radio-button__inner) {
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.45);
  padding: 8px 14px;
  font-size: 13px;
  font-weight: 700;
  color: var(--el-text-color-regular);
  background: #ffffff;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.06);
  transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease, background-color 0.18s ease;
}

:deep(.mode-group .el-radio-button__inner:hover) {
  transform: translateY(-1px);
  box-shadow: 0 12px 22px rgba(15, 23, 42, 0.09);
  border-color: rgba(59, 130, 246, 0.45);
}

:deep(.mode-group .el-radio-button__original-radio:checked + .el-radio-button__inner) {
  background: rgba(59, 130, 246, 0.12);
  border-color: rgba(59, 130, 246, 0.55);
  color: #1d4ed8;
  box-shadow: 0 14px 26px rgba(59, 130, 246, 0.18);
}

:deep(.mode-group .el-radio-button__original-radio:focus-visible + .el-radio-button__inner) {
  outline: 2px solid rgba(59, 130, 246, 0.6);
  outline-offset: 2px;
}

:deep(.mode-actions .el-button--primary) {
  border-radius: 12px;
  padding: 10px 18px;
  font-weight: 700;
  border: 1px solid rgba(37, 99, 235, 0.6);
  background: linear-gradient(180deg, #3b82f6 0%, #2563eb 100%);
  box-shadow: 0 12px 24px rgba(59, 130, 246, 0.18);
}

:deep(.mode-actions .el-button--primary:hover) {
  box-shadow: 0 16px 28px rgba(59, 130, 246, 0.22);
}

@media (max-width: 720px) {
  .mode-inline {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
  }

  .mode-inline-label {
    width: auto;
  }

  .mode-actions-row .mode-inline-label {
    display: none;
  }

  .mode-actions {
    justify-content: stretch;
  }

  :deep(.mode-actions .el-button--primary) {
    width: 100%;
  }
}
</style>
