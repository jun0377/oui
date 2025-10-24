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
          <el-tooltip :content="$t('暂不开放,和服务器IP相同')" placement="top">
            <el-input :placeholder="$t('中继服务器IP')" v-model="settings.remote_ip" disabled />
          </el-tooltip>
        </el-form-item>

        <el-form-item :label="$t('中继服务器端口')">
          <el-tooltip :content="$t('赞不支持手动设置,后续版本完善')" placement="top">
            <el-input :placeholder="$t('中继节点端口')" v-model="settings.remote_port" disabled></el-input>
          </el-tooltip>
        </el-form-item>

        <el-form-item :label="$t('组网网段')">
          <el-tooltip :content="$t('此配置在服务器端进行设置')" placement="top">
            <el-input :placeholder="$t('虚拟网络网络号')" v-model="settings.virtual_net" disabled></el-input>
          </el-tooltip>
        </el-form-item>

        <el-form-item :label="$t('本地虚拟IP')">
          <el-tooltip :content="$t('暂不支持手动设置,由服务器自动分配')" placement="top">
            <el-input :placeholder="$t('本地虚拟IP')" v-model="settings.local_ip" disabled></el-input>
          </el-tooltip>
        </el-form-item>

        <el-form-item :label="$t('本地端口')">
          <el-tooltip :content="$t('暂不支持手动设置,由系统自动分配')" placement="top">
            <el-input :placeholder="$t('本地端口')" v-model="settings.local_port" disabled></el-input>
          </el-tooltip>
        </el-form-item>

        <el-form-item :label="$t('子网地址')">
          <el-tooltip :content="$t('DHCP地址池设置,由服务器自动分配')" placement="top">
            <el-input :placeholder="$t('子网地址')" v-model="settings.subnet" disabled></el-input>
          </el-tooltip>
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
          <el-descriptions-item :label="$t('组网状态')"><el-tag type="info">{{ status.connected }}</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('RTT')"><el-tag type="info">{{ status.rtt }}ms</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('上行流量(本次连接)')"><el-tag type="info">{{ status.tx_MB }} MB</el-tag></el-descriptions-item>
          <el-descriptions-item :label="$t('下行流量(本地连接)')"><el-tag type="info">{{ status.rx_MB }} MB</el-tag></el-descriptions-item>
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
        local_port: 0,
        subnet: ''
      },
      status: {
        // openvpnDead - 进程未启动; 
        // openvpnBroken - 未连接; 
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
  beforeUmount() {
    if (this.refreshSettingsTimer) {
      clearInterval(this.refreshSettingsTimer)
    }

    if(this.refreshStatusTimer){
      clearInterval(this.refreshStatusTimer)
    }
  },
  methods: {
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
        this.settings.remote_ip = ip[0]
        // console.log('fetchSettingsRemoteIP: ', this.settings.remote_ip)
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
        this.settings.virtual_net = ip
        // console.log('fetchSettingsVirtualNet: ', this.settings.virtual_net)
      })
    },
    fetchSettingsLocalIP() {
      // console.log('fetch local ip')
      this.$oui.call('sdwan', 'getLocalIP').then(ip => {
        this.settings.local_ip = ip
        // console.log('fetchSettingsLocalIP: ', this.settings.local_ip)
      })
    },
    fetchSettingsLocalPort() {
      // console.log('fetch local port')
      this.$oui.call('sdwan', 'getLocalPort').then(port => {
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
        switch(status) {
          case 'openvpnDead':
            this.status.connected = '未启动'
            break;
          case 'openvpnBroken':
            this.status.connected = '连接断开'
            break;
          case 'openvpnNormal':
            this.status.connected = '正常'
            break;
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
