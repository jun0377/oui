<template>
  <el-container class="oui-container">
    <el-aside :width="isCollapse ? '64px' : '208px'" class="layout-aside">
      <div class="aside-brand">
        <router-link to="/" class="aside-brand-link">
          <span class="aside-logo">M</span>
          <span v-if="!isCollapse" class="aside-brand-name">{{ $oui.state.hostname }}</span>
        </router-link>
      </div>

      <el-scrollbar class="aside-scroll">
        <el-menu
          unique-opened
          router
          :default-active="selectedMenu"
          :collapse="isCollapse"
          :collapse-transition="false"
          class="aside-menu"
        >
          <el-menu-item index="/home">
            <el-icon><House /></el-icon>
            <template #title>首页</template>
          </el-menu-item>
          <template v-for="menu in filteredMenus" :key="menu.path">
            <el-sub-menu v-if="menu.children && menu.children.length" :index="menu.path">
              <template #title>
                <el-icon v-if="menu.svg"><div v-html="renderSvg('svg', menu.svg)"></div></el-icon>
                <span>{{ $t('menus.' + menu.title) }}</span>
              </template>
              <el-menu-item v-for="submenu in menu.children" :key="submenu.path" :index="submenu.path">
                <template #title>{{ $t('menus.' + submenu.title) }}</template>
              </el-menu-item>
            </el-sub-menu>
            <el-menu-item v-else :index="menu.path">
              <el-icon v-if="menu.svg"><div v-html="renderSvg('svg', menu.svg)"></div></el-icon>
              <template #title>{{ $t('menus.' + menu.title) }}</template>
            </el-menu-item>
          </template>
        </el-menu>

        <div v-if="menuKeyword && !filteredMenus.length" class="aside-empty">暂无匹配菜单</div>
      </el-scrollbar>
    </el-aside>

    <el-container class="layout-body">
      <el-header class="layout-header">
        <div class="layout-header-left">
          <el-button class="layout-collapse" text circle @click="isCollapse = !isCollapse">
            <el-icon :size="18">
              <component :is="isCollapse ? 'Expand' : 'Fold'" />
            </el-icon>
          </el-button>
          <span class="layout-header-title">{{ pageTitle }}</span>
        </div>

        <div class="layout-header-actions">
          <el-input
            v-model="menuKeyword"
            class="header-search"
            size="small"
            clearable
            placeholder="搜索菜单"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>

          <el-button class="header-action" text size="small" @click="refreshPage">
            <el-icon class="header-action-icon"><Refresh /></el-icon>
            <span class="header-action-text">刷新</span>
          </el-button>

          <span class="header-device">{{ $oui.state.hostname }}</span>

          <el-button
            class="header-icon-btn"
            text
            circle
            aria-label="切换主题"
            @click="$oui.state.isDark = !$oui.state.isDark"
          >
            <el-icon :size="18">
              <component :is="$oui.state.isDark ? MoonIcon : SunnySharpIcon" />
            </el-icon>
          </el-button>
        </div>
      </el-header>

      <el-main class="layout-content">
        <el-scrollbar>
          <router-view v-slot="{ Component }">
            <keep-alive include="ServerConfig">
              <component :is="Component"/>
            </keep-alive>
          </router-view>
          <el-backtop target=".oui-container .el-container .el-scrollbar__wrap"/>
        </el-scrollbar>
      </el-main>

      <el-footer class="layout-footer">
        <div class="copyright">
          <p>Copyright © 2026 Powered by 青青子衿</p>
        </div>
      </el-footer>
    </el-container>
  </el-container>
</template>

<script>
import {
  Translate as TranslateIcon
} from '@vicons/carbon'

import {
  House,
  Refresh,
  Search
} from '@element-plus/icons-vue'

import {
  Moon as MoonIcon,
  SunnySharp as SunnySharpIcon,
  LogOutOutline as LogoutIcon
} from '@vicons/ionicons5'

export default {
  props: {
    menus: {
      type: Array,
      required: true
    }
  },
  components: {
    TranslateIcon
  },
  data() {
    return {
      selectedMenu: '',
      isCollapse: false,
      menuKeyword: ''
    }
  },
  setup() {
    return {
      House,
      Refresh,
      Search,
      LogoutIcon,
      MoonIcon,
      SunnySharpIcon
    }
  },
  computed: {
    filteredMenus() {
      const keyword = this.menuKeyword.trim().toLowerCase()
      if (!keyword)
        return this.menus

      return this.filterMenus(this.menus, keyword)
    },
    pageTitle() {
      const path = this.$route.path

      if (path === '/' || path === '/home')
        return '首页'

      const findTitle = menus => {
        for (const menu of menus) {
          if (menu.path === path)
            return this.$t('menus.' + menu.title)

          if (Array.isArray(menu.children)) {
            const title = findTitle(menu.children)
            if (title)
              return title
          }
        }

        return ''
      }

      return findTitle(this.menus) || this.$oui.state.hostname || '控制台'
    },
    localeOptions() {
      const titles = {
        'en': 'English',
        'ja-JP': '日本語',
        'zh-CN': '简体中文',
        'zh-TW': '繁體中文'
      }

      const options = this.$i18n.availableLocales.map(locale => {
        return {
          label: titles[locale] ?? locale,
          key: locale
        }
      })

      options.unshift({
        label: this.$t('Auto'),
        key: 'auto'
      })

      return options
    }
  },
  watch: {
    '$route.path': {
      immediate: true,
      handler(path) {
        this.selectedMenu = path
      }
    }
  },
  methods: {
    filterMenus(menus, keyword) {
      return menus.reduce((result, menu) => {
        const title = String(this.$t(`menus.${menu.title}`) || '').toLowerCase()
        const rawTitle = String(menu.title || '').toLowerCase()
        const children = Array.isArray(menu.children) ? this.filterMenus(menu.children, keyword) : null
        const matched = title.includes(keyword) || rawTitle.includes(keyword)

        if (matched || (children && children.length)) {
          result.push({
            ...menu,
            children: matched && Array.isArray(menu.children) ? menu.children : children
          })
        }

        return result
      }, [])
    },
    refreshPage() {
      window.location.reload()
    },
    renderSvg(el, opt) {
      const props = []
      const children = []

      Object.keys(opt).forEach(key => {
        if (key.startsWith('-')) {
          props.push(`${key.substring(1)}="${opt[key]}"`)
        } else {
          if (Array.isArray(opt[key]))
            opt[key].forEach(item => children.push(this.renderSvg(key, item)))
          else
            children.push(this.renderSvg(key, opt[key]))
        }
      })

      return `<${el} ${props.join(' ')}>${children.join(' ')}</${el}>`
    },
    handleUserAction(command) {
      if (command === 'logout') {
        this.$oui.logout()
        this.$router.push('/login')
      } else if (command === 'reboot') {
        this.$confirm(this.$t('RebootConfirm'), this.$t('Reboot'), {
          type: 'warning'
        }).then(() => {
          this.$oui.ubus('system', 'reboot').then(() => {
            const loading = this.$loading({
              lock: true,
              text: this.$t('Rebooting') + '...',
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
}
</script>

<style scoped>
.oui-container {
  position: fixed;
  inset: 0;
  height: 100vh;
  background: var(--el-bg-color-page);
  color: var(--el-text-color-primary);
}

.layout-aside {
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  padding: 0;
  overflow: hidden;
  border-right: 1px solid var(--el-border-color-lighter);
  background: var(--el-bg-color);
  transition: width 0.2s ease;
}

.aside-brand {
  display: flex;
  flex: 0 0 56px;
  align-items: center;
  padding: 0 16px;
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.aside-brand-link {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  color: var(--el-text-color-primary);
  text-decoration: none;
}

.aside-logo {
  display: flex;
  flex: 0 0 30px;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border-radius: 9px;
  background: linear-gradient(135deg, #7c6cf4 0%, #4f46e5 100%);
  box-shadow: 0 6px 14px rgba(99, 102, 241, 0.24);
  color: #fff;
  font-size: 16px;
  font-weight: 800;
}

.aside-brand-name {
  overflow: hidden;
  font-size: 14px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.aside-scroll {
  flex: 1;
  min-height: 0;
}

.aside-menu {
  padding: 6px 0;
  border-right: none;
  background: transparent;
}

:deep(.aside-menu .el-menu-item),
:deep(.aside-menu .el-sub-menu__title) {
  height: 42px;
  margin: 2px 10px;
  padding: 0 12px;
  border-radius: 8px;
  color: var(--el-text-color-regular);
  font-size: 13px;
  font-weight: 500;
  line-height: 42px;
  transition: background-color 0.16s ease, color 0.16s ease;
}

:deep(.aside-menu .el-menu-item:hover),
:deep(.aside-menu .el-sub-menu__title:hover) {
  background: var(--el-fill-color-light);
  color: var(--el-text-color-primary);
}

:deep(.aside-menu .el-menu-item.is-active),
:deep(.aside-menu .el-sub-menu.is-active > .el-sub-menu__title) {
  background: var(--el-color-primary-light-9);
  color: var(--el-color-primary);
  font-weight: 600;
}

:deep(.aside-menu .el-sub-menu.is-opened > .el-sub-menu__title) {
  background: var(--el-fill-color-light);
  color: var(--el-text-color-primary);
}

:deep(.aside-menu .el-sub-menu.is-opened.is-active > .el-sub-menu__title) {
  background: var(--el-color-primary-light-9);
  color: var(--el-color-primary);
}

:deep(.aside-menu .el-sub-menu .el-menu) {
  background: transparent;
}

:deep(.aside-menu .el-sub-menu .el-menu-item) {
  height: 36px;
  padding-left: 40px !important;
  font-size: 12.5px;
  line-height: 36px;
}

:deep(.aside-menu .el-sub-menu .el-menu-item.is-active) {
  background: var(--el-color-primary-light-9);
  color: var(--el-color-primary);
  box-shadow: none;
}

:deep(.aside-menu .el-icon) {
  width: 18px;
  color: var(--el-text-color-secondary);
  font-size: 18px;
}

:deep(.aside-menu .el-icon div) {
  display: flex;
}

:deep(.aside-menu .el-icon svg) {
  width: 18px;
  height: 18px;
  fill: currentColor;
}

:deep(.aside-menu .el-menu-item.is-active .el-icon),
:deep(.aside-menu .el-sub-menu.is-active > .el-sub-menu__title .el-icon) {
  color: var(--el-color-primary);
}

:deep(.aside-menu.el-menu--collapse) {
  width: 100%;
}

:deep(.aside-menu.el-menu--collapse .el-menu-item),
:deep(.aside-menu.el-menu--collapse .el-sub-menu__title) {
  justify-content: center;
  margin: 2px 6px;
  padding: 0;
}

:deep(.aside-menu.el-menu--collapse .el-icon) {
  margin-right: 0;
}

:deep(.aside-menu.el-menu--collapse .el-sub-menu__icon-arrow) {
  display: none;
}

.aside-empty {
  padding: 16px 20px;
  color: var(--el-text-color-secondary);
  font-size: 12px;
}

.layout-body {
  min-width: 0;
}

.layout-header {
  display: flex;
  height: 56px;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  border-bottom: 1px solid var(--el-border-color-lighter);
  background: var(--el-bg-color);
}

.layout-header-left {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 6px;
}

.layout-collapse {
  color: var(--el-text-color-regular);
}

.layout-header-title {
  overflow: hidden;
  color: var(--el-text-color-primary);
  font-size: 15px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.layout-header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.layout-header-actions .el-button + .el-button {
  margin-left: 0;
}

.header-search {
  width: 220px;
}

:deep(.header-search .el-input__wrapper) {
  border-radius: 8px;
  background: var(--el-fill-color-light);
  box-shadow: none;
}

:deep(.header-search .el-input__wrapper.is-focus) {
  background: var(--el-bg-color);
  box-shadow: 0 0 0 1px var(--el-color-primary) inset;
}

:deep(.header-search .el-input__inner) {
  font-size: 13px;
}

.header-action {
  color: var(--el-text-color-regular);
  font-size: 13px;
}

.header-action:hover {
  color: var(--el-color-primary);
}

.header-action-icon {
  margin-right: 4px;
  font-size: 15px;
}

.header-device {
  padding-left: 2px;
  color: var(--el-text-color-secondary);
  font-size: 12px;
  white-space: nowrap;
}

.header-icon-btn {
  color: var(--el-text-color-regular);
}

.header-icon-btn:hover {
  color: var(--el-color-primary);
}

.layout-content {
  padding: 16px;
  background: var(--el-bg-color-page);
}

.layout-footer {
  display: flex;
  height: 30px;
  align-items: center;
  justify-content: flex-end;
  padding: 0 16px;
  border-top: 1px solid var(--el-border-color-extra-light);
  background: var(--el-bg-color-page);
}

.copyright {
  color: var(--el-text-color-secondary);
  font-size: 12px;
  line-height: 1;
}

.copyright p {
  margin: 0;
}

@media (max-width: 900px) {
  .header-device {
    display: none;
  }
}

@media (max-width: 720px) {
  .header-search {
    width: 160px;
  }
}

@media (max-width: 600px) {
  .header-search,
  .header-action-text {
    display: none;
  }
}
</style>

<style>
/* ==========================================================================
   全局主题: 统一布局内所有应用页面的视觉风格
   仅调整 UI, 不涉及任何页面业务逻辑
   ========================================================================== */

/* ---- 主色: 同时覆盖弹窗、下拉等挂载到 body 的组件 ---- */
:root {
  --el-color-primary: #6366f1;
  --el-color-primary-light-3: #9294f5;
  --el-color-primary-light-5: #b1b3f8;
  --el-color-primary-light-7: #d0d1fb;
  --el-color-primary-light-8: #e0e0fc;
  --el-color-primary-light-9: #eff0fe;
  --el-color-primary-dark-2: #4f52c1;
}

html.dark {
  --el-color-primary: #6366f1;
  --el-color-primary-light-3: #4547a9;
  --el-color-primary-light-5: #323379;
  --el-color-primary-light-7: #1e1f48;
  --el-color-primary-light-8: #141430;
  --el-color-primary-light-9: #0a0a18;
  --el-color-primary-dark-2: #8285f4;
}

/* ---- 基础卡片: 白底、细边框、小圆角、无投影 ---- */
.oui-container .el-card {
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 10px;
  background-color: var(--el-bg-color);
  box-shadow: none;
}

/* ---- 整页承载面板: 不额外套一层白色卡片 ---- */
.oui-container .mode-panel:not(.mode-panel-single):not(.mode-panel-aggregate):not(.mode-panel-balance),
.oui-container .management-panel,
.oui-container .sdwan-panel,
.oui-container .sim-panel,
.oui-container .wan-panel {
  border: 0 !important;
  border-radius: 0 !important;
  background: transparent !important;
  box-shadow: none !important;
}

.oui-container .mode-panel:not(.mode-panel-single):not(.mode-panel-aggregate):not(.mode-panel-balance) > .el-card__body,
.oui-container .management-panel > .el-card__body,
.oui-container .sdwan-panel > .el-card__body {
  padding: 0 !important;
}

/* ---- 实际内容卡片: 统一为白底细边框 ---- */
.oui-container .mode-panel-single,
.oui-container .mode-panel-aggregate,
.oui-container .mode-panel-balance,
.oui-container .config-card,
.oui-container .compact-card,
.oui-container .lan-panel,
.oui-container .route-device-panel,
.oui-container .home-metric-card,
.oui-container .home-section-card,
.oui-container .mgmt-metric-card,
.oui-container .announce-card,
.oui-container .logs-card,
.oui-container .sdwan-hero-card,
.oui-container .sdwan-metric-card,
.oui-container .sdwan-section-card,
.oui-container .balance-link-card,
.oui-container .route-link-card {
  border: 1px solid var(--el-border-color-lighter) !important;
  border-radius: 10px !important;
  background: var(--el-bg-color) !important;
  box-shadow: none !important;
}

/* ---- 去掉旧版卡片的左侧彩条 / 内部装饰框 ---- */
.oui-container .mode-panel::before,
.oui-container .home-metric-card::before,
.oui-container .home-section-card::before,
.oui-container .mgmt-metric-card::before,
.oui-container .sdwan-hero-card::before,
.oui-container .sdwan-metric-card::before {
  display: none !important;
}

/* ---- 页面外壳与内容区内边距对齐 ---- */
.oui-container .lan-page,
.oui-container .wan-page,
.oui-container .sim-page,
.oui-container .container,
.oui-container .server {
  padding: 0 !important;
}

/* 网络状态页: 与布局内容区同宽 */
.oui-container .container {
  max-width: none !important;
  margin: 0 !important;
}

/* ---- 网络状态页分区 ---- */
.oui-container .section {
  border: 1px solid var(--el-border-color-lighter) !important;
  border-radius: 10px !important;
  background: var(--el-bg-color) !important;
}

.oui-container .section-header {
  padding: 12px 16px !important;
  border-bottom-color: var(--el-border-color-lighter) !important;
  background: var(--el-fill-color-light) !important;
  font-size: 14px !important;
  font-weight: 600 !important;
}

.oui-container .section-content {
  padding: 16px !important;
}

/* ---- 卡片内部的小块信息区 ---- */
.oui-container .mode-group,
.oui-container .sdwan-hero-foot-item,
.oui-container .route-link-field {
  border: 1px solid var(--el-border-color-lighter) !important;
  border-radius: 8px !important;
  background: var(--el-fill-color-lighter) !important;
}

/* ---- 统一的标题层级 ---- */
.oui-container .mode h2 {
  margin: 0;
  color: var(--el-text-color-primary);
  font-size: 14px;
  font-weight: 600;
}

.oui-container .home-metric-title,
.oui-container .home-section-title,
.oui-container .mode-panel-title,
.oui-container .mgmt-metric-title,
.oui-container .sdwan-panel-title,
.oui-container .sdwan-section-title,
.oui-container .sdwan-metric-title,
.oui-container .balance-section-title,
.oui-container .single-route-title,
.oui-container .sim-metric-title,
.oui-container .wan-metric-title,
.oui-container .panel-title {
  font-size: 14px !important;
  font-weight: 600 !important;
}

/* ---- 服务页拓扑中的硬编码色改为主题变量 ---- */
.oui-container .route-link-name,
.oui-container .route-link-value {
  color: var(--el-text-color-primary) !important;
}

.oui-container .route-link-label,
.oui-container .route-link-footer,
.oui-container .sdwan-hero-foot-label {
  color: var(--el-text-color-secondary) !important;
}

.oui-container .route-link-item.is-active .route-link-card {
  border-color: var(--el-color-primary) !important;
  box-shadow: none !important;
  transform: none !important;
}

.oui-container .aggregate-v-divider,
.oui-container .balance-split::after {
  background: var(--el-border-color-lighter) !important;
}

.oui-container .balance-link-card:hover {
  transform: none !important;
}

.oui-container .upgrade-version-commit {
  color: var(--el-color-primary) !important;
}

.oui-container .balance-pie-inner {
  background: var(--el-bg-color) !important;
}

.oui-container .traffic-chart {
  border-color: var(--el-border-color-lighter) !important;
  border-radius: 8px;
  overflow: hidden;
}

/* ---- 按钮: 统一圆角与主色 ---- */
.oui-container .el-button:not(.is-circle):not(.is-round) {
  border-radius: 8px !important;
}

.oui-container .el-button--primary:not(.is-plain):not(.is-text):not(.is-link) {
  border-color: var(--el-color-primary) !important;
  background-color: var(--el-color-primary) !important;
  background-image: none !important;
  box-shadow: none !important;
}

.oui-container .el-button--primary:not(.is-plain):not(.is-text):not(.is-link):hover,
.oui-container .el-button--primary:not(.is-plain):not(.is-text):not(.is-link):focus {
  border-color: var(--el-color-primary-light-3) !important;
  background-color: var(--el-color-primary-light-3) !important;
  background-image: none !important;
  box-shadow: none !important;
}

.oui-container .el-button--primary:not(.is-plain):not(.is-text):not(.is-link):active {
  border-color: var(--el-color-primary-dark-2) !important;
  background-color: var(--el-color-primary-dark-2) !important;
  background-image: none !important;
  box-shadow: none !important;
}

.oui-container .el-button--primary.is-disabled:not(.is-plain):not(.is-text):not(.is-link),
.oui-container .el-button--primary.is-disabled:not(.is-plain):not(.is-text):not(.is-link):hover {
  border-color: var(--el-color-primary-light-5) !important;
  background-color: var(--el-color-primary-light-5) !important;
  background-image: none !important;
}

/* ---- 表单控件: 统一圆角与浅色填充 ---- */
.oui-container .el-input__wrapper,
.oui-container .el-select__wrapper,
.oui-container .el-textarea__inner {
  border-radius: 8px !important;
  background-color: var(--el-fill-color-light) !important;
  background-image: none !important;
  box-shadow: 0 0 0 1px var(--el-border-color-lighter) inset !important;
}

.oui-container .el-input__wrapper.is-focus,
.oui-container .el-select__wrapper.is-focused,
.oui-container .el-textarea__inner:focus {
  box-shadow: 0 0 0 1px var(--el-color-primary) inset !important;
}

.oui-container .el-input.is-disabled .el-input__wrapper,
.oui-container .el-select__wrapper.is-disabled,
.oui-container .el-textarea.is-disabled .el-textarea__inner {
  background-color: var(--el-fill-color-lighter) !important;
  box-shadow: 0 0 0 1px var(--el-border-color-lighter) inset !important;
}

/* ---- 单选/复选 ---- */
.oui-container .el-radio-button__inner {
  border-radius: 8px !important;
  border-color: var(--el-border-color) !important;
  background-color: var(--el-bg-color) !important;
  background-image: none !important;
  box-shadow: none !important;
}

.oui-container .el-radio-button__original-radio:checked + .el-radio-button__inner {
  border-color: var(--el-color-primary) !important;
  background-color: var(--el-color-primary-light-9) !important;
  color: var(--el-color-primary) !important;
  box-shadow: none !important;
}

.oui-container .el-radio.is-checked .el-radio__inner {
  border-color: var(--el-color-primary) !important;
  background-color: var(--el-color-primary) !important;
}

.oui-container .el-radio.is-checked .el-radio__label {
  color: var(--el-color-primary) !important;
}

/* ---- 标签: 统一为轻量柔和样式 ---- */
.oui-container .el-tag {
  border-radius: 6px !important;
  font-weight: 500;
}

.oui-container .el-tag.el-tag--info {
  border-color: var(--el-border-color-lighter) !important;
  background-color: var(--el-fill-color-light) !important;
  color: var(--el-text-color-regular) !important;
}

.oui-container .el-tag.el-tag--success {
  border-color: var(--el-color-success-light-7) !important;
  background-color: var(--el-color-success-light-9) !important;
  color: var(--el-color-success) !important;
}

.oui-container .el-tag.el-tag--warning {
  border-color: var(--el-color-warning-light-7) !important;
  background-color: var(--el-color-warning-light-9) !important;
  color: var(--el-color-warning) !important;
}

.oui-container .el-tag.el-tag--danger {
  border-color: var(--el-color-danger-light-7) !important;
  background-color: var(--el-color-danger-light-9) !important;
  color: var(--el-color-danger) !important;
}

/* ---- Tabs ---- */
.oui-container .el-tabs--border-card {
  border: 1px solid var(--el-border-color-lighter) !important;
  border-radius: 10px !important;
  background-color: var(--el-bg-color) !important;
  box-shadow: none !important;
}

.oui-container .el-tabs--border-card > .el-tabs__header {
  border-bottom: 1px solid var(--el-border-color-lighter) !important;
  background-color: var(--el-fill-color-light) !important;
}

.oui-container .el-tabs__item {
  font-size: 13px !important;
}

.oui-container .el-tabs__item.is-active {
  font-weight: 600;
}

/* ---- 表格 / 描述列表 / 表单标签 ---- */
.oui-container .el-table {
  --el-table-border-color: var(--el-border-color-lighter);
  --el-table-header-bg-color: var(--el-fill-color-light);
  --el-table-header-text-color: var(--el-text-color-regular);
  --el-table-row-hover-bg-color: var(--el-fill-color-lighter);
  font-size: 13px;
}

.oui-container .el-table th.el-table__cell {
  font-weight: 600;
}

.oui-container .el-form-item__label {
  color: var(--el-text-color-regular);
  font-size: 13px;
}

.oui-container .el-descriptions__label {
  color: var(--el-text-color-secondary);
  font-weight: 500;
}

.oui-container .el-upload-dragger {
  border-radius: 10px !important;
}

/* ---- 弹层: 与页面保持一致的圆角 ---- */
.el-dialog,
.el-message-box {
  border-radius: 10px;
}

.el-select__popper.el-popper,
.el-dropdown__popper.el-popper,
.el-popover.el-popper {
  border-radius: 8px;
}
</style>

<i18n src="./locale.json"/>
