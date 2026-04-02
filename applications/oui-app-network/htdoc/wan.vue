<template>
  <div class="wan-config-container">
    <div class="header">
      <h2> {{ status.alias }}</h2>
    </div>

    <div class="config-section">
      <!-- 左侧：基本设置卡片 -->
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
              <el-icon><ArrowLeft /></el-icon>
              {{ $t('Back') }}
            </el-button>
          </div>
        </el-card>
      </div>

      <div class="right-column">
        <div class="top-cards">
        <!-- 上方：连接状态和SIM卡状态水平排列 -->
          <!-- 连接状态卡片 -->
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

              <!-- 实时入网方式 -->
              <div class="status-item">
                <span class="status-label">{{ $t('Real Network Access') }}:</span>
                <span class="status-value">{{ status.rat }}</span>
              </div>
              <!-- 实时频段 -->
              <div class="status-item">
                <span class="status-label">{{ $t('Real Band') }}:</span>
                <span class="status-value">{{ getRealBandTypeText() }}</span>
              </div>

              <!-- NR信号强度 -->
              <div class="signal-row signal-row-right" v-if="String(status.rat).toUpperCase() !== 'LTE'">
                <div class="signal-title">NR信号:</div>
                <!-- <div class="signal-item">
                  <span class="status-label">band:</span>
                  <span class="status-value">{{ status.nr.band }}</span>
                </div> -->
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

              <!-- LTE信号强度 -->
              <div class="signal-row" v-if="['NSA', 'LTE'].includes(String(status.rat).toUpperCase())">
                <div class="signal-title">LTE信号:</div>
                <!-- <div class="signal-item">
                  <span class="status-label">band:</span>
                  <span class="status-value">{{ status.lte.band }}</span>
                </div> -->
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
                  <span class="status-value">{{ (Number(status.interface.txBytes) / 1024 / 1024).toFixed(2) }} MB</span>
                </div>
                <div class="signal-item">
                  <span class="status-label">接收:</span>
                  <span class="status-value">{{ (Number(status.interface.rxBytes) / 1024 / 1024).toFixed(2) }} MB</span>
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

          <!-- SIM卡状态和模组状态垂直排列 -->
          <div class="vertical-cards">
            <!-- SIM卡状态卡片 -->
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

            <!-- 模组状态卡片 -->
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

          <!-- NR锁频锁小区状态 -->
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
            <!-- LTE锁频锁小区状态 -->
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

        <!-- 当前驻留小区信息卡片 -->
        <el-card class="config-card compact-card">
          <template #header>
            <div class="card-header">
              <span>{{ $t('当前驻留小区信息') }}</span>
            </div>
          </template>

          <div class="status-table">
            <div class="table-title" v-if="monsc.nr">NR 驻留小区</div>
            <div class="table-row header-row" v-if="monsc.nr">
              <!-- <div class="table-cell">RAT</div> -->
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

        <!-- 下方：相邻小区信息卡片 -->
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
  name: 'settings',
  props: {
    wanData: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
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
        // 接口信息
        interface: {
          ip: '-',
          mask: '-',
          gateway: '-',
          mac: '-',
          rxBytes: '-', // 接收流量
          txBytes: '-' // 发送流量
        }
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
      monsc: {
        rat: '',
        nr: {
          cell_id: '',
          arfcn: '',
          scs: '',
          pci: '',
          tac: '',
          rsrp: '',
          rsrq: '',
          sinr: ''
        },
        lte: {
          cell_id: '',
          arfcn: '',
          pci: '',
          tac: '',
          rsrp: '',
          rsrq: '',
          rssi: ''
        },
        wcdma: {
          arfcn: '',
          pcs: '',
          cell_id: '',
          lac: '',
          rscp: '',
          rxlev: '',
          ecno: ''
        }
      },
      monnc: {
        gsm: [],
        wcdma: [],
        lte: [],
        nr: []
      },
      realSettings: {
        rat: '',
        pdp: {
          cid: '',
          pdp_type: '',
          apn: '',
          pdp_addr: ''
        },
        auth: {
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
      settings: {
        // 链路索引
        index: '',
        // 链路使能
        enable: true,
        // 链路标签,如5G-1 5G-2
        alias: '',
        name: '',
        interface: '',
        //入网方式
        net: '',
        apn: '',
        // NR锁频段 锁PCI小区
        nrBand: '',
        nrBandUnLock: true,
        // LTE锁频段 锁PCI小区
        lteBand: '',
        lteBandUnLock: true,
        // 锁小区, 锁小区时必须同时指定 频段 频点 载波 载波间隔
        nr_pci: {
          enabled: false,
          pcid: '',
          band: '',
          freq: '',
          scs: ''
        },
        lte_pci: {
          enabled: false,
          pcid: '',
          band: '',
          freq: ''
        },
        // 鉴权
        auth: '',
        username: '',
        password: ''
      },
      // 仅在首次进入页面时初始化 settings，后续不再自动覆盖
      settingsInitialized: false
    }
  },
  created() {
    if (this.wanData) {
      this.applyWanData(this.wanData)
    }
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
    getFreqLockTypeText(type) {
      const map = { '0': '解锁状态', '1': '锁频点+锁频段', '2': '锁小区+频点+锁频段', '3': '锁频段' }
      return map[type] || type
    },
    // 从freqInfo中解析出频段信息
    getRealBandTypeText() {
      const fi = this.freqInfo
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
        const rat = String(this.status?.rat ?? '').toUpperCase()
        if (rat.includes('LTE'))
          isLte = true
        else if (rat.includes('NR'))
          isNr = true
      }

      const list = Array.isArray(fi.class) ? fi.class : []
      const seen = new Set()
      const prefix = isNr ? 'n' : 'b'
      const bands = []

      for (const item of list) {
        const bandClass = item && item.band_class !== null ? String(item.band_class).trim() : ''
        if (!bandClass)
          continue
        if (seen.has(bandClass))
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
    buildBandValue() {
      const values = []
      if (!this.settings.nrBandUnLock && this.settings.nrBand)
        values.push(this.settings.nrBand)
      if (!this.settings.lteBandUnLock && this.settings.lteBand)
        values.push(this.settings.lteBand)
      return values.length ? values.join(',') : 'none'
    },
    // 将 props.wanData 映射到本地状态（wanInfo / wanConfig）
    applyWanData(data) {
      if (!data) return

      // 实时状态
      this.status = data.status
      // productInfo
      this.productInfo = data.productInfo
      // sim
      this.sim = data.sim
      // freq LTE/NR工作频率 频段
      this.freqInfo = data.freqInfo
      // 5G Core注册状态
      this.NR_5GCore = data.NR_5GCore
      // CS域注册状态, 可用于反应LTE注册状态
      this.CS = data.CS
      // monsc
      this.monsc = data.monsc
      // monnc
      this.monnc = data.monnc
      // 从模组中查到的真实配置
      this.realSettings = data.realSettings
      // console.log('real settings:', this.realSettings)

      // freq LTE/NR工作频率 频段
      this.freqInfo = data.freqInfo

      // settings 仅在首次进入页面时初始化一次
      if (!this.settingsInitialized) {
        this.settings.index = data.settings.index
        // console.log('index-----------------', this.settings.index)
        this.settings.enable = typeof data.settings.enable === 'boolean' ? data.settings.enable : true
        this.settings.alias = data.settings.alias
        this.settings.interface = data.settings.interface
        this.settings.net = String(data.settings.net || '').toUpperCase()
        this.settings.apn = data.settings.apn
        this.settings.band = data.settings.band || data.settings.settingsBand || ''
        this.settings.auth = data.settings.auth
        this.settings.username = data.settings.username
        this.settings.password = data.settings.password
        const bandTokens = String(this.settings.band || '')
          .split(',')
          .map(item => item.trim())
          .filter(Boolean)
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
    // 使能
    handleEnableChange(enabled) {
      this.settings.enable = enabled
      this.$oui.call('sim', 'changeSimEnable', this.settings).then(response => {
        if (0 === response) {
          if (enabled) {
            this.$message.success('已开启')
          } else {
            this.$message.warning('已关闭')
          }
        } else {
          this.$message.error('设置失败')
        }
      }).catch((err) => {
        console.error('changeSimEnable error:', err)
        this.$message.error('设置失败')
      })
    },
    getStatusText() {
      // 判断当前的实时网络
      return 'NR' + this.NR_5GCore.stat + ' | ' + 'LTE' + this.CS.stat
    },
    // 保存配置
    saveConfig() {
      // 验证必填字段
      if (!this.settings.interface) {
        console.log('The network interface must be specified!')
        this.$message.error('The network interface must be specified!')
        return
      }
      // if (!this.settings.nrBandUnLock && ('none' === this.settings.nrBand || '' === this.settings.nrBand)) {
      //   this.$message.error('请设置NR频段 或 解锁NR频段!')
      //   return
      // }
      // if (!this.settings.lteBandUnLock && ('none' === this.settings.lteBand || '' === this.settings.lteBand)) {
      //   this.$message.error('请设置LTE频段 或 解锁LTE频段!')
      //   return
      // }
      if (this.settings.nr_pci && this.settings.nr_pci.enabled) {
        if (!this.settings.nr_pci.pcid || !this.settings.nr_pci.band || !this.settings.nr_pci.freq || this.settings.nr_pci.scs === '') {
          this.$message.error('请完整填写NR PCI锁定参数: PCID/频段/频点/子载波间隔')
          return
        }

        console.log(this.settings.index,
          'alias:', this.settings.alias,
          'pcid:', this.settings.nr_pci.pcid,
          'band:', this.settings.nr_pci.band,
          'freq:', this.settings.nr_pci.freq,
          'scs:', this.settings.nr_pci.scs
        )
      }
      if (this.settings.lte_pci && this.settings.lte_pci.enabled) {
        if (!this.settings.lte_pci.pcid || !this.settings.lte_pci.band || !this.settings.lte_pci.freq) {
          this.$message.error('请完整填写LTE PCI锁定参数: PCID/频段/频点')
          return
        }

        console.log(this.settings.index,
          'alias:', this.settings.alias,
          'pcid:', this.settings.lte_pci.pcid,
          'band:', this.settings.lte_pci.band,
          'freq:', this.settings.lte_pci.freq
        )
      }
      // 锁小区参数
      if (!this.settings.pciUnlock && ('none' === this.settings.pci || '' === this.settings.pci)) {
        console.log('PCI locked but not specify the PCID!')
        this.$message.error('请设置小区PCID 或 解锁小区!')
        return
      }

      // if (this.settings.nrBandUnLock)
      //   this.settings.nrBand = 'none'
      // if (this.settings.lteBandUnLock)
      //   this.settings.lteBand = 'none'

      console.log('saveConf index:', this.settings.index,
        'alias:', this.settings.alias,
        'apn:', this.settings.apn,
        'net:', this.settings.net,
        'nrBand:', this.settings.nrBand,
        'lteBand:', this.settings.lteBand,
        'pcid:', this.settings.pci,
        'auth', this.settings.auth,
        'username', this.settings.username,
        'password', this.settings.password
      )

      // 调用后端API保存配置
      this.$oui.call('sim', 'changeSimSettings', this.settings).then(response => {
        if (response && 0 === response.code) {
          this.$message.success('设置成功')
        }
      })
    },
    // 测试连接
    testConnection() {
      this.$message.info(this.$t('Testing connection...'))
    },
    resetConfig() {
      this.$confirm(this.$t('Are you sure to reset to default configuration?'), this.$t('Confirm Reset'), {
        type: 'warning'
      }).then(() => {
        // 重置配置逻辑
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
    },
    handleUnlockPCI(unlocked) {
      console.log('this.settings.pciUnlock: ', this.settings.pciUnlock)
      if (unlocked) {
        this.settings.pci = ''
      } else {
        this.settings.pci = this.wanData.settingsPCI
      }
    }
  }
}
</script>

<style scoped>
.wan-config-container {
  max-width: 1600px;
  margin: 0 auto;
  padding: 20px;
  /* 统一右侧值列宽度，保证 NR/LTE 在三项中对齐 */
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

.signal-row-left {
  justify-content: flex-start;
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

.table-row:not(.header-row):hover {
  background-color: var(--el-fill-color-light);
}

.table-row:not(.header-row):hover .table-cell {
  background-color: var(--el-fill-color-light);
}

.no-data {
  text-align: center;
  padding: 20px;
  color: var(--el-text-color-secondary);
  font-size: 13px;
}

.status-info-single-line {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  padding: 10px 0;
}

.status-param {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
}

.param-label {
  font-weight: 500;
  color: var(--el-text-color-regular);
}

.param-value {
  font-weight: 600;
  color: var(--el-text-color-primary);
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

.status-value-multi {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

/* 使 5G/4G 标签固定宽度对齐，值列随内容自适应 */
.status-value-line {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 6px;
}
.status-value-label {
  width: 34px; /* 固定标签宽度，保障两行对齐 */
  text-align: right;
  flex-shrink: 0;
}

/* 让 RSRP 两行在同一右边界对齐，标签列固定宽度 */
.status-item-rsrp .status-value-multi {
  display: grid;
  grid-template-columns: 34px var(--status-value-col-width);
  justify-content: end;
  row-gap: 4px;
}
.status-item-rsrp .status-value-line {
  display: contents; /* 让 label/value 直接参与 grid 布局 */
}
.status-item-rsrp .status-value {
  text-align: right; /* 值列右对齐，保持两行最右侧对齐 */
}

/* PCID 行：右侧多行值保持顶部对齐，左侧 label 垂直居中 */
.status-item-pcid {
  align-items: flex-start;
}
.status-item-pcid .status-label {
  align-self: center;
}

/* PCID 两行与 RSRP 一致：固定 34px 标签列 + 值列右对齐 */
.status-item-pcid .status-value-multi {
  display: grid;
  grid-template-columns: 34px var(--status-value-col-width);
  justify-content: end;
  row-gap: 4px;
}
.status-item-pcid .status-value-line {
  display: contents;
}
.status-item-pcid .status-value {
  text-align: right;
}

/* Cell ID 两行与 PCID/RSRP 一致：固定 34px 标签列 + 值列右对齐 */
.status-item-cellid .status-value-multi {
  display: grid;
  grid-template-columns: 34px var(--status-value-col-width);
  justify-content: end;
  row-gap: 4px;
}
.status-item-cellid .status-value-line {
  display: contents;
}
.status-item-cellid .status-value {
  text-align: right;
}

/* 三个区块的值列统一固定宽度并右对齐，确保 NR/LTE 对齐 */
.status-item-rsrp .status-value,
.status-item-pcid .status-value,
.status-item-cellid .status-value {
  width: var(--status-value-col-width);
  text-align: right;
}

/* 固定占 5 个字符宽度，数字右对齐，使用等宽字体 */
.status-fixed-5ch {
  display: inline-block;
  width: 5ch;
  text-align: right;
  font-family: 'Courier New', monospace;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

/* 固定占 10 个字符宽度（用于 cell_nr / cell_lte） */
.status-fixed-10ch {
  display: inline-block;
  width: 10ch;
  text-align: right;
  font-family: 'Courier New', monospace;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

/* 卡片内部的操作按钮区域：靠右排列 */
.card-actions {
  justify-content: flex-end;
}

.status-connected {
  color: var(--el-color-success);
  animation: blink 1s infinite linear;
}

.status-disconnected {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
}

.status-dialing {
  color: var(--el-color-warning);
  animation: blink 1s infinite linear;
}

.status-nosim {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
}

.status-disabled {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
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

/* 让“关”字在未开启状态下显示为红色 */
:deep(.wan-enable-switch.el-switch:not(.is-checked) .el-switch__inner .is-text) {
  color: var(--el-color-danger);
}
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
