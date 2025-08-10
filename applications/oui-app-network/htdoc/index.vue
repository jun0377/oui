<template>
  <div>
    <!-- 主页面 -->
    <div v-if="currentView === 'main'" class="container">
      <!-- 广域网链路 Section -->
      <div class="section">
        <div class="section-header">{{ $t('Wan Area') }}</div>
        <div class="section-content wan-section">
          <!-- 表头行 -->
          <div class="subnet-item">
            <div class="subnet-header-empty"></div>
            <div class="subnet-info-wan">
              <span>{{ $t('SIM') }}</span>
              <span>{{ $t('Interface') }}</span>
              <span>{{ $t('Operator') }}</span>
              <span>{{ $t('Real Network Access') }}</span>
              <span>APN</span>
              <span>{{ $t('Frequency Band') }}</span>
              <span>{{ $t('Rsrp') }}</span>
              <span class="status-column">{{ $t('Status') }}</span>
              <span> </span>
            </div>
          </div>

          <!-- 分割线 -->
          <hr />

          <!-- 数据行 -->
          <div class="subnet-item" v-for="(wan, index) in wanLinks" :key="index" @click="editSubWan(wan)">
            <svg class="subnet-icon-svg" viewBox="0 0 23 23" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- SIM卡外框 -->
              <path d="M6 3C5.44772 3 5 3.44772 5 4V20C5 20.5523 5.44772 21 6 21H18C18.5523 21 19 20.5523 19 20V8L14 3H6Z" fill="#DCFCE7" stroke="#22C55E" stroke-width="1.5"/>
              <!-- SIM卡切角 -->
              <path d="M14 3V7C14 7.55228 14.4477 8 15 8H19" fill="none" stroke="#22C55E" stroke-width="1.5"/>
              <!-- SIM标识 -->
              <text x="10" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#15803D">{{ index + 1 }}</text>
            </svg>
            <div class="subnet-info-wan">
              <span>{{ wan.name }}</span>
              <span>{{ wan.interface }}</span>
              <span>{{ wan.operator }}</span>
              <span>{{ wan.realNetworkAccess }}</span>
              <span>{{ wan.apn }}</span>
              <span>{{ wan.band }}</span>
              <span>{{ wan.signal }}</span>
              <span class="status-column">
                <span :class="['status-text', getStatusClass(wan.status)]">
                  {{ $t(getStatusText(wan.status)) }}
                </span>
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
            <!-- 根据lan口名称显示网口图标或WiFi图标 -->
            <div v-if="lan.name && (lan.name.toLowerCase().includes('wireless'))">
              <svg class="subnet-icon-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <!-- WiFi图标 -->
                <path d="M12 20h.01M8.5 16.5a7 7 0 0 1 7 0M5 13a12 12 0 0 1 14 0M1.5 9.5a18 18 0 0 1 21 0" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                <circle cx="12" cy="20" r="1" fill="#000"/>
              </svg>
            </div>
            <div v-else>
              <!-- 网口图标 -->
              <svg class="subnet-icon-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <!-- 外框 -->
                <rect x="2" y="2" width="20" height="20" rx="4" ry="4" fill="none" stroke="#000" stroke-width="2"/>
                <!-- 网口主体 -->
                <rect x="6" y="8" width="12" height="8" rx="1" ry="1" fill="#000"/>
                <!-- 网口触点 -->
                <rect x="7" y="10" width="1" height="4" fill="#fff"/>
                <rect x="9" y="10" width="1" height="4" fill="#fff"/>
                <rect x="11" y="10" width="1" height="4" fill="#fff"/>
                <rect x="13" y="10" width="1" height="4" fill="#fff"/>
                <rect x="15" y="10" width="1" height="4" fill="#fff"/>
                <rect x="16" y="10" width="1" height="4" fill="#fff"/>
              </svg>
            </div>
            <div class="subnet-info-lan">
              <span></span>
              <span>{{ $t(lan.name) }}</span>
              <span></span>
              <span></span>
              <span></span>
              <span></span>
              <span></span>
              <span></span>
              <span class="subnet-arrow">›</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- WAN配置页面 -->
    <WanConfig v-else-if="currentView === 'wan-config'" :wan-data="selectedWan" @go-back="goBackToMain" />
  </div>
</template>

<script>
import WanConfig from './wan.vue'

export default {
  components: {
    WanConfig
  },
  data() {
    return {
      currentView: 'main', // 'main' 或 'wan-config'
      selectedWan: null,
      wanLinks: [
        {
          name: '5G-1',
          interface: 'usb0',
          operator: '中国移动',
          realNetworkAccess: 'NR',
          apn: '3gnet',
          band: 'n28',
          signal: '-98',
          status: 'connected'
        },
        {
          name: '5G-2',
          interface: 'usb1',
          operator: '中国联通',
          realNetworkAccess: 'NR',
          apn: 'cmnet',
          band: 'n79',
          signal: '-100',
          status: 'dialing'
        },
        {
          name: '5G-3',
          interface: 'usb2',
          operator: '中国电信',
          realNetworkAccess: 'NR',
          apn: 'ctnet',
          band: 'b41',
          signal: '-83',
          status: 'disconnected'
        },
        {
          name: '5G-4',
          interface: 'usb3',
          operator: '中国广电',
          realNetworkAccess: 'NR',
          apn: 'ctnet',
          band: 'b41',
          signal: '-83',
          status: 'nosim'
        }
      ],
      subnets: [
        {
          name: 'Wire Lan'
        },
        {
          name: 'Wireless Lan'
        }
      ]
    }
  },

  methods: {
    getStatusClass(status) {
      switch (status) {
      case 'connected': return 'status-connected'
      case 'disconnected': return 'status-disconnected'
      case 'dialing': return 'status-dialing'
      case 'nosim': return 'status-nosim'
      default: return ''
      }
    },
    getStatusText(status) {
      switch (status) {
      case 'connected': return 'Online'
      case 'disconnected': return 'Offline'
      case 'dialing': return 'Dialing'
      case 'nosim': return 'NoSim'
      default: return '未知'
      }
    },
    getStatusWan() {
      console.log('get wan status')
      this.wanLinks.forEach((wan, index) => {
        this.$oui.call('sim', 'getSimStatus').then(sta => {
          console.log('index + 1')
        })
      })
    },
    editSubWan(wan) {
      // 切换到WAN配置页面
      this.selectedWan = wan
      this.currentView = 'wan-config'
    },
    goBackToMain() {
      // 返回主页面
      this.currentView = 'main'
      this.selectedWan = null
    },
    editSubNet(lan) {
      alert('修改LAN设置: ' + lan.name)
    }
  },
  created() {
    this.$timer.create('wan', this.getStatusWan, { time: 3000, immediate: true, repeat: true})
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

.subnet-icon-svg {
  width: 20px;
  height: 20px;
  margin-right: 12px;
  flex-shrink: 0;
}

.subnet-header-icon {
  width: 12px;
  height: 12px;
  background-color: var(--el-color-primary);
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-header-empty {
  width: 12px;
  height: 12px;
  border-radius: 2px;
  margin-right: 12px;
}

.subnet-info {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.subnet-info-lan {
  flex: 1;
  display: grid;
  grid-template-columns: 0.5fr 2fr 1fr 1fr 1fr 1fr 1fr 1fr 0.5fr;
  gap: 10px;
  align-items: center;
  width: 100%;
}

.subnet-info-wan {
  flex: 1;
  display: grid;
  grid-template-columns: 0.5fr 0.5fr 1fr 1fr 1fr 1fr 1fr 1fr 0.5fr;
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

.status-text {
  font-weight: 500;
  font-size: 14px;
}

.status-text.status-connected {
  color: var(--el-color-success);
  animation: blink 1s infinite linear;
  animation-delay: 0s;
}

.status-text.status-disconnected {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
  animation-delay: 0.25s;
}

.status-text.status-dialing {
  color: var(--el-color-warning);
  animation: blink 1s infinite linear;
  animation-delay: 0.50s;
}

.status-text.status-nosim {
  color: var(--el-color-danger);
  animation: blink 1s infinite linear;
  animation-delay: 0.75s;
}

@keyframes blink {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 1;
  }
  50.1% {
    opacity: 0.3;
  }
  100% {
    opacity: 0.3;
  }
}

</style>

<i18n src="./locale.json"/>
