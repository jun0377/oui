<template>
  <div>
    <!-- 主页面 -->
    <div v-if="currentView === 'main'" class="container">
      <!-- 广域网链路 Section -->
      <div class="section">
        <div class="section-header">{{ $t('Wan Area') }}</div>
        <div class="section-content wan-section">
          <!-- 表头行 -->
          <div class="subnet-item">
            <div class="subnet-header-empty"></div>
            <div class="subnet-info-wan">
              <span>名称</span>
              <!-- <span>{{ $t('Interface') }}</span> -->
              <span>{{ $t('Operator') }}</span>
              <span>{{ $t('Real Network Access') }}</span>
              <span>APN</span>
              <span>{{ $t('Frequency Band') }}</span>
              <span>RSRP</span>
              <span class="status-column">{{ $t('Status') }}</span>
              <span> </span>
            </div>
          </div>

          <!-- 分割线 -->
          <hr />

          <!-- 数据行 -->
          <div class="subnet-item" v-for="(wan, index) in wanLinks" :key="index" @click="editSubWan(wan, index)">
            <svg class="subnet-icon-svg" viewBox="0 0 23 23" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- SIM卡外框 -->
              <path d="M6 3C5.44772 3 5 3.44772 5 4V20C5 20.5523 5.44772 21 6 21H18C18.5523 21 19 20.5523 19 20V8L14 3H6Z" fill="#DCFCE7" stroke="#22C55E" stroke-width="1.5"/>
              <!-- SIM卡切角 -->
              <path d="M14 3V7C14 7.55228 14.4477 8 15 8H19" fill="none" stroke="#22C55E" stroke-width="1.5"/>
              <!-- SIM标识 -->
              <text x="10" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#15803D">{{ index + 1 }}</text>
            </svg>
            <div class="subnet-info-wan">
              <span>{{ wan.settings.alias }}</span>
              <!-- <span>{{ wan.settings.interface }}</span> -->
              <span>{{ wan.sim.mcc }}{{ wan.sim.mnc }}</span>
              <span>{{ wan.status.rat }}</span>
              <span>{{ wan.settings.apn }}</span>
              <span>{{ getRealBandTypeText(index) }}</span>
              <span>{{ getRsrpText(index) }}</span>
              <span class="status-marquee"><span class="status-marquee-text">{{ getStstusText(index) }}</span></span>
              <span class="subnet-arrow">›</span>
            </div>
          </div>

        </div>
      </div>


      <!-- 流量图表曲线 -->
      <div class="section">
        <div class="section-header">
          <span>实时流量</span>
          <button class="traffic-refresh-btn" type="button" @click="refreshTrafficNow">刷新</button>
        </div>
        <div class="section-content">
          <div class="traffic-panes">
            <div class="traffic-pane">
              <div class="traffic-title">下行</div>
              <div class="traffic-chart">
                <svg class="traffic-svg" :viewBox="`0 0 ${traffic.width} ${traffic.height}`" preserveAspectRatio="none">
                  <polyline
                    v-for="(wan, index) in wanLinks"
                    :key="'rx-' + index"
                    :points="getTrafficPoints('rx', index)"
                    :style="getTrafficLineStyle(index)"
                  />
                  <line x1="0" :y1="traffic.height * 0.25" :x2="traffic.width" :y2="traffic.height * 0.25" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.24" class="traffic-label">{{ getTrafficLabel('rx', 0.75) }}</text>
                  <line x1="0" :y1="traffic.height * 0.50" :x2="traffic.width" :y2="traffic.height * 0.50" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.49" class="traffic-label">{{ getTrafficLabel('rx', 0.50) }}</text>
                  <line x1="0" :y1="traffic.height * 0.75" :x2="traffic.width" :y2="traffic.height * 0.75" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.74" class="traffic-label">{{ getTrafficLabel('rx', 0.25) }}</text>
                </svg>
              </div>
              <div class="traffic-scale">{{ getTrafficScaleText() }}</div>
            </div>

            <div class="traffic-pane">
              <div class="traffic-title">上行</div>
              <div class="traffic-chart">
                <svg class="traffic-svg" :viewBox="`0 0 ${traffic.width} ${traffic.height}`" preserveAspectRatio="none">
                  <polyline
                    v-for="(wan, index) in wanLinks"
                    :key="'tx-' + index"
                    :points="getTrafficPoints('tx', index)"
                    :style="getTrafficLineStyle(index)"
                  />
                  <line x1="0" :y1="traffic.height * 0.25" :x2="traffic.width" :y2="traffic.height * 0.25" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.24" class="traffic-label">{{ getTrafficLabel('tx', 0.75) }}</text>
                  <line x1="0" :y1="traffic.height * 0.50" :x2="traffic.width" :y2="traffic.height * 0.50" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.49" class="traffic-label">{{ getTrafficLabel('tx', 0.50) }}</text>
                  <line x1="0" :y1="traffic.height * 0.75" :x2="traffic.width" :y2="traffic.height * 0.75" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.74" class="traffic-label">{{ getTrafficLabel('tx', 0.25) }}</text>
                </svg>
              </div>
              <div class="traffic-scale">{{ getTrafficScaleText() }}</div>
            </div>
          </div>

          <div class="traffic-legend">
            <div class="traffic-legend-row traffic-legend-header">
              <div class="traffic-legend-cell">链路</div>
              <div class="traffic-legend-cell">下行带宽 / 总带宽占比</div>
              <div class="traffic-legend-cell">下行流量统计</div>
              <div class="traffic-legend-cell">上行带宽 / 总带宽占比</div>
              <div class="traffic-legend-cell">上行流量统计</div>
            </div>
            <div class="traffic-legend-row">
              <div class="traffic-legend-cell">
                <span class="traffic-legend-badge" :style="getTrafficBadgeStyle(-1)">总计</span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficTotal('rx', 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficTotal('rx', 'cur')) }}</span>
                  <!-- <span class="traffic-rate-pct">{{ formatPercent(getTrafficTotal('rx', 'cur'), getTrafficTotal('rx', 'cur')) }}</span> -->
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytesTotal('rx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytesTotal('rx')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficTotal('tx', 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficTotal('tx', 'cur')) }}</span>
                  <!-- <span class="traffic-rate-pct">{{ formatPercent(getTrafficTotal('tx', 'cur'), getTrafficTotal('tx', 'cur')) }}</span> -->
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytesTotal('tx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytesTotal('tx')) }}</span>
                </span>
              </div>
            </div>
            <div class="traffic-legend-row" v-for="(wan, index) in wanLinks" :key="'legend-' + index">
              <div class="traffic-legend-cell">
                <span class="traffic-legend-badge" :style="getTrafficBadgeStyle(index)">{{ wan.settings.alias || ('WAN' + (index + 1)) }}</span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficStat('rx', index, 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficStat('rx', index, 'cur')) }}</span>
                  <span class="traffic-rate-pct">{{ formatPercent(getTrafficStat('rx', index, 'cur'), getTrafficTotal('rx', 'cur')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytes(index, 'rx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytes(index, 'rx')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficStat('tx', index, 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficStat('tx', index, 'cur')) }}</span>
                  <span class="traffic-rate-pct">{{ formatPercent(getTrafficStat('tx', index, 'cur'), getTrafficTotal('tx', 'cur')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytes(index, 'tx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytes(index, 'tx')) }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>


      <!-- 局域网链路 Section（已注释/停用，保留代码） -->
      <template v-if="false">
        <div class="section">
          <div class="section-header">{{ $t('Lan Area') }}</div>
          <div class="section-content subnet-section">
            <div class="subnet-item" v-for="(lan, index) in subnets" :key="index" @click="editSubNet(lan)">
              <!-- 根据lan口名称显示网口图标或WiFi图标 -->
              <div v-if="lan.name && (lan.name.toLowerCase().includes('wireless'))">
                <svg class="subnet-icon-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <!-- WiFi图标 -->
                  <path d="M12 20h.01M8.5 16.5a7 7 0 0 1 7 0M5 13a12 12 0 0 1 14 0M1.5 9.5a18 18 0 0 1 21 0" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <circle cx="12" cy="20" r="1" fill="#000"/>
                </svg>
              </div>
              <div v-else>
                <!-- 网口图标 -->
                <svg class="subnet-icon-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <!-- 外框 -->
                  <rect x="2" y="2" width="20" height="20" rx="4" ry="4" fill="none" stroke="#000" stroke-width="2"/>
                  <!-- 网口主体 -->
                  <rect x="6" y="8" width="12" height="8" rx="1" ry="1" fill="#000"/>
                  <!-- 网口触点 -->
                  <rect x="7" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="9" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="11" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="13" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="15" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="16" y="10" width="1" height="4" fill="#fff"/>
                </svg>
              </div>
              <div class="subnet-info-lan">
                <span></span>
                <span>{{ $t(lan.name) }}</span>
                <span></span>
                <span></span>
                <span></span>
                <span></span>
                <span></span>
                <span></span>
                <span class="subnet-arrow">›</span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>

    <KeepAlive>
      <WanConfig v-if="currentView === 'wan-config'" :wan-data="selectedWan" @go-back="goBackToMain" />
    </KeepAlive>
    <DhcpConfig v-if="currentView === 'dhcp'" @go-back="goBackToMain" />
    <WirelessConfig v-if="currentView === 'wireless'" @go-back="goBackToMain" />
  </div>
</template>

<script>
import WanConfig from './wan.vue'
import DhcpConfig from './dhcp.vue'
import WirelessConfig from './wireless.vue'

const trafficMockDefault = typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.MODE === 'development'

export default {
  components: {
    WanConfig,
    DhcpConfig,
    WirelessConfig
  },
  data() {
    const createDefaultWanLink = (index) => {
      const aliasMap = {
        0: '5G-1',
        1: '5G-2',
        2: '5G-3',
        3: '有线网'
      }
      return {
        // uci配置文件
        settings: {
          index: index,
          enable: true,
          alias: aliasMap[index] || '',
          interface: '',
          net: '',
          band: '-',
          pcid: '-',
          apn: '',
          auth: '-',
          username: '-',
          password: '-'
        },
        // 模组基本信息
        productInfo: {
          vendor: '',
          product: '',
          revision: '',
          imei: '',
          iccid: '',
          imsi: ''
        },
        // sim卡基本信息
        sim: {
          operator: '',
          status: '',
          country: '',
          mcc: '',
          mnc: ''
        },
        // NR/LTE 工作频率信息
        freqInfo: {
          sysmode: '',
          class: []
        },
        // 5G Core注册状态
        NR_5GCore: {
          stat: '',
          tac: '',
          ci: '',
          act: ''
        },
        // CS域注册状态, 可用于反应LTE注册状态
        CS: {
          stat: '',
          lac: '',
          ci: '',
          act: ''
        },
        // 驻留小区信息
        monsc: {
          rat: '',
          nr:{
            cell_id:'',
            arfcn:'',
            scs:'',
            pci:'',
            tac:'',
            rsrp:'',
            rsrq:'',
            sinr:''
          },
          lte:{
            cell_id:'',
            arfcn:'',
            pci:'',
            tac:'',
            rsrp:'',
            rsrq:'',
            rssi:''
          },
          wcdma:{
            arfcn:'',
            pcs:'',
            cell_id:'',
            lac:'',
            rscp:'',
            rxlev:'',
            ecno:''
          }
        },
        // 相邻小区信息
        monnc: {
          gsm: [],
          wcdma: [],
          lte: [],
          nr: []
        },
        // 从模组中查到的配置
        realSettings:{
          // 入网设置
          rat:'',
          // pdp上下文
          pdp: {
            cid: '',
            pdp_type: '',
            apn: '',
            pdp_addr: ''
          },
          // 鉴权设置
          auth:{
            cid: '',
            auth_type: '',
            passwd: '',
            username: '',
            plmn: ''
          },
          // NR锁频段 锁频点 锁小区设置
          nrfreqlock:{
            operatetype: '',
            forbid_flag: '',
            num: '',
            band: [],
            arfcn: [],
            scstype: [],
            pci: []
          },
          // LTE锁频段 锁频点 锁小区配置
          ltefreqlock:{
            operatetype: '',
            forbid_flag: '',
            num: '',
            band: [],
            arfcn: [],
            pci: []
          }
        },
        // 基本状态
        status: {
          status: '',
          timestamp: '', // 状态更新时间戳
          rat: '-', // 实时入网方式
          // NR信号强度
          nr: {
            rsrp: '',
            rsrq: '',
            sinr: '',
            band: ''
          },
          // lte信号强度
          lte: {
            rsrp: '',
            rsrq: '',
            sinr: '',
            rssi: '',
            band: ''
          },
          // 网络接口信息
          interface: {
            ip: '-',
            mask: '-',
            gateway: '-',
            mac: '-',
            rxBytes: '-', // 接收流量
            txBytes: '-' // 发送流量
          }
        }
      }
    }
    return {
      currentView: 'main', // 'main' 或 'wan-config'
      selectedWan: null,
      selectedWanIndex: null,
      wanLinks: [
        createDefaultWanLink(0),
        createDefaultWanLink(1),
        createDefaultWanLink(2)
        // createDefaultWanLink(3)
      ],
      subnets: [
        {
          name: 'DHCP Service'
        },
        {
          name: 'Wireless Lan'
        }
      ],
      traffic: {
        width: 760,
        height: 300,
        step: 5,
        dataWanted: 152,
        intervalSec: 1,
        fillOpacity: 0.35,
        series: {
          rx: {},
          tx: {}
        },
        last: {}
      },
      trafficEnabled: true,
      trafficMock: trafficMockDefault,
      trafficMockScenario: trafficMockDefault ? 'skewed' : 'balanced',
      trafficMockTimer: null,
      trafficMockPhase: 0
    }
  },
  watch: {
    currentView() {
      this.updatePolling()
    },
    selectedWanIndex() {
      this.updatePolling()
    }
  },

  methods: {
    refreshTrafficNow() {
      if (this.currentView !== 'main' || !this.trafficEnabled)
        return

      this.resetTrafficSeries()

      if (this.trafficMock) {
        this.pushTrafficMockSample()
        this.startTrafficMock()
        return
      }

      this.wanLinks.forEach((_, index) => this.getInterfaceStatus(index))
      setTimeout(() => {
        if (this.currentView !== 'main' || !this.trafficEnabled)
          return
        this.wanLinks.forEach((_, index) => this.getInterfaceStatus(index))
      }, this.traffic.intervalSec * 1000)
    },
    resetTrafficSeries() {
      this.stopTrafficMock()
      const wanted = this.traffic.dataWanted
      this.wanLinks.forEach((_, index) => {
        this.traffic.series.rx[index] = Array.from({ length: wanted }, () => 0)
        this.traffic.series.tx[index] = Array.from({ length: wanted }, () => 0)
      })
      this.traffic.last = {}
      this.trafficMockPhase = 0
    },
    pushTrafficMockSample() {
      this.trafficMockPhase += 1
      const t = this.trafficMockPhase
      const wanted = this.traffic.dataWanted
      for (let index = 0; index < this.wanLinks.length; index += 1) {
        let rx
        let tx
        if (this.trafficMockScenario === 'skewed') {
          const rxMbitTargets = [1, 100, 20]
          const txMbitTargets = [0.5, 10, 3]
          const rxMbit = rxMbitTargets[index] || (5 + index * 2)
          const txMbit = txMbitTargets[index] || (2 + index)
          const rxBase = (rxMbit * 1024 * 1024) / 8
          const txBase = (txMbit * 1024 * 1024) / 8
          const rxWave = 0.9 + 0.1 * Math.sin((t / 8) + index)
          const txWave = 0.9 + 0.1 * Math.cos((t / 9) + index)
          rx = Math.max(0, rxBase * rxWave * (0.95 + Math.random() * 0.10))
          tx = Math.max(0, txBase * txWave * (0.95 + Math.random() * 0.10))
        } else {
          const rxMax = 6 * 1024 * 1024
          const txMax = 2 * 1024 * 1024
          const rxBase = (Math.sin((t / 10) + index) * 0.5 + 0.5) * rxMax
          const txBase = (Math.cos((t / 12) + index) * 0.5 + 0.5) * txMax
          rx = Math.max(0, rxBase * (0.6 + Math.random() * 0.4))
          tx = Math.max(0, txBase * (0.6 + Math.random() * 0.4))
        }
        this.traffic.series.rx[index].push(rx)
        this.traffic.series.tx[index].push(tx)
        if (this.traffic.series.rx[index].length > wanted) this.traffic.series.rx[index].shift()
        if (this.traffic.series.tx[index].length > wanted) this.traffic.series.tx[index].shift()
      }
    },
    updatePolling() {
      this._pollingToken = (this._pollingToken || 0) + 1
      this.stopAllPolling()

      if (this.currentView === 'main') {
        this.startPollingForIndexes([0, 1, 2], { status: true, interface: this.trafficEnabled })
        return
      }

      if (this.currentView === 'wan-config' && typeof this.selectedWanIndex === 'number') {
        this.startPollingForIndexes([this.selectedWanIndex], { status: true, product: true, modules: true, interface: true })
      }
    },
    startPollingForIndexes(indexes, plan) {
      indexes.forEach((index) => {
        if (plan.product) {
          this.$timer.start('sim-product' + index)
          this.getProductInfo(index)
        }
        if (plan.status) {
          this.$timer.start('sim-status' + index)
          this.getStatus(index)
        }
        if (plan.modules) {
          this.$timer.start('modules' + index)
          this.getModuleSettings(index)
        }
        if (plan.interface) {
          this.$timer.start('interface' + index)
          this.getInterfaceStatus(index)
        }
      })
    },
    stopAllPolling() {
      this.wanLinks.forEach((_, index) => {
        this.$timer.stop('sim-product' + index)
        this.$timer.stop('sim-status' + index)
        this.$timer.stop('modules' + index)
        this.$timer.stop('interface' + index)
      })
    },
    withInFlight(key, fn) {
      if (!this._inFlight)
        this._inFlight = {}
      if (this._inFlight[key])
        return
      this._inFlight[key] = true
      return Promise.resolve(fn()).finally(() => {
        this._inFlight[key] = false
      })
    },
    getStatusClass(status) {
      switch (status) {
      case 'connected': return 'status-connected'
      case 'disconnected': return 'status-disconnected'
      case 'dialing': return 'status-dialing'
      case 'nosim': return 'status-nosim'
      default: return ''
      }
    },
    getProductInfo(index) {
      return this.withInFlight('getProductInfo:' + index, () => {
        const token = this._pollingToken
        return this.$oui.call('sim', 'getProductInfo', { index }).then(result => {
          if (token !== this._pollingToken)
            return
          if (!(this.currentView === 'wan-config' && this.selectedWanIndex === index))
            return

          const data = typeof result === 'string' ? JSON.parse(result) : result
          const productInfo = this.wanLinks[index].productInfo
          if (data.vendor) productInfo.vendor = data.vendor
          if (data.product) productInfo.product = data.product
          if (data.revision) productInfo.revision = data.revision
          if (data.imei) productInfo.imei = data.imei
          if (data.iccid) productInfo.iccid = data.iccid
          if (data.imsi) productInfo.imsi = data.imsi
        })
      })
    },
    // 查询模组配置,是从模组中通过at指令查询到的配置,并不是uci配置
    getModuleSettings(index) {
      return this.withInFlight('getModuleSettings:' + index, () => {
        const token = this._pollingToken
        return this.$oui.call('sim', 'getModuleSettings', { index }).then(result => {
          if (token !== this._pollingToken)
            return
          if (!(this.currentView === 'wan-config' && this.selectedWanIndex === index))
            return

          const data = typeof result === 'string' ? JSON.parse(result) : result
          // console.log('data>>>>>>>>>>>', data)
          const real = this.wanLinks[index].realSettings
          if (data.rat) real.rat = data.rat
          if (data.pdp) {
            if (data.pdp.cid) real.pdp.cid = data.pdp.cid
            if (data.pdp.pdp_type) real.pdp.pdp_type = data.pdp.pdp_type
            if (data.pdp.apn) real.pdp.apn = data.pdp.apn
            if (data.pdp.pdp_addr) real.pdp.pdp_addr = data.pdp.pdp_addr
          }
          if (data.auth) {
            if (data.auth.cid) real.auth.cid = data.auth.cid
            if (data.auth.auth_type) real.auth.auth_type = data.auth.auth_type
            if (data.auth.passwd) real.auth.passwd = data.auth.passwd
            if (data.auth.username) real.auth.username = data.auth.username
            if (data.auth.plmn) real.auth.plmn = data.auth.plmn
          }
          if (data.nrfreqlock) {
            if (data.nrfreqlock.operatetype) real.nrfreqlock.operatetype = data.nrfreqlock.operatetype
            if (data.nrfreqlock.forbid_flag) real.nrfreqlock.forbid_flag = data.nrfreqlock.forbid_flag
            if (data.nrfreqlock.num) real.nrfreqlock.num = data.nrfreqlock.num
            if (data.nrfreqlock.band) real.nrfreqlock.band = data.nrfreqlock.band
            if (data.nrfreqlock.arfcn) real.nrfreqlock.arfcn = data.nrfreqlock.arfcn
            if (data.nrfreqlock.scstype) real.nrfreqlock.scstype = data.nrfreqlock.scstype
            if (data.nrfreqlock.pci) real.nrfreqlock.pci = data.nrfreqlock.pci
          }
          if (data.ltefreqlock) {
            if (data.ltefreqlock.operatetype) real.ltefreqlock.operatetype = data.ltefreqlock.operatetype
            if (data.ltefreqlock.forbid_flag) real.ltefreqlock.forbid_flag = data.ltefreqlock.forbid_flag
            if (data.ltefreqlock.num) real.ltefreqlock.num = data.ltefreqlock.num
            if (data.ltefreqlock.band) real.ltefreqlock.band = data.ltefreqlock.band
            if (data.ltefreqlock.arfcn) real.ltefreqlock.arfcn = data.ltefreqlock.arfcn
            if (data.ltefreqlock.pci) real.ltefreqlock.pci = data.ltefreqlock.pci
          }
        })
      })
    },
    getStatus(index) {
      return this.withInFlight('getStatus:' + index, () => {
        const token = this._pollingToken
        return this.$oui.call('sim', 'getStatus', { index }).then(result => {
          if (token !== this._pollingToken)
            return

          let data = result
          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              return
            }
          }

          const link = this.wanLinks[index]
          // SIM卡信息
          const sim = link.sim
          if (data.sim) sim.status = data.sim
          if (data.operator_name) sim.operator = data.operator_name
          if (data.country) sim.country = data.country
          if (data.mcc) sim.mcc = data.mcc
          if (data.mnc) sim.mnc = data.mnc
          const isDetail = this.currentView === 'wan-config' && this.selectedWanIndex === index
          const isMain = this.currentView === 'main'
          if (!isDetail && !isMain)
            return

          // NR/LTE频率频段信息
          if (data.freqInfo) {
            let freqInfo = data.freqInfo
            if (typeof freqInfo === 'string') {
              try {
                freqInfo = JSON.parse(freqInfo)
              } catch {
                freqInfo = null
              }
            }

            if (freqInfo) {
              const fi = link.freqInfo
              if (freqInfo.sysmode !== null && freqInfo.sysmode !== undefined)
                fi.sysmode = String(freqInfo.sysmode)

              const classes = freqInfo.class || freqInfo.classes || freqInfo.bands
              fi.class = Array.isArray(classes) ? classes : []
            }
          }

          {
            let c5 = data.C5GCore || data['5GCore']
            if (typeof c5 === 'string') {
              try {
                c5 = JSON.parse(c5)
              } catch {
                c5 = null
              }
            }
            if (c5) {
              if (c5.stat) link.NR_5GCore.stat = c5.stat
              if (c5.tac) link.NR_5GCore.tac = c5.tac
              if (c5.ci) link.NR_5GCore.ci = c5.ci
              if (c5.act) link.NR_5GCore.act = c5.act
            }
          }

          // CS域注册状态
          {
            let cs = data.C4GCore || data['4GCore']
            if (typeof cs === 'string') {
              try {
                cs = JSON.parse(cs)
              } catch {
                cs = null
              }
            }
            if (cs) {
              if (cs.stat) link.CS.stat = cs.stat
              if (cs.lac) link.CS.lac = cs.lac
              if (cs.ci) link.CS.ci = cs.ci
              if (cs.act) link.CS.act = cs.act
            }
          }

          // NR/LTE信号强度
          if (data.monsc) {
            const monsc = data.monsc
            const status = link.status
            if (data.monsc.rat) status.rat = data.monsc.rat
            if (data.timestamp) status.timestamp = data.timestamp
            if (monsc.nr) {
              if (monsc.nr.rsrp) status.nr.rsrp = monsc.nr.rsrp
              if (monsc.nr.rsrq) status.nr.rsrq = monsc.nr.rsrq
              if (monsc.nr.sinr) status.nr.sinr = monsc.nr.sinr
              if (monsc.nr.band) status.nr.band = monsc.nr.band
            }
            if (monsc.lte) {
              if (monsc.lte.rsrp) status.lte.rsrp = monsc.lte.rsrp
              if (monsc.lte.rsrq) status.lte.rsrq = monsc.lte.rsrq
              if (monsc.lte.sinr) status.lte.sinr = monsc.lte.sinr
              if (monsc.lte.rssi) status.lte.rssi = monsc.lte.rssi
              if (monsc.lte.band) status.lte.band = monsc.lte.band
            }

            if (isDetail) {
              const newest = link.monsc
              // 驻留小区信息
              if (monsc.rat) newest.rat = monsc.rat
              // NR驻留小区信息
              if (monsc.nr) {
                if (monsc.nr.cell_id) newest.nr.cell_id = monsc.nr.cell_id
                if (monsc.nr.arfcn) newest.nr.arfcn = monsc.nr.arfcn
                if (monsc.nr.scs) newest.nr.scs = monsc.nr.scs
                if (monsc.nr.pci) newest.nr.pci = monsc.nr.pci
                if (monsc.nr.tac) newest.nr.tac = monsc.nr.tac
                if (monsc.nr.rsrp) newest.nr.rsrp = monsc.nr.rsrp
                if (monsc.nr.rsrq) newest.nr.rsrq = monsc.nr.rsrq
                if (monsc.nr.sinr) newest.nr.sinr = monsc.nr.sinr
              }
              // LTE驻留小区信息
              if (monsc.lte) {
                if (monsc.lte.cell_id) newest.lte.cell_id = monsc.lte.cell_id
                if (monsc.lte.arfcn) newest.lte.arfcn = monsc.lte.arfcn
                if (monsc.lte.pci) newest.lte.pci = monsc.lte.pci
                if (monsc.lte.tac) newest.lte.tac = monsc.lte.tac
                if (monsc.lte.rsrp) newest.lte.rsrp = monsc.lte.rsrp
                if (monsc.lte.rsrq) newest.lte.rsrq = monsc.lte.rsrq
                if (monsc.lte.rssi) newest.lte.rssi = monsc.lte.rssi
              }
              // WCDMA驻留小区信息
              if (monsc.wcdma) {
                if (monsc.wcdma.cell_id) newest.wcdma.cell_id = monsc.wcdma.cell_id
                if (monsc.wcdma.arfcn) newest.wcdma.arfcn = monsc.wcdma.arfcn
                if (monsc.wcdma.pcs) newest.wcdma.pcs = monsc.wcdma.pcs
                if (monsc.wcdma.lac) newest.wcdma.lac = monsc.wcdma.lac
                if (monsc.wcdma.rscp) newest.wcdma.rscp = monsc.wcdma.rscp
                if (monsc.wcdma.rxlev) newest.wcdma.rxlev = monsc.wcdma.rxlev
                if (monsc.wcdma.ecno) newest.wcdma.ecno = monsc.wcdma.ecno
              }
              // 更新驻留小区信息
              if (data.monnc) {
                const monnc = link.monnc
                if (data.monnc.gsm) monnc.gsm = data.monnc.gsm
                if (data.monnc.wcdma) monnc.wcdma = data.monnc.wcdma
                if (data.monnc.lte) monnc.lte = data.monnc.lte
                if (data.monnc.nr) monnc.nr = data.monnc.nr
              }
            }
          }
        }).catch(err => {
          console.warn('getStatus failed for index', index, err)
        })
      })
    },
    // 获取网络接口信息
    getInterfaceStatus(index) {
      return this.withInFlight('getInterfaceStatus:' + index, () => {
        const token = this._pollingToken
        return this.$oui.call('sim', 'getInterfaceStatus', { index }).then(result => {
          if (token !== this._pollingToken)
            return
          if (!((this.currentView === 'wan-config' && this.selectedWanIndex === index) || (this.currentView === 'main' && this.trafficEnabled)))
            return

          const data = typeof result === 'string' ? JSON.parse(result) : result
          const inter = this.wanLinks[index].status.interface
          if (data.ip) inter.ip = data.ip
          if (data.mask) inter.mask = data.mask
          if (data.gateway) inter.gateway = data.gateway
          if (data.mac) inter.mac = data.mac
          if (data.rxBytes) inter.rxBytes = data.rxBytes
          if (data.txBytes) inter.txBytes = data.txBytes

          this.recordTrafficSample(index, data.rxBytes, data.txBytes)
        })
      })
    },
    initTrafficSeries() {
      const wanted = this.traffic.dataWanted
      this.wanLinks.forEach((_, index) => {
        if (!this.traffic.series.rx[index]) this.traffic.series.rx[index] = Array.from({ length: wanted }, () => 0)
        if (!this.traffic.series.tx[index]) this.traffic.series.tx[index] = Array.from({ length: wanted }, () => 0)
      })
    },
    startTrafficMock() {
      if (!this.trafficMock || !this.trafficEnabled)
        return
      this.stopTrafficMock()
      this.initTrafficSeries()
      this.trafficMockTimer = setInterval(() => {
        if (!this.trafficEnabled || this.currentView !== 'main')
          return
        this.trafficMockPhase += 1
        const t = this.trafficMockPhase
        const wanted = this.traffic.dataWanted
        for (let index = 0; index < this.wanLinks.length; index += 1) {
          let rx
          let tx
          if (this.trafficMockScenario === 'skewed') {
            const rxMbitTargets = [1, 100, 20]
            const txMbitTargets = [0.5, 10, 3]
            const rxMbit = rxMbitTargets[index] || (5 + index * 2)
            const txMbit = txMbitTargets[index] || (2 + index)
            const rxBase = (rxMbit * 1024 * 1024) / 8
            const txBase = (txMbit * 1024 * 1024) / 8
            const rxWave = 0.9 + 0.1 * Math.sin((t / 8) + index)
            const txWave = 0.9 + 0.1 * Math.cos((t / 9) + index)
            rx = Math.max(0, rxBase * rxWave * (0.95 + Math.random() * 0.10))
            tx = Math.max(0, txBase * txWave * (0.95 + Math.random() * 0.10))
          } else {
            const rxMax = 6 * 1024 * 1024
            const txMax = 2 * 1024 * 1024
            const rxBase = (Math.sin((t / 10) + index) * 0.5 + 0.5) * rxMax
            const txBase = (Math.cos((t / 12) + index) * 0.5 + 0.5) * txMax
            rx = Math.max(0, rxBase * (0.6 + Math.random() * 0.4))
            tx = Math.max(0, txBase * (0.6 + Math.random() * 0.4))
          }
          this.traffic.series.rx[index].push(rx)
          this.traffic.series.tx[index].push(tx)
          if (this.traffic.series.rx[index].length > wanted) this.traffic.series.rx[index].shift()
          if (this.traffic.series.tx[index].length > wanted) this.traffic.series.tx[index].shift()
        }
      }, this.traffic.intervalSec * 1000)
    },
    stopTrafficMock() {
      if (this.trafficMockTimer) {
        clearInterval(this.trafficMockTimer)
        this.trafficMockTimer = null
      }
    },
    normalizeBytes(value) {
      if (value === null || value === undefined)
        return null
      const n = Number(value)
      return Number.isFinite(n) ? n : null
    },
    recordTrafficSample(index, rxBytes, txBytes) {
      if (!this.trafficEnabled || this.currentView !== 'main')
        return
      const now = Date.now()
      const rx = this.normalizeBytes(rxBytes)
      const tx = this.normalizeBytes(txBytes)
      if (rx === null || tx === null)
        return
      if (this.trafficMockTimer)
        this.stopTrafficMock()
      const last = this.traffic.last[index]
      this.traffic.last[index] = { rxBytes: rx, txBytes: tx, ts: now }
      if (!last || !last.ts)
        return
      const dt = (now - last.ts) / 1000
      if (!(dt > 0))
        return
      const rxBps = (rx - last.rxBytes) / dt
      const txBps = (tx - last.txBytes) / dt
      if (!(Number.isFinite(rxBps) && Number.isFinite(txBps)))
        return
      if (!this.traffic.series.rx[index] || !this.traffic.series.tx[index])
        this.initTrafficSeries()
      this.traffic.series.rx[index].push(Math.max(0, rxBps))
      this.traffic.series.tx[index].push(Math.max(0, txBps))
      if (this.traffic.series.rx[index].length > this.traffic.dataWanted) this.traffic.series.rx[index].shift()
      if (this.traffic.series.tx[index].length > this.traffic.dataWanted) this.traffic.series.tx[index].shift()
    },
    getTrafficColor(index) {
      const colors = ['#e41a1c', '#377eb8', '#4daf4a', '#ff7f00', '#984ea3', '#f781bf', '#a65628']
      return colors[index % colors.length]
    },
    getTrafficLineStyle(index) {
      const color = this.getTrafficColor(index)
      return `fill:${color};fill-opacity:${this.traffic.fillOpacity};stroke:black;stroke-width:0.15;stroke-linejoin:round;stroke-linecap:round`
    },
    hexToRgba(hex, alpha) {
      const raw = String(hex || '').replace('#', '')
      const a = Number(alpha)
      const opacity = Number.isFinite(a) ? Math.min(1, Math.max(0, a)) : 1
      if (raw.length === 3) {
        const r = parseInt(raw[0] + raw[0], 16)
        const g = parseInt(raw[1] + raw[1], 16)
        const b = parseInt(raw[2] + raw[2], 16)
        return `rgba(${r},${g},${b},${opacity})`
      }
      if (raw.length >= 6) {
        const r = parseInt(raw.slice(0, 2), 16)
        const g = parseInt(raw.slice(2, 4), 16)
        const b = parseInt(raw.slice(4, 6), 16)
        return `rgba(${r},${g},${b},${opacity})`
      }
      return `rgba(0,0,0,${opacity})`
    },
    getTrafficFillColor(index) {
      const color = index === -1 ? '#ff7f00' : this.getTrafficColor(index)
      return this.hexToRgba(color, this.traffic.fillOpacity)
    },
    getTrafficBadgeStyle(index) {
      return {
        backgroundColor: this.getTrafficFillColor(index),
        border: '1px solid rgba(0,0,0,0.15)'
      }
    },
    getTrafficMax(direction) {
      let max = 0
      this.wanLinks.forEach((_, index) => {
        const s = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
        if (!Array.isArray(s))
          return
        for (let i = 0; i < s.length; i += 1) {
          const v = s[i]
          if (v > max) max = v
        }
      })
      return max > 1 ? max : 1
    },
    getTrafficLabel(direction, ratio) {
      const max = this.getTrafficMax(direction)
      return this.formatTraffic(max * ratio)
    },
    getTrafficScaleText() {
      const minutes = Math.round((this.traffic.dataWanted * this.traffic.intervalSec) / 60)
      return `(${minutes} minutes window, ${this.traffic.intervalSec} seconds interval)`
    },
    smoothTrafficSeries(series) {
      const n = series.length
      const out = new Array(n)
      for (let i = 0; i < n; i += 1) {
        let sum = 0
        let count = 0
        for (let j = i - 2; j <= i + 2; j += 1) {
          if (j < 0 || j >= n)
            continue
          sum += series[j]
          count += 1
        }
        out[i] = count ? (sum / count) : series[i]
      }
      return out
    },
    getTrafficPoints(direction, index) {
      const series = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
      if (!Array.isArray(series) || !series.length)
        return ''
      const smooth = this.smoothTrafficSeries(series)
      const max = this.getTrafficMax(direction)
      const h = this.traffic.height
      const w = this.traffic.width
      const step = this.traffic.step
      const points = []
      for (let i = 0; i < smooth.length; i += 1) {
        const x = i * step
        const y = h - (smooth[i] / max) * h
        points.push(`${x},${y.toFixed(2)}`)
      }
      points.push(`${w},${h}`)
      points.push(`0,${h}`)
      return points.join(' ')
    },
    getTrafficStat(direction, index, type) {
      const series = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
      if (!Array.isArray(series) || !series.length)
        return 0
      if (type === 'cur')
        return series[series.length - 1] || 0
      if (type === 'peak') {
        let max = 0
        for (let i = 0; i < series.length; i += 1) {
          if (series[i] > max) max = series[i]
        }
        return max
      }
      let sum = 0
      for (let i = 0; i < series.length; i += 1)
        sum += series[i]
      return sum / series.length
    },
    getTrafficTotal(direction, type) {
      let total = 0
      for (let i = 0; i < this.wanLinks.length; i += 1)
        total += this.getTrafficStat(direction, i, type)
      return total
    },
    formatTraffic(bytesPerSec) {
      const bytes = Math.max(0, Number(bytesPerSec) || 0)
      const kby = bytes / 1024
      const kbi = (bytes * 8) / 1024
      const byUnit = kby >= 1024 ? 'MB/s' : 'KB/s'
      const biUnit = kbi >= 1024 ? 'Mbit/s' : 'Kbit/s'
      const byValue = kby >= 1024 ? (kby / 1024) : kby
      const biValue = kbi >= 1024 ? (kbi / 1024) : kbi
      return `${biValue.toFixed(2)} ${biUnit} (${byValue.toFixed(2)} ${byUnit})`
    },
    calcRate(bytesPerSec) {
      const bytes = Math.max(0, Number(bytesPerSec) || 0)
      const kbi = (bytes * 8) / 1024
      if (kbi >= 1024)
        return { value: (kbi / 1024), unit: 'Mbit/s' }
      return { value: kbi, unit: 'Kbit/s' }
    },
    formatRateValue(bytesPerSec) {
      return this.calcRate(bytesPerSec).value.toFixed(2)
    },
    formatRateUnit(bytesPerSec) {
      return this.calcRate(bytesPerSec).unit
    },
    formatPercent(value, total) {
      const v = Number(value)
      const t = Number(total)
      if (!(Number.isFinite(v) && Number.isFinite(t)) || t <= 0)
        return '-'
      const p = Math.round((v / t) * 100)
      return `${Math.min(100, Math.max(0, p))}%`
    },
    getInterfaceBytes(index, dir) {
      const link = this.wanLinks && this.wanLinks[index]
      const inter = link && link.status && link.status.interface
      const raw = dir === 'tx' ? (inter && inter.txBytes) : (inter && inter.rxBytes)
      const n = Number(raw)
      return Number.isFinite(n) ? n : null
    },
    getInterfaceBytesTotal(dir) {
      let total = 0
      let has = false
      for (let i = 0; i < this.wanLinks.length; i += 1) {
        const v = this.getInterfaceBytes(i, dir)
        if (v === null)
          continue
        total += v
        has = true
      }
      return has ? total : null
    },
    formatBytes(bytes) {
      const n = Number(bytes)
      if (!Number.isFinite(n) || n < 0)
        return '-'
      const units = ['B', 'KB', 'MB', 'GB', 'TB']
      let v = n
      let u = 0
      while (v >= 1024 && u < units.length - 1) {
        v /= 1024
        u += 1
      }
      const digits = u === 0 ? 0 : 2
      return `${v.toFixed(digits)} ${units[u]}`
    },
    calcBytes(bytes) {
      const n = Number(bytes)
      if (!Number.isFinite(n) || n < 0)
        return null
      const units = ['B', 'KB', 'MB', 'GB', 'TB']
      let v = n
      let u = 0
      while (v >= 1024 && u < units.length - 1) {
        v /= 1024
        u += 1
      }
      const digits = u === 0 ? 0 : 2
      return { value: v.toFixed(digits), unit: units[u] }
    },
    formatBytesValue(bytes) {
      const r = this.calcBytes(bytes)
      return r ? r.value : '-'
    },
    formatBytesUnit(bytes) {
      const r = this.calcBytes(bytes)
      return r ? r.unit : ''
    },
    getStstusText(index) {
      let stat = ''
      if (this.wanLinks[index].NR_5GCore.stat !== '')
        stat = stat + 'NR' + this.wanLinks[index].NR_5GCore.stat

      if (this.wanLinks[index].CS.stat !== '')
        stat = stat + ' | LTE' + this.wanLinks[index].CS.stat

      return stat
    },
    getSimSettings(index) {
      this.$oui.call('sim', 'getSimUciSettings', { index }).then(result => {
        const data = typeof result === 'string' ? JSON.parse(result) : result
        const settings = this.wanLinks[index].settings

        settings.index = index
        if (data.alias) settings.alias = data.alias
        if (data.enable) settings.enable = data.enable === '1' || data.enable === 1 || data.enable === true
        if (data.usb) settings.usb = data.usb
        if (data.node) settings.node = data.node
        if (data.interface) settings.interface = data.interface
        if (data.band) settings.band = data.band
        if (data.pci) settings.pcid = data.pci
        if (data.net) settings.net = data.net
        if (data.apn) settings.apn = data.apn
        if (data.auth) settings.auth = data.auth
        if (data.user) settings.username = data.user
        if (data.passwd) settings.password = data.passwd
        if (data.dhcpRangeStart) settings.dhcpRanageStart = data.dhcpRangeStart
        if (data.dhcpRangeEnd) settings.dhcpRanageEnd = data.dhcpRangeEnd
        if (data.dhcpRangeMask) settings.dhcpRanageMask = data.dhcpRangeMask
        if (data.dhcpRangeGateway) settings.dhcpRanageGateway = data.dhcpRangeGateway
      })
    },
    // 从freqInfo中解析出频段信息
    getRealBandTypeText(index) {
      const link = this.wanLinks[index]
      const fi = link && link.freqInfo
      if (!fi)
        return ''

      const sysmode = String(fi.sysmode ?? '').trim().toUpperCase()
      let isNr = false
      let isLte = false

      if (sysmode.includes('NR')) {
        isNr = true
      } else if (sysmode.includes('LTE')) {
        isLte = true
      } else if (sysmode === '7') {
        isNr = true
      } else if (sysmode === '3') {
        isLte = true
      }

      if (!isNr && !isLte) {
        const rat = String(link?.status?.rat ?? '').toUpperCase()
        if (rat.includes('LTE'))
          isLte = true
        else if (rat.includes('NR'))
          isNr = true
      }

      if (!isNr && !isLte)
        return ''

      const list = Array.isArray(fi.class) ? fi.class : []
      const seen = new Set()
      const prefix = isNr ? 'n' : 'b'
      const bands = []

      for (const item of list) {
        const bandClass = item && item.band_class !== null && item.band_class !== undefined ? String(item.band_class).trim() : ''
        if (!bandClass)
          continue
        if (seen.has(bandClass))
          continue
        seen.add(bandClass)
        bands.push(prefix + bandClass)
      }

      return bands.join(' ')
    },
    getRsrpText(index) {
      const link = this.wanLinks[index]
      if (!link || !link.status)
        return '-'

      const nr = link.status.nr && link.status.nr.rsrp !== null && link.status.nr.rsrp !== undefined ? String(link.status.nr.rsrp).trim() : ''
      const lte = link.status.lte && link.status.lte.rsrp !== null && link.status.lte.rsrp !== undefined ? String(link.status.lte.rsrp).trim() : ''

      const nrNum = Number(nr)
      const hasNr = nr !== '' && Number.isFinite(nrNum) && nrNum !== 0
      if (hasNr)
        return nr

      return lte !== '' ? lte : '-'
    },
    // 切换到WAN配置页面
    editSubWan(wan, index) {
      this.selectedWan = wan
      this.selectedWanIndex = index
      this.currentView = 'wan-config'
    },
    // 返回主页面
    goBackToMain() {
      this.currentView = 'main'
      this.selectedWan = null
      this.selectedWanIndex = null
    },
    editSubNet(lan) {
      if (lan.name === 'DHCP Service') {
        this.currentView = 'dhcp'
      } else if (lan.name === 'Wireless Lan') {
        this.currentView = 'wireless'
      } else {
        alert('修改LAN设置: ' + lan.name)
      }
    }
  },
  created() {
    this.initTrafficSeries()
    this.startTrafficMock()
    this.wanLinks.forEach((_, index) => this.getSimSettings(index))

    this.wanLinks.forEach((wan, index) => {
      this.$timer.create('sim-product' + index, () => this.getProductInfo(index), { time: 15000, repeat: true, autostart: false })
      this.$timer.create('sim-status' + index, () => this.getStatus(index), { time: 10000, repeat: true, autostart: false })
      this.$timer.create('modules' + index, () => this.getModuleSettings(index), { time: 12000, repeat: true, autostart: false })
      this.$timer.create('interface' + index, () => this.getInterfaceStatus(index), { time: 1000, repeat: true, autostart: false })
    })

    this.updatePolling()
  },
  beforeUnmount() {
    this.stopTrafficMock()
  }
}
</script>

<style>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.section {
  border-radius: 8px;
  margin-bottom: 20px;
  overflow: hidden;
  border: 1px var(--el-border-color) var(--el-border-style);
}

.section-header {
  padding: 15px 20px;
  border-bottom: 1px solid var(--el-border-color);
  font-size: 16px;
  font-weight: 500;
  color: var(--el-text-color-primary);
  background-color: var(--el-fill-color-light);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.section-content {
  padding: 20px;
  background-color: var(--el-bg-color);
}

.wan-section {
  min-height: 80px;
}

.subnet-section {
  min-height: 120px;
}

.traffic-title {
  font-weight: 600;
  margin-bottom: 10px;
}

.traffic-refresh-btn {
  height: 28px;
  padding: 0 12px;
  border-radius: 6px;
  border: 1px solid var(--el-border-color);
  background: var(--el-bg-color);
  color: var(--el-text-color-primary);
  cursor: pointer;
  font-size: 13px;
}

.traffic-refresh-btn:hover {
  background: var(--el-fill-color-light);
}

.traffic-panes {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.traffic-pane {
  min-width: 0;
}

.traffic-chart {
  width: 100%;
  height: 300px;
  border: 1px solid #000;
  background-color: #fff;
}

.traffic-svg {
  width: 100%;
  height: 300px;
  display: block;
}

.traffic-label {
  fill: #333;
  font-size: 9pt;
  font-family: sans-serif;
}

.traffic-scale {
  text-align: right;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin: 6px 0 10px;
}

.traffic-legend {
  margin-top: 16px;
  overflow-x: hidden;
}

.traffic-legend-row {
  display: grid;
  grid-template-columns: 140px 220px 140px 220px 140px;
  gap: 8px;
  align-items: center;
  min-width: 0;
  padding: 4px 0;
}

.traffic-legend-header {
  font-weight: 600;
  color: var(--el-text-color-secondary);
}

.traffic-legend-cell {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
}

.traffic-rate {
  display: inline-grid;
  grid-template-columns: 6ch 6ch 4ch;
  column-gap: 6px;
  align-items: baseline;
  font-family: 'Courier New', monospace;
  font-variant-numeric: tabular-nums;
}

.traffic-rate-value {
  text-align: right;
}

.traffic-rate-unit {
  text-align: left;
}

.traffic-rate-pct {
  text-align: right;
}

.traffic-bytes {
  display: inline-grid;
  grid-template-columns: 7ch 3ch;
  column-gap: 6px;
  align-items: baseline;
  font-family: 'Courier New', monospace;
  font-variant-numeric: tabular-nums;
}

.traffic-bytes-value {
  text-align: right;
}

.traffic-bytes-unit {
  text-align: left;
}

.traffic-legend-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 64px;
  padding: 1px 8px;
  border-radius: 4px;
  color: #fff;
  font-weight: 600;
  line-height: 18px;
}

@media (max-width: 900px) {
  .traffic-panes {
    grid-template-columns: 1fr;
  }
}

.subnet-item {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  border-radius: 6px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: background-color 0.2s;
  color: var(--el-text-color-primary);
}

.subnet-item:hover {
  background-color: var(--el-fill-color-light);
}

.subnet-icon-svg {
  width: 20px;
  height: 20px;
  margin-right: 12px;
  flex-shrink: 0;
}

.subnet-header-icon {
  width: 12px;
  height: 12px;
  background-color: var(--el-color-primary);
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-header-empty {
  width: 12px;
  height: 12px;
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-info {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.subnet-info-lan {
  flex: 1;
  display: grid;
  grid-template-columns: 0.5fr 2fr 1fr 1fr 1fr 1fr 1fr 1fr 0.5fr;
  gap: 10px;
  align-items: center;
  width: 100%;
}

.subnet-info-wan {
  flex: 1;
  display: grid;
  grid-template-columns: 0.5fr 0.5fr 1fr 1fr 1fr 1fr 1fr 1fr 0.5fr;
  gap: 10px;
  align-items: center;
  width: 100%;
}

.subnet-info-wan span {
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-column {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.status-marquee {
  position: relative;
  overflow: hidden;
  text-overflow: clip;
  white-space: nowrap;
}

.status-marquee-text {
  display: inline-block;
  padding-left: 100%;
  animation: status-marquee 6s linear infinite;
}

@keyframes status-marquee {
  0% {
    transform: translateX(0);
  }
  100% {
    transform: translateX(-100%);
  }
}

.subnet-ip {
  font-family: 'Courier New', monospace;
  font-size: 14px;
}

.subnet-arrow {
  color: var(--el-text-color-secondary);
  font-size: 18px;
}

.empty-state {
  text-align: center;
  color: var(--el-text-color-secondary);
  padding: 40px 20px;
  font-size: 14px;
}

.add-button {
  background-color: var(--el-color-primary);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.2s;
}

.add-button:hover {
  background-color: var(--el-color-primary-light-3);
}

.status-text {
  font-weight: 500;
  font-size: 14px;
}

.status-text.status-connected {
  color: var(--el-color-success);
  animation: blink 1s infinite linear;
  animation-delay: 0s;
}

.status-text.status-disconnected {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
  animation-delay: 0.25s;
}

.status-text.status-dialing {
  color: var(--el-color-warning);
  animation: blink 1s infinite linear;
  animation-delay: 0.50s;
}

.status-text.status-nosim {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
  animation-delay: 0.75s;
}

@keyframes blink {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 1;
  }
  50.1% {
    opacity: 0.3;
  }
  100% {
    opacity: 0.3;
  }
}

</style>

<i18n src="./locale.json"/>
