<template>

<div class ="server">

  <!-- 工作模式: 单卡模式 / 负载均衡 / 聚合 -->
  <div class="mode">
    <h2> {{ $t('Mode') }} </h2>
    <el-radio-group v-model="workMode" class="mode-group" @change="handleWorkModeChange">
      <el-radio-button label="single">{{ $t('单卡模式') }}</el-radio-button>
      <el-radio-button label="aggregate">{{ $t('聚合模式') }}</el-radio-button>
      <el-radio-button label="balance">{{ $t('负载均衡') }}</el-radio-button>
      
    </el-radio-group>
  </div>

  <!-- 单卡模式 -->
  <template v-if="workMode === 'single'">
    <div class="server-section">
      <el-card class="mode-card mode-panel">
        <template #header>
          <div class="card-header">
            <div>
              <div class="mode-panel-title">单卡模式</div>
              <div class="mode-panel-subtitle">选择一条链路作为当前业务出口</div>
            </div>
          </div>
        </template>
        <div class="mode-panel-body">
          <div class="mode-inline">
            <span class="mode-inline-label">链路选择</span>
            <el-radio-group v-model="singleModeLink" class="mode-group" @change="handleSingleModeLinkChange">
              <el-radio-button label="SIM1">SIM1</el-radio-button>
              <el-radio-button label="SIM2">SIM2</el-radio-button>
              <el-radio-button label="SIM3">SIM3</el-radio-button>
              <el-radio-button label="WAN1">WAN1</el-radio-button>
              <el-radio-button label="WAN2">WAN2</el-radio-button>
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

  <template v-if="workMode === 'balance'">
    <div class="server-section">
      <el-card class="mode-card mode-panel">
        <template #header>
          <div class="card-header">
            <div>
              <div class="mode-panel-title">负载均衡</div>
              <div class="mode-panel-subtitle">在多条链路之间按策略分摊业务流量,不需要服务器</div>
            </div>
          </div>
        </template>
        <div class="mode-panel-body">
          <el-descriptions :column="1" border>
            <el-descriptions-item :label="$t('工作模式')">{{ $t('负载均衡') }}</el-descriptions-item>
            <el-descriptions-item :label="$t('说明')">{{ $t('当前会在多条链路之间分摊流量') }}</el-descriptions-item>
          </el-descriptions>
        </div>
      </el-card>
    </div>
  </template>

  <template v-if="workMode === 'aggregate'">
    <div class="server-section">
      <el-card class="mode-card mode-panel">
        <template #header>
          <div class="card-header">
            <div>
              <div class="mode-panel-title">聚合模式</div>
              <div class="mode-panel-subtitle">聚合多条链路能力,需要连接聚合服务器,带宽高,延时会有所增加</div>
            </div>
          </div>
        </template>
        <div class="mode-panel-body">
          <div class="server-section aggregate-section aggregate-split">
            <div class="server-settings-card">
              <el-form :model="ServerConfig" :rules="rules" ref="serverForm" label-width="120px" label-position="left" class="config-form">
                <el-form-item :label="$t('Server IP')" prop="ip">
                  <el-input v-model="ServerConfig.ip" class="server-ip-input" :placeholder="$t('Enter Server IP')" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
                </el-form-item>
                <el-form-item :label="$t('Server Port')" prop="port">
                  <el-input-number v-model="ServerConfig.port" :min="1" :max="65535" :controls="false" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" @click="saveConfig">{{ $t('Save & Apply') }}</el-button>
                </el-form-item>
              </el-form>
            </div>

            <div class="aggregate-v-divider" aria-hidden="true"></div>

            <div class="server-status-card">
              <div class="status-info">
                <el-descriptions :column="1" border>
                  <el-descriptions-item :label="$t('Status')">
                    <el-tag :class="{'blink-bg': true}" :type="getStatusTagType()">
                      {{ serverStatus.connected ? $t('Connected') : $t('Disconnected') }}
                    </el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item :label="$t('RTT')">
                    <el-tag :type="getRttTagType(serverStatus.rtt)">
                      {{ serverStatus.rtt }} ms
                    </el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item :label="$t('Location')">
                    <el-tag type="info">{{ serverStatus.location }}</el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item :label="$t('Server Version')">
                    <el-tag type="info">{{ serverStatus.version }}</el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item :label="$t('Server Load')">
                    <el-tag type="info">{{ serverStatus.load }}</el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item :label="$t('Notice')">
                    <el-tag type="info">{{ serverStatus.notice }}</el-tag>
                  </el-descriptions-item>
                </el-descriptions>
              </div>
            </div>
          </div>
        </div>
      </el-card>
    </div>
  </template>
</div>

</template>


<script>

const realtimeLinkDefs = [
  { key: 'SIM1', title: 'sim1', type: 'sim', index: 0 },
  { key: 'SIM2', title: 'sim2', type: 'sim', index: 1 },
  { key: 'SIM3', title: 'sim3', type: 'sim', index: 2 },
  { key: 'WAN1', title: 'wan1', type: 'wan', index: 0 },
  { key: 'WAN2', title: 'wan2', type: 'wan', index: 1 }
]

function createRealtimeLink(def) {
  return {
    key: def.key,
    title: def.title,
    type: def.type,
    index: def.index,
    interfaceName: '-',
    ip: '-',
    gateway: '-',
    protocol: '-',
    rxBytes: null,
    txBytes: null,
    detail: '等待链路状态',
    updatedAt: '-',
    online: false
  }
}

export default {
  name: 'ServerConfig',
  data() {
    return {
      ServerConfig: {
        ip: '',
        port: 0
      },
      serverStatus: {
        connected: false,
        rtt: 0,
        load: 0, // 服务器负载
        location: '',
        version: '',
        notice: ''
      },
      workMode: 'single',
      singleModeLink: 'SIM1',
      realtimeLinks: realtimeLinkDefs.map(createRealtimeLink),
      hasUnsavedChanges: false, // 是否有为保存的配置
      isEditing: false, // 用户是否正在编辑
      stopped: false,
      statusInFlight: false,
      linkStatusInFlight: false,
      pollTimer: null,
      pollIntervalMs: 5000,
      visibilityListenerAdded: false,
      rules: {
        ip: [
          { required: true, message: this.$t('Server IP is required'), trigger: 'blur' },
          { validator: this.validateIP, trigger: 'blur' }
        ],
        port: [
          { required: true, message: this.$t('Server Port is required'), trigger: 'blur' },
          { validator: this.validatePort, trigger: 'blur'}
        ]
      }
    }
  },
  created() {
  },
  mounted() {
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  activated() {
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  deactivated() {
    this.stopAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  beforeRouteLeave(to, from, next) {
    this.stopAll()
    next()
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
      this.stopped = false
      this.statusInFlight = false
      if (typeof document !== 'undefined' && document && !this.visibilityListenerAdded) {
        document.addEventListener('visibilitychange', this.onVisibilityChange)
        this.visibilityListenerAdded = true
      }
      this.fetchStaticInfo()
      this.refreshOnce()
      this.startPolling()
    },
    stopAll() {
      this.stopped = true
      this.stopPolling()
      if (typeof document !== 'undefined' && document && this.visibilityListenerAdded) {
        document.removeEventListener('visibilitychange', this.onVisibilityChange)
        this.visibilityListenerAdded = false
      }
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
    onVisibilityChange() {
      if (this.stopped)
        return
      if (typeof document !== 'undefined' && document && document.hidden) {
        this.stopPolling()
      } else {
        this.refreshOnce()
        this.startPolling()
      }
    },
    fetchStaticInfo() {
      setTimeout(() => this.fetchServerIP(), 0)
      setTimeout(() => this.fetchServerPort(), 50)
      setTimeout(() => this.fetchServerNode(), 100)
      setTimeout(() => this.fetchServerVersion(), 150)
      setTimeout(() => this.fetchServerAnnourcement(), 200)
    },
    handleWorkModeChange() {
      if (this.workMode === 'single')
        this.fetchRealtimeLinks()
    },
    handleSingleModeLinkChange() {
      this.fetchRealtimeLinks()
    },
    saveSingleMode() {
      this.hasUnsavedChanges = false
      this.$message({
        message: this.$t('Configuration has been applied'),
        type: 'success'
      })
      this.fetchRealtimeLinks()
    },
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
    async refreshOnce() {
      if (this.stopped)
        return
      if (this.isEditing || this.hasUnsavedChanges)
        return
      const tasks = [this.fetchServerStatus()]
      if (this.workMode === 'single')
        tasks.push(this.fetchRealtimeLinks())
      await Promise.allSettled(tasks)
    },
    withTimeout(promise, ms, operation) {
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          reject(new Error(`${operation} timeout after ${ms}ms`))
        }, ms)
        Promise.resolve(promise).then((value) => {
          clearTimeout(timer)
          resolve(value)
        }, (err) => {
          clearTimeout(timer)
          reject(err)
        })
      })
    },
    saveConfig() {
      // 表单验证
      this.$refs.serverForm.validate((valid) => {
        if (valid) {
          this.$message({
            message: this.$t('Configuration has been applied'),
            type: 'success'
          })
          this.setServerIP()
          this.setServerPort()
          this.hasUnsavedChanges = false
          // 保存后立即刷新状态
          this.fetchServerStatus()
        } else {
          // 验证失败，不保存
          return false
        }
      })
    },
    // 设置服务器ip
    setServerIP() {
      const params = { ip: this.ServerConfig.ip }
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerIP', params)
      this.fetchServerIP()
    },
    // 设置服务器端口
    setServerPort() {
      const params = { port: this.ServerConfig.port}
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerPort', params)
      this.fetchServerPort()
    },
    // ip格式校验
    validateIP(rule, value, callback) {
      // IP地址验证
      if (!value) {
        callback(new Error(this.$t('Server IP is required')))
      }
      // IP地址验证（格式和范围）
      const ip = String(value)
      if (!/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(ip) ||
        ip.split('.').some(part => parseInt(part, 10) < 0 || parseInt(part, 10) > 255)) {
        callback(new Error(this.$t('Invalid IP address')))
        return
      }
      this.ServerConfig.ip = ip
      callback() // 验证通过
    },
    // 端口范围校验
    validatePort(rule, value, callback) {
      if (!value) {
        callback(new Error(this.$t('Server Port is required')))
      }
      const port = Number(value)
      if (port < 0 || port > 65535) {
        callback(new Error(this.$t('Port must be between 1 and 65535')))
        return
      }
      this.ServerConfig.port = port
      callback()
    },
    // 获取服务器ip
    fetchServerIP() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (this.stopped)
          return
        if (ip) {
          this.ServerConfig.ip = ip
        }
      }).catch(() => {})
    },
    // 获取服务器端口
    fetchServerPort() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (this.stopped)
          return
        if (port) {
          this.ServerConfig.port = parseInt(port)
        }
      }).catch(() => {})
    },
    // 获取服务器节点信息
    fetchServerNode() {
      this.$oui.call('serverManager', 'getServerNode').then(node => {
        if (this.stopped)
          return
        if (node) {
          this.serverStatus.location = node
        }
      })
    },
    // 获取服务器版本
    fetchServerVersion() {
      this.$oui.call('serverManager', 'getServerVersion').then(version => {
        if (this.stopped)
          return
        if (version) {
          this.serverStatus.version = version
        }
      })
    },
    // 获取服务器公告
    fetchServerAnnourcement() {
      this.$oui.call('serverManager', 'getServerAnnourcement').then(annourcement => {
        if (this.stopped)
          return
        if (annourcement) {
          this.serverStatus.notice = annourcement
        }
      })
    },
    // 获取服务器连接状态和rtt
    fetchServerRTT() {
      return this.withTimeout(this.$oui.call('serverManager', 'getHostRtt'), 5000, 'getHostRtt').then(state => {
        if (this.stopped)
          return
        if (!state.reachable) {
          this.serverStatus.connected = false
          this.serverStatus.rtt = 0
          return
        }
        this.serverStatus.rtt = parseInt(state.rtt_ms)
      }).catch(() => {
        if (this.stopped)
          return
        this.serverStatus.rtt = 0
      })
    },
    // 获取VPN隧道状态和RTT
    fetchVPNrtt() {
      return this.withTimeout(this.$oui.call('serverManager', 'getVPNrtt'), 5000, 'getVPNrtt').then(state => {
        if (this.stopped)
          return
        if (!state.reachable) {
          this.serverStatus.connected = false
          return this.fetchServerRTT()
            .catch(() => {})
        }
        this.serverStatus.connected = true
        this.serverStatus.rtt = parseInt(state.rtt_ms)
      }).catch(() => {
        if (this.stopped)
          return
        this.serverStatus.connected = false
        this.serverStatus.rtt = 0
      })
    },
    // 获取服务器状态 - 异步并行执行
    async fetchServerStatus() {
      if (this.stopped)
        return
      if (this.statusInFlight)
        return
      this.statusInFlight = true
      try {
        await this.fetchVPNrtt()
      } catch {
        return
      } finally {
        this.statusInFlight = false
      }
    },
    async fetchRealtimeLinks() {
      if (this.stopped || this.linkStatusInFlight)
        return
      this.linkStatusInFlight = true
      try {
        const simTasks = realtimeLinkDefs
          .filter(link => link.type === 'sim')
          .map(link => this.fetchSimRealtimeLink(link))
        await Promise.allSettled(simTasks.concat([this.fetchWanRealtimeLinks()]))
      } finally {
        this.linkStatusInFlight = false
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
    getRouterAddress() {
      if (typeof window !== 'undefined' && window.location && window.location.hostname)
        return window.location.hostname
      return '-'
    },
    isRealtimeLinkOnline(link) {
      return Boolean(link && link.online)
    },
    getRealtimeLinkStatusText(link) {
      return this.isRealtimeLinkOnline(link) ? '在线' : '离线'
    },
    getRealtimeLinkTagType(link) {
      return this.isRealtimeLinkOnline(link) ? 'success' : 'danger'
    },
    getRealtimeLinkRole(link) {
      if (this.singleModeLink === link.key)
        return '当前业务出口'
      return this.isRealtimeLinkOnline(link) ? '可用备用链路' : '待机/未连接'
    },
    getOnlineRealtimeLinkCount() {
      return this.realtimeLinks.filter(link => this.isRealtimeLinkOnline(link)).length
    },
    getPollIntervalSeconds() {
      const seconds = Math.round(this.pollIntervalMs / 1000)
      return seconds > 0 ? seconds : 1
    },
    // 根据rtt判断连接状态
    getRttTagType(rtt) {
      // 根据RTT值返回不同的标签类型
      if (rtt < 50) {
        return 'success' // 优秀
      } else if (rtt < 100) {
        return 'info' // 正常
      } else if (rtt < 150) {
        return 'warning' // 较慢
      } else {
        return 'danger' // 很慢
      }
    },
    // 不同状态使用不同颜色标识
    getStatusTagType() {
      return this.serverStatus.connected ? 'success' : 'danger'
    },
    // 有未保存的改动
    markUnsavedChanges() {
      this.hasUnsavedChanges = true
    }
  }
}

</script>

<style>

.server {
  width: 100%;
  box-sizing: border-box;
  padding: 20px;
}

.header {
  margin-bottom: 20px;
}

.mode {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 20px;
}

.mode-group {
  flex-wrap: wrap;
}

.mode-inline {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  flex-wrap: wrap;
}

.mode-inline-label {
  min-width: 72px;
  padding-top: 6px;
  font-size: 14px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  white-space: nowrap;
}

.mode-actions {
  display: flex;
  justify-content: flex-start;
  margin-top: 12px;
}

.mode-actions-row .mode-inline-label {
  padding-top: 0;
}

.server-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 30px;
}

.aggregate-section {
  margin-bottom: 0;
}

.aggregate-split {
  grid-template-columns: minmax(0, 1fr) 1px minmax(0, 1fr);
  align-items: stretch;
}

.aggregate-v-divider {
  background: var(--el-border-color-lighter);
  border-radius: 1px;
}

.mode-card {
  grid-column: 1 / -1;
}

.mode-panel {
  border-radius: 12px;
}

.mode-panel-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.mode-panel-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.mode-panel-body {
  padding: 6px 4px;
}

.single-route-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--el-border-color-lighter);
}

.single-route-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 18px;
}

.single-route-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.single-route-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.single-route-topology {
  position: relative;
  display: grid;
  grid-template-columns: minmax(240px, 300px) minmax(360px, 1fr);
  gap: 36px;
  align-items: center;
}

.route-device-card {
  position: relative;
  min-width: 0;
  align-self: center;
}

.route-device-panel {
  background: linear-gradient(180deg, #ffffff 0%, #f7fbff 100%);
}

.route-device-grid {
  grid-template-columns: 1fr;
}

.route-links-stage {
  display: grid;
  grid-template-columns: minmax(360px, 1fr) 120px;
  gap: 28px;
  align-items: center;
  min-height: 560px;
}

.route-links-list {
  position: relative;
  display: grid;
  gap: 16px;
  padding-left: 0;
}

.route-links-list::before {
  display: none;
}

.route-links-active-path {
  display: none;
}

.route-links-active-path.is-sim1 {
  top: 22px;
  height: 42px;
}

.route-links-active-path.is-sim2 {
  top: 22px;
  height: 146px;
}

.route-links-active-path.is-sim3 {
  top: 22px;
  height: 250px;
}

.route-links-active-path.is-wan1 {
  top: 22px;
  height: 354px;
}

.route-links-active-path.is-wan2 {
  top: 22px;
  height: 458px;
}

.route-link-item {
  position: relative;
  width: 50%;
  max-width: 100%;
  justify-self: start;
  z-index: 2;
}

.route-link-item::before {
  display: none;
}

.route-link-item.is-active::before {
  display: none;
}

.route-link-item.is-active::after {
  display: none;
}

.route-lan-flow {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  --route-lan-flow-target-y: 78px;
  --route-lan-flow-vertical-top: 78px;
  --route-lan-flow-vertical-height: 202px;
}

.route-lan-flow-segment {
  position: absolute;
  background:
    repeating-linear-gradient(
      90deg,
      #2563eb 0 10px,
      transparent 10px 16px
    );
  background-size: 24px 3px;
  animation: route-packet-flow 1.1s linear infinite;
}

.route-lan-flow-segment-start {
  left: 300px;
  top: 280px;
  width: 44px;
  height: 3px;
}

.route-lan-flow-segment-vertical {
  left: 344px;
  top: var(--route-lan-flow-vertical-top);
  width: 3px;
  height: var(--route-lan-flow-vertical-height);
  background:
    repeating-linear-gradient(
      180deg,
      #2563eb 0 10px,
      transparent 10px 16px
    );
  background-size: 3px 24px;
}

.route-lan-flow-segment-end {
  left: 344px;
  top: var(--route-lan-flow-target-y);
  width: 154px;
  height: 3px;
}

.route-lan-flow-arrow {
  position: absolute;
  left: 490px;
  top: calc(var(--route-lan-flow-target-y) - 6px);
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-left: 10px solid #60a5fa;
}

.route-lan-flow.is-sim1 {
  --route-lan-flow-target-y: 78px;
  --route-lan-flow-vertical-top: 78px;
  --route-lan-flow-vertical-height: 202px;
}

.route-lan-flow.is-sim2 {
  --route-lan-flow-target-y: 182px;
  --route-lan-flow-vertical-top: 182px;
  --route-lan-flow-vertical-height: 98px;
}

.route-lan-flow.is-sim3 {
  --route-lan-flow-target-y: 286px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 6px;
}

.route-lan-flow.is-wan1 {
  --route-lan-flow-target-y: 390px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 110px;
}

.route-lan-flow.is-wan2 {
  --route-lan-flow-target-y: 494px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 214px;
}

.route-link-card {
  position: relative;
  padding: 18px 18px 16px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.route-link-item.is-active .route-link-card {
  border-color: #2563eb;
  box-shadow: 0 14px 32px rgba(37, 99, 235, 0.16);
  transform: translateY(-1px);
}

.route-link-item.is-active .route-link-card::after {
  display: none;
}

.route-link-item.is-active .route-link-card::before {
  display: none;
}

.route-link-item.is-online .route-link-card {
  background: linear-gradient(180deg, #ffffff 0%, #f8fffb 100%);
}

.route-link-item.is-offline .route-link-card {
  background: linear-gradient(180deg, #ffffff 0%, #fff8f8 100%);
}

.route-link-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.route-link-name {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  text-transform: lowercase;
}

.route-link-role {
  margin-top: 4px;
  font-size: 13px;
  color: #f97316;
  font-weight: 600;
}

.route-link-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin-top: 16px;
}

.route-link-field {
  padding: 10px 12px;
  border-radius: 12px;
  background: #f8fafc;
}

.route-link-field-full {
  grid-column: 1 / -1;
}

.route-link-label {
  display: block;
  margin-bottom: 4px;
  font-size: 12px;
  color: #6b7280;
}

.route-link-value {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  line-height: 1.4;
  word-break: break-all;
}

.route-link-footer {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-top: 14px;
  font-size: 12px;
  color: #6b7280;
}

.route-cloud-card {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 560px;
}

.route-cloud-shape {
  position: relative;
  width: 92px;
  height: 48px;
  border-radius: 30px;
  background: #76a9d2;
  box-shadow: inset 0 -4px 0 rgba(0, 0, 0, 0.06);
}

.route-cloud-shape::before,
.route-cloud-shape::after {
  content: '';
  position: absolute;
  background: #76a9d2;
  border-radius: 50%;
}

.route-cloud-shape::before {
  width: 38px;
  height: 38px;
  left: 12px;
  top: -18px;
}

.route-cloud-shape::after {
  width: 46px;
  height: 46px;
  right: 10px;
  top: -24px;
}

.route-cloud-text {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
  color: #fff;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.config-form {
  padding: 10px;
}

.server-ip-input {
  width: 33.3333%;
}

.status-info {
  padding: 10px;
}

/* 添加过渡效果，使状态变化更平滑 */
.el-tag {
  transition: background-color 0.3s ease, color 0.3s ease;
  font-weight: 600; /* 加深字体 */
  color: rgba(0, 0, 0, 0.85); /* 加深字体加深各种颜色的背景色 */
}

/* 加深各种状态的背景色 */
.el-tag--success {
    background-color: #67c23a !important;
    border-color: #67c23a !important;
    color: #fff !important;
  }

.el-tag--danger {
    background-color: #f56c6c !important;
    border-color: #f56c6c !important;
    color: #fff !important;
  }
.el-tag--warning {
  background-color: #e6a23c !important;
  border-color: #e6a23c !important;
  color: #fff !important;
}

.el-tag--info {
  background-color: #909399 !important;
  border-color: #909399 !important;
  color: #fff !important;
}

/* 输入框文字左对齐 */
.el-input-number /deep/ .el-input__inner {
  text-align: left !important;
}

.el-input-number ::v-deep .el-input__inner {
  text-align: left !important;
}

.config-form .el-input-number input {
  text-align: left !important;
}

/* 闪烁背景样式 */
.blink-bg {
  animation: blink-animation 1s infinite;
}

@keyframes blink-animation {
  0% { opacity: 1; }
  50% { opacity: 0.9; }
  100% { opacity: 1; }
}

@keyframes route-packet-flow {
  0% { background-position: 0 0; }
  100% { background-position: 24px 0; }
}

@media (max-width: 768px) {
  .server-section {
    grid-template-columns: 1fr;
  }

  .aggregate-v-divider {
    display: none;
  }

  .server-ip-input {
    width: 100%;
  }

  .single-route-header,
  .route-link-footer {
    flex-direction: column;
  }

  .single-route-topology {
    grid-template-columns: 1fr;
    gap: 18px;
  }

  .route-links-stage {
    grid-template-columns: 1fr;
    gap: 18px;
    min-height: auto;
  }

  .route-links-list {
    padding-left: 0;
  }

  .route-links-active-path {
    display: none;
  }

  .route-link-item::before {
    display: none;
  }

  .route-link-item {
    width: 100%;
  }

  .route-link-item.is-active::before {
    display: none;
  }

  .route-link-item.is-active::after {
    display: none;
  }

  .route-lan-flow {
    display: none;
  }

  .route-link-item.is-active .route-link-card::after,
  .route-link-item.is-active .route-link-card::before {
    display: none;
  }

  .route-cloud-card {
    min-height: auto;
    padding-top: 8px;
  }

  .route-link-grid {
    grid-template-columns: 1fr;
  }
}

</style>

<i18n src="./locale.json"/>
