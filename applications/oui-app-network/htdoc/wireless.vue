<template>
  <div class="wireless">
    <div class="header">
      <h2>无线设置</h2>
    </div>

    <div class="settings-section">
      <el-card class="settings-card">
        <template #header>
          <div class="card-header">
            <span>设置</span>
          </div>
        </template>

        <el-form class="settings-form" label-width="120px" label-position="left">
          <el-form-item label="SSID">
            <el-input v-model="settings.ssid" placeholder="请输入SSID"></el-input>
          </el-form-item>
          <el-form-item label="密码">
            <el-input v-model="settings.password" :type="settings.passwordVisible ? 'text' : 'password'" placeholder="请输入密码">
              <template #append>
                <el-button link @click="togglePasswordVisibility">
                  {{ settings.passwordVisible ? '隐藏' : '显示' }}
                </el-button>
              </template>
            </el-input>
          </el-form-item>
        </el-form>
      </el-card>

      <el-card class="status-card">
        <template #header>
          <div class="card-header">
            <span>信号强度</span>
          </div>
        </template>
        <el-descriptions class="status-descriptions" border :column="1">
          <el-descriptions-item label="当前信号强度">{{ status.signalStrength }}dBm</el-descriptions-item>
        </el-descriptions>
      </el-card>
    </div>

    <div class="footer">
      <el-button type="primary" class="action-button" @click="saveSettings">保存设置</el-button>
      <el-button type="primary" class="action-button" @click="$emit('go-back')">返回</el-button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WirelessConfig',
  data() {
    return {
      settings: {
        ssid: '',
        password: '',
        passwordVisible: false
      },
      status: {
        signalStrength: 0
      }
    }
  },
  created() {
    this.fetchSSID()
    this.fetchPassword()
  },
  methods: {
    saveSettings() {
      console.log('saveSettings:', this.settings.ssid, this.settings.password)
      this.$oui.call('wireless', 'setSSID', {'ssid': this.settings.ssid}).then(response => {
        response ? this.$message.success('SSID 设置成功') : this.$message.console.error('SSID 设置失败')
      })
      this.$oui.call('wireless', 'setPassword', { 'password' : this.settings.password}).then(response => {
        response ? this.$message.success('密码 设置成功') : this.$message.console.error('密码 设置失败')
      })
    },
    fetchSSID() {
      this.$oui.call('wireless', 'getSSID').then(response => {
        this.settings.ssid = response
      })
    },
    fetchPassword() {
      this.$oui.call('wireless', 'getPassword').then(response => {
        this.settings.password = response
      })
    },
    togglePasswordVisibility() {
      this.settings.passwordVisible = !this.settings.passwordVisible
    }
  }
}
</script>

<style scoped>
.wireless {
  padding: 20px;
}
.header {
  margin-bottom: 20px;
}
.settings-section {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}
.settings-card,
.status-card {
  flex: 1;
}
.card-header {
  font-weight: bold;
}
.footer {
  text-align: center;
  margin-top: 20px;
}
.action-button {
  width: 120px;
  margin: 0 10px;
}
</style>