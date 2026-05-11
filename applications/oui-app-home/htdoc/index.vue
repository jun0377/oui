<template>
  <div class="home-page">
    <el-card class="mode-card mode-panel">

      <div class="mode-panel-body">
        <div class="home-dashboard-grid">
          <div
            class="home-metric-card home-metric-card-primary home-workmode-card"
            :class="[featuredWorkModeCard.accentClass, workModeThemeClass]"
          >
            <div class="home-metric-head">
              <div>
                <div class="home-metric-title">{{ featuredWorkModeCard.title }}</div>
              </div>
              <el-tag :type="featuredWorkModeCard.type">{{ featuredWorkModeCard.tag }}</el-tag>
            </div>
            <div class="home-metric-value">{{ featuredWorkModeCard.value }}</div>
            <div class="home-metric-subtitle">{{ featuredWorkModeCard.subtitle }}</div>
            <div class="home-workmode-foot">
              <span class="home-workmode-foot-value">{{ featuredWorkModeCard.detail }}</span>
            </div>
          </div>

          <div class="home-metric-card home-metric-card-primary home-resource-card is-accent-blue">
            <div class="home-metric-head">
              <div class="home-metric-title">系统资源</div>
              <el-tag type="info">实时</el-tag>
            </div>

            <div class="home-resource-usage-list">
              <div v-for="item in resourceUsageItems" :key="item.title" class="home-resource-usage-item">
                <div class="home-resource-usage-label">{{ item.title }}</div>
                <div class="home-resource-usage-progress">
                  <el-progress :percentage="item.percentage" :stroke-width="16" :show-text="false" />
                </div>
                <div class="home-resource-usage-value">{{ item.value }}</div>
              </div>
            </div>

            <div class="home-resource-info-list">
              <div v-for="item in resourceInfoItems" :key="item.title" class="home-resource-info-item">
                <span class="home-resource-info-title">{{ item.title }}</span>
                <span class="home-resource-info-value">{{ item.value }}</span>
              </div>
            </div>
          </div>

          <div class="home-status-grid">
            <div
              v-for="card in primaryStatusCards"
              :key="card.key"
              class="home-metric-card home-metric-card-primary"
              :class="card.accentClass"
            >
              <div class="home-metric-head">
                <div class="home-metric-title">{{ card.title }}</div>
                <el-tag :type="card.type">{{ card.tag }}</el-tag>
              </div>
              <div class="home-metric-value">{{ card.value }}</div>
              <div class="home-metric-subtitle">{{ card.subtitle }}</div>
              <el-progress
                v-if="card.percentage !== null"
                :percentage="card.percentage"
                :stroke-width="8"
                :show-text="false"
              />
            </div>
          </div>

          <div class="home-section-card home-interface-panel">
            <div class="home-metric-head">
              <div class="home-section-title">网络接口状态</div>
              <el-tag type="info">实时</el-tag>
            </div>

            <div v-if="interfaceCards.length" class="home-interface-list">
              <div class="home-interface-head-row">
                <div class="home-interface-summary home-interface-summary-head">接口</div>
                <div class="home-interface-inline-fields home-interface-inline-fields-head">
                  <div
                    v-for="field in interfaceFieldMeta"
                    :key="`head-${field.key}`"
                    class="home-interface-inline-field home-interface-inline-field-head"
                  >
                    {{ field.label }}
                  </div>
                </div>
                <div class="home-interface-status-head">状态</div>
              </div>
              <div
                v-for="card in interfaceCards"
                :key="card.key"
                class="home-interface-card"
                :class="card.statusClass"
              >
                <div class="home-interface-row">
                  <div class="home-interface-summary">
                    <div class="home-interface-name">{{ card.name }}</div>
                    <div class="home-interface-ifname">{{ card.ifname }}</div>
                  </div>
                  <div class="home-interface-inline-fields">
                    <div
                      v-for="field in interfaceFieldMeta"
                      :key="`${card.key}-${field.key}`"
                    class="home-interface-inline-field"
                    :class="{ 'is-grouped': field.items }"
                    >
                      <template v-if="field.items">
                        <div
                          v-for="item in field.items"
                          :key="`${card.key}-${field.key}-${item.key}`"
                          class="home-interface-value-pair"
                        >
                          <span class="home-interface-subvalue-label">{{ item.label }}</span>
                          <span class="home-interface-value">{{ card[item.key] }}</span>
                        </div>
                      </template>
                      <span v-else class="home-interface-value">{{ card[field.key] }}</span>
                    </div>
                  </div>
                  <el-tag :type="card.online ? 'success' : 'danger'">
                    {{ card.online ? '在线' : '离线' }}
                  </el-tag>
                </div>
              </div>
            </div>
            <el-empty v-else description="暂无数据" />
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
const WORK_MODE_META = {
  single: {
    label: '单卡模式',
    description: '固定走单条链路',
    themeClass: 'is-mode-single'
  },
  aggregate: {
    label: '聚合模式',
    description: '聚合多链路带宽',
    themeClass: 'is-mode-aggregate'
  },
  balance: {
    label: '负载均衡',
    description: '多链路按权重分流',
    themeClass: 'is-mode-balance'
  }
}

const DEFAULT_WORK_MODE_META = {
  label: '未知模式',
  description: '等待模式数据',
  themeClass: 'is-mode-default'
}

// 卡片显示顺序与在此数据中的顺序相同
const SERVICE_CARD_META = [
  { key: 'admin-backend', title: '管理平台' },
  { key: 'network-status', title: '组网状态' },
  { key: 'dhcp-status', title: 'DHCP服务器' },
  { key: 'dns-status', title: 'DNS服务' },
]

const INTERFACE_FIELD_META = [
  { key: 'ipv4', label: 'IPv4' },
  { key: 'gateway', label: '网关' },
  {
    key: 'traffic-total',
    label: '流量统计',
    items: [
      { key: 'rxTotal', label: '↓' },
      { key: 'txTotal', label: '↑' }
    ]
  },
  {
    key: 'traffic-rate',
    label: '实时带宽',
    items: [
      { key: 'rxRate', label: '↓' },
      { key: 'txRate', label: '↑' }
    ]
  }
]

export default {
  data() {
    return {
      cpuTimes: [],
      sysinfo: null,
      boardinfo: null,
      wanLinks: [],
      interfaceStates: [],
      interfaceSnapshots: {},
      serial: null,
      version: null,
      lanIp: null,
      lanMask: null,
      workMode: '',
      workModeSettings: null,
      dhcpSettings: null,
      dhcpLeases: [],
      cpuTemperature: null,
      currentTimeText: '',
      clockTimer: null,
      rpcTestLoading: false,
      rpcTestResult: null
    }
  },
  computed: {
    cpuUsage() {
      if (this.cpuTimes.length < 2)
        return { cpu: 0 }

      const values = {}
      Object.keys(this.cpuTimes[0]).forEach(name => {
        values[name] = this.calcCpuUsage(this.cpuTimes[0][name], this.cpuTimes[1][name])
      })
      return values
    },
    memUsage() {
      if (!this.sysinfo)
        return 0
      const memory = this.sysinfo.memory
      return parseFloat(((memory.total - memory.free) * 100 / memory.total).toFixed(2))
    },
    lanAddr() {
      if (this.lanIp && this.lanMask)
        return `${this.lanIp} / ${this.lanMask}`
      return this.lanIp || '-'
    },
    workModeMeta() {
      return WORK_MODE_META[this.workMode] || DEFAULT_WORK_MODE_META
    },
    workModeThemeClass() {
      return this.workModeMeta.themeClass
    },
    dhcpLeaseCount() {
      return Array.isArray(this.dhcpLeases) ? this.dhcpLeases.length : 0
    },
    dhcpRangeText() {
      if (!this.dhcpSettings)
        return '未获取地址池'
      const start = this.formatIpv4Sections(this.dhcpSettings.dhcpStart)
      const end = this.formatIpv4Sections(this.dhcpSettings.dhcpEnd)
      if (start === '-' || end === '-')
        return '未配置地址池'
      return `${start} - ${end}`
    },
    dhcpStatus() {
      if (!this.dhcpSettings)
        return {
          label: '待检测',
          subtitle: '正在获取 DHCP 配置',
          type: 'warning'
        }
      return {
        label: '运行中',
        subtitle: `租约数 ${this.dhcpLeaseCount} / 地址池 ${this.dhcpRangeText}`,
        type: 'success'
      }
    },
    interfaceCards() {
      if (this.interfaceStates.length) {
        return this.interfaceStates.map(card => ({
          ...card,
          statusClass: card.online ? 'is-online' : 'is-offline'
        }))
      }

      return []
    },
    networkingStatus() {
      const onlineCount = this.interfaceCards.filter(card => card.online).length
      if (onlineCount >= 2) {
        return {
          label: '聚合组网',
          subtitle: `已检测到 ${onlineCount} 条上行链路在线`,
          tag: '正常',
          type: 'success'
        }
      }
      if (onlineCount === 1) {
        return {
          label: '单链路在线',
          subtitle: '仅检测到 1 条可用上行链路',
          tag: '注意',
          type: 'warning'
        }
      }
      return {
        label: '组网未就绪',
        subtitle: '当前未检测到可用上行链路',
        tag: '离线',
        type: 'danger'
      }
    },
    cpuTemperatureText() {
      return this.cpuTemperature === null ? '-' : `${this.cpuTemperature}°C`
    },
    cpuTemperaturePercent() {
      if (this.cpuTemperature === null)
        return 0
      return Math.max(0, Math.min(100, this.cpuTemperature))
    },
    resourceUsageItems() {
      return [
        {
          title: 'CPU温度',
          value: this.cpuTemperatureText,
          percentage: this.cpuTemperaturePercent
        },
        {
          title: 'CPU使用率',
          value: `${this.cpuUsage.cpu || 0}%`,
          percentage: this.cpuUsage.cpu || 0
        },
        {
          title: '内存使用率',
          value: `${this.memUsage}%`,
          percentage: this.memUsage
        }
      ]
    },
    resourceInfoItems() {
      return [
        {
          title: '设备型号',
          value: this.boardinfo?.model || '-'
        },
        {
          title: '序列号',
          value: this.serial
        },
        {
          title: '固件版本',
          value: this.version || '-'
        },
        {
          title: '已启动',
          value: this.sysinfo ? this.secondsToHuman(this.sysinfo.uptime) : '-'
        },
        {
          title: '系统时间',
          value: this.currentTimeText || '-'
        }
      ]
    },
    interfaceFieldMeta() {
      return INTERFACE_FIELD_META
    },
    // 工作模式卡片
    featuredWorkModeCard() {
      return {
        key: 'work-mode',
        title: '工作模式',
        value: this.workModeMeta.label,
        subtitle: this.workModeMeta.description,
        detail: this.workModeSettings?.detail || this.workModeSettings?.detail || '等待工作模式配置',
        tag: '策略',
        type: 'info',
        accentClass: 'is-accent-amber'
      }
    },
    sharedServiceStatus() {
      return {
        value: this.dhcpStatus.label,
        subtitle: this.dhcpStatus.subtitle,
        tag: `${this.dhcpLeaseCount} 租约`,
        type: this.dhcpStatus.type
      }
    },
    serviceCards() {
      const statusMap = {
        'network-status': this.networkingStatus,
        'admin-backend': this.sharedServiceStatus,
        'dhcp-status': this.sharedServiceStatus,
        'dns-status': this.sharedServiceStatus
      }

      return SERVICE_CARD_META.map(({ key, title }) => this.createStatusCard(key, title, statusMap[key]))
    },
    primaryStatusCards() {
      return this.serviceCards
    }
  },
  methods: {
    secondsToHuman(second) {
      if (isNaN(second))
        return ''
      const days = Math.floor(second / 86400)
      const hours = Math.floor((second % 86400) / 3600)
      const minutes = Math.floor(((second % 86400) % 3600) / 60)
      const seconds = Math.floor(((second % 86400) % 3600) % 60)
      return `${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒`
    },
    calcCpuUsage(times0, times1) {
      const times0CPU = times0[0] + times0[1] + times0[2]
      const times1CPU = times1[0] + times1[1] + times1[2]
      const val = (times1CPU - times0CPU) * 100.0 / ((times1CPU + times1[3]) - (times0CPU + times0[3]))
      return parseFloat(val.toFixed(2))
    },
    getAccentClassByType(type) {
      if (type === 'success')
        return 'is-accent-green'
      if (type === 'danger')
        return 'is-accent-red'
      return 'is-accent-amber'
    },
    createStatusCard(key, title, status) {
      return {
        key,
        title,
        value: status.value || status.label || '-',
        subtitle: status.subtitle || '',
        tag: status.tag || '状态',
        type: status.type || 'info',
        percentage: null,
        accentClass: this.getAccentClassByType(status.type)
      }
    },
    parseRpcResult(result) {
      if (typeof result === 'string') {
        try {
          return JSON.parse(result)
        } catch {
          return null
        }
      }
      return result
    },
    maskToPrefix(mask) {
      if (!mask || mask === '-' || mask === '-')
        return ''
      const parts = String(mask).split('.').map(value => Number.parseInt(value, 10))
      if (parts.length !== 4 || parts.some(value => Number.isNaN(value)))
        return mask
      const bitCount = parts
        .map(value => value.toString(2).padStart(8, '0'))
        .join('')
        .replace(/0/g, '').length
      return bitCount ? String(bitCount) : mask
    },
    formatAddressWithMask(ip, mask) {
      if (!ip || ip === '-' || ip === '-')
        return '-'
      const prefix = this.maskToPrefix(mask)
      return prefix ? `${ip}/${prefix}` : ip
    },
    parseByteValue(value) {
      const parsed = Number.parseInt(value, 10)
      return Number.isFinite(parsed) && parsed >= 0 ? parsed : null
    },
    // 流量单位转换
    formatBytes(bytes) {
      if (!Number.isFinite(bytes) || bytes < 0)
        return '-'
      const units = ['B', 'KB', 'MB', 'GB', 'TB']
      let value = bytes
      let unitIndex = 0
      while (value >= 1024 && unitIndex < units.length - 1) {
        value /= 1024
        unitIndex += 1
      }
      const precision = value >= 100 || unitIndex === 0 ? 0 : value >= 10 ? 1 : 2
      return `${value.toFixed(precision)} ${units[unitIndex]}`
    },
    // 带宽单位转换
    formatRate(bytesPerSecond) {
      if (!Number.isFinite(bytesPerSecond) || bytesPerSecond < 0)
        return '-'
      const units = ['bps', 'Kbps', 'Mbps', 'Gbps', 'Tbps']
      let value = bytesPerSecond * 8
      let unitIndex = 0
      while (value >= 1000 && unitIndex < units.length - 1) {
        value /= 1000
        unitIndex += 1
      }
      const precision = value >= 100 ? 0 : value >= 10 ? 1 : 2
      return `${value.toFixed(precision)} ${units[unitIndex]}`
    },
    attachInterfaceStats(card, rxBytes, txBytes, now) {
      const rxValue = this.parseByteValue(rxBytes)
      const txValue = this.parseByteValue(txBytes)
      const previous = this.interfaceSnapshots[card.key]
      let rxRate = '-'
      let txRate = '-'

      if (previous && Number.isFinite(previous.timestamp) && now > previous.timestamp) {
        const seconds = (now - previous.timestamp) / 1000
        if (seconds > 0) {
          if (rxValue !== null && previous.rxBytes !== null && rxValue >= previous.rxBytes)
            rxRate = this.formatRate((rxValue - previous.rxBytes) / seconds)
          if (txValue !== null && previous.txBytes !== null && txValue >= previous.txBytes)
            txRate = this.formatRate((txValue - previous.txBytes) / seconds)
        }
      }

      this.interfaceSnapshots[card.key] = {
        rxBytes: rxValue,
        txBytes: txValue,
        timestamp: now
      }

      return {
        ...card,
        rxTotal: this.formatBytes(rxValue),
        txTotal: this.formatBytes(txValue),
        rxRate,
        txRate
      }
    },
    buildDefaultInterfaceCard(link, index) {
      const key = link?.name || link?.device || `link-${index}`
      return {
        key,
        name: link?.name || link?.device || `wan${index}`,
        ifname: '-',
        ipv4: '-',
        gateway: '-',
        rxTotal: '-',
        txTotal: '-',
        rxRate: '-',
        txRate: '-',
        online: false
      }
    },
    // 网口 网络接口状态
    buildWanInterfaceCard(link, index) {
      const section = link?.name ? String(link.name) : ''
      const iface = link?.device ? String(link.device) : ''
      const baseCard = this.buildDefaultInterfaceCard(link, index)
      if (!section || !iface)
        return Promise.resolve(baseCard)

      return this.$oui.call('wan', 'getWanState', { section, interface: iface }).then((result) => {
        const data = this.parseRpcResult(result)
        if (!data || data.code !== 0)
          return baseCard

        return {
          key: section,
          name: section,
          ifname: iface || '-',
          ipv4: this.formatAddressWithMask(data.ip, data.mask),
          gateway: data.gateway && data.gateway !== '-' ? data.gateway : '-',
          rxBytes: data.rxBytes,
          txBytes: data.txBytes,
          online: data.status === '正常' || (data.ip && data.ip !== '-')
        }
      }).catch(() => baseCard)
    },
    // sim卡 网络接口状态
    buildSimInterfaceCard(link, index) {
      const rpcIndex = Number(link?.sim_index)
      const baseCard = this.buildDefaultInterfaceCard(link, index)
      if (!Number.isFinite(rpcIndex) || rpcIndex < 0)
        return Promise.resolve(baseCard)

      return Promise.all([
        this.$oui.call('sim', 'getSimUciSettings', { index: rpcIndex }),
        this.$oui.call('sim', 'getInterfaceStatus', { index: rpcIndex })
      ]).then(([settingsResult, statusResult]) => {
        const settings = this.parseRpcResult(settingsResult) || {}
        const status = this.parseRpcResult(statusResult) || {}
        const iface = settings.interface || status.interface || link?.device || link?.name || ''
        const ifname = settings.ifname || status.ifname || '-'
        return {
          key: link?.name || iface || `sim${rpcIndex}`,
          name: settings.alias || link?.name || iface || `sim${rpcIndex}`,
          ifname,
          ipv4: this.formatAddressWithMask(status.ip, status.mask),
          gateway: status.gateway || '-',
          rxBytes: status.rxBytes,
          txBytes: status.txBytes,
          online: Boolean(status.ip && status.ip !== '-' && status.ip !== '-')
        }
      }).catch(() => baseCard)
    },
    fetchInterfaceStates() {
      this.$oui.call('wan', 'getAvailWan').then((result) => {
        const data = this.parseRpcResult(result)
        const links = Array.isArray(data?.links) ? data.links : []
        this.wanLinks = links

        if (!links.length) {
          this.interfaceStates = []
          return
        }

        return Promise.all(links.map((link, index) => {
          if (link?.kind === 'sim')
            return this.buildSimInterfaceCard(link, index)
          return this.buildWanInterfaceCard(link, index)
        })).then((cards) => {
          const now = Date.now()
          this.interfaceStates = cards
            .filter(Boolean)
            .map(card => this.attachInterfaceStats(card, card.rxBytes, card.txBytes, now))
        })
      }).catch(() => {
        this.wanLinks = []
        this.interfaceStates = []
      })
    },
    formatIpv4Sections(sections) {
      if (!sections)
        return '-'
      const values = ['section1', 'section2', 'section3', 'section4']
        .map(key => sections[key])
        .filter(value => value !== undefined && value !== null && value !== '')
      return values.length === 4 ? values.join('.') : '-'
    },
    getCpuTimes() {
      this.$oui.call('system', 'get_cpu_time').then(({ times }) => {
        this.cpuTimes.push(times)
        if (this.cpuTimes.length === 3)
          this.cpuTimes.shift()
      }).catch(() => {})
    },
    getSysinfo() {
      this.$oui.ubus('system', 'info').then(r => {
        this.sysinfo = r
      }).catch(() => {})
    },
    // 负载均衡模式配置
    workModeBalanceSettings(result) {
      return {
        detail: `负载均衡模式`
      }
    },
    // 聚合模式配置
    workModeAggregateSettings(result) {

      const settings = result.settings
      const vps_ip = settings.vps_ip
      const vps_port = settings.vps_port

      return {
        detail: `聚合服务器: ${vps_ip}:${vps_port}`
      }
    },
    // 单卡模式配置
    workModeSingleSettings(result) {
      const settings = result.settings
      const channel = settings.channel
      const ifname = settings.ifname

      return {
        detail: `当前所有的流量都固定走 ${channel}(${ifname})`,
      }
    },
    // 工作模式配置信息
    fetchWorkMode() {
      this.$oui.call('home', 'workModeSettings').then((result) => {
        const mode = result.mode
        this.workMode = mode
        switch (mode) {
          case 'single':
            this.workModeSettings = this.workModeSingleSettings(result)
            break
          case 'aggregate':
            this.workModeSettings = this.workModeAggregateSettings(result)
            break;
          case 'balance':
            this.workModeSettings = this.workModeBalanceSettings(result)
          default:
            this.workModeSettings = result.settings || null
            break
        }

        console.log('xxx', this.workModeSettings)

      }).catch(() => {
        this.workMode = ''
        this.workModeSettings = null
      })
    },
    fetchDHCPSettings() {
      this.$oui.call('dhcp', 'getDHCPSettings').then((dhcpSettings) => {
        this.dhcpSettings = dhcpSettings
      }).catch(() => {
        this.dhcpSettings = null
      })
    },
    fetchDhcpLeases() {
      this.$oui.call('network', 'dhcp_leases').then(({ leases }) => {
        this.dhcpLeases = Array.isArray(leases) ? leases : []
      }).catch(() => {
        this.dhcpLeases = []
      })
    },
    fetchCpuTemperature() {
      this.$oui.ubus('file', 'exec', {
        command: 'sh',
        params: ['-c', 'for f in /sys/class/thermal/thermal_zone*/temp; do [ -f "$f" ] && cat "$f" && break; done']
      }).then(r => {
        const raw = parseInt(String(r.stdout || '').trim(), 10)
        if (Number.isNaN(raw)) {
          this.cpuTemperature = null
          return
        }
        this.cpuTemperature = raw > 1000 ? Math.round(raw / 1000) : raw
      }).catch(() => {
        this.cpuTemperature = null
      })
    },
    updateCurrentTime() {
      const now = new Date()
      const pad = value => String(value).padStart(2, '0')
      this.currentTimeText = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
    }
  },
  created() {
    this.$timer.create('homeGetCpuTimes', this.getCpuTimes, { repeat: true, immediate: true, time: 3000 })
    this.$timer.create('homeGetSysinfo', this.getSysinfo, { repeat: true, immediate: true, time: 3000 })
    this.$timer.create('homeGetInterfaceStates', this.fetchInterfaceStates, { repeat: true, immediate: true, time: 1000 })
    // 从uci配置文件中获取工作模式配置
    this.fetchWorkMode()
    this.$timer.create('homeGetDhcpSettings', this.fetchDHCPSettings, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetDhcpLeases', this.fetchDhcpLeases, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetCpuTemperature', this.fetchCpuTemperature, { repeat: true, immediate: true, time: 5000 })

    this.updateCurrentTime()
    this.clockTimer = setInterval(this.updateCurrentTime, 1000)

    this.$oui.ubus('system', 'board').then(r => {
      this.boardinfo = r
    }).catch(() => {})

    this.$oui.ubus('file', 'exec', {
      command: 'sh',
      params: ['-c', 'cat /proc/cpuinfo | grep Serial | awk \'{print $3}\'']
    }).then(r => {
      this.serial = r.stdout && r.stdout.trim() ? r.stdout.trim() : '-'
    }).catch(() => {
      this.serial = '-'
    })

    this.$oui.ubus('file', 'exec', {
      command: 'sh',
      params: ['-c', 'cat /etc/version']
    }).then(r => {
      this.version = r.stdout ? r.stdout.trim() : '-'
    }).catch(() => {
      this.version = '-'
    })

    this.$oui.call('uci', 'get', {
      config: 'network',
      section: 'lan',
      option: 'ipaddr'
    }).then(lanip => {
      this.lanIp = lanip || '-'
    }).catch(() => {
      this.lanIp = '-'
    })

    this.$oui.call('uci', 'get', {
      config: 'network',
      section: 'lan',
      option: 'netmask'
    }).then(lanMask => {
      this.lanMask = lanMask || '-'
    }).catch(() => {
      this.lanMask = '-'
    })
  },
  beforeUnmount() {
    if (this.clockTimer) {
      clearInterval(this.clockTimer)
      this.clockTimer = null
    }
  }
}
</script>

<style scoped>
.home-page {
  width: 100%;
}

.mode-card {
  width: 100%;
}

.mode-panel {
  border-radius: 12px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.home-rpc-test-bar {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border: 1px solid rgba(59, 130, 246, 0.18);
  border-radius: 12px;
  background: linear-gradient(180deg, #f8fbff 0%, #ffffff 100%);
}

.home-rpc-test-text {
  min-width: 0;
}

.home-rpc-test-title {
  font-size: 13px;
  font-weight: 700;
  color: var(--el-text-color-primary);
}

.home-rpc-test-subtitle {
  margin-top: 2px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
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

.home-dashboard-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  grid-template-areas:
    'workmode workmode interface interface'
    'status status interface interface'
    'status status resource resource';
  gap: 16px;
  align-items: stretch;
}

.home-workmode-card {
  grid-area: workmode;
}

.home-resource-card {
  grid-area: resource;
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
}

.home-status-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-content: stretch;
  grid-area: status;
}

.home-interface-panel {
  grid-area: interface;
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
}

.home-metric-card,
.home-section-card {
  display: flex;
  flex-direction: column;
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.home-metric-card {
  position: relative;
  overflow: hidden;
}

.home-metric-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.home-metric-card-primary {
  min-height: 168px;
}

.home-workmode-card {
  background: linear-gradient(135deg, #fff7ed 0%, #ffffff 100%);
  border-color: rgba(245, 158, 11, 0.28);
  box-shadow: 0 14px 30px rgba(245, 158, 11, 0.12);
}

.home-workmode-card.is-mode-single {
  background: linear-gradient(135deg, #eff6ff 0%, #ffffff 100%);
  border-color: rgba(59, 130, 246, 0.28);
  box-shadow: 0 14px 30px rgba(59, 130, 246, 0.12);
}

.home-workmode-card.is-mode-aggregate {
  background: linear-gradient(135deg, #f5f3ff 0%, #ffffff 100%);
  border-color: rgba(139, 92, 246, 0.28);
  box-shadow: 0 14px 30px rgba(139, 92, 246, 0.12);
}

.home-workmode-card.is-mode-balance {
  background: linear-gradient(135deg, #f0fdf4 0%, #ffffff 100%);
  border-color: rgba(34, 197, 94, 0.28);
  box-shadow: 0 14px 30px rgba(34, 197, 94, 0.12);
}

.home-workmode-card.is-mode-default {
  background: linear-gradient(135deg, #fff7ed 0%, #ffffff 100%);
  border-color: rgba(245, 158, 11, 0.28);
  box-shadow: 0 14px 30px rgba(245, 158, 11, 0.12);
}

.home-workmode-card .home-metric-value {
  margin-top: 18px;
  font-size: 36px;
  line-height: 1;
}

.home-workmode-label {
  margin-top: 4px;
  font-size: 12px;
  font-weight: 600;
  color: #b45309;
}

.home-workmode-card.is-mode-single .home-workmode-label,
.home-workmode-card.is-mode-single .home-workmode-foot-label {
  color: #1d4ed8;
}

.home-workmode-card.is-mode-single .home-workmode-foot {
  border-top-color: rgba(59, 130, 246, 0.18);
}

.home-workmode-card.is-mode-single .home-workmode-foot-label {
  background: rgba(59, 130, 246, 0.14);
}

.home-workmode-card.is-mode-aggregate .home-workmode-label,
.home-workmode-card.is-mode-aggregate .home-workmode-foot-label {
  color: #6d28d9;
}

.home-workmode-card.is-mode-aggregate .home-workmode-foot {
  border-top-color: rgba(139, 92, 246, 0.18);
}

.home-workmode-card.is-mode-aggregate .home-workmode-foot-label {
  background: rgba(139, 92, 246, 0.14);
}

.home-workmode-card.is-mode-balance .home-workmode-label,
.home-workmode-card.is-mode-balance .home-workmode-foot-label {
  color: #15803d;
}

.home-workmode-card.is-mode-balance .home-workmode-foot {
  border-top-color: rgba(34, 197, 94, 0.18);
}

.home-workmode-card.is-mode-balance .home-workmode-foot-label {
  background: rgba(34, 197, 94, 0.14);
}

.home-workmode-foot {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px solid rgba(245, 158, 11, 0.18);
}

.home-workmode-foot-label {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 999px;
  background: rgba(245, 158, 11, 0.14);
  color: #b45309;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.home-workmode-foot-value {
  flex: 1 1 auto;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.home-resource-usage-list {
  display: grid;
  gap: 12px;
  margin-top: 14px;
}

.home-resource-usage-item {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr) 72px;
  align-items: center;
  gap: 14px;
}

.home-resource-usage-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.home-resource-usage-progress {
  min-width: 0;
}

.home-resource-usage-value {
  text-align: right;
  font-size: 13px;
  font-weight: 700;
  color: var(--el-text-color-primary);
}

.home-resource-info-list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px 20px;
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid rgba(148, 163, 184, 0.16);
}

.home-resource-info-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.home-resource-info-title {
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.home-resource-info-value {
  text-align: right;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  word-break: break-word;
}

.home-metric-card.is-accent-blue::before {
  background: #3b82f6;
}

.home-metric-card.is-accent-purple::before {
  background: #8b5cf6;
}

.home-metric-card.is-accent-cyan::before {
  background: #06b6d4;
}

.home-metric-card.is-accent-amber::before {
  background: #f59e0b;
}

.home-metric-card.is-accent-green::before {
  background: #22c55e;
}

.home-metric-card.is-accent-red::before {
  background: #ef4444;
}

.home-metric-card.is-accent-slate::before {
  background: #64748b;
}

.home-metric-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.home-metric-title,
.home-section-title,
.home-interface-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.home-section-subtitle,
.home-metric-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.home-interface-ifname {
  margin-top: 2px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.home-metric-value {
  margin: 14px 0 6px;
  font-size: 28px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.1;
  word-break: break-word;
}

.home-interface-list {
  display: grid;
  gap: 10px;
  margin-top: 16px;
}

.home-interface-head-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 16px 2px;
}

.home-interface-summary-head,
.home-interface-inline-field-head,
.home-interface-status-head {
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
  white-space: nowrap;
}

.home-interface-status-head {
  flex: 0 0 auto;
}

.home-interface-card {
  padding: 10px 14px;
  border-radius: 14px;
  background: #f8fafc;
  border: 1px solid transparent;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;
}

.home-interface-card.is-online {
  border-color: rgba(34, 197, 94, 0.26);
  background: linear-gradient(180deg, #f0fdf4 0%, #f8fafc 100%);
  box-shadow: inset 0 0 0 1px rgba(34, 197, 94, 0.08);
}

.home-interface-card.is-offline {
  border-color: rgba(239, 68, 68, 0.26);
  background: linear-gradient(180deg, #fef2f2 0%, #fff7f7 100%);
  box-shadow: inset 0 0 0 1px rgba(239, 68, 68, 0.06);
}

.home-interface-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.home-interface-summary {
  flex: 0 0 72px;
  min-width: 0;
}

.home-interface-inline-fields {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
  flex: 1 1 auto;
  min-width: 0;
}

.home-interface-inline-field {
  display: flex;
  align-items: center;
  min-width: 0;
  white-space: nowrap;
}

.home-interface-inline-field.is-grouped {
  display: block;
}

.home-interface-value-pair + .home-interface-value-pair {
  margin-top: 2px;
}

.home-interface-value-pair {
  display: flex;
  align-items: center;
  min-width: 0;
  white-space: nowrap;
}

.home-interface-subvalue-label {
  margin-right: 6px;
  font-size: 12px;
  color: #6b7280;
  flex: 0 0 auto;
}

.home-interface-value-pair .home-interface-value {
  flex: 1 1 auto;
  min-width: 0;
  white-space: nowrap;
  word-break: normal;
  overflow: hidden;
  text-overflow: ellipsis;
}

.home-interface-value {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  line-height: 1.25;
  white-space: nowrap;
  word-break: normal;
  overflow: hidden;
  text-overflow: ellipsis;
}

@media (max-width: 1024px) {
  .home-dashboard-grid,
  .home-status-grid {
    grid-template-columns: 1fr;
  }

  .home-dashboard-grid {
    grid-template-areas:
      'workmode'
      'resource'
      'status'
      'interface';
  }
}

@media (max-width: 768px) {
  .card-header,
  .home-metric-head {
    flex-direction: column;
    align-items: flex-start;
  }

  .home-rpc-test-bar {
    width: 100%;
    justify-content: space-between;
  }

  .home-interface-row {
    flex-direction: column;
    align-items: flex-start;
  }

  .home-interface-summary {
    flex-basis: auto;
  }

  .home-interface-inline-fields {
    grid-template-columns: 1fr;
    width: 100%;
  }

  .home-resource-usage-item,
  .home-resource-info-item {
    grid-template-columns: 1fr;
    gap: 6px;
  }

  .home-workmode-foot {
    flex-direction: column;
    align-items: flex-start;
  }

  .home-resource-usage-value,
  .home-resource-info-value,
  .home-workmode-foot-value {
    text-align: left;
  }

  .home-resource-info-list {
    grid-template-columns: 1fr;
  }

  .home-metric-card-primary {
    min-height: auto;
  }
}
</style>

<i18n src="./locale.json"/>
