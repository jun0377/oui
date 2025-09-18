<template>
  <div class="wan-config-container">
    <div class="header">
      <el-button @click="goBack" type="primary" plain>
        <el-icon><ArrowLeft /></el-icon>
        {{ $t('Back') }}
      </el-button>
      <h2> {{ wanInfo.alias }}</h2>
    </div>

    <div class="config-section">
      <el-card class="config-card">
        <template #header>
          <div class="card-header">
            <span>{{ $t('Basic Settings') }}</span>
          </div>
        </template>
        <el-form :model="wanConfig" label-width="120px" class="config-form">
          <el-form-item :label="$t('Label')">
            <el-input v-model="wanConfig.alias" :placeholder="$t('Enter WAN label')" readonly/>
          </el-form-item>
          <el-form-item :label="$t('Interface')">
            <el-input v-model="wanConfig.interface" :placeholder="$t('Enter interface name')" readonly/>
          </el-form-item>

          <el-form-item :label="$t('Network Access')">
            <el-select v-model="wanConfig.net" :placeholder="$t('Select access type')" style="width: 100%">
              <el-option :label="$t('AUTO')" value="AUTO"/>
              <el-option label="SA" value="SA"/>
              <el-option label="NSA" value="NSA"/>
              <el-option label="LTE" value="LTE"/>
            </el-select>
          </el-form-item>

          <el-form-item label="APN">
            <el-input v-model="wanConfig.apn" placeholder="Enter APN"/>
          </el-form-item>

          <el-form-item :label="$t('Lock Frequency Band')">
            <div style="display: flex; align-items: center; gap: 10px;">
              <el-input
                v-model="wanConfig.band"
                :placeholder="bandUnLock ? '自动' : $t('band like: n78、b1...')"
                :readonly="bandUnLock"
                style="flex: 1;"
              />
              <el-checkbox v-model="bandUnLock" @change="handleLockChange">解锁</el-checkbox>
            </div>
          </el-form-item>

          <el-form-item :label="$t('Lock PCI')">
            <div style="display: flex; align-items: center; gap: 10px;">
              <el-input
                v-model="wanConfig.pci"
                :placeholder="pciUnlock ? '自动' : $t('Enter PCID')"
                style="flex: 1;"
              />
              <el-checkbox v-model="pciUnlock" @change="handleUnlockCell">解锁</el-checkbox>
            </div>
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
            <span class="status-label">{{ $t('Operator') }}:</span>
            <span class="status-value">{{ getOperatorString(wanInfo.operator) }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real Network Access') }}:</span>
            <span class="status-value">{{ wanInfo.realNetworkAccess }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real Band') }}:</span>
            <span class="status-value">{{ wanInfo.realBand }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real PCID') }}:</span>
            <span class="status-value">{{ wanInfo.realPCI }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Signal Strength') }}:</span>
            <span class="status-value">{{ wanInfo.signal }} dBm</span>
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
      <el-button @click="testConnection" type="success" size="large">
        {{ $t('Test Connection') }}
      </el-button>
      <el-button @click="resetConfig" type="warning" size="large">
        {{ $t('Reset to Default') }}
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
        operator: '',
        realNetworkAccess: '',
        realBand: '',
        realCell: '',
        realPCI: '',
        status: '',
        ip: '',
        mask: '',
        gateway: '',
        mac: ''
      },
      wanConfig: {
        index: '',
        name: '',
        interface: '',
        accessType: '',
        apn: '',
        band: '',
        cell: '',
        pci: ''
      },
      bandUnLock: true,
      pciUnlock: true
    }
  },
  created() {
    // 从 props 获取WAN信息
    if (this.wanData) {
      // 实时状态
      this.wanInfo.alias = this.wanData.alias
      this.wanInfo.interface = this.wanData.interface
      this.wanInfo.operator = this.wanData.operator
      this.wanInfo.realNetworkAccess = this.wanData.realNetworkAccess
      this.wanInfo.realBand = this.wanData.band
      this.wanInfo.realCell = this.wanData.cell
      this.wanInfo.realPCI = this.wanData.pci
      this.wanInfo.signal = this.wanData.signal
      this.wanInfo.status = this.wanData.status
      this.wanInfo.ip = this.wanData.ip
      this.wanInfo.mask = this.wanData.mask
      this.wanInfo.gateway = this.wanData.gateway
      this.wanInfo.mac = this.wanData.mac

      // 配置信息
      this.wanConfig.index = this.wanData.index
      this.wanConfig.alias = this.wanData.alias
      this.wanConfig.interface = this.wanData.interface
      this.wanConfig.net = this.wanData.settingNetworkAccess
      this.wanConfig.apn = this.wanData.apn
      this.wanConfig.band = this.wanData.settingsBand
      if (this.wanConfig.band === 'none') {
        this.wanConfig.bandUnLock = true
      } else {
        this.wanConfig.bandUnLock = false
      }
      this.wanConfig.cell = this.wanData.settingsCell
      // if (this.wanConfig.cell === 'none') {
      //   this.wanConfig.cellUnLock = true
      // } else {
      //   this.wanConfig.cellUnLock = false
      // }
      this.wanConfig.pci = this.wanData.settingsPCI
      if (this.wanConfig.pci === 'none') {
        this.wanConfig.pciUnlock = true
      } else {
        this.wanConfig.pciUnlock = false
      }

    }
  },
  methods: {
    goBack() {
      this.$emit('go-back')
    },
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
      // 调用后端API保存配置
      this.$oui.call('sim', 'changeSimSettings', this.wanConfig).then(response => {
        console.log('saveConf index:', this.wanConfig.index, 'apn:', this.wanConfig.apn, 'net:', this.wanConfig.net, 'band:', this.wanConfig.band, 'cell:', this.wanConfig.cell)
        if (response && 0 === response.code) {
          this.$message.success('Configuration saved successfully')
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
    handleLockChange(unlocked) {
      if (unlocked) {
        // 解锁时清空频段值，显示"自动"
        this.wanConfig.band = ''
      }
    },
    handleUnlockCell(unlocked) {
      console.log('Lock cell...')
    }
  }
}
</script>

<style scoped>
.wan-config-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
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
