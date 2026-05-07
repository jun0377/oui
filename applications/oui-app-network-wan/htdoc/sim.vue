<template>
  <div class="wan-config-container">
    <div class="header">
      <h2> {{ status.alias }}</h2>
    </div>

    <div class="config-section">
      <div class="left-column">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>{{ $t('Basic Settings') }}</span>
            </div>
          </template>
          <el-form :model="settings" label-width="120px" class="config-form" label-align="left" label-position="left">
            <el-form-item :label="$t('Label')">
              <el-input v-model="settings.alias" :placeholder="$t('Enter WAN label')" readonly disabled/>
            </el-form-item>
            <el-form-item :label="$t('Interface')">
              <el-input v-model="settings.interface" :placeholder="$t('Enter interface name')" readonly disabled/>
            </el-form-item>

            <el-form-item :label="$t('Network Access')">
              <el-select v-model="settings.net" :placeholder="$t('Select access type')" style="width: 100%">
                <el-option :label="$t('AUTO')" value="AUTO"/>
                <el-option label="SA" value="SA"/>
                <el-option label="NSA" value="NSA"/>
                <el-option label="LTE" value="LTE"/>
              </el-select>
            </el-form-item>

            <el-form-item :label="$t('Authentication')">
              <el-select v-model="settings.auth" :placeholder="$t('Select auth type')" style="width: 100%">
                <el-option :label="$t('AUTO')" value="AUTO"/>
                <el-option label="PAP" value="PAP"/>
                <el-option label="CHAP" value="CHAP"/>
                <el-option :label="$t('NONE')" value="NONE"/>
              </el-select>
            </el-form-item>

            <el-form-item :label="$t('USER')">
              <el-input v-model="settings.username" placeholder="Enter User name"/>
            </el-form-item>

            <el-form-item :label="$t('PASSWD')">
              <el-input v-model="settings.password" placeholder="Enter User password"/>
            </el-form-item>

            <el-form-item label="APN">
              <el-input v-model="settings.apn" placeholder="Enter APN"/>
            </el-form-item>

            <div style="display: flex; gap: 10px;">
              <el-form-item label="锁NR频段" style="flex: 1; margin-bottom: 0;">
                <div v-if="getNRBandOptions().length" class="band-option-list">
                  <el-tag
                    v-for="opt in getNRBandOptions()"
                    :key="opt"
                    class="band-option-tag"
                    :type="isNRBandOptionActive(opt) ? 'primary' : 'info'"
                    :effect="isNRBandOptionActive(opt) ? 'dark' : 'plain'"
                    @click="selectNRBandOption(opt)"
                  >
                    {{ opt }}
                  </el-tag>
                </div>
                <div v-else class="band-option-empty">暂无可选频段</div>
              </el-form-item>
            </div>

            <div style="display: flex; gap: 10px;">
              <el-form-item label="锁LTE频段" style="flex: 1; margin-bottom: 0;">
                <div v-if="getLTEBandOptions().length" class="band-option-list">
                  <el-tag
                    v-for="opt in getLTEBandOptions()"
                    :key="opt"
                    class="band-option-tag"
                    :type="isLTEBandOptionActive(opt) ? 'primary' : 'info'"
                    :effect="isLTEBandOptionActive(opt) ? 'dark' : 'plain'"
                    @click="selectLTEBandOption(opt)"
                  >
                    {{ opt }}
                  </el-tag>
                </div>
                <div v-else class="band-option-empty">暂无可选频段</div>
              </el-form-item>
            </div>

            <el-form-item label="锁NR PCI小区">
              <div style="display: flex; align-items: center; gap: 6px; width: 100%;">
                <el-switch
                  v-model="settings.nr_pci.enabled"
                  inline-prompt
                  :active-text="'开'"
                  :inactive-text="'关'"
                  @change="handleNRPciLock"
                  class="wan-enable-switch"
                />
                <el-input v-model="settings.nr_pci.pcid" placeholder="PCID" style="flex: 0.9;" size="small"/>
                <el-input v-model="settings.nr_pci.freq" placeholder="频点" style="flex: 0.9;" size="small"/>
                <el-select v-model="settings.nr_pci.band" placeholder="频段" style="flex: 0.9;" size="small">
                  <el-option label="n1" value="1"/>
                  <el-option label="n3" value="3"/>
                  <el-option label="n5" value="5"/>
                  <el-option label="n8" value="8"/>
                  <el-option label="n28" value="28"/>
                  <el-option label="n41" value="41"/>
                  <el-option label="n78" value="78"/>
                </el-select>
                <el-tooltip content="子载波间隔" placement="top">
                  <el-select v-model="settings.nr_pci.scs" placeholder="子载波间隔" style="flex: 1.3; min-width: 120px;" size="small">
                    <el-option label="15KHz" value="0"/>
                    <el-option label="30KHz" value="1"/>
                    <el-option label="60KHz" value="2"/>
                    <el-option label="120KHz" value="3"/>
                    <el-option label="240KHz" value="4"/>
                  </el-select>
                </el-tooltip>
              </div>
            </el-form-item>

            <el-form-item label="锁LTE PCI小区">
              <div style="display: flex; align-items: center; gap: 6px; width: 100%;">
                <el-switch
                  v-model="settings.lte_pci.enabled"
                  inline-prompt
                  :active-text="'开'"
                  :inactive-text="'关'"
                  @change="handleLtePciLock"
                  class="wan-enable-switch"
                />
                <el-input v-model="settings.lte_pci.pcid" placeholder="PCID" style="flex: 0.9;" size="small"/>
                <el-input v-model="settings.lte_pci.freq" placeholder="频点" style="flex: 0.9;" size="small"/>
                <el-select v-model="settings.lte_pci.band" placeholder="频段" style="flex: 0.9;" size="small">
                  <el-option label="b1" value="1"/>
                  <el-option label="b3" value="3"/>
                  <el-option label="b5" value="5"/>
                  <el-option label="b8" value="8"/>
                  <el-option label="b34" value="34"/>
                  <el-option label="b39" value="39"/>
                  <el-option label="b40" value="40"/>
                  <el-option label="b41" value="40"/>
                </el-select>
              </div>
            </el-form-item>

            <el-form-item :label="$t('Enable')">
              <el-switch
                v-model="settings.enable"
                inline-prompt
                :active-text="'开'"
                :inactive-text="'关'"
                @change="handleEnableChange"
                class="wan-enable-switch"
              />
            </el-form-item>
          </el-form>
          <div class="action-buttons card-actions">
            <el-button @click="saveConfig" type="primary" size="large">
              {{ $t('Save Configuration') }}
            </el-button>
            <el-button @click="testConnection" type="success" size="large" disabled>
              {{ $t('Test Connection') }}
            </el-button>
            <el-button @click="resetConfig" type="warning" size="large" disabled>
              {{ $t('Reset to Default') }}
            </el-button>
            <el-button @click="goBack" type="primary" size="large">
              {{ $t('Back') }}
            </el-button>
          </div>
        </el-card>
      </div>

      <div class="right-column">
        <div class="top-cards">
          <el-card class="config-card compact-card connection-card">
            <template #header>
              <div class="card-header">
                <span>{{ $t('连接状态') }}</span>
              </div>
            </template>

            <div class="status-info">
              <div class="status-item">
                <span class="status-label">{{ $t('Current Status') }}:</span>
                <span class="status-value">{{ getStatusText() }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('状态更新时间') }}:</span>
                <span class="status-value">{{ status.timestamp }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('Real Network Access') }}:</span>
                <span class="status-value">{{ status.rat }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('Real Band') }}:</span>
                <span class="status-value">{{ getRealBandTypeText() }}</span>
              </div>

              <div class="signal-row signal-row-right" v-if="String(status.rat).toUpperCase() !== 'LTE'">
                <div class="signal-title">NR信号:</div>
                <div class="signal-item">
                  <span class="status-label">rsrp:</span>
                  <span class="status-value">{{ status.nr.rsrp }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">rsrq:</span>
                  <span class="status-value">{{ status.nr.rsrq }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">sinr:</span>
                  <span class="status-value">{{ status.nr.sinr }}</span>
                </div>
              </div>

              <div class="signal-row" v-if="['NSA', 'LTE'].includes(String(status.rat).toUpperCase())">
                <div class="signal-title">LTE信号:</div>
                <div class="signal-item">
                  <span class="status-label">rsrp:</span>
                  <span class="status-value">{{ status.lte.rsrp }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">rsrq:</span>
                  <span class="status-value">{{ status.lte.rsrq }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">rssi:</span>
                  <span class="status-value">{{ status.lte.rssi }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">sinr:</span>
                  <span class="status-value">{{ status.lte.sinr }}</span>
                </div>
              </div>

              <div class="signal-row signal-row-right">
                <div class="signal-title">数据统计:</div>
                <div class="signal-item">
                  <span class="status-label">发送:</span>
                  <span class="status-value">{{ formatBytes(status.interface.txBytes) }}</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">接收:</span>
                  <span class="status-value">{{ formatBytes(status.interface.rxBytes) }}</span>
                </div>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('IP Address') }}:</span>
                <span class="status-value">{{ status.interface.ip }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('Netmask') }}:</span>
                <span class="status-value">{{ status.interface.mask }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('Gateway') }}:</span>
                <span class="status-value">{{ status.interface.gateway }}</span>
              </div>

              <div class="status-item">
                <span class="status-label">{{ $t('MAC') }}:</span>
                <span class="status-value">{{ status.interface.mac }}</span>
              </div>
            </div>
          </el-card>

          <div class="vertical-cards">
            <el-card class="config-card compact-card">
              <template #header>
                <div class="card-header">
                  <span>{{ $t('SIM卡状态') }}</span>
                </div>
              </template>

              <div class="status-info">
                <div class="status-item">
                  <span class="status-label">状态:</span>
                  <span class="status-value">{{ sim.status }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">国家:</span>
                  <span class="status-value">{{ sim.country }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">{{ $t('Operator') }}:</span>
                  <span class="status-value">{{ sim.mcc }}{{ sim.mnc }} {{ sim.operator }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">{{ $t('IMSI') }}:</span>
                  <span class="status-value">{{ productInfo.imsi }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">{{ $t('ICCID') }}:</span>
                  <span class="status-value">{{ productInfo.iccid }}</span>
                </div>
              </div>
            </el-card>

            <el-card class="config-card compact-card">
              <template #header>
                <div class="card-header">
                  <span>{{ $t('模组信息') }}</span>
                </div>
              </template>

              <div class="status-info">
                <div class="status-item">
                  <span class="status-label">模组型号:</span>
                  <span class="status-value">{{ productInfo.product }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">{{ $t('模组版本') }}:</span>
                  <span class="status-value">{{ productInfo.revision }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">{{ $t('IMEI') }}:</span>
                  <span class="status-value">{{ productInfo.imei }}</span>
                </div>
              </div>
            </el-card>
          </div>

          <div class="vertical-cards freqlock-cards">
            <el-card class="config-card compact-card">
              <template #header>
                <div class="card-header">
                  <span>{{ $t('NR锁频锁小区状态') }}</span>
                </div>
              </template>
              <div class="status-info">
                <div class="status-item">
                  <span class="status-label">锁状态:</span>
                  <span class="status-value">{{ getFreqLockTypeText(realSettings.nrfreqlock.operatetype) }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">频段:</span>
                  <span class="status-value">{{ realSettings.nrfreqlock.band.join(', ') }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">频点:</span>
                  <span class="status-value">{{ realSettings.nrfreqlock.arfcn.join(', ') }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">SCS:</span>
                  <span class="status-value">{{ realSettings.nrfreqlock.scstype.join(', ') }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">PCI:</span>
                  <span class="status-value">{{ realSettings.nrfreqlock.pci.join(', ') }}</span>
                </div>
              </div>
            </el-card>

            <el-card class="config-card compact-card">
              <template #header>
                <div class="card-header">
                  <span>{{ $t('LTE锁频锁小区状态') }}</span>
                </div>
              </template>
              <div class="status-info">
                <div class="status-item">
                  <span class="status-label">锁状态:</span>
                  <span class="status-value">{{ getFreqLockTypeText(realSettings.ltefreqlock.operatetype) }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">频段:</span>
                  <span class="status-value">{{ realSettings.ltefreqlock.band.map(v => 'b' + v).join(',') }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">频点:</span>
                  <span class="status-value">{{ realSettings.ltefreqlock.arfcn.join(', ') }}</span>
                </div>
                <div class="status-item">
                  <span class="status-label">PCI:</span>
                  <span class="status-value">{{ realSettings.ltefreqlock.pci.join(', ') }}</span>
                </div>
              </div>
            </el-card>
          </div>
        </div>

        <el-card class="config-card compact-card">
          <template #header>
            <div class="card-header">
              <span>{{ $t('当前驻留小区信息') }}</span>
            </div>
          </template>

          <div class="status-table">
            <div class="table-title" v-if="monsc.nr">NR 驻留小区</div>
            <div class="table-row header-row" v-if="monsc.nr">
              <div class="table-cell">ARFCN</div>
              <div class="table-cell">SCS</div>
              <div class="table-cell">Cell_ID</div>
              <div class="table-cell">PCI</div>
              <div class="table-cell">TAC</div>
              <div class="table-cell">RSRP/dBm</div>
              <div class="table-cell">RSRQ/dB</div>
              <div class="table-cell">SINR/dBm</div>
            </div>
            <div class="table-row" v-if="monsc.nr">
              <div class="table-cell">{{ monsc.nr.arfcn }}</div>
              <div class="table-cell">{{ monsc.nr.scs }}</div>
              <div class="table-cell">{{ monsc.nr.cell_id }}</div>
              <div class="table-cell">{{ monsc.nr.pci }}</div>
              <div class="table-cell">{{ monsc.nr.tac }}</div>
              <div class="table-cell">{{ monsc.nr.rsrp }}</div>
              <div class="table-cell">{{ monsc.nr.rsrq }}</div>
              <div class="table-cell">{{ monsc.nr.sinr }}</div>
            </div>

            <div class="table-title" v-if="monsc.lte.arfcn">LTE 驻留小区</div>
            <div class="table-row header-row" v-if="monsc.lte.arfcn">
              <div class="table-cell">ARFCN</div>
              <div class="table-cell">Cell_ID</div>
              <div class="table-cell">PCI</div>
              <div class="table-cell">TAC</div>
              <div class="table-cell">RSRP/dBm</div>
              <div class="table-cell">RSRQ/dB</div>
              <div class="table-cell">RSSI/dBm</div>
            </div>
            <div class="table-row" v-if="monsc.lte.arfcn">
              <div class="table-cell">{{ monsc.lte.arfcn }}</div>
              <div class="table-cell">{{ monsc.lte.cell_id }}</div>
              <div class="table-cell">{{ monsc.lte.pci }}</div>
              <div class="table-cell">{{ monsc.lte.tac }}</div>
              <div class="table-cell">{{ monsc.lte.rsrp }}</div>
              <div class="table-cell">{{ monsc.lte.rsrq }}</div>
              <div class="table-cell">{{ monsc.lte.rssi }}</div>
            </div>
          </div>
        </el-card>

        <el-card class="config-card neighbor-card">
          <template #header>
            <div class="card-header">
              <span>{{ $t('相邻小区信息') }}</span>
            </div>
          </template>

          <div class="status-table">
            <div class="table-title">NR相邻小区</div>
            <div class="table-row header-row">
              <div class="table-cell">ARFCN</div>
              <div class="table-cell">PCI</div>
              <div class="table-cell">RSRP/dBm</div>
              <div class="table-cell">RSRQ/dB</div>
              <div class="table-cell">SINR/dBm</div>
            </div>
            <div class="table-row" v-for="(cell, index) in monnc.nr" :key="'nr-' + index">
              <div class="table-cell">{{ cell.arfcn }}</div>
              <div class="table-cell">{{ cell.pci }}</div>
              <div class="table-cell">{{ cell.rsrp }}</div>
              <div class="table-cell">{{ cell.rsrq }}</div>
              <div class="table-cell">{{ cell.sinr }}</div>
            </div>
            <div class="no-data" v-if="monnc.nr.length === 0">
              {{ $t('暂无NR相邻小区数据') }}
            </div>

            <div class="table-title">LTE相邻小区</div>
            <div class="table-row header-row">
              <div class="table-cell">ARFCN</div>
              <div class="table-cell">PCI</div>
              <div class="table-cell">RSRP</div>
              <div class="table-cell">RSRQ</div>
              <div class="table-cell">RXLEV</div>
            </div>
            <div class="table-row" v-for="(cell, index) in monnc.lte" :key="'lte-' + index">
              <div class="table-cell">{{ cell.arfcn }}</div>
              <div class="table-cell">{{ cell.pci }}</div>
              <div class="table-cell">{{ cell.rsrp }}</div>
              <div class="table-cell">{{ cell.rsrq }}</div>
              <div class="table-cell">{{ cell.rxlev }}</div>
            </div>
            <div class="no-data" v-if="monnc.lte.length === 0">
              {{ $t('暂无LTE相邻小区数据') }}
            </div>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'sim-settings',
  emits: ['go-back'],
  props: {
    wanData: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      status: {
        status: '',
        timestamp: '',
        rat: '-',
        nr: { rsrp: '', rsrq: '', sinr: '', band: '' },
        lte: { rsrp: '', rsrq: '', sinr: '', rssi: '', band: '' },
        interface: { ip: '-', mask: '-', gateway: '-', mac: '-', rxBytes: '-', txBytes: '-' }
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
      monsc: {
        rat: '',
        nr: { cell_id: '', arfcn: '', scs: '', pci: '', tac: '', rsrp: '', rsrq: '', sinr: '' },
        lte: { cell_id: '', arfcn: '', pci: '', tac: '', rsrp: '', rsrq: '', rssi: '' },
        wcdma: { arfcn: '', pcs: '', cell_id: '', lac: '', rscp: '', rxlev: '', ecno: '' }
      },
      monnc: {
        gsm: [],
        wcdma: [],
        lte: [],
        nr: []
      },
      realSettings: {
        rat: '',
        pdp: { cid: '', pdp_type: '', apn: '', pdp_addr: '' },
        auth: { cid: '', auth_type: '', passwd: '', username: '', plmn: '' },
        nrfreqlock: { operatetype: '', forbid_flag: '', num: '', band: [], arfcn: [], scstype: [], pci: [] },
        ltefreqlock: { operatetype: '', forbid_flag: '', num: '', band: [], arfcn: [], pci: [] }
      },
      settings: {
        index: '',
        enable: true,
        alias: '',
        name: '',
        interface: '',
        net: '',
        apn: '',
        nrBand: '',
        nrBandUnLock: true,
        lteBand: '',
        lteBandUnLock: true,
        nr_pci: { enabled: false, pcid: '', band: '', freq: '', scs: '' },
        lte_pci: { enabled: false, pcid: '', band: '', freq: '' },
        auth: '',
        username: '',
        password: ''
      },
      settingsInitialized: false
    }
  },
  created() {
    if (this.wanData)
      this.applyWanData(this.wanData)
  },
  watch: {
    wanData: {
      handler(newVal, oldVal) {
        if (!newVal)
          return
        if (!oldVal || (oldVal.settings && newVal.settings && oldVal.settings.index !== newVal.settings.index))
          this.settingsInitialized = false
        this.applyWanData(newVal)
      },
      immediate: true
    }
  },
  methods: {
    formatBytes(bytes) {
      const n = Number(bytes)
      if (!Number.isFinite(n) || n < 0)
        return '-'
      if (n >= 1024 * 1024 * 1024)
        return `${(n / 1024 / 1024 / 1024).toFixed(2)} GB`
      if (n >= 1024 * 1024)
        return `${(n / 1024 / 1024).toFixed(2)} MB`
      if (n >= 1024)
        return `${(n / 1024).toFixed(2)} KB`
      return `${n} B`
    },
    getFreqLockTypeText(type) {
      const map = { '0': '解锁状态', '1': '锁频点+锁频段', '2': '锁小区+频点+锁频段', '3': '锁频段' }
      return map[type] || type
    },
    getRealBandTypeText() {
      const fi = this.freqInfo
      if (!fi)
        return ''
      const sysmode = String(fi.sysmode ?? '').trim().toUpperCase()
      let isNr = false
      let isLte = false
      if (sysmode.includes('NR')) isNr = true
      else if (sysmode.includes('LTE')) isLte = true
      else if (sysmode === '7') isNr = true
      else if (sysmode === '3') isLte = true
      if (!isNr && !isLte) {
        const rat = String(this.status?.rat ?? '').toUpperCase()
        if (rat.includes('LTE')) isLte = true
        else if (rat.includes('NR')) isNr = true
      }
      const list = Array.isArray(fi.class) ? fi.class : []
      const seen = new Set()
      const prefix = isNr ? 'n' : 'b'
      const bands = []
      for (const item of list) {
        const bandClass = item && item.band_class !== null ? String(item.band_class).trim() : ''
        if (!bandClass || seen.has(bandClass))
          continue
        seen.add(bandClass)
        bands.push(prefix + bandClass)
      }
      return bands.join(' ')
    },
    getNRBandOptions() {
      return ['解锁', 'n1', 'n3', 'n5', 'n8', 'n28', 'n41', 'n78', 'n79']
    },
    getLTEBandOptions() {
      return ['解锁', 'b1', 'b3', 'b5', 'b8', 'b34', 'b38', 'b39', 'b40', 'b41']
    },
    applyWanData(data) {
      if (!data)
        return
      this.status = data.status
      this.productInfo = data.productInfo
      this.sim = data.sim
      this.freqInfo = data.freqInfo
      this.NR_5GCore = data.NR_5GCore
      this.CS = data.CS
      this.monsc = data.monsc
      this.monnc = data.monnc
      this.realSettings = data.realSettings
      this.freqInfo = data.freqInfo
      if (!this.settingsInitialized) {
        this.settings.index = data.settings.index
        this.settings.enable = typeof data.settings.enable === 'boolean' ? data.settings.enable : true
        this.settings.alias = data.settings.alias
        this.settings.interface = data.settings.interface
        this.settings.net = String(data.settings.net || '').toUpperCase()
        this.settings.apn = data.settings.apn
        this.settings.band = data.settings.band || data.settings.settingsBand || ''
        this.settings.auth = data.settings.auth
        this.settings.username = data.settings.username
        this.settings.password = data.settings.password
        const bandTokens = String(this.settings.band || '').split(',').map(item => item.trim()).filter(Boolean)
        const nrStoredBand = bandTokens.find(item => item.toLowerCase().startsWith('n')) || ''
        const lteStoredBand = bandTokens.find(item => item.toLowerCase().startsWith('b')) || ''
        const nrRealBand = data.realSettings && data.realSettings.nrfreqlock && Array.isArray(data.realSettings.nrfreqlock.band) ? (data.realSettings.nrfreqlock.band[0] || '') : ''
        const lteRealBand = data.realSettings && data.realSettings.ltefreqlock && Array.isArray(data.realSettings.ltefreqlock.band) ? (data.realSettings.ltefreqlock.band[0] || '') : ''
        this.settings.nrBand = nrRealBand || nrStoredBand
        this.settings.lteBand = lteRealBand || lteStoredBand
        this.settings.nrBandUnLock = (this.settings.nrBand === 'none' || this.settings.nrBand === '')
        this.settings.lteBandUnLock = (this.settings.lteBand === 'none' || this.settings.lteBand === '')
        if (this.settings.nrBandUnLock)
          this.settings.nrBand = 'none'
        if (this.settings.lteBandUnLock)
          this.settings.lteBand = 'none'
        this.settings.bandUnLock = this.settings.nrBandUnLock && this.settings.lteBandUnLock
        this.settings.cell = data.settings.cell || data.settings.settingsCell
        this.settings.pci = data.settings.pcid || data.settings.settingsPCI
        this.settings.pciUnlock = (this.settings.pci === 'none' || this.settings.pci === '')
        this.settingsInitialized = true
      }
    },
    goBack() {
      this.$emit('go-back')
    },
    handleEnableChange(enabled) {
      this.settings.enable = enabled
      this.$oui.call('sim', 'changeSimEnable', this.settings).then((response) => {
        if (response === 0)
          this.$message[enabled ? 'success' : 'warning'](enabled ? '已开启' : '已关闭')
        else
          this.$message.error('设置失败')
      }).catch(() => {
        this.$message.error('设置失败')
      })
    },
    getStatusText() {
      return 'NR' + this.NR_5GCore.stat + ' | ' + 'LTE' + this.CS.stat
    },
    saveConfig() {
      if (!this.settings.interface) {
        this.$message.error('The network interface must be specified!')
        return
      }
      if (this.settings.nr_pci && this.settings.nr_pci.enabled) {
        if (!this.settings.nr_pci.pcid || !this.settings.nr_pci.band || !this.settings.nr_pci.freq || this.settings.nr_pci.scs === '') {
          this.$message.error('请完整填写NR PCI锁定参数: PCID/频段/频点/子载波间隔')
          return
        }
      }
      if (this.settings.lte_pci && this.settings.lte_pci.enabled) {
        if (!this.settings.lte_pci.pcid || !this.settings.lte_pci.band || !this.settings.lte_pci.freq) {
          this.$message.error('请完整填写LTE PCI锁定参数: PCID/频段/频点')
          return
        }
      }
      if (!this.settings.pciUnlock && ('none' === this.settings.pci || '' === this.settings.pci)) {
        this.$message.error('请设置小区PCID 或 解锁小区!')
        return
      }
      this.$oui.call('sim', 'changeSimSettings', this.settings).then((response) => {
        if (response && response.code === 0)
          this.$message.success('设置成功')
      })
    },
    testConnection() {
      this.$message.info(this.$t('Testing connection...'))
    },
    resetConfig() {
      this.$confirm(this.$t('Are you sure to reset to default configuration?'), this.$t('Confirm Reset'), { type: 'warning' }).then(() => {
        this.settings = { ...this.status }
        this.$message.success(this.$t('Configuration reset successfully'))
      })
    },
    handleNRPciLock(enabled) {
      if (!enabled) {
        this.settings.nr_pci.pcid = ''
        this.settings.nr_pci.band = ''
        this.settings.nr_pci.freq = ''
        this.settings.nr_pci.scs = ''
      }
    },
    handleLtePciLock(enabled) {
      if (!enabled) {
        this.settings.lte_pci.pcid = ''
        this.settings.lte_pci.band = ''
        this.settings.lte_pci.freq = ''
      }
    },
    selectNRBandOption(value) {
      if (value === '解锁') {
        this.settings.nrBand = 'none'
        this.settings.nrBandUnLock = true
        return
      }
      this.settings.nrBand = value
      this.settings.nrBandUnLock = false
    },
    selectLTEBandOption(value) {
      if (value === '解锁') {
        this.settings.lteBand = 'none'
        this.settings.lteBandUnLock = true
        return
      }
      this.settings.lteBand = value
      this.settings.lteBandUnLock = false
    },
    isNRBandOptionActive(value) {
      if (value === '解锁')
        return this.settings.nrBandUnLock || this.settings.nrBand === ''
      return !this.settings.nrBandUnLock && this.settings.nrBand === value
    },
    isLTEBandOptionActive(value) {
      if (value === '解锁')
        return this.settings.lteBandUnLock || this.settings.lteBand === ''
      return !this.settings.lteBandUnLock && this.settings.lteBand === value
    }
  }
}
</script>

<style scoped>
.wan-config-container {
  max-width: 1600px;
  margin: 0 auto;
  padding: 20px;
  --status-value-col-width: 10ch;
}

.header {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  gap: 15px;
}

.header h2 {
  margin: 0;
  color: var(--el-text-color-primary);
}

.config-section {
  display: grid;
  grid-template-columns: 0.7fr 1.3fr;
  gap: 20px;
  margin-bottom: 30px;
  align-items: start;
}

.left-column {
  display: flex;
  flex-direction: column;
}

.right-column {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.top-cards {
  display: flex;
  gap: 20px;
  align-items: stretch;
}

.top-cards .config-card {
  flex: 1;
}

.top-cards .connection-card {
  flex: 1.1;
}

.vertical-cards {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.vertical-cards.freqlock-cards {
  flex: 1;
}

.vertical-cards .config-card {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.vertical-cards .config-card .status-info {
  flex: 1;
}

.config-card {
  border-radius: 8px;
}

.compact-card .card-header {
  font-size: 14px;
}

.vertical-cards .compact-card .card-header {
  padding: 0 15px;
}

.compact-card .status-item {
  padding: 6px 0;
}

.vertical-cards .compact-card .status-item {
  padding: 4px 0;
}

.compact-card .status-label {
  font-size: 13px;
}

.vertical-cards .compact-card .status-label {
  font-size: 12px;
}

.compact-card .status-value {
  font-size: 13px;
}

.vertical-cards .compact-card .status-value {
  font-size: 12px;
}

.compact-card .status-value-label {
  font-size: 12px;
}

.neighbor-card {
  flex: 2;
}

.card-header {
  font-weight: 500;
  font-size: 16px;
}

.config-form {
  padding: 10px 0;
}

.status-info {
  padding: 10px 0;
}

.signal-row {
  display: flex;
  gap: 15px;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
  align-items: center;
}

.signal-row:last-child {
  border-bottom: none;
}

.signal-row-right {
  justify-content: flex-start;
}

.signal-row-right .signal-title {
  margin-right: auto;
}

.signal-row-right .signal-item {
  justify-content: flex-end;
  flex: 0 0 auto;
}

.signal-title {
  font-size: 13px;
  font-weight: 500;
  color: var(--el-text-color-regular);
  min-width: 80px;
}

.signal-item {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  gap: 5px;
  flex: 1;
}

.signal-item .status-label {
  font-size: 11px;
  color: var(--el-text-color-regular);
}

.signal-item .status-value {
  font-size: 12px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.status-table {
  display: flex;
  flex-direction: column;
  gap: 15px;
  padding: 10px 0;
}

.table-title {
  font-weight: 600;
  font-size: 14px;
  color: var(--el-text-color-primary);
  margin-bottom: 5px;
  text-align: center;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.table-title::before,
.table-title::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid var(--el-border-color-lighter);
  margin: 0 10px;
}

.table-row {
  display: flex;
  gap: 10px;
}

.header-row {
  border-bottom: 1px solid var(--el-border-color-lighter);
  padding-bottom: 5px;
  margin-bottom: 5px;
}

.table-cell {
  flex: 1;
  text-align: center;
  font-size: 12px;
  padding: 5px 2px;
}

.header-row .table-cell {
  font-weight: 600;
  color: var(--el-text-color-regular);
}

.table-row:not(.header-row) .table-cell {
  font-weight: 500;
  color: var(--el-text-color-primary);
}

.table-row:not(.header-row):hover,
.table-row:not(.header-row):hover .table-cell {
  background-color: var(--el-fill-color-light);
}

.no-data {
  text-align: center;
  padding: 20px;
  color: var(--el-text-color-secondary);
  font-size: 13px;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.status-item:last-child {
  border-bottom: none;
}

.status-label {
  font-weight: 500;
  color: var(--el-text-color-regular);
}

.status-value {
  font-weight: 600;
}

.card-actions {
  justify-content: flex-end;
}

.action-buttons {
  display: flex;
  justify-content: center;
  gap: 15px;
}

.band-option-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  min-height: 32px;
  align-items: center;
}

.band-option-tag {
  cursor: pointer;
}

.band-option-empty {
  color: var(--el-text-color-secondary);
  font-size: 12px;
}

:deep(.wan-enable-switch.el-switch:not(.is-checked) .el-switch__inner .is-text),
:deep(.wan-enable-switch:not(.is-checked) .el-switch__inner .is-text) {
  color: var(--el-color-danger);
}

@media (max-width: 768px) {
  .config-section {
    grid-template-columns: 1fr;
  }

  .action-buttons {
    flex-direction: column;
    align-items: center;
  }

  .action-buttons .el-button {
    width: 200px;
  }
}
</style>

<i18n src="./locale.json"/>
