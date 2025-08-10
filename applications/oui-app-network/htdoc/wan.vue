<template>
  <div class="wan-config-container">
    <div class="header">
      <el-button @click="goBack" type="primary" plain>
        <el-icon><ArrowLeft /></el-icon>
        {{ $t('Back') }}
      </el-button>
      <h2> {{ wanInfo.name }}</h2>
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
            <el-input v-model="wanConfig.name" :placeholder="$t('Enter WAN label')" readonly/>
          </el-form-item>
          <el-form-item :label="$t('Interface')">
            <el-input v-model="wanConfig.interface" :placeholder="$t('Enter interface name')" readonly/>
          </el-form-item>

          <el-form-item :label="$t('Network Access')">
            <el-select v-model="wanConfig.accessType" :placeholder="$t('Select access type')" style="width: 100%">
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
                :placeholder="bandUnlocked ? '自动' : $t('Enter frequency band')"
                :readonly="bandUnlocked"
                style="flex: 1;"
              />
              <el-checkbox v-model="bandUnlocked" @change="handleUnlockChange">解锁</el-checkbox>
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
            <span :class="['status-value', getStatusClass(wanStatus.status)]">
              {{ getStatusText(wanStatus.status) }}
            </span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Operator') }}:</span>
            <span class="status-value">{{ wanStatus.operator }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Real Network Access') }}:</span>
            <span class="status-value">{{ wanStatus.realNetworkAccess }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Signal Strength') }}:</span>
            <span class="status-value">{{ wanStatus.signal }} dBm</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('IP Address') }}:</span>
            <span class="status-value">{{ wanStatus.ip }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Netmask') }}:</span>
            <span class="status-value">{{ wanStatus.ip }}</span>
          </div>

          <div class="status-item">
            <span class="status-label">{{ $t('Gateway') }}:</span>
            <span class="status-value">{{ wanStatus.gateway }}</span>
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
// 不直接从@element-plus/icons-vue导入，而是使用全局注册的组件

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
      wanInfo: {},
      wanConfig: {
        name: '',
        interface: '',
        accessType: '',
        apn: '',
        band: ''
      },
      wanStatus: {
        operator: '中国移动',
        realNetworkAccess: 'NR-5G',
        signal: '-83',
        status: 'connected',
        ip: '127.0.0.1',
        netmask: '255.255.255.255',
        gateway: '127.0.0.1'
      },
      bandUnlocked: false // 解锁状态，false表示锁定，true表示解锁
    }
  },
  created() {
    // 从 props 获取WAN信息
    if (this.wanData) {
      this.wanInfo = { ...this.wanData }
      this.wanConfig = { ...this.wanData }
    }
  },
  methods: {
    goBack() {
      this.$emit('go-back')
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
    saveConfig() {
      // 这里实现保存配置的逻辑
      this.$message.success(this.$t('Configuration saved successfully'))
    },
    testConnection() {
      // 这里实现测试连接的逻辑
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
    handleUnlockChange(unlocked) {
      if (unlocked) {
        // 解锁时清空频段值，显示"自动"
        this.wanConfig.band = ''
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
