<template>
  <el-container class="oui-container" style="height: calc(100vh - 16px);">
    <el-aside :width="isCollapse ? '64px' : '248px'" class="layout-aside">
      <el-scrollbar>
        <div v-if="!isCollapse" class="aside-brand">
          <div class="aside-brand-link">{{ $oui.state.hostname }}</div>
        </div>
        <div v-if="!isCollapse" class="aside-divider"></div>

        <el-menu
          unique-opened
          router
          :default-active="selectedMenu"
          :collapse="isCollapse"
          class="aside-menu"
        >
          <el-menu-item index="/">
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
      </el-scrollbar>
    </el-aside>
    <el-container>
      <el-header>
        <el-icon @click="isCollapse = !isCollapse" class="collapse-icon" :size="25">
          <component :is="isCollapse ? 'Expand' : 'Fold'"/>
        </el-icon>
        <el-space size="large">
          <el-icon color="#ffd93b" size="24" style="cursor: pointer;" @click="$oui.state.isDark = !$oui.state.isDark">
            <component :is="$oui.state.isDark ? MoonIcon : SunnySharpIcon"/>
          </el-icon>
          <!-- <el-dropdown @command="lang => $oui.setLocale(lang)">
            <span class="el-dropdown-link"><el-icon><TranslateIcon/></el-icon></span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item v-for="i in localeOptions" :key="i.key" :command="i.key" :class="{selected: i.key === $oui.state.locale}">{{ i.label }}</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown> -->
          <!-- <el-dropdown @command="handleUserAction">
            <span class="el-dropdown-link"><el-icon><Avatar/></el-icon></span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout" :icon="LogoutIcon">{{ $t('Logout') }}</el-dropdown-item>
                <el-dropdown-item command="reboot" icon="SwitchButton">{{ $t('Reboot') }}</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown> -->
        </el-space>
      </el-header>
      <el-main>
        <el-scrollbar>
          <router-view v-slot="{ Component }">
            <keep-alive include="ServerConfig">
              <component :is="Component"/>
            </keep-alive>
          </router-view>
          <el-backtop target=".oui-container .el-container .el-scrollbar__wrap"/>
        </el-scrollbar>
      </el-main>
      <el-footer>
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
  House
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
  },
  mounted() {
    this.selectedMenu = this.$route.path
  }
}
</script>

<style scoped>
.layout-aside {
  box-sizing: border-box;
}

.oui-container .el-menu {
  border-right: none;
  background: transparent;
}

.oui-container .el-aside {
  padding: 18px 12px 12px;
  border-right: 1px var(--el-border-color) var(--el-border-style);
  background:
    radial-gradient(circle at top left, rgba(129, 140, 248, 0.16) 0%, rgba(129, 140, 248, 0) 34%),
    linear-gradient(180deg, #f7f7ff 0%, #f3f4f8 100%);
}

.aside-brand {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 14px;
  padding: 8px 0 2px;
  text-align: center;
}

.aside-brand-link {
  font-size: 22px;
  font-weight: 800;
  letter-spacing: 0.02em;
  color: #5b5ce6;
  text-shadow: 0 6px 18px rgba(99, 102, 241, 0.18);
}

.aside-divider {
  height: 1px;
  margin: 0 8px 16px;
  background: linear-gradient(90deg, rgba(99, 102, 241, 0) 0%, rgba(99, 102, 241, 0.35) 18%, rgba(99, 102, 241, 0.7) 50%, rgba(99, 102, 241, 0.35) 82%, rgba(99, 102, 241, 0) 100%);
}

.aside-search {
  margin-bottom: 14px;
}

.aside-menu {
  background: transparent;
}

:deep(.aside-search .el-input__wrapper) {
  border-radius: 999px;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.7) inset;
  background: #ffffff;
}

:deep(.aside-search .el-input__inner) {
  text-align: left;
}

:deep(.aside-menu .el-menu-item),
:deep(.aside-menu .el-sub-menu__title) {
  height: 44px;
  margin-bottom: 8px;
  border-radius: 12px;
  color: #5c6677;
  font-size: 15px;
  font-weight: 600;
  transition: transform 0.18s ease, background-color 0.18s ease, box-shadow 0.18s ease, color 0.18s ease;
}

:deep(.aside-menu .el-menu-item:hover),
:deep(.aside-menu .el-sub-menu__title:hover) {
  background: rgba(99, 102, 241, 0.12);
  color: #4f46e5;
  transform: translateX(2px);
}

:deep(.aside-menu .el-menu-item.is-active) {
  background: linear-gradient(90deg, #7c6cf4 0%, #6366f1 100%);
  color: #ffffff;
  box-shadow: 0 10px 22px rgba(99, 102, 241, 0.24);
}

:deep(.aside-menu .el-menu-item.is-active .el-icon),
:deep(.aside-menu .el-menu-item.is-active svg) {
  color: #ffffff;
  fill: currentColor;
}

:deep(.aside-menu .el-sub-menu .el-menu) {
  background: transparent;
}

:deep(.aside-menu .el-sub-menu.is-opened > .el-sub-menu__title) {
  color: #4f46e5;
  background: rgba(99, 102, 241, 0.08);
}

:deep(.aside-menu .el-icon),
:deep(.aside-menu svg) {
  color: #8f99ac;
  fill: currentColor;
}

:deep(.layout-aside .el-scrollbar__view) {
  min-height: 100%;
}

.oui-container .el-header {
  height: 35px;
}

.oui-container .el-main {
  border: 1px var(--el-border-color) var(--el-border-style);
}

:deep(.el-dropdown-menu__item).selected {
  background-color: var(--el-dropdown-menuItem-hover-fill);
  color: var(--el-dropdown-menuItem-hover-color);
}

.el-header {
  display: flex;
  justify-content: space-between;
}

.collapse-icon {
  color: var(--el-color-primary);
  cursor: pointer;
}

.copyright {
  text-align: right;
  font-size: 1.2em;
  color: #888;
}

.el-dropdown-link {
  color: var(--el-color-primary);
  cursor: pointer;
}

.el-dropdown-link:focus {
  outline: none;
}

.el-dropdown-link .el-icon {
  font-size: 24px;
}
</style>

<i18n src="./locale.json"/>
