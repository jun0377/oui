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
      refreshTimer: null,
      blinkTimer: null,
      isBlinking: false, // 控制状态背景闪烁
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
    this.fetchServerIP()
    this.fetchServerPort()
    // 初始加载服务器状态
    this.fetchServerStatus()
    // 设置定时刷新，每5秒刷新一次
    this.refreshTimer = setInterval(() => {
      this.fetchServerStatus()
    }, 5000)
    // 设置背景闪烁定时器，每秒切换一次
    this.blinkTimer = setInterval(() => {
      this.isBlinking = !this.isBlinking
    }, 1000)
  },
  beforeUnmount() {
    // 组件销毁前清除定时器
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
    if (this.blinkTimer) {
      clearInterval(this.blinkTimer)
    }
  },
  methods: {
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
      console.log('Calling setServerIP with params:', params)
      this.serverStatus.connected = false
      this.serverStatus.rtt = 0
      this.$oui.call('serverManager', 'setServerIP', params)
      this.fetchServerIP()
    },
    // 设置服务器端口
    setServerPort() {
      const params = { port: this.ServerConfig.port}
      console.log('set server port: ', params)
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
      console.log('get Server IP')
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (ip) {
          this.ServerConfig.ip = ip
          console.log('getServerIP: ', this.ServerConfig.ip)
        }
      }).catch(error => {
        console.error('Failed to get server IP:', error)
      })
    },
    // 获取服务器端口
    fetchServerPort() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      console.log('get Server Port')
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (port) {
          this.ServerConfig.port = parseInt(port)
          console.log('getServerPort: ', this.ServerConfig.port)
        }
      }).catch (errno => {
        console.error('Failed to get server Port:', errno)
      })
    },
    // 创建超时Promise
    createTimeoutPromise(ms, operation) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          reject(new Error(`${operation} timeout after ${ms}ms`))
        }, ms)
      })
    },
    // 获取服务器连接状态和rtt
    fetchServerRTT() {
      console.log('get Server RTT')
      // 使用Promise.race实现超时机制，5秒超时
      return Promise.race([
        this.$oui.call('serverManager', 'getHostRtt'),
        this.createTimeoutPromise(5000, 'getHostRtt')
      ]).then(state => {
        if (!state.reachable) {
          console.warn('Server Unreachable! Server: ', this.ServerConfig.ip)
          this.serverStatus.connected = false
          this.serverStatus.rtt = 0
          return
        }
        this.serverStatus.rtt = parseInt(state.rtt_ms)
        console.log('getHostRtt', this.serverStatus.rtt)
      }).catch(error => {
        console.error('Failed to get server RTT:', error)
        this.serverStatus.rtt = 0
        if (error.message.includes('timeout')) {
          console.warn('get rtt timeout...')
        }
      })
    },
    // 获取VPN隧道状态和RTT
    fetchVPNrtt() {
      console.log('get VPN RTT')
      return Promise.race([
        this.$oui.call('serverManager', 'getVPNrtt'),
        this.createTimeoutPromise(5000, 'getVPNrtt')
      ]).then(state => {
        if (!state.reachable) {
          console.log('Server VPN Unreachable!')
          this.serverStatus.connected = false
          this.fetchServerRTT()
          return
        }
        this.serverStatus.connected = true
        this.serverStatus.rtt = parseInt(state.rtt_ms)
      })
    },
    // 获取服务器状态 - 异步并行执行
    async fetchServerStatus() {
      try {
        // 使用 Promise.allSettled 并行执行，避免一个失败影响其他
        const results = await Promise.allSettled([
          // this.fetchServerRTT(),
          this.fetchVPNrtt()
        ])
        // 检查每个操作的结果
        const operations = ['fetchVPNrtt']
        results.forEach((result, index) => {
          if (result.status === 'fulfilled') {
            // console.log(`${operations[index]} completed successfully`)
          } else {
            console.error(`${operations[index]} failed:`, result.reason)
          }
        })
        // console.log('Server status fetch completed')
      } catch (error) {
        console.error('Unexpected error in fetchServerStatus:', error)
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
      if (this.isBlinking) {
        return this.serverStatus.connected ? 'warning' : 'success'
      } else {
        return this.serverStatus.connected ? 'success' : 'danger'
      }
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