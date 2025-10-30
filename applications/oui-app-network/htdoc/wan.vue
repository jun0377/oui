<template>
  <div class="wan-config-container">
    <div class="header">
      <h2> {{ wanInfo.alias }}</h2>
    </div>

    <div class="config-section">
      <el-card class="config-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('Basic Settings') }}</span>
          </div>
        </template>
        <el-form :model="wanConfig" label-width="120px" class="config-form" label-align="left" label-position="left">
          <el-form-item :label="$t('Label')">
            <el-input v-model="wanConfig.alias" :placeholder="$t('Enter WAN label')" readonly disabled/>
          </el-form-item>
          <el-form-item :label="$t('Interface')">
            <el-input v-model="wanConfig.interface" :placeholder="$t('Enter interface name')" readonly disabled/>
          </el-form-item>

          <el-form-item :label="$t('Network Access')">
            <el-select v-model="wanConfig.net" :placeholder="$t('Select access type')" style="width: 100%">
              <el-option :label="$t('AUTO')" value="AUTO"/>
              <el-option label="SA" value="SA"/>
              <el-option label="NSA" value="NSA"/>
              <el-option label="LTE" value="LTE"/>
            </el-select>
          </el-form-item>

          <el-form-item :label="$t('Authentication')">
            <el-select v-model="wanConfig.auth" :placeholder="$t('Select auth type')" style="width: 100%">
              <el-option :label="$t('AUTO')" value="AUTO"/>
              <el-option label="PAP" value="PAP"/>
              <el-option label="CHAP" value="CHAP"/>
              <el-option :label="$t('NONE')" value="NONE"/>
            </el-select>
          </el-form-item>

          <el-form-item :label="$t('USER')">
            <el-input v-model="wanConfig.username" placeholder="Enter User name"/>
          </el-form-item>

          <el-form-item :label="$t('PASSWD')">
            <el-input v-model="wanConfig.password" placeholder="Enter User password"/>
          </el-form-item>

          <el-form-item label="APN">
            <el-input v-model="wanConfig.apn" placeholder="Enter APN"/>
          </el-form-item>

          <el-form-item :label="$t('Lock Frequency Band')">
            <div style="display: flex; align-items: center; gap: 10px;">
              <el-input
                v-model="wanConfig.band"
                :placeholder="wanConfig.bandUnLock ? '自动' : $t('band like: n78、b1...')"
                :readonly="wanConfig.bandUnLock"
                style="flex: 1;"
              />
              <el-checkbox v-model="wanConfig.bandUnLock" @change="handleUnlockBand">解锁</el-checkbox>
            </div>
          </el-form-item>

          <el-form-item :label="$t('Lock PCI')">
            <div style="display: flex; align-items: center; gap: 10px;">
              <el-input
                v-model="wanConfig.pci"
                :placeholder="wanConfig.pciUnlock ? '自动' : $t('Enter PCID')"
                :readonly="wanConfig.pciUnlock"
                style="flex: 1;"
              />
              <el-checkbox v-model="wanConfig.pciUnlock" @change="handleUnlockPCI">解锁</el-checkbox>
            </div>
          </el-form-item>

          <el-form-item :label="$t('Enable')">
            <el-switch
              v-model="wanConfig.enable"
              inline-prompt
              :active-text="'开'"
              :inactive-text="'关'"
              @change="handleEnableChange"
              class="wan-enable-switch"
            />
          </el-form-item>

        </el-form>
      </el-card>

      <el-card class="config-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('Status Information') }}</span>
          </div>
        </template>

        <div class="status-info">
          <div class="status-item">
            <span class="status-label">{{ $t('Current Status') }}:</span>
            <span :class="['status-value', getStatusClass(wanInfo.status)]">
              {{ getStatusText(wanInfo.status) }}
            </span>
          </div>
          
          <div class="status-item">
            <span class="status-label">{{ $t('状态更新时间') }}:</span>
            <span class="status-value">{{ wanInfo.timestamp }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Operator') }}:</span>
            <span class="status-value">{{ getOperatorString(wanInfo.operator) }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('IMSI') }}:</span>
            <span class="status-value">{{ wanInfo.imsi }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('IMEI') }}:</span>
            <span class="status-value">{{ wanInfo.imei }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real Network Access') }}:</span>
            <span class="status-value">{{ wanInfo.realNetworkAccess }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real Band') }}:</span>
            <span class="status-value">{{ wanInfo.realBand }}</span>
          </div>

          <div class="status-item status-item-cellid">
            <span class="status-label">{{ $t('Cell ID') }}:</span>
            <div class="status-value-multi">
              <div class="status-value-line">
                <span class="status-value-label">NR:</span>
                <span class="status-value status-fixed-10ch">{{ wanInfo.cell_nr }}</span>
              </div>
              <div class="status-value-line">
                <span class="status-value-label">LTE:</span>
                <span class="status-value status-fixed-10ch">{{ wanInfo.cell_lte }}</span>
              </div>
            </div>
          </div>

          <div class="status-item status-item-pcid">
            <span class="status-label">{{ $t('Physical Cell ID(PCID)') }}:</span>
            <div class="status-value-multi">
              <div class="status-value-line">
                <span class="status-value-label">NR:</span>
                <span class="status-value status-fixed-5ch">{{ wanInfo.realPCINR }}</span>
              </div>
              <div class="status-value-line">
                <span class="status-value-label">LTE:</span>
                <span class="status-value status-fixed-5ch">{{ wanInfo.realPCILTE }}</span>
              </div>
            </div>
          </div>

          <div class="status-item status-item-rsrp">
            <span class="status-label">{{ $t('Signal Strength') }}:</span>
            <div class="status-value-multi">
              <div class="status-value-line">
                <span class="status-value-label">NR: </span>
                <span class="status-value"><span class="status-fixed-5ch">{{ wanInfo.rsrp_nr }}</span> dBm</span>
              </div>
              <div class="status-value-line">
                <span class="status-value-label">LTE: </span>
                <span class="status-value"><span class="status-fixed-5ch">{{ wanInfo.rsrp_lte }}</span> dBm</span>
              </div>
            </div>
          </div>

          <div class="status-item status-item-rsrp">
            <span class="status-label">{{ $t('信噪比') }}:</span>
            <div class="status-value-multi">
              <div class="status-value-line">
                <span class="status-value-label">NR: </span>
                <span class="status-value"><span class="status-fixed-5ch">{{ wanInfo.sinr_nr }}</span> dB</span>
              </div>
              <div class="status-value-line">
                <span class="status-value-label">LTE: </span>
                <span class="status-value"><span class="status-fixed-5ch">{{ wanInfo.sinr_lte }}</span> dB</span>
              </div>
            </div>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('模组版本') }}:</span>
            <span class="status-value">{{ wanInfo.version }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('IP Address') }}:</span>
            <span class="status-value">{{ wanInfo.ip }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Netmask') }}:</span>
            <span class="status-value">{{ wanInfo.mask }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Gateway') }}:</span>
            <span class="status-value">{{ wanInfo.gateway }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('MAC') }}:</span>
            <span class="status-value">{{ wanInfo.mac }}</span>
          </div>

        </div>
      </el-card>
    </div>

    <div class="action-buttons">
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
  </div>
</template>

<script>

export default {
  name: 'WanConfig',
  props: {
    wanData: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      wanInfo: {
        alias: '',
        interface: '',
        timestamp: '',
        version: '',
        imsi: '',
        imei: '',
        operator: '',
        realNetworkAccess: '',
        realBand: '',
        realCell: '',
        realPCI: '',
        realPCINR: '',
        realPCILTE: '',
        rsrp_nr: '',
        rsrp_lte: '',
        sinr_nr: '',
        sinr_lte: '',
        cell_nr: '',
        cell_lte: '',
        signal: '',
        status: '',
        ip: '',
        mask: '',
        gateway: '',
        mac: ''
      },
      wanConfig: {
        index: '',
        enable: true,
        alias: '',
        name: '',
        interface: '',
        net: '',
        accessType: '',
        apn: '',
        band: '',
        bandUnLock: true,
        cell: '',
        pci: '',
        pciUnlock: true,
        auth: '',
        username: '',
        password: ''
      }
    }
  },
  created() {
    // 初始化一次
    if (this.wanData) {
      this.applyWanData(this.wanData)
    }
  },
  watch: {
    // 监听父组件传入的 wanData，实时更新界面
    wanData: {
      handler(newVal) {
        if (newVal) {
          this.applyWanData(newVal)
        }
      },
      deep: true,
      immediate: true
    }
  },
  methods: {
    // 将 props.wanData 映射到本地状态（wanInfo / wanConfig）
    applyWanData(data) {
      if (!data) return
      // 实时状态
      this.wanInfo.alias = data.alias
      this.wanInfo.interface = data.interface
      this.wanInfo.version = data.version
      this.wanInfo.timestamp = data.timestamp
      this.wanInfo.imsi = data.imsi
      this.wanInfo.imei = data.imei
      this.wanInfo.operator = data.operator
      this.wanInfo.realNetworkAccess = data.realNetworkAccess
      this.wanInfo.realBand = data.band
      this.wanInfo.realCell = data.cell
      this.wanInfo.cell_nr = data.cell_nr
      this.wanInfo.cell_lte = data.cell_lte
      this.wanInfo.realPCINR = data.pcid_nr
      this.wanInfo.realPCILTE = data.pcid_lte
      this.wanInfo.signal = data.signal
      this.wanInfo.rsrp_nr = data.rsrp_nr
      this.wanInfo.rsrp_lte = data.rsrp_lte
      this.wanInfo.sinr_nr = data.sinr_nr
      this.wanInfo.sinr_lte = data.sinr_lte
      this.wanInfo.status = data.status
      this.wanInfo.ip = data.ip
      this.wanInfo.mask = data.mask
      this.wanInfo.gateway = data.gateway
      this.wanInfo.mac = data.mac

      // 配置信息
      this.wanConfig.index = data.index
      this.wanConfig.enable = typeof data.enable === 'boolean' ? data.enable : true
      this.wanConfig.alias = data.alias
      this.wanConfig.interface = data.interface
      this.wanConfig.net = data.settingNetworkAccess
      this.wanConfig.apn = data.apn
      this.wanConfig.band = data.settingsBand
      this.wanConfig.auth = data.auth
      this.wanConfig.username = data.username
      this.wanConfig.password = data.password

      this.wanConfig.bandUnLock = (this.wanConfig.band === 'none' || this.wanConfig.band === '')
      this.wanConfig.cell = data.settingsCell
      this.wanConfig.pci = data.settingsPCI
      this.wanConfig.pciUnlock = (this.wanConfig.pci === 'none' || this.wanConfig.pci === '')
    },
    goBack() {
      this.$emit('go-back')
    },
    // 使能
    handleEnableChange(enabled) {
      this.wanConfig.enable = enabled
      this.$oui.call('sim', 'changeSimEnable', this.wanConfig).then(response => {
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
    // 运营商
    getOperatorString(operatorID) {
      switch (operatorID) {
      case '46000': return '中国移动'
      case '46002': return '中国移动'
      case '46004': return '中国移动'
      case '46007': return '中国移动'
      case '46008': return '中国移动'
      case '46001': return '中国联通'
      case '46006': return '中国联通'
      case '46009': return '中国联通'
      case '46003': return '中国电信'
      case '46005': return '中国电信'
      case '46011': return '中国电信'
      case '46015': return '中国广电'
      case '46020': return '中国铁通'
      default: return '未知'
      }
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
    getStatusText(status) {
      switch (status) {
      case 'connected': return this.$t('Connected')
      case 'disconnected': return this.$t('Disconnected')
      case 'dialing': return this.$t('Connecting')
      case 'nosim': return this.$t('NoSim')
      default: return this.$t('Unknown')
      }
    },
    // 保存配置
    saveConfig() {
      console.log('saveConfig...')
      // 验证必填字段
      if (!this.wanConfig.interface) {
        console.log('The network interface must be specified!')
        this.$message.error('The network interface must be specified!')
        return
      }
      // 锁频段参数
      if (!this.wanConfig.bandUnLock && ('none' === this.wanConfig.band || '' === this.wanConfig.band)) {
        console.log('Band locked but not specify the band!')
        this.$message.error('请设置频段 或 解锁频段!')
        return
      }
      // 锁小区参数
      if (!this.wanConfig.pciUnlock && ('none' === this.wanConfig.pci || '' === this.wanConfig.pci)) {
        console.log('PCI locked but not specify the PCID!')
        this.$message.error('请设置小区PCID 或 解锁小区!')
        return
      }
      console.log('saveConf index:', this.wanConfig.index,
        'APN:', this.wanConfig.apn,
        'NET:', this.wanConfig.net,
        'Band:', this.wanConfig.band,
        'PCID:', this.wanConfig.pci,
        'auth', this.wanConfig.auth,
        'username', this.wanConfig.username,
        'password', this.wanConfig.password)
      // 调用后端API保存配置
      this.$oui.call('sim', 'changeSimSettings', this.wanConfig).then(response => {
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
        this.wanConfig = { ...this.wanInfo }
        this.$message.success(this.$t('Configuration reset successfully'))
      })
    },
    handleUnlockBand(unlocked) {
      console.log('this.wanConfig.bandUnlock: ', this.wanConfig.bandUnLock)
      if (unlocked) {
        this.wanConfig.band = ''
      } else {
        this.wanConfig.band = this.wanData.settingsBand
      }
    },
    handleUnlockPCI(unlocked) {
      console.log('this.wanConfig.pciUnlock: ', this.wanConfig.pciUnlock)
      if (unlocked) {
        this.wanConfig.pci = ''
      } else {
        this.wanConfig.pci = this.wanData.settingsPCI
      }
    }
  }
}
</script>

<style scoped>
.wan-config-container {
  max-width: 1200px;
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
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 30px;
}

.config-card {
  border-radius: 8px;
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
