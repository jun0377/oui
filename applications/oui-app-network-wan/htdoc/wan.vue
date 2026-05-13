<template>
  <div class="wan-page">
    <el-card class="wan-panel">
      <div class="wan-panel-body">
        <div class="wan-layout wired-config-section" :class="{ 'is-equal-height': settings.proto === 'DHCP' }">
          <div class="wan-hero">
            <div class="wan-metric-head">
              <div class="wan-metric-main">
                <div class="wan-metric-title">{{ settings.alias || 'WAN' }}</div>
                <div class="wan-metric-subtitle">{{ settings.interface || '-' }}</div>
              </div>
            </div>
          </div>
          <div class="left-column">
            <el-card class="config-card wan-accent-slate">
          <template #header>
            <div class="card-header">
              <span class="wan-card-title">{{ $t('Basic Settings') }}</span>
              <el-tag type="info">{{ $t('配置') }}</el-tag>
            </div>
          </template>
          <el-form :model="settings" label-width="120px" class="config-form" label-align="left" label-position="left">
            <el-form-item :label="$t('Label')">
              <el-input v-model="settings.alias" readonly disabled/>
            </el-form-item>
            <el-form-item :label="$t('Interface')">
              <el-input v-model="settings.interface" readonly disabled/>
            </el-form-item>
            <el-form-item label="协议">
              <el-select v-model="settings.proto" class="wan-full-width">
                <el-option label="DHCP" value="DHCP"/>
                <el-option label="静态IP" value="STATIC"/>
              </el-select>
            </el-form-item>
            <el-form-item v-if="settings.proto === 'STATIC'" label="IP地址">
              <el-input v-model="settings.ipaddr" placeholder="请输入静态IP地址"/>
            </el-form-item>
            <el-form-item v-if="settings.proto === 'STATIC'" label="子网掩码">
              <el-input v-model="settings.netmask" placeholder="请输入子网掩码"/>
            </el-form-item>
            <el-form-item v-if="settings.proto === 'STATIC'" label="默认网关">
              <el-input v-model="settings.gateway" placeholder="请输入默认网关"/>
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
              {{ $t('保存 & 应用') }}
            </el-button>
            <el-button @click="goBack" native-type="button" type="info" size="large">
              {{ $t('Back') }}
            </el-button>
          </div>
        </el-card>
      </div>

      <div class="right-column">
        <el-card class="config-card compact-card wan-accent-blue">
          <template #header>
            <div class="card-header">
              <span class="wan-card-title">接口状态</span>
              <el-tag type="info">{{ $t('实时') }}</el-tag>
            </div>
          </template>
          <div class="status-info">
            <div class="status-item">
              <span class="status-label">状态:</span>
              <span class="status-value">{{ status.interface.status }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">IP:</span>
              <span class="status-value">{{ status.interface.ip }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">掩码:</span>
              <span class="status-value">{{ status.interface.mask }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">网关:</span>
              <span class="status-value">{{ status.interface.gateway }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">MAC:</span>
              <span class="status-value">{{ status.interface.mac }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">接收流量:</span>
              <span class="status-value">{{ formatBytes(status.interface.rxBytes) }}</span>
            </div>
            <div class="status-item">
              <span class="status-label">发送流量:</span>
              <span class="status-value">{{ formatBytes(status.interface.txBytes) }}</span>
            </div>
          </div>
        </el-card>
      </div>
    </div>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'wan-settings',
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
        alias: '',
        rat: '-',
        interface: {
          status: '-',
          ip: '-',
          mask: '-',
          gateway: '-',
          mac: '-',
          rxBytes: '-',
          txBytes: '-'
        }
      },
      settings: {
        alias: '',
        name: '',
        interface: '',
        enable: true,
        proto: 'DHCP',
        ipaddr: '',
        netmask: '',
        gateway: ''
      },
      wanStateActive: false,
      wanStateTimerId: null,
      wanStateInFlight: false
    }
  },
  watch: {
    wanData: {
      handler(newVal) {
        this.applyWanData(newVal)
        this.fetchWanProto()
        if (this.wanStateActive)
          this.startWanStatePolling()
      },
      immediate: true
    }
  },
  activated() {
    this.wanStateActive = true
    this.startWanStatePolling()
  },
  deactivated() {
    this.wanStateActive = false
    this.stopWanStatePolling()
  },
  beforeUnmount() {
    this.stopWanStatePolling()
  },
  methods: {
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
    // 获取协议: DHCP or 静态IP
    fetchWanProto() {
      const section = this.settings && this.settings.name ? this.settings.name : ''
      if (!section || section === '-')
        return Promise.resolve()

      return this.$oui.call('wan', 'getWanProto', { section }).then((result) => {
        let data = result
        if (typeof result === 'string') {
          try {
            data = JSON.parse(result)
          } catch {
            data = null
          }
        }

        const proto = data && typeof data.proto === 'string'
          ? data.proto.trim().toLowerCase()
          : ''

        if (proto === 'static') {
          this.settings.proto = 'STATIC'
          if (typeof data.ipaddr === 'string') this.settings.ipaddr = data.ipaddr
          if (typeof data.netmask === 'string') this.settings.netmask = data.netmask
          if (typeof data.gateway === 'string') this.settings.gateway = data.gateway
        } else if (proto === 'dhcp') {
          this.settings.proto = 'DHCP'
          this.settings.ipaddr = ''
          this.settings.netmask = ''
          this.settings.gateway = ''
        }
      }).catch(() => {})
    },
    applyWanData(data) {
      if (!data || data.kind !== 'wan')
        return

      const uci = data.uci || {}
      const iface = data.status && data.status.interface ? data.status.interface : {}
      const alias = data.settings && data.settings.alias
        ? data.settings.alias
        : (uci.name ? String(uci.name).toUpperCase() : 'WAN')
      const proto = String(uci.proto || (data.status && data.status.rat) || '').trim().toLowerCase()

      this.status = {
        alias,
        rat: data.status && data.status.rat ? data.status.rat : (uci.proto ? String(uci.proto).toUpperCase() : '-'),
        interface: {
          status: '-',
          ip: iface.ip || '-',
          mask: iface.mask || '-',
          gateway: iface.gateway || '-',
          mac: iface.mac || '-',
          rxBytes: iface.rxBytes ?? '-',
          txBytes: iface.txBytes ?? '-'
        }
      }

      this.settings.alias = alias
      this.settings.name = uci.name || '-'
      this.settings.interface = data.settings && data.settings.interface ? data.settings.interface : (uci.device || '-')
      this.settings.enable = typeof data.settings?.enable === 'boolean'
        ? data.settings.enable
        : !(String(uci.auto || '1') === '0')
      this.settings.proto = proto === 'static' ? 'STATIC' : 'DHCP'
      this.settings.ipaddr = uci.ipaddr || (proto === 'static' ? (iface.ip || '') : '')
      this.settings.netmask = uci.netmask || (proto === 'static' ? (iface.mask || '') : '')
      this.settings.gateway = uci.gateway || (proto === 'static' ? (iface.gateway || '') : '')
    },
    handleEnableChange(enabled) {
      this.settings.enable = enabled
    },
    goBack() {
      this.$emit('go-back', { refresh: true })
    },
    fetchWanState() {
      const iface = this.settings && this.settings.interface ? this.settings.interface : ''
      if (!iface || iface === '-')
        return Promise.resolve()
      if (this.wanStateInFlight)
        return Promise.resolve()

      const section = this.settings && this.settings.name ? this.settings.name : ''
      this.wanStateInFlight = true
      return this.$oui.call('wan', 'getWanState', { section, interface: iface }).then((result) => {
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

        const v = data
        if (!this.status.interface)
          this.status.interface = {}
        if (typeof v.status === 'string') this.status.interface.status = v.status
        if (typeof v.ip === 'string') this.status.interface.ip = v.ip
        if (typeof v.mask === 'string') this.status.interface.mask = v.mask
        if (typeof v.gateway === 'string') this.status.interface.gateway = v.gateway
        if (typeof v.mac === 'string') this.status.interface.mac = v.mac
        if (v.rxBytes !== undefined && v.rxBytes !== null) this.status.interface.rxBytes = v.rxBytes
        if (v.txBytes !== undefined && v.txBytes !== null) this.status.interface.txBytes = v.txBytes
      }).catch(() => {}).finally(() => {
        this.wanStateInFlight = false
      })
    },
    startWanStatePolling() {
      this.stopWanStatePolling()
      this.fetchWanState()
      this.wanStateTimerId = setInterval(() => {
        this.fetchWanState()
      }, 3000)
    },
    stopWanStatePolling() {
      if (this.wanStateTimerId) {
        clearInterval(this.wanStateTimerId)
        this.wanStateTimerId = null
      }
      this.wanStateInFlight = false
    },
    parseIPv4(value) {
      if (typeof value !== 'string')
        return null
      const v = value.trim()
      const parts = v.split('.')
      if (parts.length !== 4)
        return null
      const nums = parts.map(p => (p === '' ? NaN : Number(p)))
      if (nums.some(n => !Number.isInteger(n) || n < 0 || n > 255))
        return null
      return nums
    },
    ipv4ToInt(parts) {
      return ((parts[0] << 24) >>> 0) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    },
    isValidNetmask(parts) {
      const mask = this.ipv4ToInt(parts) >>> 0
      if (mask === 0)
        return false
      const inv = (~mask) >>> 0
      return (inv & (inv + 1)) === 0
    },
    // 保存配置并应用
    saveConfig() {
      const section = this.settings && this.settings.name ? this.settings.name : ''
      if (!section || section === '-') {
        this.$message.error('WAN section 缺失')
        return
      }

      // 静态IP时校验配置是否合法
      if (this.settings.proto === 'STATIC') {
        const ipParts = this.parseIPv4(this.settings.ipaddr)
        if (!ipParts) {
          this.$message.error('IP地址格式不正确')
          return
        }

        const maskParts = this.parseIPv4(this.settings.netmask)
        if (!maskParts || !this.isValidNetmask(maskParts)) {
          this.$message.error('子网掩码格式不正确')
          return
        }

        const gwParts = this.parseIPv4(this.settings.gateway)
        if (!gwParts) {
          this.$message.error('默认网关格式不正确')
          return
        }

        const ipInt = this.ipv4ToInt(ipParts) >>> 0
        const maskInt = this.ipv4ToInt(maskParts) >>> 0
        const gwInt = this.ipv4ToInt(gwParts) >>> 0

        const network = (ipInt & maskInt) >>> 0
        const broadcast = (network | ((~maskInt) >>> 0)) >>> 0

        if (ipInt === 0 || ipInt === 0xFFFFFFFF) {
          this.$message.error('IP地址不合法')
          return
        }

        if (ipInt === network || ipInt === broadcast) {
          this.$message.error('IP地址不能是网络地址或广播地址')
          return
        }

        if (gwInt === ipInt) {
          this.$message.error('默认网关不能与IP地址相同')
          return
        }

        if (((gwInt & maskInt) >>> 0) !== network) {
          this.$message.error('默认网关不在同一网段')
          return
        }
      }

      const payload = {
        section,
        proto: this.settings.proto,
        enable: this.settings.enable,
        ipaddr: this.settings.ipaddr,
        netmask: this.settings.netmask,
        gateway: this.settings.gateway
      }
      if (payload.enable === false)
        this.$message.warning('链路已关闭')

      this.$oui.call('wan', 'setWanConf', payload).then((result) => {
        let data = result
        if (typeof result === 'string') {
          try {
            data = JSON.parse(result)
          } catch {
            data = null
          }
        }
        if (data && data.code === 0)
          this.$message.success(this.$t('保存成功'))
        else
          this.$message.error(data && data.msg ? data.msg : '保存失败')
      }).catch(() => {
        this.$message.error('保存失败')
      })
    }
  }
}
</script>

<style scoped>
.wan-page {
  max-width: 1600px;
  margin: 0 auto;
  padding: 18px;
}

.wan-panel {
  width: 100%;
  border-radius: 12px;
  border: 0;
  box-shadow: none;
}

:deep(.wan-panel .el-card__body) {
  padding: 0;
}

.wan-panel-body {
  padding: 10px 8px;
}

.wan-hero {
  grid-column: 1 / -1;
  margin-bottom: 16px;
  padding: 18px;
  border: 1px solid rgba(59, 130, 246, 0.18);
  border-radius: 16px;
  background: linear-gradient(135deg, #eff6ff 0%, #ffffff 100%);
  box-shadow: 0 14px 30px rgba(59, 130, 246, 0.12);
}

.wan-metric-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.wan-metric-main {
  flex: 1;
  min-width: 0;
  text-align: center;
}

.wan-metric-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.wan-metric-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
  word-break: break-word;
}

.wan-metric-tags {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.wan-layout {
  display: grid;
  gap: 16px;
  align-items: start;
}

.wan-layout.is-equal-height {
  align-items: stretch;
}

.wan-layout.is-equal-height .left-column,
.wan-layout.is-equal-height .right-column {
  height: 100%;
}

.wan-layout.is-equal-height .left-column .config-card,
.wan-layout.is-equal-height .right-column .config-card {
  height: 100%;
}

.wired-config-section {
  grid-template-columns: minmax(360px, 520px) minmax(360px, 520px);
  justify-content: start;
}

.left-column,
.right-column {
  display: flex;
  flex-direction: column;
}

.config-card {
  width: 100%;
  position: relative;
  overflow: hidden;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.config-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.wan-accent-blue::before {
  background: #3b82f6;
}

.wan-accent-slate::before {
  background: #64748b;
}

:deep(.config-card .el-card__header) {
  padding: 14px 18px 0;
  border-bottom: 0;
}

:deep(.config-card .el-card__body) {
  padding: 12px 18px 18px;
}

:deep(.compact-card .el-card__header) {
  padding: 12px 16px 0;
}

:deep(.compact-card .el-card__body) {
  padding: 10px 16px 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.wan-card-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.config-form {
  padding: 10px 0;
}

:deep(.config-form .el-form-item) {
  margin-bottom: 14px;
}

:deep(.config-form .el-form-item:last-child) {
  margin-bottom: 0;
}

:deep(.config-form .el-form-item__label) {
  line-height: 32px;
  padding-bottom: 0;
}

:deep(.config-form .el-form-item__content) {
  min-height: 32px;
  align-items: center;
}

.status-info {
  padding: 10px 0;
  font-size: var(--el-font-size-base);
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
  font-weight: 400;
  color: var(--el-text-color-regular);
}

.status-value {
  font-weight: 400;
  color: var(--el-text-color-primary);
}

.wan-full-width {
  width: 100%;
}

.action-buttons {
  display: flex;
  justify-content: center;
  gap: 15px;
}

.card-actions {
  justify-content: center;
}

:deep(.wan-enable-switch.el-switch:not(.is-checked) .el-switch__inner .is-text),
:deep(.wan-enable-switch:not(.is-checked) .el-switch__inner .is-text) {
  color: var(--el-color-danger);
}

@media (max-width: 768px) {
  .wired-config-section {
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
