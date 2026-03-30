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
              <span>{{ $t('SIM') }}</span>
              <!-- <span>{{ $t('Interface') }}</span> -->
              <span>{{ $t('Operator') }}</span>
              <span>{{ $t('Real Network Access') }}</span>
              <span>APN</span>
              <span>{{ $t('Frequency Band') }}</span>
              <span>{{ $t('Rsrp') }}dbm</span>
              <span class="status-column">{{ $t('Status') }}</span>
              <span> </span>
            </div>
          </div>

          <!-- 分割线 -->
          <hr />

          <!-- 数据行 -->
          <div class="subnet-item" v-for="(wan, index) in wanLinks" :key="index" @click="editSubWan(wan)">
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
              <span>{{ wan.monsc.rat }}</span>
              <span>{{ wan.settings.apn }}</span>
              <span>{{ wan.status.band }}</span>
              <span>{{ (wan.status.rsrp_nr === '' || wan.status.rsrp_nr == null || +wan.status.rsrp_nr === 0) ? wan.status.rsrp_lte : wan.status.rsrp_nr }}</span>
              <span class="status-column">
                <span :class="['status-text', getStatusClass(wan.status.status)]">
                  {{ $t(getStatusText(wan.status.status)) }}
                </span>
              </span>
              <span class="subnet-arrow">›</span>
            </div>
          </div>

        </div>
      </div>

      <!-- 局域网链路 Section -->
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
    </div>

    <!-- WAN配置页面 -->
    <WanConfig v-else-if="currentView === 'wan-config'" :wan-data="selectedWan" @go-back="goBackToMain" />
    <!-- DHCP配置页面 -->
    <DhcpConfig v-else-if="currentView === 'dhcp'" @go-back="goBackToMain" />
    <!-- Wireless配置页面 -->
    <WirelessConfig v-else-if="currentView === 'wireless'" @go-back="goBackToMain" />
  </div>
</template>

<script>
import WanConfig from './wan.vue'
import DhcpConfig from './dhcp.vue'
import WirelessConfig from './wireless.vue'

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
        2: '5G-3'
      }
      return {
        settings: {
          index: '',
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
          // 锁频端 锁频点 锁小区设置
          freqlock:{
            operatetype: '',
            forbid_flag: '',
            num: '',
            band: [],
            arfcn: [],
            scstype: [],
            pci: []
          }
        },
        status: {
          timestamp: '',
          net: '-',
          band: '',
          cell_nr: '-',
          cell_lte: '-',
          pcid_nr: '--',
          pcid_lte: '--',
          rsrp_nr: '-',
          rsrp_lte: '-',
          sinr_nr: '-',
          sinr_lte: '-',
          status: '',
          ip: '-',
          mask: '-',
          gateway: '-',
          mac: '-'
        }
      }
    }
    return {
      currentView: 'main', // 'main' 或 'wan-config'
      selectedWan: null,
      wanLinks: [
        createDefaultWanLink(0),
        createDefaultWanLink(1),
        createDefaultWanLink(2)
      ],
      subnets: [
        {
          name: 'DHCP Service'
        },
        {
          name: 'Wireless Lan'
        }
      ]
    }
  },

  methods: {
    getStatusClass(status) {
      switch (status) {
      case 'connected': return 'status-connected'
      case 'disconnected': return 'status-disconnected'
      case 'dialing': return 'status-dialing'
      case 'nosim': return 'status-nosim'
      default: return ''
      }
    },
    getStatusText(status) {
      switch (status) {
      case 'connected': return 'Online'
      case 'disconnected': return 'Offline'
      case 'dialing': return 'Dialing'
      case 'nosim': return 'NoSim'
      default: return '未知'
      }
    },
    getSimSettings() {
      // this.wanLinks.forEach((wan, index) => {
      //   this.$oui.call('sim', 'getSimStatus', {'index': index}).then(sim => {
      //     this.wanLinks[index].settings.index = index
      //     this.wanLinks[index].settings.alias = sim.settings.alias
      //     this.wanLinks[index].settings.interface = sim.settings.interface
      //     this.wanLinks[index].settings.net = sim.settings.net
      //     this.wanLinks[index].settings.apn = sim.settings.apn
      //     this.wanLinks[index].settings.band = sim.settings.band
      //     this.wanLinks[index].settings.auth = sim.settings.auth
      //     this.wanLinks[index].settings.username = sim.settings.user
      //     this.wanLinks[index].settings.password = sim.settings.passwd
      //   })
      // })
    },
    getProductInfo(index) {
      this.$oui.call('sim', 'getProductInfo', {'index': index}).then(result => {
        const data = typeof result === 'string' ? JSON.parse(result) : result
        const productInfo = this.wanLinks[index].productInfo
        if (data.vendor) productInfo.vendor = data.vendor
        if (data.product) productInfo.product = data.product
        if (data.revision) productInfo.revision = data.revision
        if (data.imei) productInfo.imei = data.imei
        if (data.iccid) productInfo.iccid = data.iccid
        if (data.imsi) productInfo.imsi = data.imsi
        this.wanLinks[index].productInfo = { ...productInfo }
      })
    },
    // 查询模组配置,是从模组中通过at指令查询到的配置,并不是uci配置
    getModuleSettings(index) {
      this.$oui.call('sim', 'getModuleSettings', {'index': index}).then(result => {
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
        if (data.freqlock) {
          if (data.freqlock.operatetype) real.freqlock.operatetype = data.freqlock.operatetype
          if (data.freqlock.forbid_flag) real.freqlock.forbid_flag = data.freqlock.forbid_flag
          if (data.freqlock.num) real.freqlock.num = data.freqlock.num
          if (data.freqlock.band) real.freqlock.band = data.freqlock.band
          if (data.freqlock.arfcn) real.freqlock.arfcn = data.freqlock.arfcn
          if (data.freqlock.scstype) real.freqlock.scstype = data.freqlock.scstype
          if (data.freqlock.pci) real.freqlock.pci = data.freqlock.pci
        }
        this.wanLinks[index].realSettings = { ...real }
      })
    },
    getStatus(index) {
      this.$oui.call('sim', 'getStatus', {'index': index}).then(result => {
        const data = typeof result === 'string' ? JSON.parse(result) : result
        const sim = this.wanLinks[index].sim
        if (data.sim) sim.status = data.sim
        if (data.operator_name) sim.operator = data.operator_name
        if (data.country) sim.country = data.country
        if (data.mcc) sim.mcc = data.mcc
        if (data.mnc) sim.mnc = data.mnc
        this.wanLinks[index].sim = { ...sim }

        if (data.monsc) {
          const monsc = data.monsc
          const newest = this.wanLinks[index].monsc
          if (monsc.rat) newest.rat = monsc.rat
          if (monsc.nr) {
            if (monsc.nr.cell_id) newest.nr.cell_id = monsc.nr.cell_id
            if (monsc.nr.arfcn) newest.nr.arfcn = monsc.nr.arfcn
            if (monsc.nr.scs) newest.nr.scs = monsc.nr.scs
            if (monsc.nr.pci) newest.nr.pci = monsc.nr.pci
            if (monsc.nr.tac) newest.nr.tac = monsc.nr.tac
            if (monsc.nr.rsrp) newest.nr.rsrp = monsc.nr.rsrp
            if (monsc.nr.rsrq) newest.nr.rsrq = monsc.nr.rsrq
            if (monsc.nr.sinr) newest.nr.sinr = monsc.nr.sinr
            // console.log("nr:", newest.nr)
          }
          if (monsc.lte) {
            if (monsc.lte.cell_id) newest.lte.cell_id = monsc.lte.cell_id
            if (monsc.lte.arfcn) newest.lte.arfcn = monsc.lte.arfcn
            if (monsc.lte.pci) newest.lte.pci = monsc.lte.pci
            if (monsc.lte.tac) newest.lte.tac = monsc.lte.tac
            if (monsc.lte.rsrp) newest.lte.rsrp = monsc.lte.rsrp
            if (monsc.lte.rsrq) newest.lte.rsrq = monsc.lte.rsrq
            if (monsc.lte.rssi) newest.lte.rssi = monsc.lte.rssi
            // console.log("lte:", newest.lte)
          }
          if (monsc.wcdma) {
            if (monsc.wcdma.cell_id) newest.wcdma.cell_id = monsc.wcdma.cell_id
            if (monsc.wcdma.arfcn) newest.wcdma.arfcn = monsc.wcdma.arfcn
            if (monsc.wcdma.pcs) newest.wcdma.pcs = monsc.wcdma.pcs
            if (monsc.wcdma.lac) newest.wcdma.lac = monsc.wcdma.lac
            if (monsc.wcdma.rscp) newest.wcdma.rscp = monsc.wcdma.rscp
            if (monsc.wcdma.rxlev) newest.wcdma.rxlev = monsc.wcdma.rxlev
            if (monsc.wcdma.ecno) newest.wcdma.ecno = monsc.wcdma.ecno
            // console.log("wcdma:", newest.wcdma)
          }
          this.wanLinks[index].monsc = { ...newest }

          if (data.monnc) {
            this.wanLinks[index].monnc = { ...data.monnc }
          }
        }
      })
    },
    // 切换到WAN配置页面
    editSubWan(wan) {
      this.selectedWan = wan
      this.currentView = 'wan-config'
    },
    // 返回主页面
    goBackToMain() {
      this.currentView = 'main'
      this.selectedWan = null
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
    this.getSimSettings()

    this.wanLinks.forEach((wan, index) => {
      this.$timer.create('sim-product' + index, () => this.getProductInfo(index), { time: 15000, immediate: true, repeat: true})
      this.$timer.create('sim-status' + index, () => this.getStatus(index), { time: 10000, immediate: true, repeat: true})
      this.$timer.create('modules' + index, () => this.getModuleSettings(index), { time: 12000, immediate: true, repeat: true})
    })
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
