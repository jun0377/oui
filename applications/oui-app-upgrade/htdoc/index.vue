<template>
  <div class="upgrade-page">
    <el-card class="mode-card mode-panel">
      <div class="mode-panel-body">
        <div class="upgrade-grid">
          <div class="upgrade-version-card home-metric-card home-metric-card-primary is-accent-blue">
            <div class="home-metric-head">
              <div class="home-metric-title">{{ $t('Current version') }}</div>
            </div>
            <div v-if="versionInfo" class="home-metric-subtitle">
              <div class="upgrade-version-item">
                <span class="upgrade-version-label">当前版本:</span>
                <span class="upgrade-version-value">{{ versionInfo.version || '-' }}</span>
              </div>
              <div class="upgrade-version-item">
                <span class="upgrade-version-label">构建时间:</span>
                <span>{{ versionInfo.build_timestamp || '-' }}</span>
              </div>
              <div class="upgrade-version-item">
                <span class="upgrade-version-label">Commit ID:</span>
                <span class="upgrade-version-commit">{{ versionInfo.commit || '-' }}</span>
              </div>
            </div>
            <div v-else class="home-metric-subtitle">
              <span class="upgrade-version-loading">{{ $t('Loading') }}...</span>
            </div>
          </div>

          <div class="upgrade-upload-card home-metric-card home-metric-card-primary is-accent-violet">
            <div class="home-metric-head">
              <div class="home-metric-title">上传升级包</div>
            </div>
            <div class="upgrade-upload-body">
              <el-upload
                v-loading="loading"
                drag
                action="/oui-upload"
                :data="{sid: $oui.state.sid, path: '/tmp/firmware.bin'}"
                :show-file-list="false"
                :on-success="onUploadSuccess"
                :before-upload="() => loading = true"
              >
                <el-icon size="30"><upload-filled/></el-icon>
                <div class="upgrade-upload-text">{{ $t('Click or drag files to this area to upload') }}</div>
              </el-upload>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <el-dialog v-model="modalConfirm" :title="$t('Upgrade')">
      <el-space direction="vertical" fill>
        <p>{{ $t('flash-confirm', { btn: this.$t('OK') }) }}</p>
        <el-text type="info">{{ this.$t('Size') + ': ' + bytesToHuman(this.size) }}</el-text>
        <el-text type="info">{{ 'MD5: ' + this.md5 }}</el-text>
        <el-checkbox v-model="keepConfig" :label="$t('Keep settings and retain the current configuration')"/>
      </el-space>
      <template #footer>
        <el-button @click="modalConfirm = false">{{  $t('Cancel') }}</el-button>
        <el-button type="primary" @click="doUpgrade">{{ $t('OK') }}</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
export default {
  data() {
    return {
      loading: false,
      modalConfirm: false,
      size: 0,
      md5: '',
      keepConfig: true,
      versionInfo: null
    }
  },
  created() {
    this.fetchVersion()
  },
  methods: {
    fetchVersion() {
      this.$oui.call('version', 'get_version').then(r => {
        this.versionInfo = r
        console.log('versionInfo:', r)
      }).catch(() => {
        this.versionInfo = null
      })
    },
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
    onUploadSuccess(res) {
      this.loading = false

      this.$oui.ubus('system', 'validate_firmware_image', { path: '/tmp/firmware.bin' }).then(({ valid }) => {
        if (!valid) {
          this.$message.error(this.$t('Firmware verification failed. Please upload the firmware again'))
        } else {
          this.size = res.size
          this.md5 = res.md5
          this.modalConfirm = true
          this.keepConfig = true
        }
      })
    },
    doUpgrade() {
      this.modalConfirm = false

      this.$oui.call('system', 'sysupgrade', { keep: this.keepConfig }).then(() => {
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
    }
  }
}
</script>

<i18n src="./locale.json"/>

<style scoped>
/* ---- 与首页一致的基础布局 ---- */
.upgrade-page {
  width: 100%;
}

.mode-card {
  width: 100%;
}

.mode-panel {
  border-radius: 12px;
  border: 0;
  box-shadow: none;
}

.mode-panel-body {
  padding: 6px 4px;
}

/* ---- 网格布局 ---- */
.upgrade-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

/* ---- 卡片基础样式（与首页 home-metric-card 一致） ---- */
.home-metric-card {
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  padding: 18px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
}

.home-metric-card::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 4px;
  border-radius: 16px 0 0 16px;
  background: #cbd5e1;
}

.home-metric-card-primary {
  min-height: 168px;
}

.home-metric-card.is-accent-blue::before {
  background: #3b82f6;
}

.home-metric-card.is-accent-violet::before {
  background: #8b5cf6;
}

/* ---- 卡片头部 ---- */
.home-metric-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.home-metric-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.home-metric-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

/* ---- 版本信息 ---- */
.upgrade-version-card .home-metric-subtitle {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.upgrade-version-item {
  display: flex;
  gap: 8px;
  line-height: 22px;
}

.upgrade-version-label {
  color: var(--el-text-color-placeholder);
  min-width: 60px;
}

.upgrade-version-value {
  font-weight: 600;
}

.upgrade-version-commit {
  font-family: monospace;
  color: #3b82f6;
}

.upgrade-version-loading {
  color: var(--el-text-color-placeholder);
}

/* ---- 上传区域 ---- */
.upgrade-upload-body {
  margin-top: 12px;
  flex: 1;
  display: flex;
  align-items: center;
}

.upgrade-upload-body :deep(.el-upload) {
  width: 100%;
}

.upgrade-upload-body :deep(.el-upload-dragger) {
  width: 100%;
  padding: 24px 20px;
  border-radius: 12px;
}

.upgrade-upload-text {
  margin-top: 8px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

</style>
