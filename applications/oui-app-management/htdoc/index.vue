<template>
  <div class="management-page">
    <el-card class="management-card">
      <div class="management-title">{{ $t('管理平台') }}</div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'Management'
}
</script>

<style>
.management-page {
  display: flex;
  justify-content: center;
  padding: 60px 16px;
}

.management-card {
  width: 100%;
  max-width: 640px;
  border: 0;
  border-radius: 12px;
  box-shadow: none;
}

.management-title {
  padding: 48px 0;
  text-align: center;
  font-size: 32px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}
</style>

<i18n src="./locale.json"/>
