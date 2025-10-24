<template>
  <div class="dhcp">
    <div class="header">
      <h2>DHCP 服务</h2>
    </div>

    <div class="settings-section">
      <!-- 左侧配置卡片 -->
      <el-card class="settings-card">
        <template #header>
          <div class="card-header">
            <span>配置</span>
          </div>
        </template>

        <el-form class="settings-form" label-width="120px" label-position="left">
          <el-form-item label="网关">
            <div style="display: flex; align-items: center; gap: 4px;">
              <input v-model="dhcp.gw.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.gw.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.gw.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.gw.section4" type="text" maxlength="3" style="width: 50px;" disabled />
            </div>
          </el-form-item>

          <el-form-item label="掩码">
            <div style="display: flex; align-items: center; gap: 4px;">
              <input v-model="dhcp.mask.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.mask.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.mask.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.mask.section4" type="text" maxlength="3" style="width: 50px;" disabled />
            </div>
          </el-form-item>

          <el-form-item label="起始 IP">
            <div style="display: flex; align-items: center; gap: 4px;">
              <input v-model="dhcp.dhcpStart.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpStart.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpStart.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpStart.section4" type="text" maxlength="3" style="width: 50px;" disabled />
            </div>
          </el-form-item>

          <el-form-item label="结束 IP">
            <div style="display: flex; align-items: center; gap: 4px;">
              <input v-model="dhcp.dhcpEnd.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpEnd.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpEnd.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
              <input v-model="dhcp.dhcpEnd.section4" type="text" maxlength="3" style="width: 50px;" disabled />
            </div>
          </el-form-item>
        </el-form>
      </el-card>

      <!-- 右侧租约信息卡片 -->
      <el-card class="status-card">
        <template #header>
          <div class="card-header">
            <span>租约信息</span>
          </div>
        </template>

        <el-table :data="leaseInfo.details" style="width: 100%" height="300" border>
          <el-table-column prop="ip" label="IP 地址" width="150" />
          <el-table-column prop="mac" label="MAC 地址" width="200" />
          <el-table-column prop="status" label="状态" width="100" />
          <el-table-column prop="leaseTime" label="租约时间" width="150" />
        </el-table>
      </el-card>
    </div>

    <!-- 按钮区域 -->
    <div class="button-section">
      <el-button type="primary" @click="setDHCPSettings" style="width: 120px;">保存设置</el-button>
      <el-button type="warning" @click="resetDhcpConfig" style="margin-left: 10px; width: 120px;">恢复默认</el-button>
      <el-button type="primary" @click="$emit('go-back')" style="margin-left: 10px; width: 120px;">返回</el-button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DhcpConfig',
  data() {
    return {
      dhcp: {
        gw: {
          section1: '',
          section2: '',
          section3: '',
          section4: ''
        },
        mask: {
          section1: '',
          section2: '',
          section3: '',
          section4: ''
        },
        dhcpStart: {
          section1: '',
          section2: '',
          section3: '',
          section4: ''
        },
        dhcpEnd: {
          section1: '',
          section2: '',
          section3: '',
          section4: ''
        }
      },
      leaseInfo: {
        total: 100,
        active: 80,
        expired: 20,
        details: [
          {ip: '192.168.100.1', mac: 'E4:5F:01:53:B2:FF', status: 'Active', leaseTime: '24h'},
          {ip: '192.168.100.2', mac: 'E4:5F:01:53:B2:FF', status: 'Expired', leaseTime: '12h'}
        ]
      },
      refreshTimer: null
    }
  },
  created() {
    this.fetchDHCPSettings()
    // Commenting out fetchLeaseInfo to use simulated data
    // this.fetchLeaseInfo()

    this.refreshTimer = setInterval(() => {
      this.fetchDHCPSettings()
      // Commenting out fetchLeaseInfo to use simulated data
      // this.fetchLeaseInfo()
    }, 5000)
  },
  beforeUnmount() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  },
  methods: {
    fetchDHCPSettings() {
      this.$oui.call('dhcp', 'getDHCPSettings').then((dhcpSettings) => {
        this.dhcp.gw = dhcpSettings.gw
        this.dhcp.mask = dhcpSettings.mask
        this.dhcp.dhcpStart = dhcpSettings.dhcpStart
        this.dhcp.dhcpEnd = dhcpSettings.dhcpEnd
      })
    },
    // fetchLeaseInfo() {
    //   this.$oui.call('dhcp', 'getLeaseInfo').then((leaseInfo) => {
    //     this.leaseInfo.total = leaseInfo.total
    //     this.leaseInfo.active = leaseInfo.active
    //     this.leaseInfo.expired = leaseInfo.expired
    //     this.leaseInfo.details = leaseInfo.details
    //   });
    // },
    setDHCPSettings() {
      this.$oui.call('dhcp', 'setDHCPSettings', this.dhcp).then(response => {
        console.log('response: ', response)
      })
    },
    resetDhcpConfig() {
      this.dhcp.dhcpStart.section4 = '100'
      this.dhcp.dhcpEnd.section4 = '254'
    }
  }
}

</script>

<style scoped>
.dhcp {
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

.status-card {
  width: 600px; /* Adjusted width to accommodate table */
}

.button-section {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}
</style>