<template>
  <div class="server-section">
    <el-card class="mode-card mode-panel">
      <template #header>
        <div class="card-header">
          <div>
            <div class="mode-panel-title">聚合模式</div>
            <div class="mode-panel-subtitle">聚合多条链路能力,需要连接聚合服务器,带宽高,延时会有所增加</div>
          </div>
        </div>
      </template>
      <div class="mode-panel-body">
        <div class="server-section aggregate-section aggregate-split">
          <div class="server-settings-card">
            <el-form :model="ServerConfig" :rules="rules" ref="serverForm" label-width="120px" label-position="left" class="config-form">
              <el-form-item :label="$t('服务器IP')" prop="ip">
                <el-input v-model="ServerConfig.ip" class="server-ip-input" :placeholder="$t('Enter Server IP')" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
              </el-form-item>
              <el-form-item :label="$t('服务器端口')" prop="port">
                <el-input-number v-model="ServerConfig.port" :min="0" :max="65535" :controls="false" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="saveConfig">{{ $t('保存 & 应用') }}</el-button>
              </el-form-item>
            </el-form>
          </div>

          <div class="aggregate-v-divider" aria-hidden="true"></div>

          <div class="server-status-card">
            <div class="status-info">
              <el-descriptions :column="1" border>
                <el-descriptions-item :label="$t('连接状态')">
                  <el-tag :class="{'blink-bg': true}" :type="getStatusTagType()">
                    {{ serverStatus.connected ? $t('Connected') : $t('Disconnected') }}
                  </el-tag>
                </el-descriptions-item>
                <el-descriptions-item :label="$t('RTT')">
                  <el-tag :type="getRttTagType(serverStatus.rtt)">
                    {{ serverStatus.rtt }} ms
                  </el-tag>
                </el-descriptions-item>
                <el-descriptions-item :label="$t('服务器节点')">
                  <el-tag type="info">{{ serverStatus.location }}</el-tag>
                </el-descriptions-item>
                <el-descriptions-item :label="$t('服务器版本')">
                  <el-tag type="info">{{ serverStatus.version }}</el-tag>
                </el-descriptions-item>
                <el-descriptions-item :label="$t('服务器负载')">
                  <el-tag type="info">{{ serverStatus.load }}</el-tag>
                </el-descriptions-item>
                <el-descriptions-item :label="$t('服务器公告')">
                  <el-tag type="info">{{ serverStatus.notice }}</el-tag>
                </el-descriptions-item>
              </el-descriptions>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'ModeAggregate',
  props: {
    pageActive: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      ServerConfig: {
        ip: '',
        port: 0
      },
      serverStatus: {
        connected: false,
        rtt: 0,
        load: 0,
        location: '',
        version: '',
        notice: ''
      },
      hasUnsavedChanges: false,
      isEditing: false,
      stopped: true,
      statusInFlight: false,
      pollTimer: null,
      pollIntervalMs: 5000,
      rules: {
        ip: [
          { required: true, message: this.$t('Server IP is required'), trigger: 'blur' },
          { validator: this.validateIP, trigger: 'blur' }
        ],
        port: [
          { required: true, message: this.$t('Server Port is required'), trigger: 'blur' },
          { validator: this.validatePort, trigger: 'blur' }
        ]
      }
    }
  },
  watch: {
    pageActive(value) {
      if (value)
        this.startAll()
      else
        this.stopAll()
    }
  },
  mounted() {
    if (this.pageActive)
      this.startAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  methods: {
    runAfterFirstFrame(fn) {
      if (typeof requestAnimationFrame === 'function') {
        requestAnimationFrame(() => requestAnimationFrame(() => fn()))
      } else {
        setTimeout(() => fn(), 0)
      }
    },
    startAll() {
      if (!this.stopped)
        return
      this.stopped = false
      this.statusInFlight = false
      this.fetchServerConfig()
      this.runAfterFirstFrame(() => {
        if (this.stopped)
          return
        this.fetchStaticInfo()
        this.refreshOnce()
        this.startPolling()
      })
    },
    stopAll() {
      this.stopped = true
      this.stopPolling()
    },
    startPolling() {
      if (this.stopped)
        return
      this.stopPolling()
      this.pollTimer = setTimeout(async() => {
        await this.refreshOnce()
        this.startPolling()
      }, this.pollIntervalMs)
    },
    stopPolling() {
      if (this.pollTimer) {
        clearTimeout(this.pollTimer)
        this.pollTimer = null
      }
    },
    // 获取服务器配置信息
    fetchServerConfig() {
      this.fetchServerIP()
      this.fetchServerPort()
    },
    // 获取状态信息
    fetchStaticInfo() {
      setTimeout(() => this.fetchServerNode(), 100)
      setTimeout(() => this.fetchServerVersion(), 150)
      setTimeout(() => this.fetchServerAnnourcement(), 200)
    },
    async refreshOnce() {
      if (this.stopped)
        return
      if (this.isEditing || this.hasUnsavedChanges)
        return
      await Promise.allSettled([this.fetchServerStatus()])
    },
    withTimeout(promise, ms, operation) {
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          reject(new Error(`${operation} timeout after ${ms}ms`))
        }, ms)
        Promise.resolve(promise).then((value) => {
          clearTimeout(timer)
          resolve(value)
        }, (err) => {
          clearTimeout(timer)
          reject(err)
        })
      })
    },
    // 保存配置
    saveConfig() {
      this.$refs.serverForm.validate((valid) => {
        if (valid) {
          this.$message({
            message: this.$t('Configuration has been applied'),
            type: 'success'
          })
          this.setWorkMode()
          this.setServerIP()
          this.setServerPort()
          this.hasUnsavedChanges = false
          this.fetchServerStatus()
        } else {
          return false
        }
      })
    },
    // 设置工作模式为聚合模式
    setWorkMode() {
      this.$oui.call('mode', 'setMode', { mode: 'aggregate' })
      console.log('工作模式: 聚合模式')
    },
    // 设置服务器IP
    setServerIP() {
      const params = { ip: this.ServerConfig.ip }
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerIP', params)
      console.log('服务器IP: ', this.ServerConfig.ip)
    },
    // 设置服务器端口
    setServerPort() {
      const params = { port: this.ServerConfig.port }
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerPort', params)
      console.log('服务器IP: ', this.ServerConfig.port)
    },
    // IP格式是否合法
    validateIP(rule, value, callback) {
      if (!value) {
        callback(new Error(this.$t('Server IP is required')))
      }
      const ip = String(value)
      if (!/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(ip) ||
        ip.split('.').some(part => parseInt(part, 10) < 0 || parseInt(part, 10) > 255)) {
        callback(new Error(this.$t('Invalid IP address')))
        return
      }
      this.ServerConfig.ip = ip
      callback()
    },
    validatePort(rule, value, callback) {
      if (!value) {
        callback(new Error(this.$t('Server Port is required')))
      }
      const port = Number(value)
      if (port < 0 || port > 65535) {
        callback(new Error(this.$t('Port must be between 1 and 65535')))
        return
      }
      this.ServerConfig.port = port
      callback()
    },
    // 获取服务器IP
    fetchServerIP() {
      if (this.isEditing)
        return
      if (this.hasUnsavedChanges)
        return
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (this.stopped)
          return
        if (ip) {
          this.ServerConfig.ip = ip
        }
      })
    },
    // 获取服务器端口 
    fetchServerPort() {
      if (this.isEditing)
        return
      if (this.hasUnsavedChanges)
        return
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (this.stopped)
          return
        if (port) {
          this.ServerConfig.port = parseInt(port)
        }
      }).catch(() => {})
    },
    fetchServerNode() {
      this.$oui.call('serverManager', 'getServerNode').then(node => {
        if (this.stopped)
          return
        if (node) {
          this.serverStatus.location = node
        }
      }).catch(() => {})
    },
    fetchServerVersion() {
      this.$oui.call('serverManager', 'getServerVersion').then(version => {
        if (this.stopped)
          return
        if (version) {
          this.serverStatus.version = version
        }
      }).catch(() => {})
    },
    fetchServerAnnourcement() {
      this.$oui.call('serverManager', 'getServerAnnourcement').then(annourcement => {
        if (this.stopped)
          return
        if (annourcement) {
          this.serverStatus.notice = annourcement
        }
      }).catch(() => {})
    },
    fetchServerRTT() {
      return this.withTimeout(this.$oui.call('serverManager', 'getHostRtt'), 5000, 'getHostRtt').then(state => {
        if (this.stopped)
          return
        if (!state.reachable) {
          this.serverStatus.connected = false
          this.serverStatus.rtt = 0
          return
        }
        this.serverStatus.rtt = parseInt(state.rtt_ms)
      }).catch(() => {
        if (this.stopped)
          return
        this.serverStatus.rtt = 0
      })
    },
    fetchVPNrtt() {
      return this.withTimeout(this.$oui.call('serverManager', 'getVPNrtt'), 5000, 'getVPNrtt').then(state => {
        if (this.stopped)
          return
        if (!state.reachable) {
          this.serverStatus.connected = false
          return this.fetchServerRTT()
            .catch(() => {})
        }
        this.serverStatus.connected = true
        this.serverStatus.rtt = parseInt(state.rtt_ms)
      }).catch(() => {
        if (this.stopped)
          return
        this.serverStatus.connected = false
        this.serverStatus.rtt = 0
      })
    },
    async fetchServerStatus() {
      if (this.stopped)
        return
      if (this.statusInFlight)
        return
      this.statusInFlight = true
      try {
        await this.fetchVPNrtt()
      } catch {
        return
      } finally {
        this.statusInFlight = false
      }
    },
    getRttTagType(rtt) {
      if (rtt < 50) {
        return 'success'
      } else if (rtt < 100) {
        return 'info'
      } else if (rtt < 150) {
        return 'warning'
      } else {
        return 'danger'
      }
    },
    getStatusTagType() {
      return this.serverStatus.connected ? 'success' : 'danger'
    },
    markUnsavedChanges() {
      this.hasUnsavedChanges = true
    }
  }
}
</script>
