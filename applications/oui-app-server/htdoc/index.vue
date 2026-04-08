<template>

<div class ="server">

  <div class="header">
    <h2> {{ $t('Server') }} </h2>
  </div>

  <div class="server-section">
    <!-- Server Settings -->
    <el-card class="server-settings-card">
      <!-- Server Settings -> header -->
      <template #header>
        <div class="card-header">
          <span>{{ $t('Server Settings')}}</span>
        </div>
      </template>

      <!-- Server Settings -> body -->
      <el-form :model="ServerConfig" :rules="rules" ref="serverForm" label-width="120px" label-position="left" class="config-form">
        <!-- Server Settings -> body -> Server IP -->
        <el-form-item :label="$t('Server IP')" prop="ip">
          <el-input v-model="ServerConfig.ip" :placeholder="$t('Enter Server IP')" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
        </el-form-item>
        <!-- Server Settings -> body -> Server Port -->
        <el-form-item :label="$t('Server Port')" prop="port">
          <el-input-number v-model="ServerConfig.port" :min="1" :max="65535" :controls="false" @focus="isEditing = true" @blur="isEditing = false" @input="markUnsavedChanges"/>
        </el-form-item>
        <!-- Server Settings -> body -> Save Button -->
        <el-form-item>
          <el-button type="primary" @click="saveConfig">{{ $t('Save & Apply') }}</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- Server Status -->
    <el-card class="server-status-card">
      <!-- Server Status -> header -->
      <template #header>
        <div class="card-header">
          <span>{{ $t('Server Status')}}</span>
        </div>
      </template>
      <!-- Server Status -> body -->
      <div class="status-info">
        <el-descriptions :column="1" border>
          <!-- Server Status -> body -> Status -->
          <el-descriptions-item :label="$t('Status')">
            <el-tag :class="{'blink-bg': true}" :type="getStatusTagType()">
              {{ serverStatus.connected ? $t('Connected') : $t('Disconnected') }}
            </el-tag>
          </el-descriptions-item>
          <!-- Server Status -> body -> rtt -->
          <el-descriptions-item :label="$t('RTT')">
            <el-tag :type="getRttTagType(serverStatus.rtt)">
              {{ serverStatus.rtt }} ms
            </el-tag>
          </el-descriptions-item>
          <!-- Server Status -> body -> location -->
          <el-descriptions-item :label="$t('Location')">
            <el-tag type="info">{{ serverStatus.location }}</el-tag>
          </el-descriptions-item>
          <!-- Server Status -> body -> Server Version -->
          <el-descriptions-item :label="$t('Server Version')">
            <el-tag type="info">{{ serverStatus.version }}</el-tag>
          </el-descriptions-item>
          <!-- Server Status -> body -> Server Load -->
          <el-descriptions-item :label="$t('Server Load')">
            <el-tag type="info">{{ serverStatus.load }}</el-tag>
          </el-descriptions-item>
          <!-- Server Status -> body -> Service Notice -->
          <el-descriptions-item :label="$t('Notice')">
            <el-tag type="info">{{ serverStatus.notice }}</el-tag>
          </el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>

  </div>
</div>

</template>


<script>

export default {
  name: 'ServerConfig',
  data() {
    return {
      ServerConfig: {
        ip: '',
        port: 0
      },
      serverStatus: {
        connected: false,
        rtt: 0,
        load: 0, // 服务器负载
        location: '',
        version: '',
        notice: ''
      },
      hasUnsavedChanges: false, // 是否有为保存的配置
      isEditing: false, // 用户是否正在编辑
      stopped: false,
      statusInFlight: false,
      pollTimer: null,
      pollIntervalMs: 5000,
      visibilityListenerAdded: false,
      rules: {
        ip: [
          { required: true, message: this.$t('Server IP is required'), trigger: 'blur' },
          { validator: this.validateIP, trigger: 'blur' }
        ],
        port: [
          { required: true, message: this.$t('Server Port is required'), trigger: 'blur' },
          { validator: this.validatePort, trigger: 'blur'}
        ]
      }
    }
  },
  created() {
  },
  mounted() {
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  activated() {
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  deactivated() {
    this.stopAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  beforeRouteLeave(to, from, next) {
    this.stopAll()
    next()
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
      this.stopped = false
      this.statusInFlight = false
      if (typeof document !== 'undefined' && document && !this.visibilityListenerAdded) {
        document.addEventListener('visibilitychange', this.onVisibilityChange)
        this.visibilityListenerAdded = true
      }
      this.fetchStaticInfo()
      this.refreshOnce()
      this.startPolling()
    },
    stopAll() {
      this.stopped = true
      this.stopPolling()
      if (typeof document !== 'undefined' && document && this.visibilityListenerAdded) {
        document.removeEventListener('visibilitychange', this.onVisibilityChange)
        this.visibilityListenerAdded = false
      }
    },
    startPolling() {
      if (this.stopped)
        return
      this.stopPolling()
      this.pollTimer = setTimeout(async () => {
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
    onVisibilityChange() {
      if (this.stopped)
        return
      if (typeof document !== 'undefined' && document && document.hidden) {
        this.stopPolling()
      } else {
        this.refreshOnce()
        this.startPolling()
      }
    },
    fetchStaticInfo() {
      setTimeout(() => this.fetchServerIP(), 0)
      setTimeout(() => this.fetchServerPort(), 50)
      setTimeout(() => this.fetchServerNode(), 100)
      setTimeout(() => this.fetchServerVersion(), 150)
      setTimeout(() => this.fetchServerAnnourcement(), 200)
    },
    async refreshOnce() {
      if (this.stopped)
        return
      if (this.isEditing || this.hasUnsavedChanges)
        return
      await this.fetchServerStatus()
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
    saveConfig() {
      // 表单验证
      this.$refs.serverForm.validate((valid) => {
        if (valid) {
          this.$message({
            message: this.$t('Configuration has been applied'),
            type: 'success'
          })
          this.setServerIP()
          this.setServerPort()
          this.hasUnsavedChanges = false
          // 保存后立即刷新状态
          this.fetchServerStatus()
        } else {
          // 验证失败，不保存
          return false
        }
      })
    },
    // 设置服务器ip
    setServerIP() {
      const params = { ip: this.ServerConfig.ip }
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerIP', params)
      this.fetchServerIP()
    },
    // 设置服务器端口
    setServerPort() {
      const params = { port: this.ServerConfig.port}
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerPort', params)
      this.fetchServerPort()
    },
    // ip格式校验
    validateIP(rule, value, callback) {
      // IP地址验证
      if (!value) {
        callback(new Error(this.$t('Server IP is required')))
      }
      // IP地址验证（格式和范围）
      const ip = String(value)
      if (!/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(ip) ||
        ip.split('.').some(part => parseInt(part, 10) < 0 || parseInt(part, 10) > 255)) {
        callback(new Error(this.$t('Invalid IP address')))
        return
      }
      this.ServerConfig.ip = ip
      callback() // 验证通过
    },
    // 端口范围校验
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
    // 获取服务器ip
    fetchServerIP() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (this.stopped)
          return
        if (ip) {
          this.ServerConfig.ip = ip
        }
      }).catch(() => {})
    },
    // 获取服务器端口
    fetchServerPort() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (this.stopped)
          return
        if (port) {
          this.ServerConfig.port = parseInt(port)
        }
      }).catch(() => {})
    },
    // 获取服务器节点信息
    fetchServerNode() {
      this.$oui.call('serverManager', 'getServerNode').then(node => {
        if (this.stopped)
          return
        if (node) {
          this.serverStatus.location = node
        }
      })
    },
    // 获取服务器版本
    fetchServerVersion() {
      this.$oui.call('serverManager', 'getServerVersion').then(version => {
        if (this.stopped)
          return
        if (version) {
          this.serverStatus.version = version
        }
      })
    },
    // 获取服务器公告
    fetchServerAnnourcement() {
      this.$oui.call('serverManager', 'getServerAnnourcement').then(annourcement => {
        if (this.stopped)
          return
        if (annourcement) {
          this.serverStatus.notice = annourcement
        }
      })
    },
    // 获取服务器连接状态和rtt
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
    // 获取VPN隧道状态和RTT
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
    // 获取服务器状态 - 异步并行执行
    async fetchServerStatus() {
      if (this.stopped)
        return
      if (this.statusInFlight)
        return
      this.statusInFlight = true
      try {
        await this.fetchVPNrtt()
      } catch {
      } finally {
        this.statusInFlight = false
      }
    },
    // 根据rtt判断连接状态
    getRttTagType(rtt) {
      // 根据RTT值返回不同的标签类型
      if (rtt < 50) {
        return 'success' // 优秀
      } else if (rtt < 100) {
        return 'info' // 正常
      } else if (rtt < 150) {
        return 'warning' // 较慢
      } else {
        return 'danger' // 很慢
      }
    },
    // 不同状态使用不同颜色标识
    getStatusTagType() {
      return this.serverStatus.connected ? 'success' : 'danger'
    },
    // 有未保存的改动
    markUnsavedChanges() {
      this.hasUnsavedChanges = true
    }
  }
}

</script>

<style>

.server {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  margin-bottom: 20px;
}

.server-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 30px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.config-form {
  padding: 10px;
}

.status-info {
  padding: 10px;
}

/* 添加过渡效果，使状态变化更平滑 */
.el-tag {
  transition: background-color 0.3s ease, color 0.3s ease;
  font-weight: 600; /* 加深字体 */
  color: rgba(0, 0, 0, 0.85); /* 加深字体加深各种颜色的背景色 */
}

/* 加深各种状态的背景色 */
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

/* 输入框文字左对齐 */
.el-input-number /deep/ .el-input__inner {
  text-align: left !important;
}

.el-input-number ::v-deep .el-input__inner {
  text-align: left !important;
}

.config-form .el-input-number input {
  text-align: left !important;
}

/* 闪烁背景样式 */
.blink-bg {
  animation: blink-animation 1s infinite;
}

@keyframes blink-animation {
  0% { opacity: 1; }
  50% { opacity: 0.9; }
  100% { opacity: 1; }
}

@media (max-width: 768px) {
  .server-section {
    grid-template-columns: 1fr;
  }
}

</style>

<i18n src="./locale.json"/>
