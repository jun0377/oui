<template>

<div class ="server">

  <!-- 工作模式: 单卡模式 / 负载均衡 / 聚合 -->
  <div class="mode">
    <h2> {{ $t('Mode') }} </h2>
    <el-radio-group v-model="workMode" class="mode-group" :disabled="!workModeReady" @change="handleWorkModeChange">
      <el-radio-button value="single">{{ $t('单卡模式') }}</el-radio-button>
      <el-radio-button value="aggregate">{{ $t('聚合模式') }}</el-radio-button>
      <el-radio-button value="balance">{{ $t('负载均衡') }}</el-radio-button>
    </el-radio-group>
  </div>

  <!-- 单卡模式 -->
  <ModeSingle v-if="workModeReady && workMode === 'single'" :page-active="pageActive" />

  <ModeBalance v-if="workModeReady && workMode === 'balance'" />

  <ModeAggregate v-if="workModeReady && workMode === 'aggregate'" :page-active="pageActive" />
</div>

</template>


<script>
import ModeAggregate from './ModeAggregate.vue'
import ModeBalance from './ModeBalance.vue'
import ModeSingle from './ModeSingle.vue'

export default {
  name: 'ServerConfig',
  components: {
    ModeAggregate,
    ModeBalance,
    ModeSingle
  },
  data() {
    return {
      workMode: '',
      workModeReady: false,
      pageActive: false,
      stopped: true
    }
  },
  created() {
  },
  mounted() {
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  activated() {
    if (!this.stopped)
      return
    this.runAfterFirstFrame(() => {
      this.startAll()
    })
  },
  deactivated() {
    this.stopAll()
  },
  beforeUnmount() {
    this.stopAll()
  },
  beforeRouteLeave(to, from, next) {
    this.stopAll()
    next()
  },
  methods: {
    runAfterFirstFrame(fn) {
      if (typeof requestAnimationFrame === 'function') {
        requestAnimationFrame(() => requestAnimationFrame(() => fn()))
      } else {
        setTimeout(() => fn(), 0)
      }
    },
    startAll() {
      this.stopped = false
      this.workModeReady = false
      this.workMode = ''
      this.pageActive = true
      this.fetchWorkMode().finally(() => {
        if (this.stopped)
          return
        this.workModeReady = true
      })
    },
    stopAll() {
      this.stopped = true
      this.pageActive = false
    },
    // 把后端返回的工作模组字段归一化处理
    normalizeWorkMode(rawMode) {
      const mode = String(rawMode || '').trim().toLowerCase()
      if (mode === 'single' || mode === 'aggregate' || mode === 'balance')
        return mode
      if (mode.includes('agg'))
        return 'aggregate'
      if (mode.includes('bal') || mode.includes('load'))
        return 'balance'
      return 'single'
    },
    // 获取工作模式
    fetchWorkMode() {
      return this.$oui.call('mode', 'getMode').then((mode) => {
        if (this.stopped)
          return
        const normalized = this.normalizeWorkMode(mode)
        this.workMode = normalized
      })
    },
    // 设置工作模式
    handleWorkModeChange() {
      return
    }
  }
}

</script>

<style>

.server {
  width: 100%;
  box-sizing: border-box;
  padding: 20px;
}

.header {
  margin-bottom: 20px;
}

.mode {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 20px;
}

.mode-group {
  flex-wrap: wrap;
}

.mode-inline {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  flex-wrap: wrap;
}

.mode-inline-label {
  min-width: 72px;
  padding-top: 6px;
  font-size: 14px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  white-space: nowrap;
}

.mode-actions {
  display: flex;
  justify-content: flex-start;
  margin-top: 12px;
}

.mode-actions-row .mode-inline-label {
  padding-top: 0;
}

.server-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 30px;
}

.aggregate-section {
  margin-bottom: 0;
}

.aggregate-split {
  grid-template-columns: minmax(0, 1fr) 1px minmax(0, 1fr);
  align-items: stretch;
}

.aggregate-v-divider {
  background: var(--el-border-color-lighter);
  border-radius: 1px;
}

.mode-card {
  grid-column: 1 / -1;
}

.mode-panel {
  border-radius: 12px;
}

.mode-panel-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.mode-panel-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.mode-panel-body {
  padding: 6px 4px;
}

.single-route-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--el-border-color-lighter);
}

.single-route-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 18px;
}

.single-route-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.single-route-subtitle {
  margin-top: 4px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

.single-route-topology {
  position: relative;
  display: grid;
  grid-template-columns: minmax(240px, 300px) minmax(360px, 1fr);
  gap: 36px;
  align-items: center;
}

.route-device-card {
  position: relative;
  min-width: 0;
  align-self: center;
}

.route-device-panel {
  background: linear-gradient(180deg, #ffffff 0%, #f7fbff 100%);
}

.route-device-grid {
  grid-template-columns: 1fr;
}

.route-links-stage {
  display: grid;
  grid-template-columns: minmax(360px, 1fr) 120px;
  gap: 28px;
  align-items: center;
  min-height: 560px;
}

.route-links-list {
  position: relative;
  display: grid;
  gap: 16px;
  padding-left: 0;
}

.route-links-list::before {
  display: none;
}

.route-links-active-path {
  display: none;
}

.route-links-active-path.is-sim1 {
  top: 22px;
  height: 42px;
}

.route-links-active-path.is-sim2 {
  top: 22px;
  height: 146px;
}

.route-links-active-path.is-sim3 {
  top: 22px;
  height: 250px;
}

.route-links-active-path.is-wan1 {
  top: 22px;
  height: 354px;
}

.route-links-active-path.is-wan2 {
  top: 22px;
  height: 458px;
}

.route-link-item {
  position: relative;
  width: 50%;
  max-width: 100%;
  justify-self: start;
  z-index: 2;
}

.route-link-item::before {
  display: none;
}

.route-link-item.is-active::before {
  display: none;
}

.route-link-item.is-active::after {
  display: none;
}

.route-lan-flow {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  --route-lan-flow-target-y: 78px;
  --route-lan-flow-vertical-top: 78px;
  --route-lan-flow-vertical-height: 202px;
}

.route-lan-flow-segment {
  position: absolute;
  background:
    repeating-linear-gradient(
      90deg,
      #2563eb 0 10px,
      transparent 10px 16px
    );
  background-size: 24px 3px;
  animation: route-packet-flow 1.1s linear infinite;
}

.route-lan-flow-segment-start {
  left: 300px;
  top: 280px;
  width: 44px;
  height: 3px;
}

.route-lan-flow-segment-vertical {
  left: 344px;
  top: var(--route-lan-flow-vertical-top);
  width: 3px;
  height: var(--route-lan-flow-vertical-height);
  background:
    repeating-linear-gradient(
      180deg,
      #2563eb 0 10px,
      transparent 10px 16px
    );
  background-size: 3px 24px;
}

.route-lan-flow-segment-end {
  left: 344px;
  top: var(--route-lan-flow-target-y);
  width: 154px;
  height: 3px;
}

.route-lan-flow-arrow {
  position: absolute;
  left: 490px;
  top: calc(var(--route-lan-flow-target-y) - 6px);
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-left: 10px solid #60a5fa;
}

.route-lan-flow.is-sim1 {
  --route-lan-flow-target-y: 78px;
  --route-lan-flow-vertical-top: 78px;
  --route-lan-flow-vertical-height: 202px;
}

.route-lan-flow.is-sim2 {
  --route-lan-flow-target-y: 182px;
  --route-lan-flow-vertical-top: 182px;
  --route-lan-flow-vertical-height: 98px;
}

.route-lan-flow.is-sim3 {
  --route-lan-flow-target-y: 286px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 6px;
}

.route-lan-flow.is-wan1 {
  --route-lan-flow-target-y: 390px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 110px;
}

.route-lan-flow.is-wan2 {
  --route-lan-flow-target-y: 494px;
  --route-lan-flow-vertical-top: 280px;
  --route-lan-flow-vertical-height: 214px;
}

.route-link-card {
  position: relative;
  padding: 18px 18px 16px;
  border: 1px solid var(--el-border-color);
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.06);
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.route-link-item.is-active .route-link-card {
  border-color: #2563eb;
  box-shadow: 0 14px 32px rgba(37, 99, 235, 0.16);
  transform: translateY(-1px);
}

.route-link-item.is-active .route-link-card::after {
  display: none;
}

.route-link-item.is-active .route-link-card::before {
  display: none;
}

.route-link-item.is-online .route-link-card {
  background: linear-gradient(180deg, #ffffff 0%, #f8fffb 100%);
}

.route-link-item.is-offline .route-link-card {
  background: linear-gradient(180deg, #ffffff 0%, #fff8f8 100%);
}

.route-link-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.route-link-name {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  text-transform: lowercase;
}

.route-link-role {
  margin-top: 4px;
  font-size: 13px;
  color: #f97316;
  font-weight: 600;
}

.route-link-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin-top: 16px;
}

.route-link-field {
  padding: 10px 12px;
  border-radius: 12px;
  background: #f8fafc;
}

.route-link-field-full {
  grid-column: 1 / -1;
}

.route-link-label {
  display: block;
  margin-bottom: 4px;
  font-size: 12px;
  color: #6b7280;
}

.route-link-value {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  line-height: 1.4;
  word-break: break-all;
}

.route-link-footer {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-top: 14px;
  font-size: 12px;
  color: #6b7280;
}

.route-cloud-card {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 560px;
}

.route-cloud-shape {
  position: relative;
  width: 92px;
  height: 48px;
  border-radius: 30px;
  background: #76a9d2;
  box-shadow: inset 0 -4px 0 rgba(0, 0, 0, 0.06);
}

.route-cloud-shape::before,
.route-cloud-shape::after {
  content: '';
  position: absolute;
  background: #76a9d2;
  border-radius: 50%;
}

.route-cloud-shape::before {
  width: 38px;
  height: 38px;
  left: 12px;
  top: -18px;
}

.route-cloud-shape::after {
  width: 46px;
  height: 46px;
  right: 10px;
  top: -24px;
}

.route-cloud-text {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
  color: #fff;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.config-form {
  padding: 10px;
}

.server-ip-input {
  width: 33.3333%;
}

.status-info {
  padding: 10px;
}

/* 添加过渡效果，使状态变化更平滑 */
.el-tag {
  transition: background-color 0.3s ease, color 0.3s ease;
  font-weight: 600; /* 加深字体 */
  color: rgba(0, 0, 0, 0.85); /* 加深字体加深各种颜色的背景色 */
}

/* 加深各种状态的背景色 */
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

/* 输入框文字左对齐 */
.el-input-number /deep/ .el-input__inner {
  text-align: left !important;
}

.el-input-number ::v-deep .el-input__inner {
  text-align: left !important;
}

.config-form .el-input-number input {
  text-align: left !important;
}

/* 闪烁背景样式 */
.blink-bg {
  animation: blink-animation 1s infinite;
}

@keyframes blink-animation {
  0% { opacity: 1; }
  50% { opacity: 0.9; }
  100% { opacity: 1; }
}

@keyframes route-packet-flow {
  0% { background-position: 0 0; }
  100% { background-position: 24px 0; }
}

@media (max-width: 768px) {
  .server-section {
    grid-template-columns: 1fr;
  }

  .aggregate-v-divider {
    display: none;
  }

  .server-ip-input {
    width: 100%;
  }

  .single-route-header,
  .route-link-footer {
    flex-direction: column;
  }

  .single-route-topology {
    grid-template-columns: 1fr;
    gap: 18px;
  }

  .route-links-stage {
    grid-template-columns: 1fr;
    gap: 18px;
    min-height: auto;
  }

  .route-links-list {
    padding-left: 0;
  }

  .route-links-active-path {
    display: none;
  }

  .route-link-item::before {
    display: none;
  }

  .route-link-item {
    width: 100%;
  }

  .route-link-item.is-active::before {
    display: none;
  }

  .route-link-item.is-active::after {
    display: none;
  }

  .route-lan-flow {
    display: none;
  }

  .route-link-item.is-active .route-link-card::after,
  .route-link-item.is-active .route-link-card::before {
    display: none;
  }

  .route-cloud-card {
    min-height: auto;
    padding-top: 8px;
  }

  .route-link-grid {
    grid-template-columns: 1fr;
  }
}

</style>

<i18n src="./locale.json"/>
