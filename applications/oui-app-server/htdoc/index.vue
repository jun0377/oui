<template>
  <el-form ref="form" size="large" label-width="auto" label-suffix=":" :model="formValue" :rules="rules">
    <el-form-item :label="$t('Server IP')" prop="serverIP">
      <el-input v-model="formValue.serverIP"/>
    </el-form-item>
    <el-form-item :label="$t('Server Port')" prop="serverPort">
      <el-input v-model="formValue.serverPort"/>
    </el-form-item>
  </el-form>
  <div style="text-align: right; padding-right: 100px">
    <el-button type="primary" :loading="loading" @click="handleSubmit">{{ $t('Save & Apply') }}</el-button>
  </div>
</template>

<script>

export default {
  data() {
    return {
      loading: false,
      formValue: {
        serverIP: '',
        serverPort: ''
      },
      rules: {
        serverIP: {
          required: true,
          trigger: 'blur',
          validator: (_, value, callback) => {
            if (!value)
              return callback(new Error(this.$t('This field is required')))

            // IP地址验证正则表达式
            const ipRegex = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
            if (ipRegex.test(value))
              return callback()
            return callback(new Error(this.$t('Invalid IP address')))
          }
        },
        serverPort: {
          required: true,
          trigger: 'blur',
          validator: (_, value, callback) => {
            if (!value)
              return callback(new Error(this.$t('This field is required')))

            const port = parseInt(value)
            if (port >= 1 && port <= 65535)
              return callback()
            return callback(new Error(this.$t('Port must be between 1 and 65535')))
          }
        }
      }
    }
  },
  created() {
    // uci get openmptcprouter.vps.ip
    this.$oui.call('uci', 'get', {
      config: 'openmptcprouter',
      section: 'vps',
      option: 'ip'
    }).then(ip => {
      if (ip) {
        // 目前只支持设置一个服务器
        this.formValue.serverIP = ip[0]
        console.log('server IP:', this.formValue.serverIP)
      } else {
        console.log('server IP not found')
        this.formValue.serverIP = 'N/A'
      }
    }).catch(e => {
      console.error('Faile to get server IP:', e)
      this.formValue.serverIP = 'N/A'
    })


    // uci get openmptcprouter.vps.port
    this.$oui.call('uci', 'get', {
      config: 'openmptcprouter',
      section: 'vps',
      option: 'port'
    }).then(port => {
      if (port) {
        // 目前只支持设置一个服务器
        this.formValue.serverPort = port
        console.log('server Port:', this.formValue.serverPort)
      } else {
        console.log('server IP not found')
        this.formValue.serverPort = 'N/A'
      }
    }).catch(e => {
      console.error('Faile to get server Port:', e)
      this.formValue.serverPort = 'N/A'
    })

  },
  methods: {
    handleSubmit() {
      this.$refs.form.validate(async valid => {
        if (!valid)
          return

        this.loading = true

        try {

          // uci del_list openmptcprouter.vps.ip
          this.$oui.ubus('file', 'exec', {
            command: 'sh',
            params: ['-c', 'uci del openmptcprouter.vps.ip']
          })

          // uci add_list openmptcprouter.vps.ip=192.168.10.116
          this.$oui.ubus('file', 'exec', {
            command: 'sh',
            params: ['-c', 'uci add_list openmptcprouter.vps.ip=' + this.formValue.serverIP]
          })

          // uci set openmptcprouter.vps.port=65500
          await this.$oui.call('uci', 'set', {
            config: 'openmptcprouter',
            section: 'vps',
            values: {
              port: this.formValue.serverPort
            }
          })

          await this.$oui.reloadConfig('openmptcprouter')

          this.$message.success(this.$t('Configuration has been applied'))
        } catch (error) {
          this.$message.error(this.$t('Failed to save configuration: ', error))
        } finally {
          this.loading = false
        }
      })
    }
  }
}
</script>

<i18n src="./locale.json"/>
