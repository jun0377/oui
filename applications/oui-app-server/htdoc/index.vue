<template>

<div class ="server">

  <div class="header">
    <h2> {{ $t('Server') }} </h2>
  </div>

  <div class="server-section">

    <el-card class="server-settings-card">
      <template #header>
        <div class="card-header">
          <span>{{ $t('Server Settings')}}</span>
        </div>
      </template>

      <el-form :model="ServerConfig" :rules="rules" ref="serverForm" label-width="120px" class="config-form">
        <el-form-item :label="$t('Server IP')" prop="ip">
          <el-input v-model="ServerConfig.ip" :placeholder="$t('Enter Server IP')" />
        </el-form-item>
        <el-form-item :label="$t('Server Port')" prop="port">
          <el-input v-model="ServerConfig.port" type="number" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="saveConfig">{{ $t('Save & Apply') }}</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="server-status-card">
      <template #header>
        <div class="card-header">
          <span>{{ $t('Server Status')}}</span>
        </div>
      </template>
      <div class="status-info">
        <el-descriptions :column="1" border>
          <el-descriptions-item :label="$t('Status')">
            <el-tag :type="serverStatus.connected ? 'success' : 'danger'">
              {{ serverStatus.connected ? $t('Connected') : $t('Disconnected') }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item :label="$t('RTT')">
            <el-tag :type="getRttTagType(serverStatus.rtt)">
              {{ serverStatus.rtt }} ms
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item :label="$t('Location')">
            <el-tag type="info">{{ serverStatus.location }}</el-tag>
          </el-descriptions-item>
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
        port: '65500'
      },
      serverStatus: {
        connected: false,
        rtt: 0,
        location: '',
        notice: ''
      },
      refreshTimer: null,
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
  },
  beforeUnmount() {
    // 组件销毁前清除定时器
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  },
  methods: {
    saveConfig() {
      // 表单验证
      this.$refs.serverForm.validate((valid) => {
        if (valid) {
          // 验证通过，保存配置
          // 实际项目中应该调用API保存配置
          this.$message({
            message: this.$t('Configuration has been applied'),
            type: 'success'
          })
          // 保存后立即刷新状态
          this.fetchServerStatus()
        } else {
          // 验证失败，不保存
          return false
        }
      })
    },
    validateIP(rule, value, callback) {
      // IP地址验证
      if (!value) {
        callback(new Error(this.$t('Server IP is required')))
      }
      // 简单的IP地址格式验证
      const ipPattern = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/
      if (!ipPattern.test(value)) {
        callback(new Error(this.$t('Invalid IP address')))
        return
      }
      // 验证每个段落的范围
      const parts = value.split('.')
      for (const part of parts) {
        const num = parseInt(part, 10)
        if (num < 0 || num > 255) {
          callback(new Error(this.$t('Invalid IP address')))
          return
        }
      }
      callback() // 验证通过
    },
    fetchServerStatus() {
      // 模拟从后台API获取服务器状态
      // 实际项目中应该替换为真实的API调用
      // 例如: this.$http.get('/api/server/status')
      // 模拟API响应延迟
      setTimeout(() => {
        // 模拟API返回数据
        const mockResponse = {
          connected: Math.random() > 0.2, // 80%概率连接成功
          rtt: Math.floor(Math.random() * 200), // 0-200ms的RTT
          location: '上海 电信',
          notice: this.$t('Notice') + ': ' + new Date().toLocaleTimeString() // 动态公告
        }
        // 更新状态
        this.serverStatus = mockResponse
      }, 300)
    },
    getRttTagType(rtt) {
      // 根据RTT值返回不同的标签类型
      if (rtt < 50) {
        return 'success' // 优秀
      } else if (rtt < 100) {
        return '' // 正常（默认颜色）
      } else if (rtt < 150) {
        return 'warning' // 较慢
      } else {
        return 'danger' // 很慢
      }
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

@media (max-width: 768px) {
  .server-section {
    grid-template-columns: 1fr;
  }
}

</style>

<i18n src="./locale.json"/>