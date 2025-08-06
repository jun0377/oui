<template>
  <el-space :size="100">
    <!-- 循环显示CPU各核心使用率 -->
    <dashboard :label="$t('CPU Usage')" :percentage="cpuUsage['cpu']" :color="cpuUsageColor">
      <div v-for="name in Object.keys(cpuUsage).sort()" :key="name">{{ name + ': ' + cpuUsage[name] + '%' }}</div>
    </dashboard>
    <!-- 显示内存项目名称和大小 -->
    <dashboard :label="$t('Memory Usage')" :percentage="memUsage" :color="memUsageColor">
      <div v-for="item in memInfo" :key="item[0]">{{ $t(item[0]) + ': ' + bytesToHuman(item[1])}}</div>
    </dashboard>
    <!-- 显示存储空间使用率 -->
    <dashboard v-if="sysinfo && sysinfo.root" :label="$t('Storage Usage')" :percentage="storageUsage" :color="storageUsageColor">
      <div>{{ $t('Total') + ': ' + bytesToHuman(sysinfo.root.total * 1024) }}</div>
      <div>{{ $t('Used') + ': ' + bytesToHuman(sysinfo.root.used * 1024) }}</div>
    </dashboard>
  </el-space>
  <el-divider/>
  <el-space wrap>
    <!-- 循环显示系统信息项 -->
    <el-descriptions :title="$t('System')" border :column="1">
      <el-descriptions-item v-for="item in renderSysinfo" :key="item[0]" :label="$t(item[0])">{{ item[1] }}</el-descriptions-item>
    </el-descriptions>
    <!-- 显示IPv4网络详细信息 -->
    <el-descriptions v-for="net in wanNetworks" :key="net.interface" :title="'IPv4 ' + $t('Upstream')" border :column="1">
      <el-descriptions-item v-for="item in renderNetworkInfo(net)" :key="item[0]" :label="$t(item[0])">{{ item[1] }}</el-descriptions-item>
    </el-descriptions>
    <!-- 显示IPv6网络详细信息 -->
    <el-descriptions v-for="net in wan6Networks" :key="net.interface" :title="'IPv6 '+ $t('Upstream')" border :column="1">
      <el-descriptions-item v-for="item in renderNetworkInfo(net, true)" :key="item[0]" :label="$t(item[0])">{{ item[1] }}</el-descriptions-item>
    </el-descriptions>
  </el-space>
</template>

<script>
import dashboard from './dashboard.vue'

export default {

  // 数据定义
  data() {
    return {
      cpuTimes: [],
      sysinfo: null,
      boardinfo: null,
      wanNetworks: [],
      wan6Networks: [],
      serial: null,
      version: null,
      serverIP: null
    }
  },

  // 引入dashboard子组件，用于显示仪表盘
  components: {
    dashboard
  },

  // 计算属性
  computed: {

    // CPU各核心使用率
    cpuUsage() {
      if (this.cpuTimes.length < 2)
        return {cpu: 0}

      const values = {}

      Object.keys(this.cpuTimes[0]).forEach(name => {
        values[name] = this.calcCpuUsage(this.cpuTimes[0][name], this.cpuTimes[1][name])
      })

      return values
    },

    // 根据CPU不同的使用率显示不同的颜色
    cpuUsageColor() {
      const val = this.cpuUsage['cpu']

      if (val > 95)
        return 'maroon'

      if (val > 90)
        return 'red'

      return undefined
    },

    // 内存使用率
    memUsage() {
      if (!this.sysinfo)
        return 0
      const memory = this.sysinfo.memory
      return parseFloat(((memory.total - memory.free) * 100 / memory.total).toFixed(2))
    },

    // 不同的内存使用率显示不同的颜色
    memUsageColor() {
      const val = this.memUsage

      if (val > 95)
        return 'maroon'

      if (val > 90)
        return 'red'

      return undefined
    },

    // 格式化内存详细信息（总量、可用、已用、缓存等）
    memInfo() {
      if (!this.sysinfo)
        return []

      const memory = this.sysinfo.memory
      const info = [
        ['Total', memory.total],
        ['Available', memory.available ? memory.available : memory.free + memory.buffered],
        ['Used', memory.total - memory.free]
      ]

      if (memory.buffered)
        info.push(['Buffered', memory.buffered])
      if (memory.cached)
        info.push(['Cached', memory.cached])

      return info
    },

    // 存储空间使用率
    storageUsage() {
      if (!this.sysinfo)
        return 0
      const root = this.sysinfo.root
      return parseFloat((root.used * 100 / root.total).toFixed(2))
    },

    // 存储空间使用率颜色指示
    storageUsageColor() {
      const val = this.storageUsage

      if (val > 95)
        return 'maroon'

      if (val > 90)
        return 'red'

      return undefined
    },

    // 系统信息格式化显示
    renderSysinfo() {
      const sysinfo = this.sysinfo
      const boardinfo = this.boardinfo

      if (!sysinfo || !boardinfo)
        return []

      const load = sysinfo.load
      const info = [
        // ['Hostname', boardinfo.hostname],
        // ['Model', boardinfo.model],
        // ['Architecture', boardinfo.system],
        // ['Target Platform', boardinfo.release ? boardinfo.release.target : ''],
        ['Serial Number', this.serial || 'N/A'],
        ['Version', this.version || 'N/A'],
        ['Server IP', this.server || 'N/A'],
        // ['Firmware Version', boardinfo.release ? boardinfo.release.description : ''],
        ['Kernel Version', boardinfo.kernel],
        ['Uptime', this.secondsToHuman(sysinfo.uptime)],
        ['Load Average', load.map(v => (v / 65535).toFixed(2)).join(', ')]
      ]
      return info
    }
  },
  // 方法定义
  methods: {
    // 将字节转换为可读性更高的格式（KB, MB, GB等）
    bytesToHuman(bytes) {
      if (isNaN(bytes))
        return ''

      if (bytes < 0)
        return ''

      let units = ''

      const k = Math.floor((Math.log2(bytes) / 10))
      if (k > 0)
        units = 'KMGTPEZY'[k - 1] + 'iB'

      return (bytes / Math.pow(1024, k)).toFixed(2) + ' ' + units
    },

    // 将秒数转换为天时分秒格式
    secondsToHuman(second) {
      if (isNaN(second))
        return ''
      const days = Math.floor(second / 86400)
      const hours = Math.floor((second % 86400) / 3600)
      const minutes = Math.floor(((second % 86400) % 3600) / 60)
      const seconds = Math.floor(((second % 86400) % 3600) % 60)
      return `${days}d ${hours}h ${minutes}m ${seconds}s`
    },

    // 计算两个时间点之间的CPU使用率
    calcCpuUsage(times0, times1) {
      const times0CPU = times0[0] + times0[1] + times0[2]
      const times1CPU = times1[0] + times1[1] + times1[2]

      const val = (times1CPU - times0CPU) * 100.0 / ((times1CPU + times1[3]) - (times0CPU + times0[3]))

      return parseFloat(val.toFixed(2))
    },

    // 获取CPU时间
    getCpuTimes() {
      this.$oui.call('system', 'get_cpu_time').then(({ times }) => {
        this.cpuTimes.push(times)
        if (this.cpuTimes.length === 3)
          this.cpuTimes.shift()
      })
    },

    // 获取系统信息
    getSysinfo() {
      this.$oui.ubus('system', 'info').then(r => {
        this.sysinfo = r
      })
    },

    // 获取IPv4网络信息
    getWanNetworks() {
      this.$oui.call('network', 'get_wan_networks').then(({ networks }) => {
        this.wanNetworks = networks
      })
    },

    // 获取IPv6网络信息
    getWan6Networks() {
      this.$oui.call('network', 'get_wan6_networks').then(({ networks }) => {
        this.wan6Networks = networks
      })
    },

    // 格式化网络接口信息
    renderNetworkInfo(net, ipv6) {
      const info = [
        ['Protocol', net.proto]
      ]

      if (ipv6) {
        const prefix = net['ipv6-prefix'][0]
        if (prefix)
          info.push(['Prefix Delegated', prefix.address + '/' + prefix.mask])
        info.push(['Address', net['ipv6-address'].map(a => a.address + '/' + a.mask)[0]])
        info.push(['Gateway', net.route.filter(r => r.target === '::' && r.mask === 0).map(r => r.nexthop)[0]])
      } else {
        info.push(['Address', net['ipv4-address'].map(a => a.address + '/' + a.mask)[0]])
        info.push(['Gateway', net.route.filter(r => r.target === '0.0.0.0' && r.mask === 0).map(r => r.nexthop)[0]])
      }

      info.push(['DNS', net['dns-server'].join(', ')])
      info.push(['Connected', this.secondsToHuman(net.uptime)])

      return info
    }
  },

  // 生命周期钩子,组件创建时执行的初始化操作
  created() {
    // 创建定时器，定期获取数据
    this.$timer.create('getCpuTimes', this.getCpuTimes, {repeat: true, immediate: true, time: 3000})
    this.$timer.create('getSysinfo', this.getSysinfo, {repeat: true, immediate: true, time: 3000})
    this.$timer.create('getWanNetworks', this.getWanNetworks, {repeat: true, immediate: true, time: 5000})
    this.$timer.create('getWan6Networks', this.getWan6Networks, {repeat: true, immediate: true, time: 5000})

    // ubus获取主板信息
    this.$oui.ubus('system', 'board').then(r => {
      this.boardinfo = r
    })

    // 获取序列号
    this.$oui.ubus('file', 'exec', {
      command: 'sh',
      params: ['-c', 'cat /proc/cpuinfo | grep Serial | awk \'{print $3}\'']
    }).then(r => {
      if (r.stdout && r.stdout.trim()) {
        this.serial = r.stdout.trim()
      } else {
        this.serial = 'N/A'
      }
    }).catch(e => {
      console.error('Failed to get serial:', e)
      this.serial = 'N/A'
    })

    // 获取版本号
    this.$oui.ubus('file', 'exec', {
      command: 'sh',
      params: ['-c', 'cat /etc/version']
    }).then(r => {
      if (r.stdout) {
        this.version = r.stdout
      } else {
        this.version = 'N/A'
      }
    }).catch(e => {
      console.error('Failed to get version:', e)
      this.version = 'N/A'
    })

    // 获取服务器IP
    this.$oui.call('uci', 'get', {
      config: 'openmptcprouter',
      section: 'vps',
      option: 'ip'
    }).then(ip => {
      if (ip) {
        // 目前只支持设置一个服务器
        this.server = ip[0]
        console.log('server IP:', ip)
      } else {
        console.log('server IP not found')
        this.server = 'N/A'
      }
    }).catch(e => {
      console.error('Faile to get server IP:', e)
      this.server = 'N/A'
    })

  }
}
</script>

<i18n src="./locale.json"/>
