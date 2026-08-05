<template>
  <div class="login-page">
    <div class="bg-grid"></div>
    <div class="bg-scan"></div>
    <div class="geo-shape geo-circle-1"></div>
    <div class="geo-shape geo-circle-2"></div>
    <div class="geo-shape geo-circle-3"></div>
    <div class="geo-shape geo-square-1"></div>
    <div class="geo-shape geo-square-2"></div>
    <div class="geo-shape geo-diamond-1"></div>
    <div class="geo-shape geo-triangle-1"></div>
    <div class="geo-shape geo-cross-1"></div>
    <div class="geo-shape geo-dot-1"></div>
    <div class="geo-shape geo-dot-2"></div>
    <div class="geo-shape geo-dot-3"></div>
    <el-card class="mode-card mode-panel mode-panel-login login-card">
      <template #header>
        <div class="login-head">
          <div class="login-title">{{ $t('Login') }}</div>
        </div>
      </template>

      <div class="login-panel-body">
        <el-form ref="form" :model="formValue" :rules="rules" label-position="top" size="large" class="login-form">
          <el-form-item :label="$t('Username')" prop="username">
            <el-input v-model="formValue.username" prefix-icon="user" :placeholder="$t('Please enter username')" @keyup.enter="login" autofocus/>
          </el-form-item>
          <el-form-item :label="$t('Password')" prop="password">
            <el-input type="password" v-model="formValue.password" prefix-icon="lock" :placeholder="$t('Please enter password')" @keyup.enter="login" show-password/>
          </el-form-item>
          <el-form-item class="login-actions">
            <el-button type="primary" :loading="loading" @click="login" class="login-button">{{ $t('Login') }}</el-button>
          </el-form-item>
        </el-form>

        <el-divider class="login-divider"/>
      </div>
    </el-card>

    <div class="copyright">
      <p>Copyright © {{ currentYear }} Powered by 青青子衿</p>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      loading: false,
      currentYear: new Date().getFullYear(),
      formValue: {
        username: '',
        password: ''
      },
      rules: {
        username: {
          required: true,
          trigger: 'blur',
          message: () => this.$t('Please enter username')
        }
      }
    }
  },
  methods: {
    login() {
      this.$refs.form.validate(async valid => {
        if (!valid)
          return

        this.loading = true

        try {
          await this.$oui.login(this.formValue.username, this.formValue.password)
          this.$router.push('/')
        } catch {
          this.$message.error(this.$t('wrong username or password'))
        }

        this.loading = false
      })
    }
  }
}
</script>

<style scoped>
.login-page {
  position: fixed;
  inset: 0;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 18px 200px;
  background: #eef2f7;
}

/* 点阵网格背景 */
.bg-grid {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle, rgba(79, 141, 247, 0.25) 1px, transparent 1px);
  background-size: 28px 28px;
  animation: gridDrift 40s linear infinite;
  pointer-events: none;
  z-index: 0;
}

@keyframes gridDrift {
  0% { background-position: 0 0; }
  100% { background-position: 28px 28px; }
}

/* 扫描线效果 */
.bg-scan {
  position: absolute;
  left: 0;
  right: 0;
  height: 180px;
  background: linear-gradient(180deg, transparent, rgba(79, 141, 247, 0.1) 50%, transparent);
  animation: scanDown 12s linear infinite;
  pointer-events: none;
  z-index: 0;
}

@keyframes scanDown {
  0% { top: -180px; }
  100% { top: 100%; }
}

/* 几何形状通用 */
.geo-shape {
  position: absolute;
  pointer-events: none;
  z-index: 0;
  box-sizing: border-box;
}

/* 大圆环 - 右上角 */
.geo-circle-1 {
  width: 420px;
  height: 420px;
  border: 1.5px solid rgba(79, 141, 247, 0.35);
  border-radius: 50%;
  top: -120px;
  right: -100px;
  animation: drift1 50s ease-in-out infinite;
}

/* 大圆环上的节点 */
.geo-circle-1::after {
  content: '';
  position: absolute;
  width: 8px;
  height: 8px;
  background: rgba(79, 141, 247, 0.6);
  border-radius: 50%;
  top: -4px;
  left: 50%;
  box-shadow: 0 0 8px rgba(79, 141, 247, 0.4);
}

/* 小圆环 - 左下角 */
.geo-circle-2 {
  width: 260px;
  height: 260px;
  border: 1.5px solid rgba(45, 212, 191, 0.35);
  border-radius: 50%;
  bottom: -80px;
  left: -60px;
  animation: drift2 35s ease-in-out infinite;
}

.geo-circle-2::after {
  content: '';
  position: absolute;
  width: 7px;
  height: 7px;
  background: rgba(45, 212, 191, 0.6);
  border-radius: 50%;
  top: 50%;
  right: -3px;
  box-shadow: 0 0 8px rgba(45, 212, 191, 0.4);
}

/* 方形 - 左侧 */
.geo-square-1 {
  width: 160px;
  height: 160px;
  border: 1.5px solid rgba(79, 141, 247, 0.28);
  top: 35%;
  left: 6%;
  animation: drift3 60s ease-in-out infinite;
}

/* 菱形 - 右下 */
.geo-diamond-1 {
  width: 100px;
  height: 100px;
  border: 1.5px solid rgba(167, 139, 250, 0.35);
  bottom: 18%;
  right: 10%;
  animation: drift4 28s ease-in-out infinite;
}

/* 中圆环 - 右下偏中 */
.geo-circle-3 {
  width: 180px;
  height: 180px;
  border: 1px dashed rgba(79, 141, 247, 0.22);
  border-radius: 50%;
  bottom: 10%;
  right: 28%;
  animation: drift5 45s ease-in-out infinite;
}

/* 小方形 - 右上 */
.geo-square-2 {
  width: 70px;
  height: 70px;
  border: 1.5px solid rgba(45, 212, 191, 0.28);
  top: 22%;
  right: 22%;
  animation: drift6 25s ease-in-out infinite;
}

/* 三角形 - 左下 */
.geo-triangle-1 {
  width: 0;
  height: 0;
  border-left: 50px solid transparent;
  border-right: 50px solid transparent;
  border-bottom: 86px solid rgba(167, 139, 250, 0.12);
  bottom: 15%;
  left: 18%;
  animation: drift7 30s ease-in-out infinite;
}

/* 十字标记 - 左上 */
.geo-cross-1 {
  width: 30px;
  height: 30px;
  top: 18%;
  left: 15%;
  animation: drift8 20s ease-in-out infinite;
}

.geo-cross-1::before,
.geo-cross-1::after {
  content: '';
  position: absolute;
  background: rgba(79, 141, 247, 0.4);
}

.geo-cross-1::before {
  width: 100%;
  height: 1.5px;
  top: 50%;
  transform: translateY(-50%);
}

.geo-cross-1::after {
  width: 1.5px;
  height: 100%;
  left: 50%;
  transform: translateX(-50%);
}

/* 独立节点 */
.geo-dot-1 {
  width: 6px;
  height: 6px;
  background: rgba(79, 141, 247, 0.5);
  border-radius: 50%;
  top: 28%;
  right: 35%;
  box-shadow: 0 0 6px rgba(79, 141, 247, 0.3);
  animation: driftDot1 8s ease-in-out infinite;
}

.geo-dot-2 {
  width: 5px;
  height: 5px;
  background: rgba(45, 212, 191, 0.5);
  border-radius: 50%;
  bottom: 35%;
  left: 30%;
  box-shadow: 0 0 6px rgba(45, 212, 191, 0.3);
  animation: driftDot2 10s ease-in-out infinite;
}

.geo-dot-3 {
  width: 4px;
  height: 4px;
  background: rgba(167, 139, 250, 0.5);
  border-radius: 50%;
  top: 60%;
  right: 8%;
  box-shadow: 0 0 6px rgba(167, 139, 250, 0.3);
  animation: driftDot3 12s ease-in-out infinite;
}

/* 各元素独立漂移+旋转轨迹 */
@keyframes drift1 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(90deg) translate(-40px, 30px); }
  50%      { transform: rotate(180deg) translate(-20px, 60px); }
  75%      { transform: rotate(270deg) translate(30px, 30px); }
}

@keyframes drift2 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(-90deg) translate(40px, -30px); }
  50%      { transform: rotate(-180deg) translate(60px, -10px); }
  75%      { transform: rotate(-270deg) translate(20px, -40px); }
}

@keyframes drift3 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(90deg) translate(30px, -25px); }
  50%      { transform: rotate(180deg) translate(50px, 10px); }
  75%      { transform: rotate(270deg) translate(20px, 30px); }
}

@keyframes drift4 {
  0%, 100% { transform: rotate(45deg) translate(0, 0); }
  25%      { transform: rotate(135deg) translate(-25px, -20px); }
  50%      { transform: rotate(225deg) translate(-10px, -40px); }
  75%      { transform: rotate(315deg) translate(15px, -20px); }
}

@keyframes drift5 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(-90deg) translate(-30px, -25px); }
  50%      { transform: rotate(-180deg) translate(-50px, 10px); }
  75%      { transform: rotate(-270deg) translate(-20px, 30px); }
}

@keyframes drift6 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(90deg) translate(-30px, 25px); }
  50%      { transform: rotate(180deg) translate(-15px, 50px); }
  75%      { transform: rotate(270deg) translate(20px, 25px); }
}

@keyframes drift7 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(90deg) translate(30px, -20px); }
  50%      { transform: rotate(180deg) translate(50px, 0); }
  75%      { transform: rotate(270deg) translate(20px, 25px); }
}

@keyframes drift8 {
  0%, 100% { transform: rotate(0deg) translate(0, 0); }
  25%      { transform: rotate(90deg) translate(25px, 20px); }
  50%      { transform: rotate(180deg) translate(40px, -10px); }
  75%      { transform: rotate(270deg) translate(10px, -30px); }
}

@keyframes driftDot1 {
  0%, 100% { opacity: 0.3; transform: scale(1) translate(0, 0); }
  25%      { opacity: 0.7; transform: scale(1.3) translate(15px, -12px); }
  50%      { opacity: 1;   transform: scale(1.4) translate(25px, 8px); }
  75%      { opacity: 0.7; transform: scale(1.2) translate(10px, 18px); }
}

@keyframes driftDot2 {
  0%, 100% { opacity: 0.3; transform: scale(1) translate(0, 0); }
  25%      { opacity: 0.7; transform: scale(1.3) translate(-18px, -15px); }
  50%      { opacity: 1;   transform: scale(1.4) translate(-25px, 5px); }
  75%      { opacity: 0.7; transform: scale(1.2) translate(-10px, 20px); }
}

@keyframes driftDot3 {
  0%, 100% { opacity: 0.3; transform: scale(1) translate(0, 0); }
  25%      { opacity: 0.7; transform: scale(1.3) translate(20px, -10px); }
  50%      { opacity: 1;   transform: scale(1.4) translate(30px, 15px); }
  75%      { opacity: 0.7; transform: scale(1.2) translate(15px, -20px); }
}

.login-card {
  position: relative;
  z-index: 1;
  width: 33.333vw;
  min-width: 360px;
  max-width: 520px;
}

.mode-card {
  width: 100%;
}

.mode-panel {
  position: relative;
  border-radius: 14px;
  border: 1px solid var(--el-border-color);
  background: #ffffff;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
  overflow: hidden;
}

.mode-panel::before {
  content: '';
  position: absolute;
  inset: 0 auto 0 0;
  width: 3px;
  border-radius: 14px 0 0 14px;
  background: rgba(79, 141, 247, 0.6);
}

.login-head {
  display: flex;
  justify-content: center;
  align-items: center;
}

.login-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.login-panel-body {
  padding-top: 2px;
}

.login-form {
  width: 100%;
}

:deep(.mode-panel .el-card__header) {
  padding: 18px 18px 0;
  border-bottom: 0;
}

:deep(.mode-panel .el-card__body) {
  padding: 12px 18px 18px;
}

:deep(.login-form .el-form-item__label) {
  font-size: 13px;
  font-weight: 600;
  color: var(--el-text-color-secondary);
}

:deep(.login-form .el-input__wrapper) {
  border-radius: 12px;
}

.login-actions {
  margin-bottom: 0;
}

:deep(.login-actions .el-form-item__content) {
  justify-content: center;
}

.login-button {
  width: 100%;
  border-radius: 12px;
  font-weight: 700;
  box-shadow: none;
}

.login-button:hover {
  box-shadow: none;
}

.login-divider {
  margin: 18px 0 12px;
}

.copyright {
  position: absolute;
  left: 18px;
  bottom: 16px;
  text-align: left;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  z-index: 1;
}

@media (max-width: 420px) {
  :deep(.mode-panel .el-card__header) {
    padding: 16px 16px 0;
  }

  :deep(.mode-panel .el-card__body) {
    padding: 12px 16px 16px;
  }
}
</style>

<i18n src="./locale.json"/>
