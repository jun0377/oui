<template>
  <div class="server-section">
    <el-card class="mode-card mode-panel">
      <template #header>
        <div class="card-header">
          <div>
            <div class="mode-panel-title">负载均衡</div>
            <div class="mode-panel-subtitle">在多条链路之间按策略分摊业务流量,不需要服务器</div>
          </div>
        </div>
      </template>
      <div class="mode-panel-body">
        <el-descriptions :column="1" border>
          <el-descriptions-item :label="$t('工作模式')">{{ $t('负载均衡') }}</el-descriptions-item>
          <el-descriptions-item :label="$t('说明')">{{ $t('当前会在多条链路之间分摊流量') }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'ModeBalance'
}
</script>
