<template>
  <div class="dhcp-container">
    <div class="dhcp-header">
      <button class="back-btn" @click="$emit('go-back')">返回</button>
      <h2>DHCP服务</h2>
    </div>
    <div class="dhcp-settings">
      <form @submit.prevent="saveDhcpConfig">
        <div class="form-group">
          <label for="startIp">地址池起始IP:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.startIp1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.startIp2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.startIp3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input id="startIp4" v-model="dhcp.startIp4" type="text" maxlength="3" style="width: 50px;" required />
          </div>
        </div>
        <div class="form-group">
          <label for="endIp">地址池结束IP:</label>
          <div style="display: flex; align-items: center; gap: 4px;">
            <input v-model="dhcp.endIp1" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.endIp2" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input v-model="dhcp.endIp3" type="text" maxlength="3" style="width: 50px;" disabled />.
            <input id="endIp4" v-model="dhcp.endIp4" type="text" maxlength="3" style="width: 50px;" required />
          </div>
        </div>
        <button class="save-btn" type="submit">保存设置</button>
        <button class="reset-btn" type="button" @click="resetDhcpConfig">恢复默认</button>
      </form>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DhcpConfig',
  data() {
    return {
      dhcp: {
        startIp1: '192',
        startIp2: '168',
        startIp3: '1',
        startIp4: '',
        endIp1: '192',
        endIp2: '168',
        endIp3: '1',
        endIp4: ''
      }
    }
  },
  methods: {
    saveDhcpConfig() {
      const startIp = `${this.dhcp.startIp1}.${this.dhcp.startIp2}.${this.dhcp.startIp3}.${this.dhcp.startIp4}`;
      const endIp = `${this.dhcp.endIp1}.${this.dhcp.endIp2}.${this.dhcp.endIp3}.${this.dhcp.endIp4}`;
      alert(`保存DHCP设置: \n地址池: ${startIp} - ${endIp}`)
    },
    resetDhcpConfig() {
      this.dhcp.startIp4 = '100';
      this.dhcp.endIp4 = '254';
    }
  }
}
</script>


<style scoped>
.dhcp-container {
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