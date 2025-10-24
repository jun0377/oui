<template>

  <div class="dhcp-settings-container">
    <div class="dhcp-header">
      <button class="back-btn" @click="$emit('go-back')">返回</button>
      <h2>DHCP服务</h2>
    </div>
    <div class="dhcp-settings">
      <form @submit.prevent="setDHCPSettings">
        <div class="form-group">
          <label for="startIp">网 关:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.gw.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.gw.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.gw.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.gw.section4" type="text" maxlength="3" style="width: 50px;" disabled />
          </div>
        </div>
        <div class="form-group">
          <label for="startIp">掩 码:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.mask.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.mask.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.mask.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.mask.section4" type="text" maxlength="3" style="width: 50px;" disabled />
          </div>
        </div>
        <div class="form-group">
          <label for="startIp">起 始 IP:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.dhcpStart.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpStart.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpStart.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpStart.section4" type="text" maxlength="3" style="width: 50px;" disabled />
          </div>
        </div>
        <div class="form-group">
          <label for="endIp">结 束 IP:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.dhcpEnd.section1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpEnd.section2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpEnd.section3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.dhcpEnd.section4" type="text" maxlength="3" style="width: 50px;" disabled />
          </div>
        </div>
        <button class="save-btn" type="submit">保存设置</button>
        <button class="reset-btn" type="button" @click="resetDhcpConfig">恢复默认</button>
      </form>
    </div>
  </div>

  <div class="dhcp-status-container">
    <div class="header">
      <h2>DHCP租约</h2>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DhcpConfig',
  data() {
    return {
      dhcp: {
        gw : {
          section1: '',
          section2: '',
          section3: '',
          section4: '',
        },
        mask : {
          section1: '',
          section2: '',
          section3: '',
          section4: '',
        },
        dhcpStart : {
          section1: '',
          section2: '',
          section3: '',
          section4: '',
        },
        dhcpEnd : {
          section1: '',
          section2: '',
          section3: '',
          section4: '',
        }
      },
      refreshTimer: null
    }
  },
  created() {

    this.fetchDHCPSettings()

    this.refreshTimer = setInterval(() => {
      this.fetchDHCPSettings()
    }, 5000)
  },
  beforeUnmount() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  },
  methods: {
    resetDhcpConfig() {
      this.dhcp.startIp4 = '100'
      this.dhcp.endIp4 = '254'
    },
    fetchDHCPSettings() {
      this.$oui.call('dhcp', 'getDHCPSettings').then(dhcpSettings => {
        console.log(dhcpSettings)
        this.dhcp.gw.section1 = dhcpSettings.gw.section1
        this.dhcp.gw.section2 = dhcpSettings.gw.section2
        this.dhcp.gw.section3 = dhcpSettings.gw.section3
        this.dhcp.gw.section4 = dhcpSettings.gw.section4

        this.dhcp.mask.section1 = dhcpSettings.mask.section1
        this.dhcp.mask.section2 = dhcpSettings.mask.section2
        this.dhcp.mask.section3 = dhcpSettings.mask.section3
        this.dhcp.mask.section4 = dhcpSettings.mask.section4

        this.dhcp.dhcpStart.section1 = dhcpSettings.gw.section1
        this.dhcp.dhcpStart.section2 = dhcpSettings.gw.section2
        this.dhcp.dhcpStart.section3 = dhcpSettings.gw.section3
        this.dhcp.dhcpStart.section4 = dhcpSettings.dhcpStart

        this.dhcp.dhcpEnd.section1 = dhcpSettings.gw.section1
        this.dhcp.dhcpEnd.section2 = dhcpSettings.gw.section2
        this.dhcp.dhcpEnd.section3 = dhcpSettings.gw.section3
        this.dhcp.dhcpEnd.section4 = dhcpSettings.dhcpEnd
      })
    },
    setDHCPSettings() {
      console.log('setDHCPSettings...')
      this.$oui.call('dhcp', 'setDHCPSettings', this.dhcp)
    }
  }
}
</script>


<style scoped>
.dhcp-settings-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 30px;
  background: var(--el-bg-color);
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
.dhcp-header {
  display: flex;
  align-items: center;
  margin-bottom: 24px;
}
.back-btn {
  margin-right: 20px;
  padding: 6px 16px;
  background: var(--el-color-primary);
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.back-btn:hover {
  background: var(--el-color-primary-light-3);
}
.dhcp-settings {
  font-size: 16px;
  color: var(--el-text-color-primary);
}
.form-group {
  margin-bottom: 18px;
  display: flex;
  align-items: center;
}
.form-group label {
  width: 120px;
  font-weight: 500;
}
.form-group input {
  flex: 1;
  padding: 6px 12px;
  border: 1px solid var(--el-border-color);
  border-radius: 4px;
  font-size: 15px;
}
.save-btn {
  background: var(--el-color-primary);
  color: #fff;
  border: none;
  padding: 8px 24px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 15px;
}
.save-btn:hover {
  background: var(--el-color-primary-light-3);
}
.reset-btn {
  background: var(--el-color-warning);
  color: #fff;
  border: none;
  padding: 8px 24px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 15px;
  margin-left: 16px;
}
.reset-btn:hover {
  background: var(--el-color-warning-light-3);
}
</style>