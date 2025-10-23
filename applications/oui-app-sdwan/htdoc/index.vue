<template>

<div class="sdwan">
  <div class="header">
    <h2>{{ $t('中继组网') }}</h2>
  </div>

  <div class="settings-section">
    <el-card class="settings-card">
      <template #header>
        <div class="card-header">
          <span>{{ $t('设置') }}</span>
        </div>
      </template>

      <el-form class="settings-form" label-width="120px" label-position="left">
        <el-form-item :label="$t('中继服务器')">
          <el-input :placeholder="$t('中继服务器IP')" v-model="settings.remote_ip" disabled />
        </el-form-item>
        <el-form-item :label="$t('中继服务器端口')">
          <el-input :placeholder="$t('中继节点端口')" v-model="settings.remote_port" disabled></el-input>
        </el-form-item>
        <el-form-item :label="$t('组网网段')">
          <el-input :placeholder="$t('虚拟网络网络号')" v-model="settings.virtual_net" disabled></el-input>
        </el-form-item>
        <el-form-item :label="$t('本地虚拟IP')">
          <el-input :placeholder="$t('本地虚拟IP')" v-model="settings.local_ip" disabled></el-input>
        </el-form-item>
        <el-form-item :label="$t('本地端口')">
          <el-input :placeholder="$t('本地端口')" v-model="settings.local_port" disabled></el-input>
        </el-form-item>
      </el-form>

    </el-card>

    <el-card class="status-card">
      <template #header>
        <div class="card-header">
          <span>{{ $t('状态') }}</span>
        </div>
      </template>
      <div class="status-info">
        <el-descriptions :column="1" border>
          <el-descriptions-item :label="$t('组网状态')"><el-tag type="info">正常</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('RTT')"><el-tag type="info">10ms</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('上行流量')"><el-tag type="info">10MB</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('下行流量')"><el-tag type="info">99KB</el-tag></el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>
  </div>
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
        local_port: 0
      },
      status: {
        connected: false,
        rtt: 0,
        tx_bytes: 99,
        rx_bytes: 200
      },
      refreshTimer: null
    }
  },
  created() {
    this.fetchRemoteIP()
    this.fetchRemotePort()

    this.refreshTimer = setInterval(() => {
      this.fetchRemoteIP()
      this.fetchRemotePort()
      this.fetchVirtualNet()
      this.fetchLocalIP()
      this.fetchLocalPort()
    }, 3000)
  },
  beforeUmount() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  },
  methods: {
    fetchRemoteIP() {
      console.log('fetch remote ip')
      this.$oui.call('sdwan', 'getRemoteIP').then(ip => {
        this.settings.remote_ip = ip
        console.log('fetchRtemoteIP: ', this.settings.remote_ip)
      })
    },
    fetchRemotePort() {
      console.log('fetch remote port')
      this.$oui.call('sdwan', 'getRemotePort').then(port => {
        this.settings.remote_port = Number(port)
        console.log('fetchRemotePort: ', this.settings.remote_port)
      })
    },
    fetchVirtualNet() {
      console.log('fetch virtual net')
      this.$oui.call('sdwan', 'getVirtualNet').then(ip => {
        this.settings.virtual_net = ip
        console.log('fetchVirtualNet: ', this.settings.virtual_net)
      })
    },
    fetchLocalIP() {
      console.log('fetch local ip')
      this.$oui.call('sdwan', 'getLocalIP').then(ip => {
        this.settings.local_ip = ip
        console.log('fetchLocalIP: ', this.settings.local_ip)
      })
    },
    fetchLocalPort() {
      console.log('fetch local port')
      this.$oui.call('sdwan', 'getLocalPort').then(port => {
        this.settings.local_port = port
        console.log('fetchLocalPort: ', this.settings.local_port)
      })
    }
  }



}

</script>

<style>

.sdwan {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  margin-bottom: 20px;
}

.settings-section {
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

.settings-form {
  padding: 10px;
}

.status-info {
  padding: 10px;
}

.el-tag {
  transition: background-color 0.3s ease, color 0.3s ease;
  font-weight: 600; /* 加深字体 */
  color: rgba(0, 0, 0, 0.85); /* 加深字体加深各种颜色的背景色 */
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

</style>

<i18n src="./locale.json"/>
