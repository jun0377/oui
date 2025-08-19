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
      <el-form :model="ServerConfig" :rules="rules" ref="serverForm" label-width="120px" class="config-form">
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
          { type: 'number', min: 1, max: 65535, message: this.$t('Port must be between 1 and 65535'), trigger: 'blur' }
        ]
      }
    }
  },
  created() {
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
    setServerIP() {
      console.log('set server ip: ', this.ServerConfig.ip)
      return this.$oui.call('serverManager', 'setServerIP', this.ServerConfig.ip)
    },
    setServerPort() {
      console.log('set server port: ', this.ServerConfig.port)
      return this.$oui.call('serverManager', 'setServerPort', this.ServerConfig.port)
    },
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
    fetchServerIP() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerIP').then(ip => {
        if (ip) {
          this.ServerConfig.ip = ip
        }
      }).catch(error => {
        console.error('Failed to get server IP:', error)
      })
    },
    fetchServerPort() {
      if (this.isEditing) // 当输入框处于focus状态时，不要更新
        return
      if (this.hasUnsavedChanges) // 当有未保存的配置时，不要更新
        return
      this.$oui.call('serverManager', 'getServerPort').then(port => {
        if (port) {
          this.ServerConfig.port = port
        }
      }).catch (errno => {
        console.error('Failed to get server Port:', errno)
      })
    },
    // 获取服务器状态
    fetchServerStatus() {
      this.fetchServerIP()
      this.fetchServerPort()
    },
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
    getStatusTagType() {
      // 根据闪烁状态和连接状态返回不同的标签类型
      if (this.isBlinking) {
        return this.serverStatus.connected ? 'warning' : 'success'
      } else {
        return this.serverStatus.connected ? 'success' : 'danger'
      }
    },
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