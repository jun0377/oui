<template>
  <div class="home-page">
    <el-card class="mode-card mode-panel">

      <div class="mode-panel-body">
        <div class="home-dashboard-grid">
          <div class="home-metric-card home-metric-card-primary home-workmode-card">
            <div class="home-metric-title">{{ featuredWorkModeCard.title }}</div>
            <div class="home-metric-value">{{ featuredWorkModeCard.value }}</div>
            <div class="home-metric-subtitle">{{ featuredWorkModeCard.subtitle }}</div>
            <div class="home-workmode-foot">
              <span class="home-workmode-foot-value">{{ featuredWorkModeCard.detail }}</span>
            </div>
          </div>

          <div class="home-metric-card home-metric-card-primary home-resource-card">
            <div class="home-metric-title">系统资源</div>

            <div class="home-resource-usage-list">
              <div v-for="item in resourceUsageItems" :key="item.title" class="home-resource-usage-item">
                <div class="home-resource-usage-label">{{ item.title }}</div>
                <div class="home-resource-usage-sparkline">
                  <svg viewBox="0 0 96 30" preserveAspectRatio="none" aria-hidden="true">
                    <rect x="0" y="0" width="96" height="30" rx="4" class="home-resource-sparkline-bg"/>
                    <line x1="0" y1="26" x2="96" y2="26" class="home-resource-axis-line"/>
                    <polyline
                      :points="getUsageSparklinePoints(item.title)"
                      fill="none"
                      class="home-resource-curve-line"
                      vector-effect="non-scaling-stroke"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                  </svg>
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
            >
              <div class="home-metric-title">{{ card.title }}</div>
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
            <div class="home-section-title">网络接口状态</div>

            <div v-if="interfaceLoading" class="home-interface-loading">
              <div
                v-for="n in 3"
                :key="'skel-' + n"
                class="home-interface-skeleton"
              >
                <div class="home-interface-skeleton-row">
                  <div class="home-interface-skeleton-summary">
                    <div class="home-interface-skeleton-name skeleton-bar" />
                    <div class="home-interface-skeleton-ifname skeleton-bar skeleton-bar-short" />
                  </div>
                  <div class="home-interface-skeleton-fields">
                    <div class="home-interface-skeleton-field skeleton-bar" />
                    <div class="home-interface-skeleton-field skeleton-bar" />
                    <div class="home-interface-skeleton-field skeleton-bar skeleton-bar-narrow" />
                  </div>
                  <div class="home-interface-skeleton-tag skeleton-bar skeleton-bar-tag" />
                </div>
              </div>
            </div>

            <div v-else-if="interfaceCards.length" class="home-interface-list">
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
                  <el-tag
                    class="home-interface-status-tag"
                    :type="card.statusTagType || (card.online ? 'success' : 'danger')"
                  >
                    {{ card.statusText || (card.online ? '在线' : '离线') }}
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
    description: '组网的流量经过服务器中转, 其它流量固定走单条链路(不经过服务器)'
  },
  aggregate: {
    label: '聚合模式',
    description: '聚合多链路带宽'
  },
  balance: {
    label: '负载均衡',
    description: '并发的连接按链路权重分流'
  }
}

const DEFAULT_WORK_MODE_META = {
  label: '未知模式',
  description: '等待模式数据'
}

// 卡片显示顺序与在此数据中的顺序相同
const SERVICE_CARD_META = [
  { key: 'admin-backend', title: '管理平台' },
  { key: 'network-status', title: '组网状态' },
  { key: 'dhcp-status', title: 'DHCP服务器' },
  { key: 'dns-status', title: 'DNS服务' }
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
      interfaceStates: [],
      interfaceLoading: true,
      interfaceFetching: false,
      interfaceSnapshots: {},
      serial: null,
      version: null,
      workMode: '',
      // 工作模式设置
      workModeSettings: null,
      // DHCP地址池设置
      dhcpSettings: null,
      // DHCP租约状态
      dhcpLeases: [],
      // dns解析状态
      dnsStatusData: null,
      // openvpn组网状态
      openvpnStatus: null,
      // cpu温度
      cpuTemperature: null,
      // 当前时间
      currentTimeText: '',
      // 定时器
      clockTimer: null,
      // 是否定制刷新
      stopped: false,
      // 资源使用历史数据（用于sparkline曲线）
      usageHistory: { 'CPU温度': [], 'CPU使用率': [], '内存使用率': [] },
      // 管理平台IP
      serverIp: '',
      // 管理平台端口
      serverPort: null,
      // 管理平台连接状态
      serverTrackerStatus: null
    }
  },
  computed: {
    // CPU使用率
    cpuUsage() {
      if (this.cpuTimes.length < 2)
        return { cpu: 0 }

      const values = {}
      Object.keys(this.cpuTimes[0]).forEach(name => {
        values[name] = this.calcCpuUsage(this.cpuTimes[0][name], this.cpuTimes[1][name])
      })
      return values
    },
    // 内存使用率
    memUsage() {
      if (!this.sysinfo)
        return 0
      const memory = this.sysinfo.memory
      return parseFloat(((memory.total - memory.free) * 100 / memory.total).toFixed(2))
    },
    // 工作模式
    workModeMeta() {
      return WORK_MODE_META[this.workMode] || DEFAULT_WORK_MODE_META
    },
    // DHCP租约状态
    dhcpLeaseCount() {
      return Array.isArray(this.dhcpLeases) ? this.dhcpLeases.length : 0
    },
    // DHCP范围
    dhcpRangeText() {
      if (!this.dhcpSettings)
        return '未获取地址池'
      const start = this.formatIpv4Sections(this.dhcpSettings.dhcpStart)
      const end = this.formatIpv4Sections(this.dhcpSettings.dhcpEnd)
      if (start === '-' || end === '-')
        return '未配置地址池'
      return `${start} - ${end}`
    },
    // DHCP状态
    dhcpStatus() {
      if (!this.dhcpSettings)
        return {
          label: '待检测',
          subtitle: '正在获取 DHCP 配置'
        }
      return {
        label: '运行中',
        subtitle: `租约数 ${this.dhcpLeaseCount} / 地址池 ${this.dhcpRangeText}`
      }
    },
    // 网络接口状态
    interfaceCards() {
      if (this.interfaceStates.length) {
        return this.interfaceStates.map(card => ({
          ...card,
          statusClass: card.statusTagType ? 'is-status-' + card.statusTagType : (card.online ? 'is-online' : 'is-offline')
        }))
      }

      return []
    },
    // 组网状态
    networkingStatus() {
      const status = this.openvpnStatus
      if (!status) {
        return {
          label: '待检测',
          subtitle: '正在获取 OpenVPN 组网状态'
        }
      }

      const rx_bytes = Number.isFinite(Number(status.rx_bytes)) ? Number(status.rx_bytes) : 0
      const tx_bytes = Number.isFinite(Number(status.tx_bytes)) ? Number(status.tx_bytes) : 0
      const totalBytes = rx_bytes + tx_bytes
      const updated = status.updated ? `更新时间 ${status.updated}` : '未获取到更新时间'

      if (status.connected) {
        return {
          label: '组网已连接',
          subtitle: `上行: ${this.formatBytes(tx_bytes)} | 下行: ${this.formatBytes(rx_bytes)} | 总计: ${this.formatBytes(totalBytes)}`
        }
      }
      // 运行中, 但是未连接成功
      if (status.running) {
        return {
          label: '运行中,未连接',
          subtitle: '组网进程运行中, 但是尚未建立连接'
        }
      }

      return {
        label: '组网未启动',
        subtitle: status.updated ? `${status.msg || '组网进程未运行'} / ${updated}` : (status.msg || '组网进程未运行')
      }
    },
    // CPU温度
    cpuTemperatureText() {
      return this.cpuTemperature === null ? '-' : `${this.cpuTemperature}°C`
    },
    cpuTemperaturePercent() {
      if (this.cpuTemperature === null)
        return 0
      return Math.max(0, Math.min(100, this.cpuTemperature))
    },
    // 系统资源状态
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
    // 系统信息
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
        detail: this.workModeSettings?.detail || '等待工作模式配置'
      }
    },
    sharedServiceStatus() {
      return {
        value: this.dhcpStatus.label,
        subtitle: this.dhcpStatus.subtitle
      }
    },
    // DNS 服务器状态
    dnsServiceStatus() {
      const status = this.dnsStatusData
      // 获取DNS状态失败
      if (!status) {
        return {
          value: '检测中',
          subtitle: '正在获取 DNS 解析状态'
        }
      }
      // 进程未启动, 服务未运行
      if (!status.running) {
        return {
          value: '未启动',
          subtitle: status.msg || 'DNS 服务未运行'
        }
      }
      // 解析正常
      if (status.resolved) {
        return {
          value: '解析正常',
          subtitle: `正常: ${status.query} -> ${status.answer}`
        }
      }
      // 其它异常
      return {
        value: '解析异常',
        subtitle: status.msg || `${status.resolver || 'DNS'} 解析失败`
      }
    },
    // 管理平台状态: 聚合服务器 和 控制后台 是同一个
    serverStatus() {
      const addr = this.serverIp && this.serverPort ? `${this.serverIp}:${this.serverPort}` : (this.serverIp || '-')
      const tracker = this.serverTrackerStatus
      if (!tracker) {
        return {
          value: '检测中',
          subtitle: `地址: ${addr}`
        }
      }
      // 连接状态: OK/ERROR
      const status = String(tracker.status || '').trim().toUpperCase()
      // 异常信息
      const msg = String(tracker.msg || '').trim()
      // 连接正常
      if (status === 'OK') {
        return {
          value: '已连接',
          subtitle: `地址: ${addr}`
        }
      }
      // 连接异常
      return {
        value: '连接异常',
        subtitle: msg || `地址: ${addr}`
      }
    },
    serviceCards() {
      const statusMap = {
        'network-status': this.networkingStatus,
        'admin-backend': this.serverStatus,
        'dhcp-status': this.sharedServiceStatus,
        'dns-status': this.dnsServiceStatus
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
    createStatusCard(key, title, status) {
      return {
        key,
        title,
        value: status.value || status.label || '-',
        subtitle: status.subtitle || '',
        percentage: null
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
    getRsrpFromStatus(simStatus) {
      if (!simStatus || !simStatus.hcsq)
        return '-'
      let h = simStatus.hcsq
      if (typeof h === 'string') {
        try {
          h = JSON.parse(h)
        } catch {
          return '-'
        }
      }
      const sysmode = String(h.sysmode || '').toUpperCase()
      if (sysmode.indexOf('NR') !== -1 || sysmode.indexOf('LTE') !== -1) {
        if (h.rsrp_dbm)
          return String(h.rsrp_dbm)
      }
      // fallback to monsc cell rsrp
      if (simStatus.monsc && simStatus.monsc.cell && simStatus.monsc.cell.rsrp) {
        const m = String(simStatus.monsc.cell.rsrp).match(/-?\d+/)
        return m ? m[0] : '-'
      }
      return '-'
    },
    getRsrpLevel(rsrp) {
      if (rsrp === '-' || rsrp === '')
        return 0
      const n = parseFloat(rsrp)
      if (!Number.isFinite(n) || n >= 0)
        return 0
      if (n >= -80) return 4
      if (n >= -90) return 3
      if (n >= -100) return 2
      return 1
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
    // 网口 网络接口状态 (数据来自 home.getInterfaceOverview 聚合结果)
    buildWanInterfaceCard(link, index) {
      const section = link?.name ? String(link.name) : ''
      const iface = link?.device ? String(link.device) : ''
      const baseCard = this.buildDefaultInterfaceCard(link, index)
      const status = link.status || {}
      if (!section || !iface || status.code !== 0)
        return baseCard

      const ip = status.ip && status.ip !== '-' ? status.ip : ''
      return {
        key: section,
        name: section,
        ifname: iface || '-',
        ipv4: this.formatAddressWithMask(status.ip, status.mask),
        gateway: status.gateway && status.gateway !== '-' ? status.gateway : '-',
        rxBytes: status.rxBytes,
        txBytes: status.txBytes,
        online: status.status === '正常' || Boolean(ip)
      }
    },
    // sim卡 网络接口状态 (数据来自 home.getInterfaceOverview 聚合结果)
    buildSimInterfaceCard(link, index) {
      const settings = link.settings || {}
      const status = link.status || {}
      const simStatus = link.simStatus || {}
      const productInfo = link.product || {}

      const iface = settings.interface || status.interface || link.device || link.name || ''
      const ifname = settings.ifname || status.interface || link.device || '-'
      const ip = status.ip || ''

      // 解析 hcsq（可能是 JSON 字符串，聚合结果一般已是对象）
      let hcsq = simStatus.hcsq || null
      if (typeof hcsq === 'string') {
        try {
          hcsq = JSON.parse(hcsq)
        } catch {
          hcsq = null
        }
      }

      // 构建状态文本（与 network-wan 的 getStatusText 逻辑一致）
      let statusText = '离线'
      let statusTagType = 'danger'
      if (settings.enable === '0' || settings.enable === 'false') {
        statusText = '已禁用'
        statusTagType = 'danger'
      } else if (link.moduleExist === false) {
        // 模组未被系统识别(未安装模组 / 未上电)
        statusText = '模组不存在'
        statusTagType = 'danger'
      } else {
        const iccid = productInfo.iccid || ''
        if (iccid === '' || iccid === '-') {
          statusText = '未识别SIM卡'
          statusTagType = 'danger'
        } else if (hcsq && hcsq.sysmode === 'NOSERVICE') {
          statusText = '无服务'
          statusTagType = 'warning'
        } else if (ip && ip !== '-') {
          // 计算信号强度描述
          const rsrp = this.getRsrpFromStatus(simStatus)
          const rsrpLevel = this.getRsrpLevel(rsrp)
          const labels = { 4: '信号极好', 3: '信号良好', 2: '信号一般', 1: '信号差' }
          const signalLabel = labels[rsrpLevel] || ''
          statusText = signalLabel ? '在线 ' + signalLabel : '在线'
          statusTagType = 'success'
        } else {
          // 无 IP 时检查 SIM 卡状态
          const simState = (simStatus.sim || '').toUpperCase()
          if (simState && !simState.includes('NOT'))
            statusText = '拨号中...'
        }
      }

      const key = link?.name || iface || `sim${index}`
      return {
        key,
        name: settings.alias || link?.name || iface || `sim${index}`,
        ifname,
        ipv4: this.formatAddressWithMask(ip, status.mask),
        gateway: status.gateway || '-',
        rxBytes: status.rxBytes,
        txBytes: status.txBytes,
        online: Boolean(ip && ip !== '-'),
        statusText,
        statusTagType
      }
    },
    // 获取网络接口状态
    fetchInterfaceStates() {
      // 上一次请求尚未返回时跳过本轮, 避免请求堆积
      if (this.interfaceFetching)
        return
      this.interfaceFetching = true
      this.$oui.call('home', 'getInterfaceOverview').then((result) => {
        const data = this.parseRpcResult(result)
        const links = Array.isArray(data?.links) ? data.links : []

        if (!links.length) {
          this.interfaceStates = []
          return
        }

        const cards = links
          .map((link, index) => {
            if (link?.kind === 'sim')
              return this.buildSimInterfaceCard(link, index)
            return this.buildWanInterfaceCard(link, index)
          })
          .filter(Boolean)

        const now = Date.now()
        this.interfaceStates = cards.map(card => this.attachInterfaceStats(card, card.rxBytes, card.txBytes, now))
      }).catch(() => {
        this.interfaceStates = []
      }).finally(() => {
        this.interfaceLoading = false
        this.interfaceFetching = false
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
    workModeBalanceSettings() {
      return {
        detail: '不同链路按权重承载不同比例的连接数,同一连接的所有数据包始终走同一条链路'
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
        detail: `当前所有的流量都固定走 ${channel}(${ifname})`
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
          break
        case 'balance':
          this.workModeSettings = this.workModeBalanceSettings()
          break
        default:
          this.workModeSettings = result.settings || null
          break
        }
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
    // 获取DNS解析状态
    fetchDNSStatus() {
      this.$oui.call('home', 'getDNSStatus').then((result) => {
        if (this.stopped)
          return
        this.dnsStatusData = result || null
      }).catch(() => {
        if (this.stopped)
          return
        this.dnsStatusData = null
      })
    },
    // 获取DHCP租约状态
    fetchDhcpLeases() {
      this.$oui.call('network', 'dhcp_leases').then(({ leases }) => {
        this.dhcpLeases = Array.isArray(leases) ? leases : []
      }).catch(() => {
        this.dhcpLeases = []
      })
    },
    // 获取CPU温度
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
    },
    fetchServerIP() {
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (this.stopped)
          return
        if (ip)
          this.serverIp = Array.isArray(ip) ? String(ip[0] || '') : String(ip)
      }).catch(() => {})
    },
    fetchServerPort() {
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (this.stopped)
          return
        if (port)
          this.serverPort = parseInt(port, 10)
      }).catch(() => {})
    },
    fetchOpenVPNStatus() {
      this.$oui.call('home', 'getOpenVPNStatus').then((result) => {
        if (this.stopped)
          return
        this.openvpnStatus = result || null
      }).catch(() => {
        if (this.stopped)
          return
        this.openvpnStatus = null
      })
    },
    // 获取服务器状态
    fetchServerStatus() {
      this.$oui.call('home', 'getServerStatus').then((result) => {
        if (this.stopped)
          return
        this.serverTrackerStatus = result || null
      }).catch(() => {
        if (this.stopped)
          return
        this.serverTrackerStatus = null
      })
    },
    // 采集资源使用历史数据（用于sparkline曲线）
    collectUsageHistory() {
      const items = this.resourceUsageItems
      const samples = this.usageHistory
      items.forEach(item => {
        if (!samples[item.title])
          samples[item.title] = []
        const arr = samples[item.title]
        arr.push(item.percentage)
        if (arr.length > 50)
          arr.shift()
      })
    },
    getUsageMaxSamples() {
      return 50
    },
    // 生成资源使用sparkline曲线点坐标
    getUsageSparklinePoints(title) {
      const arr = this.usageHistory[title]
      if (!arr || arr.length < 2)
        return ''
      const range = this.getUsageSparklineRange(title)
      const startX = 0
      const endX = 96
      const topY = 4
      const bottomY = 26
      const width = endX - startX
      const height = bottomY - topY
      const maxSamples = this.getUsageMaxSamples()
      const stepX = width / Math.max(1, maxSamples - 1)
      const offset = maxSamples - arr.length
      return arr.map((v, i) => {
        const x = startX + (offset + i) * stepX
        const y = bottomY - ((v - range.min) / (range.range || 1)) * height
        return `${x.toFixed(1)},${y.toFixed(1)}`
      }).join(' ')
    },
    // 获取sparkline范围（用于坐标轴标注）
    getUsageSparklineRange(title) {
      const arr = this.usageHistory[title]
      if (!arr || arr.length === 0)
        return { min: 0, max: 100, range: 100 }
      const rawMin = Math.min(...arr)
      const rawMax = Math.max(...arr)
      const padding = Math.max(2, (rawMax - rawMin) * 0.2)
      const min = Math.max(0, rawMin - padding)
      const max = Math.min(100, rawMax + padding)
      return { min, max, range: max - min || 1 }
    }
  },
  created() {
    this.$timer.create('homeGetCpuTimes', this.getCpuTimes, { repeat: true, immediate: true, time: 3000 })
    this.$timer.create('homeGetSysinfo', this.getSysinfo, { repeat: true, immediate: true, time: 3000 })
    this.$timer.create('homeCollectUsageHistory', this.collectUsageHistory, { repeat: true, immediate: true, time: 3000 })
    this.$timer.create('homeGetInterfaceStates', this.fetchInterfaceStates, { repeat: true, immediate: true, time: 1000 })
    // 从uci配置文件中获取工作模式配置
    this.fetchWorkMode()
    this.$timer.create('homeGetDhcpSettings', this.fetchDHCPSettings, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetDNSStatus', this.fetchDNSStatus, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetDhcpLeases', this.fetchDhcpLeases, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetCpuTemperature', this.fetchCpuTemperature, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetOpenVPNStatus', this.fetchOpenVPNStatus, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetServerIP', this.fetchServerIP, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetServerPort', this.fetchServerPort, { repeat: true, immediate: true, time: 5000 })
    this.$timer.create('homeGetServerStatus', this.fetchServerStatus, { repeat: true, immediate: true, time: 5000 })

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
      try {
        const v = JSON.parse(r.stdout)
        this.version = 'V' + ([v.version, v.build_timestamp, v.commit].filter(Boolean).join('-') || '-')
      } catch {
        this.version = '-'
      }
    }).catch(() => {
      this.version = '-'
    })
  },
  beforeUnmount() {
    this.stopped = true
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

  /* 本地设计 token: 圆角/间距/字号/边框统一取值, 避免逐处硬编码 */
  --home-radius: 8px;
  --home-radius-sm: 6px;
  --home-gap: 16px;
  --home-font-title: 14px;
  --home-font-label: 13px;
  --home-font-minor: 12px;
  --home-font-metric: 26px;
  --home-font-metric-sm: 20px;
  --home-border: 1px solid var(--el-border-color-lighter);
}

.mode-card {
  width: 100%;
}

/* 页面容器: 仅作承载, 不设圆角/边框/阴影 */
.mode-panel {
  border: 0;
  border-radius: 0;
  box-shadow: none;
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
    'resource resource interface interface';
  gap: var(--home-gap);
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
  gap: var(--home-gap);
  /* 卡片按自身内容定高, 不被外层网格拉伸 */
  align-content: start;
  grid-area: status;
}

.home-interface-panel {
  grid-area: interface;
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
}

/* 指标卡: 一层浅边框 + 纯色底, 不使用渐变/投影/彩色装饰条 */
.home-metric-card,
.home-section-card {
  display: flex;
  flex-direction: column;
  padding: 16px;
  border: var(--home-border);
  border-radius: var(--home-radius);
  background: var(--el-bg-color);
}

.home-metric-card-primary {
  min-height: 168px;
}

/* 服务卡只有标题/数值/副标题三行, 压到约半高(168px -> 84px), 消除卡片内大片留白 */
.home-status-grid .home-metric-card-primary {
  min-height: 84px;
  padding: 10px 14px;
}

.home-status-grid .home-metric-title {
  line-height: 1.2;
}

.home-status-grid .home-metric-value {
  margin: 8px 0 2px;
  font-size: var(--home-font-metric-sm);
}

.home-status-grid .home-metric-subtitle {
  margin-top: 2px;
  line-height: 1.3;
}

.home-workmode-foot {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  margin-top: 18px;
  padding-top: 14px;
  border-top: var(--home-border);
}

.home-workmode-foot-value {
  flex: 1 1 auto;
  text-align: left;
  font-size: var(--home-font-label);
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
  font-size: var(--home-font-label);
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.home-resource-usage-sparkline {
  min-width: 0;
  padding: 1px 0;
}

.home-resource-usage-sparkline svg {
  display: block;
  width: 100%;
  height: 30px;
}

.home-resource-sparkline-bg {
  fill: var(--el-fill-color-lighter);
}

.home-resource-axis-line {
  stroke: var(--el-border-color);
  stroke-width: 0.8;
}

.home-resource-grid-line {
  stroke: var(--el-border-color-lighter);
  stroke-width: 0.65;
}

.home-resource-curve-line {
  stroke: var(--el-color-primary);
  stroke-width: 1.35;
}

.home-resource-usage-value {
  text-align: right;
  font-size: var(--home-font-label);
  font-weight: 700;
  color: var(--el-text-color-primary);
  font-variant-numeric: tabular-nums;
}

.home-resource-info-list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px 20px;
  margin-top: 18px;
  padding-top: 16px;
  border-top: var(--home-border);
}

.home-resource-info-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.home-resource-info-title {
  font-size: var(--home-font-label);
  color: var(--el-text-color-secondary);
}

.home-resource-info-value {
  text-align: right;
  font-size: var(--home-font-label);
  font-weight: 600;
  color: var(--el-text-color-primary);
  word-break: break-word;
}

.home-metric-title,
.home-section-title,
.home-interface-name {
  font-size: var(--home-font-title);
  font-weight: 600;
  color: var(--el-text-color-primary);
}

/* 网口名在表格列内居中, 卡片标题保持左对齐 */
.home-interface-name {
  text-align: center;
}

.home-metric-subtitle {
  margin-top: 4px;
  font-size: var(--home-font-label);
  color: var(--el-text-color-secondary);
}

.home-interface-ifname {
  margin-top: 2px;
  font-size: var(--home-font-minor);
  color: var(--el-text-color-secondary);
  text-align: center;
}

.home-metric-value {
  margin: 14px 0 6px;
  font-size: var(--home-font-metric);
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
  display: grid;
  grid-template-columns: 72px minmax(0, 1fr) 88px;
  align-items: center;
  column-gap: 8px;
  padding: 0 14px 2px;
}

.home-interface-summary-head {
  flex: 0 0 72px;
  font-size: var(--home-font-minor);
  font-weight: 600;
  color: var(--el-text-color-secondary);
  white-space: nowrap;
  text-align: center;
}

.home-interface-inline-fields-head {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
  flex: 1 1 auto;
}

.home-interface-inline-field-head,
.home-interface-status-head {
  font-size: var(--home-font-minor);
  font-weight: 600;
  color: var(--el-text-color-secondary);
  white-space: nowrap;
  text-align: center;
}

.home-interface-status-head {
  width: 100%;
}

/* 网口行: 状态色只取 el 语义色板, 不做渐变/内阴影 */
.home-interface-card {
  padding: 10px 14px;
  border: 1px solid transparent;
  border-radius: var(--home-radius);
  background: var(--el-fill-color-lighter);
  transition: border-color 0.2s ease, background-color 0.2s ease;
}

.home-interface-card.is-online,
.home-interface-card.is-status-success {
  border-color: var(--el-color-success-light-5);
  background: var(--el-color-success-light-9);
}

.home-interface-card.is-offline,
.home-interface-card.is-status-danger {
  border-color: var(--el-color-danger-light-5);
  background: var(--el-color-danger-light-9);
}

.home-interface-card.is-status-warning {
  border-color: var(--el-color-warning-light-5);
  background: var(--el-color-warning-light-9);
}

.home-interface-card.is-status-info {
  border-color: var(--el-border-color-lighter);
  background: var(--el-fill-color-light);
}

.home-interface-row {
  display: grid;
  grid-template-columns: 72px minmax(0, 1fr) 88px;
  align-items: center;
  column-gap: 8px;
}

.home-interface-summary {
  flex: 0 0 72px;
  min-width: 0;
  text-align: center;
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
  justify-content: center;
  width: 100%;
  min-width: 0;
  white-space: nowrap;
}

.home-interface-inline-field > .home-interface-value {
  width: 100%;
  text-align: center;
}

.home-interface-inline-field.is-grouped {
  display: grid;
  grid-template-columns: 14px auto;
  justify-content: center;
  justify-items: start;
  align-content: center;
  row-gap: 2px;
}

.home-interface-value-pair {
  display: contents;
}

.home-interface-subvalue-label {
  width: 14px;
  margin-right: 4px;
  font-size: var(--home-font-minor);
  color: var(--el-text-color-secondary);
  flex: 0 0 auto;
  text-align: center;
}

.home-interface-value-pair .home-interface-value {
  min-width: 0;
  white-space: nowrap;
  word-break: normal;
  overflow: hidden;
  text-overflow: ellipsis;
  text-align: left;
}

.home-interface-value {
  display: block;
  font-size: var(--home-font-label);
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.25;
  text-align: center;
  white-space: nowrap;
  word-break: normal;
  overflow: hidden;
  text-overflow: ellipsis;
}

.home-interface-status-tag {
  justify-self: center;
}

/* Skeleton loading: 保留流光动画(功能性加载反馈), 配色取自 el 填充色 */
.skeleton-bar {
  background: linear-gradient(90deg, var(--el-fill-color) 25%, var(--el-fill-color-light) 50%, var(--el-fill-color) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
  border-radius: var(--home-radius-sm);
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

.home-interface-loading {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.home-interface-skeleton {
  padding: 10px 14px;
  border: var(--home-border);
  border-radius: var(--home-radius);
  background: var(--el-fill-color-lighter);
}

.home-interface-skeleton-row {
  display: flex;
  align-items: center;
  gap: 16px;
}

.home-interface-skeleton-summary {
  flex: 0 0 120px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.home-interface-skeleton-name {
  height: 16px;
  width: 80px;
}

.skeleton-bar-short {
  width: 60px;
  height: 12px;
}

.home-interface-skeleton-fields {
  flex: 1;
  display: flex;
  gap: 20px;
}

.home-interface-skeleton-field {
  height: 16px;
  width: 64px;
}

.skeleton-bar-narrow {
  width: 48px;
}

.skeleton-bar-tag {
  width: 52px;
  height: 24px;
  border-radius: 999px;
}

.home-interface-skeleton-tag {
  flex-shrink: 0;
}

@media (max-width: 1024px) {
  .home-dashboard-grid,
  .home-status-grid {
    grid-template-columns: 1fr;
  }

  .home-dashboard-grid {
    grid-template-areas:
      'workmode'
      'status'
      'resource'
      'interface';
  }
}

@media (max-width: 768px) {
  .home-interface-row {
    flex-direction: column;
    align-items: flex-start;
    grid-template-columns: 1fr;
    row-gap: 8px;
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
