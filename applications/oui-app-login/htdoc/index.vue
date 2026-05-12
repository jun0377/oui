<template>
  <div class="login-page">
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

        <div class="copyright">
          <p>Copyright © 2026 Powered by 青青子衿</p>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  data() {
    return {
      loading: false,
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
  min-height: 100vh;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 24px 18px;
  background: #f8fafc;
}

.login-card {
  margin-top: calc(100vh / 5);
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
  text-align: center;
  font-size: 12px;
  color: var(--el-text-color-secondary);
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
