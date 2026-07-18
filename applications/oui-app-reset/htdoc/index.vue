<template>
  <el-button type="danger" @click="doReset">{{ $t('Perform reset') }}</el-button>
</template>

<script>
export default {
  methods: {
    doReset() {
      this.$confirm(this.$t('ResettConfirm') + '?', this.$t('Reset to defaults'), {
        type: 'warning'
      }).then(() => {
        this.$oui.ubus('system', 'reset').then(() => {
          const loading = this.$loading({
            lock: true,
            text: this.$t('Upgrading') + '...',
            background: 'rgba(0, 0, 0, 0.7)'
          })

          this.$oui.reconnect().then(() => {
            loading.close()
            this.$router.push('/login')
          })
        })
      })
    }
  }
}
</script>

<i18n src="./locale.json"/>
