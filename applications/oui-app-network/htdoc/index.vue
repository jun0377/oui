<template>
  <div class="container">
    <!-- 广域网链路 Section -->
    <div class="section">
      <div class="section-header">{{ $t('Wan Area') }}</div>
      <div class="section-content wan-section">
        <!-- 表头行 -->
        <div class="subnet-item">
          <div class="subnet-header-icon"></div>
          <div class="subnet-info-wan">
            <span>{{ $t('Label') }}</span>
            <span>{{ $t('Interface') }}</span>
            <span>{{ $t('Operator') }}</span>
            <span>{{ $t('Network Access') }}</span>
            <span>APN</span>
            <span>{{ $t('Frequency Band') }}</span>
            <span>{{ $t('Rsrp') }}</span>
            <span class="status-column">{{ $t('Status') }}</span>
            <span> </span>
          </div>
        </div>

        <!-- 数据行 -->
        <div class="subnet-item" v-for="(wan, index) in wanLinks" :key="index" @click="editSubWan(wan)">
          <div class="subnet-icon"></div>
          <div class="subnet-info-wan">
            <span>{{ wan.name }}</span>
            <span>{{ wan.interface }}</span>
            <span>{{ wan.operator }}</span>
            <span>{{ wan.accessType }}</span>
            <span>{{ wan.apn }}</span>
            <span>{{ wan.band }}</span>
            <span>{{ wan.signal }}</span>
            <span class="status-column">
              <span :class="['status-indicator', getStatusClass(wan.status)]"></span>
            </span>
            <span class="subnet-arrow">›</span>
          </div>  
        </div>

      </div>
    </div>

    <!-- 局域网链路 Section -->
    <div class="section">
      <div class="section-header">{{ $t('Lan Area') }}</div>
      <div class="section-content subnet-section">
        <div class="subnet-item" v-for="(lan, index) in subnets" :key="index" @click="editSubNet(lan)">
          <div class="subnet-icon"></div>
          <div class="subnet-info-wan">
            <span>{{ lan.name }}</span>
            <span class="subnet-arrow">›</span>
          </div>
        </div>
      </div>
    </div>


  </div>
  


</template>

<script>

export default {
  data(){
    return {
      wanLinks: [
        {
          name: '5G-1',
          interface: 'usb0',
          operator: '中国移动',
          accessType: 'NR',
          apn: '3gnet',
          band: 'n28',
          signal: '-98',
          status: 'connected'
        },
        {
          name: '5G-2',
          interface: 'usb1',
          operator: '中国联通',
          accessType: 'NR',
          apn: 'cmnet',
          band: 'n79',
          signal: '-100',
          status: 'dialing'
        },
        {
          name: '5G-3',
          interface: 'usb2',
          operator: '中国电信',
          accessType: 'NR',
          apn: 'ctnet',
          band: 'b41',
          signal: '-83',
          status: 'disconnected'
        },
      ],
      subnets: [
        {
          name: '有线网络'
        },
        {
          name: '无线网络'
        },
      ]
    };
  },

  methods: {
    getStatusClass(status) {
      switch(status){
        case 'connected': return 'status-connected';
        case 'disconnected': return 'status-disconnected';
        case 'dialing': return 'status-dialing';
        default: return '';
      }
    },
    editSubWan(wan) {
      alert('修改WAN设置: ' + wan.name);
    },
    editSubNet(lan) {
      alert('修改LAN设置: ' + lan.name);
    }
  }
}
</script>

<style>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.section {
  border-radius: 8px;
  margin-bottom: 20px;
  overflow: hidden;
  border: 1px var(--el-border-color) var(--el-border-style);
}

.section-header {
  padding: 15px 20px;
  border-bottom: 1px solid var(--el-border-color);
  font-size: 16px;
  font-weight: 500;
  color: var(--el-text-color-primary);
  background-color: var(--el-fill-color-light);
}

.section-content {
  padding: 20px;
  background-color: var(--el-bg-color);
}

.wan-section {
  min-height: 80px;
}

.subnet-section {
  min-height: 120px;
}

.subnet-item {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  border-radius: 6px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: background-color 0.2s;
  color: var(--el-text-color-primary);
}

.subnet-item:hover {
  background-color: var(--el-fill-color-light);
}

.subnet-icon {
  width: 12px;
  height: 12px;
  background-color: var(--el-color-success);
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-header-icon {
  width: 12px;
  height: 12px;
  background-color: var(--el-color-primary);
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-info {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.subnet-info-wan {
  flex: 1;
  display: grid;
  grid-template-columns: 0.3fr 0.5fr 1fr 1fr 1fr 1fr 1fr 1fr 0.5fr;
  gap: 10px;
  align-items: center;
  width: 100%;
}

.subnet-info-wan span {
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-column {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.subnet-ip {
  font-family: 'Courier New', monospace;
  font-size: 14px;
}

.subnet-arrow {
  color: var(--el-text-color-secondary);
  font-size: 18px;
}

.empty-state {
  text-align: center;
  color: var(--el-text-color-secondary);
  padding: 40px 20px;
  font-size: 14px;
}

.add-button {
  background-color: var(--el-color-primary);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.2s;
}

.add-button:hover {
  background-color: var(--el-color-primary-light-3);
}

.status-indicator {
  display: inline-block;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  margin-right: 8px;
}

.status-connected {
  background-color: var(--el-color-success);
}

.status-disconnected {
  background-color: var(--el-color-danger);
}

.status-dialing {
  background-color: var(--el-color-warning);
}
</style>

<i18n src="./locale.json"/>
