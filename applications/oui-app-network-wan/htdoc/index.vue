<template>
  <div>
    <!-- 主页面 -->
    <div v-if="currentView === 'main'" class="container">
      <!-- 广域网链路 Section -->
      <div class="section">
        <div class="section-header">{{ $t('Wan Area') }}</div>
        <div class="section-content wan-section">
          <div class="wan-group">
            <div class="wan-table-row wan-table-row-sim wan-table-row-header">
              <div class="wan-group-title">移动数据</div>
              <div class="subnet-info-wan">
                <span>名称</span>
                <span>{{ $t('Operator') }}</span>
                <span>{{ $t('Real Network Access') }}</span>
                <span>APN</span>
                <span>{{ $t('Frequency Band') }}</span>
                <span>RSRP/dBm</span>
                <span class="status-column">{{ $t('Status') }}</span>
                <span> </span>
              </div>
            </div>
            <hr />
            <div class="wan-table-row wan-table-row-sim wan-table-row-clickable" v-for="(item, idx) in simEntries" :key="'sim-' + item.index" @click="editSubWan(item.wan, item.index)">
              <div class="wan-table-leading">
                <svg class="subnet-icon-svg" viewBox="0 0 23 23" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M6 3C5.44772 3 5 3.44772 5 4V20C5 20.5523 5.44772 21 6 21H18C18.5523 21 19 20.5523 19 20V8L14 3H6Z" fill="#DCFCE7" stroke="#22C55E" stroke-width="1.5"/>
                  <path d="M14 3V7C14 7.55228 14.4477 8 15 8H19" fill="none" stroke="#22C55E" stroke-width="1.5"/>
                  <text x="10" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#15803D">{{ idx + 1 }}</text>
                </svg>
              </div>
              <div class="subnet-info-wan">
                <span>{{ item.wan.settings.alias }}</span>
                <span>{{ item.wan.sim.operator || (item.wan.sim.mcc + item.wan.sim.mnc) }}</span>
                <span>{{ item.wan.status.rat }}</span>
                <span>{{ item.wan.settings.apn }}</span>
                <span>{{ getRealBandTypeText(item.index) }}</span>
                <span class="signal-icon-wrapper">
                  <svg class="signal-icon" viewBox="0 0 16 12" width="16" height="12">
                    <rect x="0" y="8" width="3" height="4" rx="0.5" :fill="getRsrpLevel(item.index) >= 1 ? getRsrpLevelColor(item.index) : '#ddd'" />
                    <rect x="4" y="5" width="3" height="7" rx="0.5" :fill="getRsrpLevel(item.index) >= 2 ? getRsrpLevelColor(item.index) : '#ddd'" />
                    <rect x="8" y="2" width="3" height="10" rx="0.5" :fill="getRsrpLevel(item.index) >= 3 ? getRsrpLevelColor(item.index) : '#ddd'" />
                    <rect x="12" y="0" width="3" height="12" rx="0.5" :fill="getRsrpLevel(item.index) >= 4 ? getRsrpLevelColor(item.index) : '#ddd'" />
                  </svg><span :class="'rsrp-level-' + getRsrpLevel(item.index)">{{ getRsrpText(item.index) }}</span>
                </span>
                <span class="status-marquee"><span class="status-marquee-text">{{ getStatusText(item.index) }}</span></span>
                <span class="subnet-arrow">›</span>
              </div>
            </div>
          </div>

          <div class="wan-group" v-if="wanPortEntries.length > 0">
            <div class="wan-table-row wan-table-row-port wan-table-row-header">
              <div class="wan-group-title">有线网</div>
              <div class="subnet-info-wan-port">
                <span>名称</span>
                <span>{{ $t('Interface') }}</span>
                <span>协议</span>
                <span class="status-column">{{ $t('Status') }}</span>
                <span> </span>
              </div>
            </div>
            <hr />
            <div class="wan-table-row wan-table-row-port wan-table-row-clickable" v-for="(item, idx) in wanPortEntries" :key="'wan-' + (item.wan.uci && item.wan.uci.name ? item.wan.uci.name : idx)" @click="editSubWan(item.wan, item.index)">
              <div class="wan-table-leading">
                <svg class="subnet-icon-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect x="2" y="5" width="20" height="14" rx="2" ry="2" fill="#E0F2FE" stroke="#0284C7" stroke-width="1.5"/>
                  <rect x="6" y="8" width="12" height="8" rx="1" ry="1" fill="#000"/>
                  <rect x="7" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="9" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="11" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="13" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="15" y="10" width="1" height="4" fill="#fff"/>
                  <rect x="16" y="10" width="1" height="4" fill="#fff"/>
                </svg>
              </div>
              <div class="subnet-info-wan-port">
                <span>{{ item.wan.settings.alias }}</span>
                <span>{{ item.wan.settings.interface || '-' }}</span>
                <span>{{ item.wan.status.interface.proto === 'STATIC' ? '静态IP' : (item.wan.status.interface.proto || '-') }}</span>
                <span class="status-marquee"><span class="status-marquee-text">{{ item.wan.status.interface.status || '-' }}</span></span>
                <span class="subnet-arrow">›</span>
              </div>
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
                    v-for="item in trafficEntries"
                    :key="'rx-' + item.index"
                    :points="getTrafficPoints('rx', item.index)"
                    :style="getTrafficLineStyle(item.index)"
                  />
                  <line x1="0" :y1="traffic.height * 0.25" :x2="traffic.width" :y2="traffic.height * 0.25" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.24" class="traffic-label">{{ getTrafficLabel('rx', 0.75) }}</text>
                  <line x1="0" :y1="traffic.height * 0.50" :x2="traffic.width" :y2="traffic.height * 0.50" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.49" class="traffic-label">{{ getTrafficLabel('rx', 0.50) }}</text>
                  <line x1="0" :y1="traffic.height * 0.75" :x2="traffic.width" :y2="traffic.height * 0.75" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.74" class="traffic-label">{{ getTrafficLabel('rx', 0.25) }}</text>
                  <line
                    v-for="item in trafficMarkerEntriesRx"
                    :key="'rx-marker-line-' + item.index"
                    x1="0"
                    :x2="traffic.width"
                    :y1="getTrafficLatestY('rx', item.index)"
                    :y2="getTrafficLatestY('rx', item.index)"
                    :style="getTrafficMarkerLineStyle(item.index)"
                  />
                  <circle
                    v-for="item in trafficMarkerEntriesRx"
                    :key="'rx-marker-dot-' + item.index"
                    :cx="getTrafficLatestX('rx', item.index)"
                    :cy="getTrafficLatestY('rx', item.index)"
                    r="2.2"
                    :style="getTrafficMarkerDotStyle(item.index)"
                  />
                  <text
                    v-for="item in trafficMarkerEntriesRx"
                    :key="'rx-marker-text-' + item.index"
                    :x="traffic.width - 6"
                    :y="Math.max(10, getTrafficLatestY('rx', item.index) - 6)"
                    text-anchor="end"
                    class="traffic-marker-text"
                    :style="{ fill: getTrafficColor(item.index) }"
                  >{{ formatRateValue(getTrafficStat('rx', item.index, 'cur')) }} {{ formatRateUnit(getTrafficStat('rx', item.index, 'cur')) }}</text>
                </svg>
              </div>
              <div class="traffic-scale">{{ getTrafficScaleText() }}</div>
            </div>

            <div class="traffic-pane">
              <div class="traffic-title">上行</div>
              <div class="traffic-chart">
                <svg class="traffic-svg" :viewBox="`0 0 ${traffic.width} ${traffic.height}`" preserveAspectRatio="none">
                  <polyline
                    v-for="item in trafficEntries"
                    :key="'tx-' + item.index"
                    :points="getTrafficPoints('tx', item.index)"
                    :style="getTrafficLineStyle(item.index)"
                  />
                  <line x1="0" :y1="traffic.height * 0.25" :x2="traffic.width" :y2="traffic.height * 0.25" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.24" class="traffic-label">{{ getTrafficLabel('tx', 0.75) }}</text>
                  <line x1="0" :y1="traffic.height * 0.50" :x2="traffic.width" :y2="traffic.height * 0.50" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.49" class="traffic-label">{{ getTrafficLabel('tx', 0.50) }}</text>
                  <line x1="0" :y1="traffic.height * 0.75" :x2="traffic.width" :y2="traffic.height * 0.75" style="stroke:black;stroke-width:0.1" />
                  <text x="20" :y="traffic.height * 0.74" class="traffic-label">{{ getTrafficLabel('tx', 0.25) }}</text>
                  <line
                    v-for="item in trafficMarkerEntriesTx"
                    :key="'tx-marker-line-' + item.index"
                    x1="0"
                    :x2="traffic.width"
                    :y1="getTrafficLatestY('tx', item.index)"
                    :y2="getTrafficLatestY('tx', item.index)"
                    :style="getTrafficMarkerLineStyle(item.index)"
                  />
                  <circle
                    v-for="item in trafficMarkerEntriesTx"
                    :key="'tx-marker-dot-' + item.index"
                    :cx="getTrafficLatestX('tx', item.index)"
                    :cy="getTrafficLatestY('tx', item.index)"
                    r="2.2"
                    :style="getTrafficMarkerDotStyle(item.index)"
                  />
                  <text
                    v-for="item in trafficMarkerEntriesTx"
                    :key="'tx-marker-text-' + item.index"
                    :x="traffic.width - 6"
                    :y="Math.max(10, getTrafficLatestY('tx', item.index) - 6)"
                    text-anchor="end"
                    class="traffic-marker-text"
                    :style="{ fill: getTrafficColor(item.index) }"
                  >{{ formatRateValue(getTrafficStat('tx', item.index, 'cur')) }} {{ formatRateUnit(getTrafficStat('tx', item.index, 'cur')) }}</text>
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
                <span class="traffic-legend-badge" :style="{ ...getTrafficBadgeStyle(-1), color: '#000' }">总计</span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficTotal('rx', 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficTotal('rx', 'cur')) }}</span>
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
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytesTotal('tx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytesTotal('tx')) }}</span>
                </span>
              </div>
            </div>
            <div class="traffic-legend-row" v-for="item in trafficEntries" :key="'legend-' + item.index">
              <div class="traffic-legend-cell">
                <span class="traffic-legend-badge" :style="{ ...getTrafficBadgeStyle(item.index), color: '#000' }">{{ item.wan.settings.alias || ('WAN' + (item.index + 1)) }}</span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficStat('rx', item.index, 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficStat('rx', item.index, 'cur')) }}</span>
                  <span class="traffic-rate-pct">{{ formatPercent(getTrafficStat('rx', item.index, 'cur'), getTrafficTotal('rx', 'cur')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytes(item.index, 'rx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytes(item.index, 'rx')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-rate">
                  <span class="traffic-rate-value">{{ formatRateValue(getTrafficStat('tx', item.index, 'cur')) }}</span>
                  <span class="traffic-rate-unit">{{ formatRateUnit(getTrafficStat('tx', item.index, 'cur')) }}</span>
                  <span class="traffic-rate-pct">{{ formatPercent(getTrafficStat('tx', item.index, 'cur'), getTrafficTotal('tx', 'cur')) }}</span>
                </span>
              </div>
              <div class="traffic-legend-cell">
                <span class="traffic-bytes">
                  <span class="traffic-bytes-value">{{ formatBytesValue(getInterfaceBytes(item.index, 'tx')) }}</span>
                  <span class="traffic-bytes-unit">{{ formatBytesUnit(getInterfaceBytes(item.index, 'tx')) }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>


    </div>

    <KeepAlive>
      <SimConfig v-if="currentView === 'sim-config' && selectedWan" :wan-data="selectedWan" @go-back="goBackToMain" />
    </KeepAlive>
    <KeepAlive>
      <WanConfig v-if="currentView === 'wan-config' && selectedWan" :wan-data="selectedWan" @go-back="goBackToMain" />
    </KeepAlive>
    <DhcpConfig v-if="currentView === 'dhcp'" @go-back="goBackToMain" />
    <WirelessConfig v-if="currentView === 'wireless'" @go-back="goBackToMain" />
  </div>
</template>

<script>
import SimConfig from './sim.vue'
import WanConfig from './wan.vue'
import DhcpConfig from './dhcp.vue'
import WirelessConfig from './wireless.vue'

const createEmptyMonsc = () => ({
  rat: '',
  mcc: '',
  mnc: '',
  cell: {
    type: '',
    arfcn: '',
    scs: '',
    cell_id: '',
    pci: '',
    tac: '',
    rsrp: '',
    rsrq: '',
    sinr: '',
    rssi: ''
  }
})

const createEmptyMonnc = () => ({
  gsm: [],
  wcdma: [],
  lte: [],
  nr: []
})

const createDefaultWanLink = (index) => {

  return {
    settings: {
      index: index,
      ifname: '',
      enable: true,
      alias: '',
      interface: '',
      net: '',
      band: '-',
      pcid: '-',
      apn: '',
      auth: '-',
      username: '-',
      password: '-'
    },
    productInfo: {
      vendor: '',
      product: '',
      revision: '',
      imei: '',
      iccid: '',
      imsi: ''
    },
    sim: {
      operator: '',
      status: '',
      country: '',
      mcc: '',
      mnc: ''
    },
    freqInfo: {
      sysmode: '',
      class: []
    },
    NR_5GCore: {
      stat: '',
      tac: '',
      ci: '',
      act: ''
    },
    CS: {
      stat: '',
      lac: '',
      ci: '',
      act: ''
    },
    monsc: createEmptyMonsc(),
    monnc: createEmptyMonnc(),
    // 配置
    realSettings:{
      rat:'',
      pdp: {
        cid: '',
        pdp_type: '',
        apn: '',
        pdp_addr: ''
      },
      auth:{
        cid: '',
        auth_type: '',
        passwd: '',
        username: '',
        plmn: ''
      },
      nrfreqlock:{
        operatetype: '',
        forbid_flag: '',
        num: '',
        band: [],
        arfcn: [],
        scstype: [],
        pci: []
      },
      ltefreqlock:{
        operatetype: '',
        forbid_flag: '',
        num: '',
        band: [],
        arfcn: [],
        pci: []
      }
    },
    // 实时状态
    status: {
      status: '',
      timestamp: '',
      rat: '-',
      // 5G NR实时状态
      nr: {
        rsrp: '',
        rsrq: '',
        sinr: '',
        band: ''
      },
      // LTE 实时状态
      lte: {
        rsrp: '',
        rsrq: '',
        sinr: '',
        rssi: '',
        band: ''
      },
      // 网口interface实时状态
      interface: {
        up: false,
        proto: '',
        status: '-',
        ip: '-',
        mask: '-',
        gateway: '-',
        mac: '-',
        rxBytes: '-',
        txBytes: '-'
      },
      // HCSQ 信号强度
      hcsq: {
        sysmode: '',
        rsrp: '',
        rsrp_dbm: '',
        rsrq: '',
        rsrq_db: '',
        sinr: '',
        sinr_db: '',
        rssi: '',
        rssi_dbm: ''
      }
    }
  }
}

export default {
  components: {
    SimConfig,
    WanConfig,
    DhcpConfig,
    WirelessConfig
  },
  computed: {
    simEntries() {
      return (this.wanLinks || [])
        .map((wan, index) => ({ wan, index }))
        .filter(item => item.wan && item.wan.kind === 'sim')
    },
    wanPortEntries() {
      return (this.wanLinks || [])
        .map((wan, index) => ({ wan, index }))
        .filter(item => item.wan && item.wan.kind === 'wan')
    },
    // 返回所有的可用链路
    trafficEntries() {
      return (this.wanLinks || [])
        .map((wan, index) => ({ wan, index }))
        .filter(item => item.wan && (item.wan.kind === 'sim' || item.wan.kind === 'wan'))
    },
    trafficMarkerEntriesRx() {
      return this.trafficEntries.filter((item) => {
        if (!this.hasTrafficSeries('rx', item.index))
          return false
        return this.getTrafficStat('rx', item.index, 'cur') > 0
      })
    },
    trafficMarkerEntriesTx() {
      return this.trafficEntries.filter((item) => {
        if (!this.hasTrafficSeries('tx', item.index))
          return false
        return this.getTrafficStat('tx', item.index, 'cur') > 0
      })
    }
  },
  data() {
    return {
      currentView: 'main', // 'main' 或 'wan-config'
      selectedWan: null,
      selectedWanIndex: null,
      wanLinks: [],
      wanPortStateTimerId: null,
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
      trafficEnabled: true
    }
  },
  watch: {
    currentView() {
      this.updatePolling()
      this.updateWanPortStatePolling()
    },
    selectedWanIndex() {
      this.updatePolling()
    }
  },

  methods: {
    // 获取指定索引链路的 RPC 参数（返回 {ifname: "sim1"} 或 null）
    getRpcIndex(index) {
      const link = this.wanLinks && this.wanLinks[index]
      if (link && link.kind && link.kind !== 'sim')
        return null
      const v = link && link.settings && link.settings.ifname
      return v || null
    },
    // 初始化组件：加载可用 WAN 链路、初始化流量数据、启动所有定时任务
    bootstrap() {
      return this.loadAvailWanLinks().then(() => {
        this.initTrafficSeries()
        this.wanLinks.forEach((_, index) => this.getSimSettings(index))

        this.wanLinks.forEach((_, index) => {
          if (this.getRpcIndex(index) === null)
            return
          this.$timer.create('sim-product' + index, () => this.getProductInfo(index), { time: 15000, repeat: true, autostart: false })
          this.$timer.create('sim-status' + index, () => this.getStatus(index), { time: 10000, repeat: true, autostart: false })
          this.$timer.create('modules' + index, () => this.getModuleSettings(index), { time: 12000, repeat: true, autostart: false })
          this.$timer.create('interface' + index, () => this.getInterfaceStatus(index), { time: 1000, repeat: true, autostart: false })
        })

        this.updatePolling()
      })
    },
    // 通过 RPC 调用 'wan' 模块的 'getAvailWan' 方法，获取可用链路列表，并构建 wanLinks 数组
    loadAvailWanLinks() {
      return this.$oui.call('wan', 'getAvailWan', {}).then((result) => {
        let data = result
        if (typeof result === 'string') {
          try {
            data = JSON.parse(result)
          } catch {
            data = null
          }
        }

        const links = data && Array.isArray(data.links) ? data.links : []
        const uiLinks = []

        for (const item of links) {
          if (!item || !item.kind)
            continue
          // sim卡链路
          if (item.kind === 'sim') {
            const n = Number(item.sim_index)
            if (!Number.isFinite(n) || n < 0)
              continue
            const model = createDefaultWanLink(n)
            model.kind = 'sim'
            model.uci = item
            model.settings.index = n
            model.settings.ifname = item.name || ''
            if (item.name) model.settings.interfaceName = item.name
            model.settings.interface = item.device || ''
            uiLinks.push(model)
            continue
          }
          // 网线
          if (item.kind === 'wan') {
            const model = createDefaultWanLink(0)
            model.kind = 'wan'
            model.uci = item
            model.settings.index = null
            model.settings.alias = item.name ? String(item.name).toUpperCase() : 'WAN'
            model.settings.interface = item.device || ''
            // model.status.rat = item.proto ? String(item.proto).toUpperCase() : '-'
            model.status.interface.proto = item.proto ? String(item.proto).toUpperCase() : ''
            uiLinks.push(model)
          }
        }

        // 排序：sim 在前，wan 在后
        if (uiLinks.length) {
          uiLinks.sort((a, b) => {
            const ak = a && a.kind === 'sim' ? 0 : 1
            const bk = b && b.kind === 'sim' ? 0 : 1
            if (ak !== bk)
              return ak - bk

            if (ak === 0) {
              const ai = Number(a?.settings?.index)
              const bi = Number(b?.settings?.index)
              if (Number.isFinite(ai) && Number.isFinite(bi))
                return ai - bi
              if (Number.isFinite(ai))
                return -1
              if (Number.isFinite(bi))
                return 1
              return 0
            }

            const aw = Number(a?.uci?.wan_index)
            const bw = Number(b?.uci?.wan_index)
            if (Number.isFinite(aw) && Number.isFinite(bw))
              return aw - bw
            if (Number.isFinite(aw))
              return -1
            if (Number.isFinite(bw))
              return 1
            return 0
          })
          this.wanLinks = uiLinks
          this.updateWanPortStatePolling()
          return
        }

        // 降级：创建三个默认 SIM 链路
        this.wanLinks = [createDefaultWanLink(0), createDefaultWanLink(1), createDefaultWanLink(2)]
        this.updateWanPortStatePolling()
      }).catch(() => {
        this.wanLinks = [createDefaultWanLink(0), createDefaultWanLink(1), createDefaultWanLink(2)]
        this.updateWanPortStatePolling()
      })
    },
    updateWanPortStatePolling() {
      if (this.currentView === 'main')
        this.startWanPortStatePolling()
      else
        this.stopWanPortStatePolling()
    },
    // 获取所有 WAN 类型链路的状态（一次性），并记录流量样本
    fetchWanPortStatesOnce() {
      if (this.currentView !== 'main')
        return

      const links = Array.isArray(this.wanLinks) ? this.wanLinks : []
      for (let index = 0; index < links.length; index += 1) {
        const wan = links[index]
        if (!wan || wan.kind !== 'wan')
          continue
        const section = wan.uci && wan.uci.name ? String(wan.uci.name) : ''
        const iface = wan.settings && wan.settings.interface ? String(wan.settings.interface) : ''
        if (!section || !iface)
          continue

        this.$oui.call('wan', 'getWanState', { section, interface: iface }).then((result) => {
          let data = result
          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              data = null
            }
          }
          if (!data || data.code !== 0)
            return
          if (!wan.status || !wan.status.interface)
            return
          const inter = wan.status.interface
          if (typeof data.status === 'string') inter.status = data.status
          if (typeof data.ip === 'string') inter.ip = data.ip
          if (typeof data.mask === 'string') inter.mask = data.mask
          if (typeof data.gateway === 'string') inter.gateway = data.gateway
          if (typeof data.mac === 'string') inter.mac = data.mac
          if (data.rxBytes !== undefined && data.rxBytes !== null) inter.rxBytes = data.rxBytes
          if (data.txBytes !== undefined && data.txBytes !== null) inter.txBytes = data.txBytes
          if (this.trafficEnabled)
            this.recordTrafficSample(index, data.rxBytes, data.txBytes)
        }).catch(() => {})
      }
    },
    // 启动 WAN 端口状态轮询定时器
    startWanPortStatePolling() {
      this.stopWanPortStatePolling()
      this.fetchWanPortStatesOnce()
      this.wanPortStateTimerId = setInterval(() => {
        this.fetchWanPortStatesOnce()
      }, this.traffic.intervalSec * 1000)
    },
    // 停止 WAN 端口状态轮询定时器
    stopWanPortStatePolling() {
      if (this.wanPortStateTimerId) {
        clearInterval(this.wanPortStateTimerId)
        this.wanPortStateTimerId = null
      }
    },
    // 强制刷新流量数据：重置流量序列，重新获取接口状态
    refreshTrafficNow() {
      if (this.currentView !== 'main' || !this.trafficEnabled)
        return

      this.resetTrafficSeries()

      this.wanLinks.forEach((_, index) => this.getInterfaceStatus(index))
      this.fetchWanPortStatesOnce()
      setTimeout(() => {
        if (this.currentView !== 'main' || !this.trafficEnabled)
          return
        this.wanLinks.forEach((_, index) => this.getInterfaceStatus(index))
        this.fetchWanPortStatesOnce()
      }, this.traffic.intervalSec * 1000)
    },
    // 重置所有链路的流量数据序列（归零）
    resetTrafficSeries() {
      const wanted = this.traffic.dataWanted
      this.wanLinks.forEach((_, index) => {
        this.traffic.series.rx[index] = Array.from({ length: wanted }, () => 0)
        this.traffic.series.tx[index] = Array.from({ length: wanted }, () => 0)
      })
      this.traffic.last = {}
    },
    // 根据当前视图和选中的链路，启动或停止对应 SIM 卡的数据轮询
    updatePolling() {
      this._pollingToken = (this._pollingToken || 0) + 1
      this.stopAllPolling()

      if (this.currentView === 'main') {
        const indexes = this.wanLinks
          .map((_, index) => index)
          .filter(index => this.getRpcIndex(index) !== null)
        this.startPollingForIndexes(indexes, { status: true, product: true, modules: true, interface: this.trafficEnabled })
        return
      }

      if (this.currentView === 'sim-config' && typeof this.selectedWanIndex === 'number') {
        this.startPollingForIndexes([this.selectedWanIndex], { status: true, product: true, modules: true, interface: true })
      }
    },
    // 为指定的索引列表启动轮询任务
    startPollingForIndexes(indexes, plan) {
      indexes.forEach((index) => {
        if (this.getRpcIndex(index) === null)
          return
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
    // 停止所有 SIM 相关的轮询定时器
    stopAllPolling() {
      this.wanLinks.forEach((_, index) => {
        this.$timer.stop('sim-product' + index)
        this.$timer.stop('sim-status' + index)
        this.$timer.stop('modules' + index)
        this.$timer.stop('interface' + index)
      })
    },
    // 防止重复调用 RPC 的辅助函数
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
    // 根据状态字符串返回对应的 CSS 类名
    getStatusClass(status) {
      switch (status) {
      case 'connected': return 'status-connected'
      case 'disconnected': return 'status-disconnected'
      case 'dialing': return 'status-dialing'
      case 'nosim': return 'status-nosim'
      default: return ''
      }
    },
    // 获取 SIM 卡的产品信息（厂家、型号、IMEI、ICCID、IMSI）
    getProductInfo(index) {
      return this.withInFlight('getProductInfo:' + index, () => {
        const token = this._pollingToken
        const rpcIndex = this.getRpcIndex(index)
        if (rpcIndex === null)
          return
        return this.$oui.call('sim', 'getProductInfo', { ifname: rpcIndex }).then(result => {
          if (token !== this._pollingToken)
            return
          if (this.currentView === 'sim-config' && this.selectedWanIndex !== index)
            return
          if (this.currentView !== 'sim-config' && this.currentView !== 'main')
            return

          let data = result
          console.log(data)

          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              return
            }
          }
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
        const rpcIndex = this.getRpcIndex(index)
        if (rpcIndex === null)
          return
        return this.$oui.call('sim', 'getModuleSettings', { ifname: rpcIndex }).then(result => {
          if (token !== this._pollingToken)
            return
          if (this.currentView === 'sim-config' && this.selectedWanIndex !== index)
            return
          if (this.currentView !== 'sim-config' && this.currentView !== 'main')
            return

          let data = result
          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              return
            }
          }
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
    // 获取 SIM 卡的状态信息（注册状态、信号强度、小区信息等）
    getStatus(index) {
      return this.withInFlight('getStatus:' + index, () => {
        const token = this._pollingToken
        const rpcIndex = this.getRpcIndex(index)
        if (rpcIndex === null)
          return
        return this.$oui.call('sim', 'getStatus', { ifname: rpcIndex }).then(result => {
          if (token !== this._pollingToken)
            return

          // console.log('status', result)

          let data = result
          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              return
            }
          }

          const link = this.wanLinks[index]
          const sim = link.sim
          if (data.sim) sim.status = data.sim
          if (data.operator_name) sim.operator = data.operator_name
          if (data.country) sim.country = data.country
          if (data.mcc) sim.mcc = data.mcc
          if (data.mnc) sim.mnc = data.mnc
          const isDetail = this.currentView === 'sim-config' && this.selectedWanIndex === index
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

          // HCSQ 信号强度（优先于 monsc 中的值）
          if (data.hcsq) {
            console.log(data.hcsq)
            let h = data.hcsq
            if (typeof h === 'string') {
              try {
                h = JSON.parse(h)
              } catch {
                h = null
              }
            }
            if (h) {
              const hcsq = link.status.hcsq
              if (h.sysmode) hcsq.sysmode = h.sysmode
              if (h.rsrp) hcsq.rsrp = h.rsrp
              if (h.rsrp_dbm) hcsq.rsrp_dbm = h.rsrp_dbm
              if (h.rsrq) hcsq.rsrq = h.rsrq
              if (h.rsrq_db) hcsq.rsrq_db = h.rsrq_db
              if (h.sinr) hcsq.sinr = h.sinr
              if (h.sinr_db) hcsq.sinr_db = h.sinr_db
              if (h.rssi) hcsq.rssi = h.rssi
              if (h.rssi_dbm) hcsq.rssi_dbm = h.rssi_dbm
              // HCSQ 的 sysmode 比 monsc.rat 更准
              const sysmode = String(h.sysmode).toUpperCase()
              const status = link.status
              if (sysmode.indexOf('NR') !== -1) {
                if (h.rsrp_dbm) status.nr.rsrp = String(h.rsrp_dbm) + 'dBm'
                if (h.rsrq_db) status.nr.rsrq = String(h.rsrq_db) + 'dB'
                if (h.sinr_db) status.nr.sinr = String(h.sinr_db) + 'dB'
              } else if (sysmode.indexOf('LTE') !== -1) {
                if (h.rsrp_dbm) status.lte.rsrp = String(h.rsrp_dbm) + 'dBm'
                if (h.rsrq_db) status.lte.rsrq = String(h.rsrq_db) + 'dB'
                if (h.sinr_db) status.lte.sinr = String(h.sinr_db) + 'dB'
                if (h.rssi_dbm) status.lte.rssi = String(h.rssi_dbm) + 'dBm'
              }
              if (h.sysmode) status.rat = h.sysmode
            }
          }

          // NR/LTE信号强度
          if (data.timestamp) link.status.timestamp = data.timestamp
          if (data.monsc) {
            const monsc = data.monsc
            const status = link.status
            if (data.monsc.rat) status.rat = data.monsc.rat
            const cell = monsc.cell
            if (cell) {
              if (cell.type === 'nr') {
                if (cell.rsrp) status.nr.rsrp = cell.rsrp
                if (cell.rsrq) status.nr.rsrq = cell.rsrq
                if (cell.sinr) status.nr.sinr = cell.sinr
                if (cell.band) status.nr.band = cell.band
              } else if (cell.type === 'lte') {
                if (cell.rsrp) status.lte.rsrp = cell.rsrp
                if (cell.rsrq) status.lte.rsrq = cell.rsrq
                if (cell.sinr) status.lte.sinr = cell.sinr
                if (cell.rssi) status.lte.rssi = cell.rssi
                if (cell.band) status.lte.band = cell.band
              }
            }

            if (isDetail) {
              const newest = createEmptyMonsc()
              if (monsc.rat) newest.rat = monsc.rat
              if (monsc.mcc) newest.mcc = monsc.mcc
              if (monsc.mnc) newest.mnc = monsc.mnc
              if (monsc.cell) {
                if (monsc.cell.type) newest.cell.type = monsc.cell.type
                if (monsc.cell.arfcn) newest.cell.arfcn = monsc.cell.arfcn
                if (monsc.cell.scs) newest.cell.scs = monsc.cell.scs
                if (monsc.cell.cell_id) newest.cell.cell_id = monsc.cell.cell_id
                if (monsc.cell.pci) newest.cell.pci = monsc.cell.pci
                if (monsc.cell.tac) newest.cell.tac = monsc.cell.tac
                if (monsc.cell.rsrp) newest.cell.rsrp = monsc.cell.rsrp
                if (monsc.cell.rsrq) newest.cell.rsrq = monsc.cell.rsrq
                if (monsc.cell.sinr) newest.cell.sinr = monsc.cell.sinr
                if (monsc.cell.rssi) newest.cell.rssi = monsc.cell.rssi
              }
              link.monsc = newest
            }
          } else if (isDetail) {
            link.monsc = createEmptyMonsc()
          }

          if (isDetail) {
            const monnc = createEmptyMonnc()
            if (data.monnc) {
              if (Array.isArray(data.monnc.gsm)) monnc.gsm = data.monnc.gsm
              if (Array.isArray(data.monnc.wcdma)) monnc.wcdma = data.monnc.wcdma
              if (Array.isArray(data.monnc.lte)) monnc.lte = data.monnc.lte
              if (Array.isArray(data.monnc.nr)) monnc.nr = data.monnc.nr
            }
            link.monnc = monnc
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
        const rpcIndex = this.getRpcIndex(index)
        if (rpcIndex === null)
          return
        return this.$oui.call('sim', 'getInterfaceStatus', { ifname: rpcIndex }).then(result => {
          if (token !== this._pollingToken)
            return
          if (!((this.currentView === 'sim-config' && this.selectedWanIndex === index) || (this.currentView === 'main' && this.trafficEnabled)))
            return

          let data = result
          if (typeof result === 'string') {
            try {
              data = JSON.parse(result)
            } catch {
              return
            }
          }
          const inter = this.wanLinks[index].status.interface
          if (data.up !== undefined) inter.up = !!data.up
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
    // 初始化所有链路的流量数据序列（填充0）
    initTrafficSeries() {
      const wanted = this.traffic.dataWanted
      this.wanLinks.forEach((_, index) => {
        if (!this.traffic.series.rx[index]) this.traffic.series.rx[index] = Array.from({ length: wanted }, () => 0)
        if (!this.traffic.series.tx[index]) this.traffic.series.tx[index] = Array.from({ length: wanted }, () => 0)
      })
    },
    // 将传入的值转换为数值，若无效则返回 null
    normalizeBytes(value) {
      if (value === null || value === undefined)
        return null
      const n = Number(value)
      return Number.isFinite(n) ? n : null
    },
    // 记录一次流量样本（根据前后两次字节数差值计算瞬时速率）
    recordTrafficSample(index, rxBytes, txBytes) {
      if (!this.trafficEnabled || this.currentView !== 'main')
        return
      const now = Date.now()
      const rx = this.normalizeBytes(rxBytes)
      const tx = this.normalizeBytes(txBytes)
      if (rx === null || tx === null)
        return
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
    // 每个链路用不同的颜色标识
    getTrafficColor(index) {
      const colors = ['#ef4444', '#3b82f6', '#22c55e', '#f97316', '#a855f7', '#ec4899', '#f59e0b', '#14b8a6', '#06b6d4', '#84cc16']
      return colors[index % colors.length]
    },
    // 获取流量图表的线条样式（填充色、透明度、边框等）
    getTrafficLineStyle(index) {
      const color = this.getTrafficColor(index)
      return `fill:${color};fill-opacity:${this.traffic.fillOpacity};stroke:black;stroke-width:0.15;stroke-linejoin:round;stroke-linecap:round`
    },
    // 判断指定方向（rx/tx）的链路是否已有流量数据序列
    hasTrafficSeries(direction, index) {
      const series = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
      return Array.isArray(series) && series.length > 0
    },
    // 获取流量图中最后一个点的 X 坐标（时间轴位置）
    getTrafficLatestX(direction, index) {
      const series = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
      if (!Array.isArray(series) || !series.length)
        return 0
      return (series.length - 1) * this.traffic.step
    },
    // 获取流量图中最后一个点的 Y 坐标（速率值映射到画布高度）
    getTrafficLatestY(direction, index) {
      const series = this.traffic.series && this.traffic.series[direction] && this.traffic.series[direction][index]
      const h = this.traffic.height
      if (!Array.isArray(series) || !series.length)
        return h
      const max = this.getTrafficMax(direction) || 1
      const v = series[series.length - 1] || 0
      const y = h - (v / max) * h
      if (!Number.isFinite(y))
        return h
      return Math.min(h, Math.max(0, y))
    },
    // 获取流量图中标记线的样式（用于在图表顶部标识链路）
    getTrafficMarkerLineStyle(index) {
      const color = this.getTrafficColor(index)
      return `stroke:${color};stroke-width:0.25;opacity:0.85`
    },
    // 获取流量标记点的样式（圆点）
    getTrafficMarkerDotStyle(index) {
      const color = this.getTrafficColor(index)
      return `fill:${color};stroke:#000;stroke-width:0.35`
    },
    // 将十六进制颜色转换为 rgba 格式
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
    // 获取流量图表的填充颜色（带透明度）
    getTrafficFillColor(index) {
      const color = index === -1 ? '#ff7f00' : this.getTrafficColor(index)
      return this.hexToRgba(color, this.traffic.fillOpacity)
    },
    // 获取流量图标的背景样式（用于 Legend）
    getTrafficBadgeStyle(index) {
      return {
        backgroundColor: this.getTrafficFillColor(index),
        border: '1px solid rgba(0,0,0,0.15)'
      }
    },
    // 获取所有链路中指定方向（rx/tx）的最大速率（字节/秒
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

      if (!(max > 1))
        return 1

      const bits = max * 8
      const kbit = bits / 1024
      const mbit = kbit / 1024
      const gbit = mbit / 1024

      const roundNice = (x) => {
        const v = Number(x)
        if (!(Number.isFinite(v) && v > 0))
          return 1
        const exp = Math.floor(Math.log10(v))
        const base = 10 ** exp
        const m = v / base
        const steps = [1, 2, 3, 4, 5, 6, 8, 10]
        for (let i = 0; i < steps.length; i += 1) {
          if (m <= steps[i])
            return steps[i] * base
        }
        return 10 * base
      }

      if (gbit >= 1) {
        const nice = roundNice(gbit)
        return (nice * 1024 * 1024 * 1024) / 8
      }
      if (mbit >= 1) {
        const nice = roundNice(mbit)
        return (nice * 1024 * 1024) / 8
      }
      const nice = roundNice(kbit)
      return (nice * 1024) / 8
    },
    // 获取流量图表 Y 轴标签（根据最大速率的一定比例生成）
    getTrafficLabel(direction, ratio) {
      const max = this.getTrafficMax(direction)
      return this.formatTraffic(max * ratio)
    },
    // 获取流量图表的时间范围描述文本
    getTrafficScaleText() {
      const minutes = Math.round((this.traffic.dataWanted * this.traffic.intervalSec) / 60)
      return `(${minutes}分钟, ${this.traffic.intervalSec}秒采样)`
    },
    // 对流量序列进行平滑处理（相邻5点平均）
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
    // 获取用于绘制 SVG 多边形（流量填充图）的点字符串
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
    // 获取指定链路指定方向（rx/tx）的流量统计值（当前/峰值/平均）
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
    // 获取所有链路指定方向的总流量统计值
    getTrafficTotal(direction, type) {
      let total = 0
      for (let i = 0; i < this.wanLinks.length; i += 1)
        total += this.getTrafficStat(direction, i, type)
      return total
    },
    // 格式化速率（字节/秒）为可读字符串，同时显示 bit/s 和 Byte/s
    formatTraffic(bytesPerSec) {
      const bytes = Math.max(0, Number(bytesPerSec) || 0)
      const bits = bytes * 8
      const kbit = bits / 1024
      const mbit = kbit / 1024
      const gbit = mbit / 1024
      const kby = bytes / 1024
      const mby = kby / 1024
      const gby = mby / 1024

      let biValue
      let biUnit
      if (gbit >= 1) {
        biValue = gbit
        biUnit = 'Gbit/s'
      } else if (mbit >= 1) {
        biValue = mbit
        biUnit = 'Mbit/s'
      } else {
        biValue = kbit
        biUnit = 'Kbit/s'
      }

      let byValue
      let byUnit
      if (gby >= 1) {
        byValue = gby
        byUnit = 'GB/s'
      } else if (mby >= 1) {
        byValue = mby
        byUnit = 'MB/s'
      } else {
        byValue = kby
        byUnit = 'KB/s'
      }

      return `${biValue.toFixed(2)} ${biUnit} (${byValue.toFixed(2)} ${byUnit})`
    },
    // 计算速率值及其单位（仅返回数值和单位对象）
    calcRate(bytesPerSec) {
      const bytes = Math.max(0, Number(bytesPerSec) || 0)
      const bits = bytes * 8
      const kbit = bits / 1024
      const mbit = kbit / 1024
      const gbit = mbit / 1024
      if (gbit >= 1)
        return { value: gbit, unit: 'Gbit/s' }
      if (mbit >= 1)
        return { value: mbit, unit: 'Mbit/s' }
      return { value: kbit, unit: 'Kbit/s' }
    },
    formatRateValue(bytesPerSec) {
      return this.calcRate(bytesPerSec).value.toFixed(2)
    },
    formatRateUnit(bytesPerSec) {
      return this.calcRate(bytesPerSec).unit
    },
    // 计算百分比（用于流量占比显示）
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
    // 将字节数格式化为带单位的人类可读字符串（B, KB, MB, GB, TB）
    formatBytes(bytes) {
      const r = this.calcBytes(bytes)
      return r ? `${r.value} ${r.unit}` : '-'
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
    // 获取链路状态文本（组合 NR 和 LTE 注册状态）
    getStatusText(index) {
      const link = this.wanLinks[index]
      if (!link)
        return ''

      // 检查是否使能
      if (link.settings && !link.settings.enable)
        return '已禁用'

      // 检查是否插卡（ICCID 为空说明未插卡/未插网线）
      const iccid = link.productInfo && link.productInfo.iccid
      if (iccid === '' || iccid === '-')
        return '未识别SIM卡'

      // 检查信号强度是否无服务
      if ((link.status && link.status.hcsq && link.status.hcsq.sysmode) === 'NOSERVICE')
        return '无服务'

      // 检查RSRP信号强度, 将信号强度描述拼接到后面返回的信息中
      let rsrpLabel = ''
      const rsrp = this.getRsrpText(index)
      if (rsrp && rsrp !== '-') {
        const lvl = this.getRsrpLevel(index)
        const labels = { 4: '信号极好', 3: '信号良好', 2: '信号一般', 1: '信号差' }
        rsrpLabel = labels[lvl] || ''
      }

      // 有 IP 即为在线
      const ip = link.status && link.status.interface && link.status.interface.ip
      if (ip && ip !== '-' && ip !== '')
        return rsrpLabel ? '在线 ' + rsrpLabel : '在线'

      // 无 IP 时检查 SIM 卡状态
      const simStatus = link.sim && link.sim.status
      if (simStatus && simStatus !== '' && !simStatus.toLowerCase().includes('not'))
        return '拨号中...'

      // 离线时拼接 NR/LTE 注册状态
      let stat = '离线: '
      const nrStat = link.NR_5GCore && link.NR_5GCore.stat
      const csStat = link.CS && link.CS.stat
      if (nrStat && nrStat !== '')
        stat = stat + 'NR' + nrStat
      if (csStat && csStat !== '') {
        if (nrStat && nrStat !== '')
          stat = stat + ' | '
        stat = stat + 'LTE' + csStat
      }
      return stat
    },
    // 从UCI配置文件/etc/config/sim中查询配置
    getSimSettings(index) {
      const rpcIndex = this.getRpcIndex(index)
      if (rpcIndex === null)
        return
      this.$oui.call('sim', 'getSimUciSettings', { ifname: rpcIndex }).then(result => {
        let data = result
        if (typeof result === 'string') {
          try {
            data = JSON.parse(result)
          } catch {
            return
          }
        }
        const settings = this.wanLinks[index].settings

        if (data.alias) settings.alias = data.alias
        if (data.enable) settings.enable = data.enable === '1' || data.enable === 'true' || data.enable === 1 || data.enable === true
        if (data.usb) settings.usb = data.usb
        if (data.node) settings.node = data.node
        if (data.interface && !String(data.interface).startsWith('/dev/')) settings.interface = data.interface
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
        return '-'

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
        return '-'

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
    // 获取当前链路的 RSRP 值（优先取 NR，若无则取 LTE）
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
    getRsrpLevel(index) {
      const text = this.getRsrpText(index)
      if (text === '-' || text === '')
        return 0
      const n = parseFloat(text)
      if (!Number.isFinite(n) || n >= 0)
        return 0
      if (n >= -80) return 4
      if (n >= -90) return 3
      if (n >= -100) return 2
      return 1
    },
    getRsrpLevelColor(index) {
      const colors = { 4: '#22c55e', 3: '#84cc16', 2: '#eab308', 1: '#ef4444', 0: '#ccc' }
      return colors[this.getRsrpLevel(index)] || '#ccc'
    },
    // 切换到WAN配置页面
    editSubWan(wan, index) {
      this.selectedWan = wan
      this.selectedWanIndex = index
      this.currentView = wan && wan.kind === 'sim' ? 'sim-config' : 'wan-config'
      this.updateWanPortStatePolling()
    },
    // 返回主页面
    goBackToMain(payload) {
      this.currentView = 'main'
      this.selectedWan = null
      this.selectedWanIndex = null
      this.updateWanPortStatePolling()
      if (payload && payload.refresh) {
        this.loadAvailWanLinks().then(() => {
          this.initTrafficSeries()
          this.wanLinks.forEach((_, index) => this.getSimSettings(index))
          this.fetchWanPortStatesOnce()
          this.updatePolling()
        }).catch(() => {})
      }
    },
    // 编辑子网配置（DHCP 或 Wireless）
    editSubNet(lan) {
      if (lan.name === 'DHCP Service') {
        this.currentView = 'dhcp'
        this.updateWanPortStatePolling()
      } else if (lan.name === 'Wireless Lan') {
        this.currentView = 'wireless'
        this.updateWanPortStatePolling()
      } else {
        alert('修改LAN设置: ' + lan.name)
      }
    }
  },
  created() {
    this.bootstrap()
  },
  beforeUnmount() {
    this.stopWanPortStatePolling()
  }
}
</script>

<style scoped>
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

.wan-group {
  padding-bottom: 14px;
}

.wan-group + .wan-group {
  border-top: 1px solid var(--el-border-color);
  padding-top: 14px;
}

.wan-group-title {
  width: 56px;
  margin-right: 0;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
  font-size: 13px;
  font-weight: 500;
  color: var(--el-text-color-primary);
}

.wan-table-row {
  display: grid;
  column-gap: 12px;
  align-items: center;
  padding: 12px 20px;
  border-radius: 6px;
  margin-bottom: 10px;
  color: var(--el-text-color-primary);
  font-size: 13px;
}

.wan-table-row-sim {
  grid-template-columns: 56px 100px 100px 120px 100px 120px 90px 1fr 18px;
}

.wan-table-row-port {
  grid-template-columns: 56px 120px 100px 100px 100px 18px;
}

.wan-table-row-header {
  margin-bottom: 0;
}

.wan-table-row-clickable {
  cursor: pointer;
  transition: background-color 0.2s;
}

.wan-table-row-clickable:hover {
  background-color: var(--el-fill-color-light);
}

.wan-table-leading {
  width: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.wan-table-leading .subnet-icon-svg {
  margin-right: 0;
}

.subnet-info-wan-port {
  display: contents;
}

.subnet-info-wan-port span {
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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

.traffic-marker-text {
  font-size: 10px;
  font-family: sans-serif;
  stroke: #fff;
  stroke-width: 3px;
  paint-order: stroke;
  dominant-baseline: central;
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
  color: #000;
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
  display: contents;
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

.signal-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
  height: 100%;
}

.signal-icon {
  color: var(--el-color-success);
  flex-shrink: 0;
}

.rsrp-level-4 { color: #22c55e; font-weight: 600; }
.rsrp-level-3 { color: #84cc16; font-weight: 600; }
.rsrp-level-2 { color: #eab308; font-weight: 600; }
.rsrp-level-1 { color: #ef4444; font-weight: 600; }

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
