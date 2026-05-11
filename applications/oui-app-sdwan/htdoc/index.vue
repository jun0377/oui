<template>
  <div class="sdwan-page">
    <el-card class="sdwan-panel">
      <div class="sdwan-panel-body">

        <div class="sdwan-dashboard-grid">
          <div class="sdwan-section-card sdwan-settings-card">
            <div class="sdwan-metric-head">
              <div>
                <div class="sdwan-section-title">{{ $t('设置') }}</div>
                <div class="sdwan-section-subtitle">{{ $t('以下配置项当前仅展示系统或服务器下发的参数') }}</div>
              </div>
              <el-tag type="info">{{ $t('只读') }}</el-tag>
            </div>

            <el-form class="sdwan-settings-form" label-width="120px" label-position="top">
              <el-form-item :label="$t('中继服务器')">
                <el-tooltip :content="$t('暂不开放,和服务器IP相同')" placement="top">
                  <el-input :placeholder="$t('中继服务器IP')" v-model="settings.remote_ip" disabled />
                </el-tooltip>
              </el-form-item>

              <el-form-item :label="$t('中继服务器端口')">
                <el-tooltip :content="$t('暂不支持手动设置,后续版本完善')" placement="top">
                  <el-input :placeholder="$t('中继节点端口')" v-model="settings.remote_port" disabled></el-input>
                </el-tooltip>
              </el-form-item>

              <el-form-item :label="$t('组网网段')">
                <el-tooltip :content="$t('此配置在服务器端进行设置')" placement="top">
                  <div class="sdwan-field-control">
                    <el-radio-group v-model="fieldModes.virtual_net" size="small" class="sdwan-field-mode" @change="handleFieldModeChange('virtual_net')">
                      <el-radio-button label="auto">{{ $t('自动') }}</el-radio-button>
                      <el-radio-button label="manual">{{ $t('手动') }}</el-radio-button>
                    </el-radio-group>
                    <el-input
                      :placeholder="$t('虚拟网络网络号')"
                      v-model="settings.virtual_net"
                      :disabled="fieldModes.virtual_net === 'auto'"
                    ></el-input>
                  </div>
                </el-tooltip>
              </el-form-item>

              <el-form-item :label="$t('本地虚拟IP')">
                <el-tooltip :content="$t('暂不支持手动设置,由服务器自动分配')" placement="top">
                  <div class="sdwan-field-control">
                    <el-radio-group v-model="fieldModes.local_ip" size="small" class="sdwan-field-mode" @change="handleFieldModeChange('local_ip')">
                      <el-radio-button label="auto">{{ $t('自动') }}</el-radio-button>
                      <el-radio-button label="manual">{{ $t('手动') }}</el-radio-button>
                    </el-radio-group>
                    <el-input
                      :placeholder="$t('本地虚拟IP')"
                      v-model="settings.local_ip"
                      :disabled="fieldModes.local_ip === 'auto'"
                    ></el-input>
                  </div>
                </el-tooltip>
              </el-form-item>

              <el-form-item :label="$t('本地端口')">
                <el-tooltip :content="$t('暂不支持手动设置,由系统自动分配')" placement="top">
                  <div class="sdwan-field-control">
                    <el-radio-group v-model="fieldModes.local_port" size="small" class="sdwan-field-mode" @change="handleFieldModeChange('local_port')">
                      <el-radio-button label="auto">{{ $t('自动') }}</el-radio-button>
                      <el-radio-button label="manual">{{ $t('手动') }}</el-radio-button>
                    </el-radio-group>
                    <el-input
                      :placeholder="$t('本地端口')"
                      v-model="settings.local_port"
                      :disabled="fieldModes.local_port === 'auto'"
                    ></el-input>
                  </div>
                </el-tooltip>
              </el-form-item>

              <el-form-item :label="$t('子网地址')">
                <el-tooltip :content="$t('DHCP地址池设置,由服务器自动分配')" placement="top">
                  <el-input :placeholder="$t('子网地址')" v-model="settings.subnet" disabled></el-input>
                </el-tooltip>
              </el-form-item>
            </el-form>

            <div class="sdwan-settings-actions">
              <el-button type="primary" class="sdwan-action-button">
                {{ $t('保存 & 应用') }}
              </el-button>
              <el-button class="sdwan-action-button">
                {{ $t('恢复默认') }}
              </el-button>
            </div>
          </div>

          <div class="sdwan-status-grid">
            <div class="sdwan-metric-card sdwan-metric-card-primary is-accent-blue">
              <div class="sdwan-metric-head">
                <div class="sdwan-metric-title">{{ $t('组网状态') }}</div>
                <el-tag type="info">{{ $t('状态') }}</el-tag>
              </div>
              <div class="sdwan-metric-value">{{ status.connected || '--' }}</div>
              <div class="sdwan-metric-subtitle">{{ $t('用于展示当前 OpenVPN 中继连接状态') }}</div>
            </div>

            <div class="sdwan-metric-card sdwan-metric-card-primary is-accent-cyan">
              <div class="sdwan-metric-head">
                <div class="sdwan-metric-title">{{ $t('RTT') }}</div>
                <el-tag type="info">ms</el-tag>
              </div>
              <div class="sdwan-metric-value">{{ status.rtt }}</div>
              <div class="sdwan-metric-subtitle">{{ $t('显示当前中继网络的往返时延') }}</div>
            </div>

            <div class="sdwan-metric-card sdwan-metric-card-primary is-accent-amber">
              <div class="sdwan-metric-head">
                <div class="sdwan-metric-title">{{ $t('上行流量') }}</div>
                <el-tag type="info">MB</el-tag>
              </div>
              <div class="sdwan-metric-value">{{ status.tx_MB }}</div>
              <div class="sdwan-metric-subtitle">{{ $t('统计当前连接期间累计发送的数据量') }}</div>
            </div>

            <div class="sdwan-metric-card sdwan-metric-card-primary is-accent-green">
              <div class="sdwan-metric-head">
                <div class="sdwan-metric-title">{{ $t('下行流量') }}</div>
                <el-tag type="info">MB</el-tag>
              </div>
              <div class="sdwan-metric-value">{{ status.rx_MB }}</div>
              <div class="sdwan-metric-subtitle">{{ $t('统计当前连接期间累计接收的数据量') }}</div>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>

export default {
  data() {
    return {
      settings: {
        remote_ip: '',
        remote_port: 0,
        virtual_net: '',
        local_ip: '',
        local_port: 0,
        subnet: ''
      },
      fieldModes: {
        virtual_net: 'auto',
        local_ip: 'auto',
        local_port: 'auto'
      },
      status: {
        // openvpnDead - 进程未启动
        // openvpnBroken - 未连接
        // openvpnNormal - 正常
        // openvpnUnknownStatus - 用于调试
        connected: '',
        rtt: 0,
        tx_MB: 0,
        rx_MB: 0
      },
      refreshSettingsTimer: null,
      refreshStatusTimer: null
    }
  },
  created() {
    this.refreshSettings()
    this.refreshStatus()

    this.refreshSettingsTimer = setInterval(() => {
      console.log('Get Settings...')
      this.refreshSettings()
    }, 10000)

    this.refreshStatusTimer = setInterval(() => {
      console.log('Get Status...')
      this.refreshStatus()
    }, 3000)
  },
  beforeUnmount() {
    if (this.refreshSettingsTimer) {
      clearInterval(this.refreshSettingsTimer)
    }

    if (this.refreshStatusTimer) {
      clearInterval(this.refreshStatusTimer)
    }
  },
  methods: {
    handleFieldModeChange(field) {
      if (field === 'virtual_net' && this.fieldModes.virtual_net === 'auto')
        this.fetchSettingsVirtualNet()
      if (field === 'local_ip' && this.fieldModes.local_ip === 'auto')
        this.fetchSettingsLocalIP()
      if (field === 'local_port' && this.fieldModes.local_port === 'auto')
        this.fetchSettingsLocalPort()
    },
    refreshSettings() {
      this.fetchSettingsRemoteIP()
      this.fetchSettingsRemotePort()
      this.fetchSettingsVirtualNet()
      this.fetchSettingsLocalIP()
      this.fetchSettingsLocalPort()
      this.fetchSettingsSubNet()
      this.fetchSettingsTransBytes()
      console.log(this.settings)
    },
    fetchSettingsRemoteIP() {
      // console.log('fetch remote ip')
      this.$oui.call('sdwan', 'getRemoteIP').then(ip => {
        if (Array.isArray(ip))
          this.settings.remote_ip = ip[0] || ''
        else if (typeof ip === 'string')
          this.settings.remote_ip = ip
        else
          this.settings.remote_ip = ''
      }).catch(() => {
        this.settings.remote_ip = ''
      })
    },
    fetchSettingsRemotePort() {
      // console.log('fetch remote port')
      this.$oui.call('sdwan', 'getRemotePort').then(port => {
        this.settings.remote_port = Number(port)
        // console.log('fetchSettingsRemotePort: ', this.settings.remote_port)
      })
    },
    fetchSettingsVirtualNet() {
      // console.log('fetch virtual net')
      this.$oui.call('sdwan', 'getVirtualNet').then(ip => {
        if (this.fieldModes.virtual_net === 'auto')
          this.settings.virtual_net = ip
        // console.log('fetchSettingsVirtualNet: ', this.settings.virtual_net)
      })
    },
    fetchSettingsLocalIP() {
      // console.log('fetch local ip')
      this.$oui.call('sdwan', 'getLocalIP').then(ip => {
        if (this.fieldModes.local_ip === 'auto')
          this.settings.local_ip = ip
        // console.log('fetchSettingsLocalIP: ', this.settings.local_ip)
      })
    },
    fetchSettingsLocalPort() {
      // console.log('fetch local port')
      this.$oui.call('sdwan', 'getLocalPort').then(port => {
        if (this.fieldModes.local_port === 'auto')
          this.settings.local_port = port
        // console.log('fetchSettingsLocalPort: ', this.settings.local_port)
      })
    },
    fetchSettingsSubNet() {
      // console.log('fetch subnet')
      this.$oui.call('sdwan', 'getSubnet').then(sublan => {
        this.settings.subnet = sublan
        // console.log('fetchSettingsSubNet: ', this.settings.subnet)
      })
    },
    fetchSettingsTransBytes() {
      // console.log('fetch trans data bytes')
      this.$oui.call('sdwan', 'getTransBytes').then(bytes => {
        this.status.tx_MB = (bytes.tx_bytes / 1024 / 1024).toFixed(2)
        this.status.rx_MB = (bytes.rx_bytes / 1024 / 1024).toFixed(2)
        // console.log('fetchSettingsTransBytes tx_MB: ', this.status.tx_bytes)
        // console.log('fetchSettingsTransBytes rx_MB: ', this.status.rx_bytes)
      })
    },
    refreshStatus() {
      this.fetchStatusConnectStatus()
      this.fetchStatusRTT()
      console.log(this.status)
    },
    fetchStatusConnectStatus() {
      this.$oui.call('sdwan', 'getStatusConnectStatus').then(status => {
        switch (status) {
        case 'openvpnDead' :
          this.status.connected = '未启动'
          break
        case 'openvpnBroken':
          this.status.connected = '连接断开'
          break
        case 'openvpnNormal':
          this.status.connected = '正常'
          break
        default:
          this.status.connected = '未知状态'
        }
      })
    },
    fetchStatusRTT() {
      this.$oui.call('sdwan', 'getStatusRTT').then(rtt_ms => {
        this.status.rtt = rtt_ms.toFixed(2)
      })
    }
  }



}

</script>

<style>
.sdwan-page {
  width: 100%;
}

.sdwan-panel {
  width: 100%;
  border-radius: 12px;
  border: 0;
  box-shadow: none;
}

.sdwan-panel-body {
  padding: 6px 4px;
}

.sdwan-dashboard-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr);
  gap: 16px;
  align-items: stretch;
  margin-top: 16px;
}

.sdwan-status-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-content: stretch;
}

.sdwan-hero-card,
.sdwan-metric-card,
.sdwan-section-card {
  display: flex;
  flex-direction: column;
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.sdwan-hero-card,
.sdwan-metric-card {
  position: relative;
  overflow: hidden;
}

.sdwan-hero-card::before,
.sdwan-metric-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
}

.sdwan-hero-card::before {
  background: #8b5cf6;
}

.sdwan-hero-card {
  background: linear-gradient(135deg, #f5f3ff 0%, #ffffff 100%);
  border-color: rgba(139, 92, 246, 0.28);
  box-shadow: 0 14px 30px rgba(139, 92, 246, 0.12);
}

.sdwan-metric-card-primary {
  min-height: 180px;
}

.sdwan-settings-card {
  min-width: 0;
}

.sdwan-metric-card.is-accent-blue::before {
  background: #3b82f6;
}

.sdwan-metric-card.is-accent-cyan::before {
  background: #06b6d4;
}

.sdwan-metric-card.is-accent-amber::before {
  background: #f59e0b;
}

.sdwan-metric-card.is-accent-green::before {
  background: #22c55e;
}

.sdwan-metric-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.sdwan-panel-title,
.sdwan-section-title,
.sdwan-metric-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.sdwan-panel-subtitle,
.sdwan-section-subtitle,
.sdwan-metric-subtitle,
.sdwan-hero-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.sdwan-hero-value,
.sdwan-metric-value {
  margin: 14px 0 6px;
  font-size: 28px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.1;
  word-break: break-word;
}

.sdwan-hero-value {
  margin-top: 18px;
  font-size: 36px;
}

.sdwan-hero-foot {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px solid rgba(139, 92, 246, 0.18);
}

.sdwan-hero-foot-item {
  min-width: 0;
  padding: 12px 14px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid rgba(139, 92, 246, 0.12);
}

.sdwan-hero-foot-label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #6d28d9;
}

.sdwan-hero-foot-value {
  display: block;
  margin-top: 6px;
  font-size: 18px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  word-break: break-word;
}

.sdwan-settings-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px 16px;
  margin-top: 18px;
}

.sdwan-field-control {
  display: grid;
  gap: 10px;
}

.sdwan-field-mode {
  width: fit-content;
}

.sdwan-settings-actions {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 8px;
  padding-top: 16px;
  border-top: 1px solid rgba(148, 163, 184, 0.16);
}

.sdwan-action-button {
  min-width: 120px;
  border-radius: 12px;
}

.sdwan-settings-form :deep(.el-form-item) {
  margin-bottom: 14px;
}

.sdwan-settings-form :deep(.el-form-item__label) {
  padding-bottom: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.4;
}

.sdwan-settings-form :deep(.el-input__wrapper) {
  border-radius: 12px;
  box-shadow: none;
  background: #f8fafc;
}

.sdwan-settings-form :deep(.el-input.is-disabled .el-input__wrapper) {
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
  box-shadow: inset 0 0 0 1px rgba(148, 163, 184, 0.16);
}

.sdwan-settings-form :deep(.el-input__inner) {
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.sdwan-settings-form :deep(.el-radio-group) {
  display: inline-flex;
  flex-wrap: wrap;
}

.sdwan-settings-form :deep(.el-radio-button__inner) {
  border-radius: 10px;
  font-weight: 600;
}

.el-tag {
  transition: background-color 0.3s ease, color 0.3s ease;
  font-weight: 600;
}

.el-tag--success {
  background-color: #67c23a !important;
  border-color: #67c23a !important;
  color: #fff !important;
}

.el-tag--danger {
  background-color: #f56c6c !important;
  border-color: #f56c6c !important;
  color: #fff !important;
}

.el-tag--warning {
  background-color: #e6a23c !important;
  border-color: #e6a23c !important;
  color: #fff !important;
}

.el-tag--info {
  background-color: #909399 !important;
  border-color: #909399 !important;
  color: #fff !important;
}

@media (max-width: 1024px) {
  .sdwan-dashboard-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .sdwan-metric-head,
  .sdwan-hero-foot {
    grid-template-columns: 1fr;
  }

  .sdwan-metric-head {
    flex-direction: column;
    align-items: flex-start;
  }

  .sdwan-status-grid,
  .sdwan-settings-form {
    grid-template-columns: 1fr;
  }

  .sdwan-settings-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .sdwan-metric-card-primary {
    min-height: auto;
  }
}
</style>

<i18n src="./locale.json"/>
