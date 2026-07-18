<template>
  <div class="lan-page">
    <el-card class="lan-panel">
      <template #header>
        <div class="panel-header">
          <span class="panel-title">局域网</span>
          <el-tag type="info">LAN</el-tag>
        </div>
      </template>

      <div class="lan-grid">
        <el-card class="config-card lan-accent-violet">
          <template #header>
            <div class="card-header">
              <span class="card-title">DHCP 地址池设置</span>
              <!-- <el-tag type="info">配置</el-tag> -->
            </div>
          </template>

          <el-form ref="dhcpFormRef" :model="dhcpForm" :rules="dhcpRules" label-width="120px" label-align="left" label-position="left" class="config-form">
            <el-form-item label="网关" prop="ipaddr">
              <el-input v-model="dhcpForm.ipaddr" placeholder="例如 192.168.100.1" @input="validateDhcpField('ipaddr')" />
            </el-form-item>
            <el-form-item label="子网掩码" prop="netmask">
              <el-input v-model="dhcpForm.netmask" placeholder="例如 255.255.255.0" @input="validateDhcpField('netmask')" />
            </el-form-item>
            <el-form-item label="地址池起始" prop="poolStart">
              <el-input v-model="dhcpForm.poolStart" class="pool-ip" placeholder="例如 192.168.100.100" @input="validateDhcpField('poolStart')" />
            </el-form-item>
            <el-form-item label="地址池结束" prop="poolEnd">
              <el-input v-model="dhcpForm.poolEnd" class="pool-ip" placeholder="例如 192.168.100.253" @input="validateDhcpField('poolEnd')" />
            </el-form-item>
          </el-form>

          <div class="card-actions">
            <el-button type="primary" size="large" :loading="dhcpSaving" @click="saveDhcp">保存 & 应用</el-button>
            <el-button type="warning" size="large" :disabled="dhcpSaving" @click="resetDhcpDefaults">恢复默认</el-button>
          </div>
        </el-card>

        <el-card class="config-card lan-accent-blue">
          <template #header>
            <div class="card-header">
              <span class="card-title">WiFi AP设置</span>
            </div>
          </template>

          <el-form :model="wifiForm" label-width="120px" label-align="left" label-position="left" class="config-form">
            <el-form-item label="SSID">
              <el-input v-model="wifiForm.ssid" placeholder="请输入 SSID" />
            </el-form-item>
            <el-form-item label="密码">
              <el-input
                v-model="wifiForm.password"
                :type="wifiForm.passwordVisible ? 'text' : 'password'"
                placeholder="请输入密码"
              >
                <template #append>
                  <el-button link :disabled="wifiSaving" @click="togglePasswordVisibility">
                    {{ wifiForm.passwordVisible ? '隐藏' : '显示' }}
                  </el-button>
                </template>
              </el-input>
            </el-form-item>
          </el-form>

          <div class="card-actions">
            <el-button type="primary" size="large" :loading="wifiSaving" @click="saveWifi">保存 & 应用</el-button>
            <el-button type="warning" size="large" :disabled="wifiSaving" @click="resetWifiDefaults">恢复默认</el-button>
          </div>
        </el-card>

        <el-card class="config-card lan-accent-emerald lan-span-2">
          <template #header>
            <div class="card-header">
              <span class="card-title">子网设备</span>
              <el-tag type="info">实时</el-tag>
            </div>
          </template>

          <el-table
            v-loading="dhcpLeasesLoading"
            :data="dhcpLeases"
            height="320"
            table-layout="fixed"
            border
            class="dhcp-lease-table"
          >
            <el-table-column prop="hostname" label="设备名" show-overflow-tooltip />
            <el-table-column prop="ipaddr" label="IP地址" show-overflow-tooltip />
            <el-table-column label="MAC地址" show-overflow-tooltip>
              <template #default="{ row }">
                <span>{{ row && row.macaddr ? String(row.macaddr).toUpperCase() : '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="租约剩余" show-overflow-tooltip>
              <template #default="{ row }">
                <span>{{ row && row.expire != null ? formatSecond(row.expire) : '-' }}</span>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'lan-settings',
  data() {
    return {
      dhcpForm: {
        ipaddr: '',
        netmask: '',
        poolStart: '',
        poolEnd: ''
      },
      dhcpLeases: [],
      dhcpLeasesLoading: false,
      dhcpLeasesTimerId: null,
      dhcpSaving: false,
      wifiForm: {
        ssid: '',
        password: '',
        passwordVisible: false
      },
      wifiSaving: false
    }
  },
  computed: {
    dhcpRules() {
      return {
        ipaddr: [
          { validator: this.validateDhcpIpaddr, trigger: 'change' }
        ],
        netmask: [
          { validator: this.validateDhcpNetmask, trigger: 'change' }
        ],
        poolStart: [
          { validator: this.validateDhcpPoolStart, trigger: 'change' }
        ],
        poolEnd: [
          { validator: this.validateDhcpPoolEnd, trigger: 'change' }
        ]
      }
    }
  },
  created() {
    this.reloadDhcp()
    this.reloadWifi()
    this.startDhcpLeasesPolling()
  },
  beforeUnmount() {
    this.stopDhcpLeasesPolling()
  },
  methods: {
    formatSecond(second) {
      if (typeof second === 'string') return second
      const s = Number(second)
      if (!Number.isFinite(s) || s < 0)
        return '-'
      const days = Math.floor(s / 86400)
      const hours = Math.floor((s % 86400) / 3600)
      const minutes = Math.floor(((s % 86400) % 3600) / 60)
      const seconds = Math.floor(((s % 86400) % 3600) % 60)
      return `${days}d ${hours}h ${minutes}m ${seconds}s`
    },
    async loadDhcpLeases() {
      if (this.dhcpLeasesLoading)
        return
      this.dhcpLeasesLoading = true
      try {
        const r = await this.$oui.call('lan', 'dhcp_leases')
        this.dhcpLeases = r && Array.isArray(r.leases) ? r.leases : []
      } catch {
        this.dhcpLeases = []
      } finally {
        this.dhcpLeasesLoading = false
      }
    },
    startDhcpLeasesPolling() {
      this.stopDhcpLeasesPolling()
      this.loadDhcpLeases()
      this.dhcpLeasesTimerId = setInterval(() => {
        this.loadDhcpLeases()
      }, 3000)
    },
    stopDhcpLeasesPolling() {
      if (this.dhcpLeasesTimerId) {
        clearInterval(this.dhcpLeasesTimerId)
        this.dhcpLeasesTimerId = null
      }
      this.dhcpLeasesLoading = false
    },
    validateDhcpField(field) {
      const form = this.$refs.dhcpFormRef
      if (!form || typeof form.validateField !== 'function')
        return

      form.validateField(field).catch(() => {})
      if (field === 'ipaddr' || field === 'netmask') {
        form.validateField(['poolStart', 'poolEnd']).catch(() => {})
      } else if (field === 'poolStart') {
        form.validateField('poolEnd').catch(() => {})
      } else if (field === 'poolEnd') {
        form.validateField('poolStart').catch(() => {})
      }
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
    buildSections(parts, last) {
      return {
        section1: String(parts[0]),
        section2: String(parts[1]),
        section3: String(parts[2]),
        section4: String(last)
      }
    },
    toDotted(sections) {
      if (!sections)
        return ''
      const s1 = sections.section1 ?? ''
      const s2 = sections.section2 ?? ''
      const s3 = sections.section3 ?? ''
      const s4 = sections.section4 ?? ''
      const v = `${s1}.${s2}.${s3}.${s4}`
      return v.includes('..') ? '' : v
    },
    getDhcpSubnetInfo() {
      const ipParts = this.parseIPv4(this.dhcpForm.ipaddr)
      const maskParts = this.parseIPv4(this.dhcpForm.netmask)
      if (!ipParts || !maskParts || !this.isValidNetmask(maskParts))
        return null
      const ipInt = this.ipv4ToInt(ipParts) >>> 0
      const maskInt = this.ipv4ToInt(maskParts) >>> 0
      const network = (ipInt & maskInt) >>> 0
      const broadcast = (network | ((~maskInt) >>> 0)) >>> 0
      return { ipParts, maskParts, ipInt, maskInt, network, broadcast }
    },
    validateDhcpIpaddr(rule, value, callback) {
      const v = String(value || '').trim()
      if (!v)
        return callback(new Error('网关不能为空'))
      const parts = this.parseIPv4(v)
      if (!parts)
        return callback(new Error('网关格式不正确'))
      callback()
    },
    validateDhcpNetmask(rule, value, callback) {
      const v = String(value || '').trim()
      if (!v)
        return callback(new Error('子网掩码不能为空'))
      const parts = this.parseIPv4(v)
      if (!parts || !this.isValidNetmask(parts))
        return callback(new Error('子网掩码格式不正确'))
      callback()
    },
    validateDhcpPoolStart(rule, value, callback) {
      const v = String(value || '').trim()
      if (!v)
        return callback(new Error('地址池起始不能为空'))
      const parts = this.parseIPv4(v)
      if (!parts)
        return callback(new Error('地址池起始 IP 格式不正确'))

      const info = this.getDhcpSubnetInfo()
      if (info) {
        const startInt = this.ipv4ToInt(parts) >>> 0
        if (((startInt & info.maskInt) >>> 0) !== info.network)
          return callback(new Error('地址池必须与网关在同一网段'))
        if (startInt === info.network || startInt === info.broadcast)
          return callback(new Error('地址池不能包含网络地址或广播地址'))
      }

      callback()
    },
    validateDhcpPoolEnd(rule, value, callback) {
      const v = String(value || '').trim()
      if (!v)
        return callback(new Error('地址池结束不能为空'))
      const parts = this.parseIPv4(v)
      if (!parts)
        return callback(new Error('地址池结束 IP 格式不正确'))

      const info = this.getDhcpSubnetInfo()
      if (info) {
        const endInt = this.ipv4ToInt(parts) >>> 0
        if (((endInt & info.maskInt) >>> 0) !== info.network)
          return callback(new Error('地址池必须与网关在同一网段'))
        if (endInt === info.network || endInt === info.broadcast)
          return callback(new Error('地址池不能包含网络地址或广播地址'))

        const startParts = this.parseIPv4(this.dhcpForm.poolStart)
        if (startParts) {
          const startInt = this.ipv4ToInt(startParts) >>> 0
          if (endInt < startInt)
            return callback(new Error('地址池结束不能小于起始'))
        }
      }

      callback()
    },
    async reloadDhcp() {
      try {
        const data = await this.$oui.call('dhcp', 'getDHCPSettings')
        this.dhcpForm.ipaddr = this.toDotted(data && data.gw)
        this.dhcpForm.netmask = this.toDotted(data && data.mask)
        this.dhcpForm.poolStart = this.toDotted(data && data.dhcpStart)
        this.dhcpForm.poolEnd = this.toDotted(data && data.dhcpEnd)
        this.$nextTick(() => {
          const form = this.$refs.dhcpFormRef
          if (form && typeof form.clearValidate === 'function')
            form.clearValidate()
        })
      } catch {
        this.$message.error('读取 DHCP 配置失败')
      }
    },
    async saveDhcp() {
      if (this.dhcpSaving)
        return

      const form = this.$refs.dhcpFormRef
      if (form && typeof form.validate === 'function') {
        try {
          await form.validate()
        } catch {
          return
        }
      }

      const ipParts = this.parseIPv4(this.dhcpForm.ipaddr)
      const maskParts = this.parseIPv4(this.dhcpForm.netmask)
      const startParts = this.parseIPv4(this.dhcpForm.poolStart)
      const endParts = this.parseIPv4(this.dhcpForm.poolEnd)
      if (!ipParts || !maskParts || !startParts || !endParts)
        return

      const payload = {
        gw: this.buildSections(ipParts, ipParts[3]),
        mask: this.buildSections(maskParts, maskParts[3]),
        dhcpStart: this.buildSections(startParts, startParts[3]),
        dhcpEnd: this.buildSections(endParts, endParts[3])
      }

      this.dhcpSaving = true
      try {
        const r = await this.$oui.call('dhcp', 'setDHCPSettings', payload)
        if (r === 0 || r === true) {
          this.$message.success('DHCP 配置已保存')
          await this.reloadDhcp()
        } else {
          this.$message.error('DHCP 配置保存失败')
        }
      } catch {
        this.$message.error('DHCP 配置保存失败')
      } finally {
        this.dhcpSaving = false
      }
    },
    resetDhcpDefaults() {
      this.dhcpForm.ipaddr = '192.168.100.1'
      this.dhcpForm.netmask = '255.255.255.0'
      this.dhcpForm.poolStart = '192.168.100.100'
      this.dhcpForm.poolEnd = '192.168.100.253'
      this.$nextTick(() => {
        const form = this.$refs.dhcpFormRef
        if (form && typeof form.clearValidate === 'function')
          form.clearValidate()
      })
    },
    togglePasswordVisibility() {
      this.wifiForm.passwordVisible = !this.wifiForm.passwordVisible
    },
    async reloadWifi() {
      try {
        const [ssid, password] = await Promise.all([
          this.$oui.call('wireless', 'getSSID'),
          this.$oui.call('wireless', 'getPassword')
        ])
        this.wifiForm.ssid = typeof ssid === 'string' ? ssid : ''
        this.wifiForm.password = typeof password === 'string' ? password : ''
      } catch {
        this.$message.error('读取 WiFi 配置失败')
      }
    },
    async saveWifi() {
      if (this.wifiSaving)
        return

      const ssid = String(this.wifiForm.ssid || '').trim()
      if (!ssid) {
        this.$message.error('SSID 不能为空')
        return
      }

      const password = String(this.wifiForm.password || '')
      if (password.length < 8) {
        this.$message.error('密码长度至少 8 位')
        return
      }

      this.wifiSaving = true
      try {
        const r1 = await this.$oui.call('wireless', 'setSSID', { ssid })
        const r2 = await this.$oui.call('wireless', 'setPassword', { password })
        if (r1 && r2) {
          this.$message.success('WiFi 配置已保存')
          await this.reloadWifi()
        } else {
          this.$message.error('WiFi 配置保存失败')
        }
      } catch {
        this.$message.error('WiFi 配置保存失败')
      } finally {
        this.wifiSaving = false
      }
    },
    resetWifiDefaults() {
      this.wifiForm.ssid = 'MP-Router'
      this.wifiForm.password = '88888888'
    }
  }
}
</script>

<i18n src="./locale.json"/>

<style scoped>
.lan-page {
  max-width: 1400px;
  margin: 0 auto;
  padding: 18px;
}

.lan-panel {
  width: 100%;
  border-radius: 12px;
  border: 0;
  box-shadow: none;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.panel-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--el-text-color-primary);
}

.lan-grid {
  display: grid;
  gap: 16px;
  grid-template-columns: minmax(360px, 1fr) minmax(360px, 1fr);
  align-items: stretch;
}

.config-card {
  height: 100%;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
  overflow: hidden;
  position: relative;
}

.config-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.lan-accent-blue::before {
  background: #3b82f6;
}

.lan-accent-violet::before {
  background: #8b5cf6;
}

.lan-accent-emerald::before {
  background: #10b981;
}

.lan-accent-slate::before {
  background: #64748b;
}

:deep(.config-card .el-card__header) {
  padding: 14px 18px 0;
  border-bottom: 0;
}

:deep(.config-card .el-card__body) {
  padding: 12px 18px 18px;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.card-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.config-form {
  padding: 10px 0;
}

.pool-ip {
  width: 100%;
}

.lan-span-2 {
  grid-column: 1 / -1;
}

.dhcp-lease-table {
  width: 100%;
}

.card-actions {
  margin-top: auto;
  padding-top: 12px;
  display: flex;
  justify-content: center;
  gap: 15px;
}

@media (max-width: 960px) {
  .lan-grid {
    grid-template-columns: 1fr;
  }
}
</style>
