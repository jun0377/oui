/* SPDX-License-Identifier: MIT */
/*
 * Author: Jianhui Zhao <zhaojh329@gmail.com>
 */

import { computed, reactive } from 'vue'
import { useDark } from '@vueuse/core'
import * as Vue from 'vue'
import axios from 'axios'
import md5 from 'js-md5'
import i18n from '../i18n'

const isDark = useDark()

// 国际化消息支持，将当前菜单项的翻译文本存储到对应语言的menus[key]中
function mergeLocaleMessage(key, locales) {
  for (const locale in locales) {
    const messages = i18n.global.getLocaleMessage(locale)
    if (!messages.menus)
      messages.menus = {}
    messages.menus[key] = locales[locale]
  }
}

// 会话IP获取,从浏览器的 sessionStorage 中获取当前用户的会话 ID
// 在login()方法中设置了会话ID
function getSID() {
  return sessionStorage.getItem('__oui__sid__') || ''
}

// 核心OUI类
class Oui {

  // 构造函数
  constructor() {
    window.Vue = Vue          // 将Vue暴露到全局window对象
    this.menus = null         // 菜单数据，初始为空
    this.inited = false       // 初始化状态标志
    this.aliveTimer = null    // 会话保活定时器
    this.state = reactive({
      sid: '',                // 会话ID
      locale: '',             // 语言设置
      hostname: ''            // 主机名
    })

    // 暗色主题计算属性
    this.state.isDark = computed({
      // 是否使用暗色主题
      get() {
        return isDark.value
      },
      // 设置暗色主题
      set: dark => {
        isDark.value = dark
        const theme = dark ? 'dark' : 'light'
        if (this.inited)
          this.call('uci', 'set', { config: 'oui', section: 'global', values: { theme }})
      }
    })

    // 异步初始化流程
    const p = [
      this.call('ui', 'get_locale'),            // 获取语言设置
      this.call('ui', 'get_theme')              // 获取主题设置
    ]

    // 检查会话是否有效
    const sid = getSID()
    if (sid)
      p.push(this.rpc('alive', { sid }))

    // 初始化完成处理
    Promise.all(p).then(results => {

      // 处理语言设置
      let locale = results[0].locale
      if (!locale)
        locale = 'auto'

      this.state.locale = locale

      if (locale === 'auto')
        i18n.global.locale = navigator.language             // 使用浏览器语言
      else
        i18n.global.locale = locale                         // 使用指定语言

      // 处理主题设置
      this.state.isDark = results[1].theme === 'dark'

      // 会话恢复
      if (sid) {
        const alive = results[2].alive
        if (alive)
          this.initWithAlived(sid)
      }
      
      // 标记初始化完成
      this.inited = true
    })
  }

  // 条件等待，用于等待某个条件满足
  waitUntil(conditionFn) {

    // 条件已满足,return
    if (conditionFn())
      return

    // 条件不满足，重设定时器，下一次继续检查
    return new Promise((resolve) => {
      const intervalId = setInterval(() => {
        if (conditionFn()) {
          clearInterval(intervalId)
          resolve()
        }
      }, 10)
    })
  }

  // 当用户已有有效会话时，系统会调用此方法来恢复会话状态
  initWithAlived(sid) {
    this.state.sid = sid

    // 获取系统信息，设置主机名
    this.ubus('system', 'board').then(({ hostname }) => this.state.hostname = hostname)

    // 启动包活定时器，没5000ms发送一次保活请求
    this.aliveTimer = setInterval(() => {
      this.rpc('alive', { sid })
    }, 5000)
  }

  // 基础RPC调用 - 最底层HTTP通信
  async rpc(method, params) {
    return (await axios.post('/oui-rpc', { method, params })).data
  }

  // 模块化调用 - 中间层模块调用
  async call(mod, func, params = {}) {
    return (await this.rpc('call', [getSID(), mod, func, params])).result
  }

  // ubus系统调用 - 顶层ubus系统总线调用
  ubus(obj, method, params) {
    return this.call('ubus', 'call', {object: obj, method, params})
  }

  reloadConfig(config) {
    return this.ubus('service', 'event', { type: 'config.change', data: { package: config }})
  }

  // 认证与会话管理
  async login(username, password) {
    // 1. 获取服务器提供的随机数，用于防止重放共计
    const { nonce } = await this.rpc('challenge', { username })
    // 2. 第一次哈希，将用户名和密码组合后进行 MD5 哈希
    const hash1 = md5(`${username}:${password}`)
    // 3. 第二次哈希，将第一次哈希结果与服务器提供的随机数组合
    const hash2 = md5(`${hash1}:${nonce}`)
    // 4. 登录请求，密码字段传入第二次哈希结果
    const { sid } = await this.rpc('login', { username, password: hash2 })
    // 5. 保存会话ID
    sessionStorage.setItem('__oui__sid__', sid)
    // 6. 初始化会话
    this.initWithAlived(sid)
  }

  // 退出登录
  logout() {
    this.menus = null                                 // 1. 清空菜单数据
    const sid = getSID()                              // 2. 获取当前会话ID
    if (!sid)
      return

    // 3. 清理保活定时器
    if (this.aliveTimer) {
      clearInterval(this.aliveTimer)                
      this.aliveTimer = null
    }

    // 4. 清除本地会话存储
    sessionStorage.removeItem('__oui__sid__')

    // 5. 通知服务器登出
    return this.rpc('logout', { sid })
  }

  // 验证当前会话是否仍然有效
  async isAlived() {
    const sid = getSID()
    if (!sid)
      return false
    return (await this.rpc('alive', { sid })).alive
  }

  // 菜单系统,将原始菜单数据转换为层次化的菜单数据
  parseMenus(raw) {

    // 菜单对象
    const menus = {}

    // 第一层：根菜单
    for (const path in raw) {
      const paths = path.split('/')

      // paths.length === 2 表示根级菜单（如 /system ）
      if (paths.length === 2)
        menus[path] = raw[path]
    }

    // 第二层：子菜单
    for (const path in raw) {
      const paths = path.split('/')

      // paths.length === 3 表示二级菜单（如 /system/general ）
      if (paths.length === 3) {

        // 查找对应的父菜单
        const parent = menus['/' + paths[1]]
        // 父菜单不存在或已有视图，则跳过
        if (!parent || parent.view)
          continue
        
        // 为父菜单创建 children 对象
        if (!parent.children)
          parent.children = {}
        
        // 建立父子关系
        parent.children[path] = raw[path]
        parent.children[path].parent = parent
      }
    }

    // 菜单数组
    const menusArray = []

    for (const path in menus) {

      // 只包含有视图或有子菜单的项目
      const m = menus[path]
      if (m.view || m.children) {
        menusArray.push({
          path: path,
          ...m
        })

        // 国际化支持
        mergeLocaleMessage(m.title, m.locales)
      }
    }

    // 按 index 属性排序
    menusArray.sort((a, b) => (a.index ?? 0) - (b.index ?? 0))

    // 处理子菜单
    menusArray.forEach(m => {
      if (!m.children)
        return

      // 将子菜单对象转换为数组
      const children = []
      for (const path in m.children) {
        const c = m.children[path]
        children.push({
          path: path,
          ...c
        })

        // 国际化支持
        mergeLocaleMessage(c.title, c.locales)
      }

      // 按index排序子菜单
      children.sort((a, b) => (a.index ?? 0) - (b.index ?? 0))

      // 替换原有的 children 对象
      m.children = children
    })

    return menusArray
  }

  // 菜单加载方法,获取菜单数据并进行解析处理。
  async loadMenus() {

    // 缓存检查：如果 this.menus 已存在，直接返回缓存的菜单
    if (this.menus)
      return this.menus

    // 通过 RPC 调用获取原始菜单数据, ui模块的get_menus方法
    const { menus } = await this.call('ui', 'get_menus')
    // 菜单解析
    this.menus = this.parseMenus(menus)
    return this.menus
  }

  // 语言设置
  async setLocale(locale) {
    if (locale !== 'auto' && !i18n.global.availableLocales.includes(locale))
      return

    await this.call('uci', 'set', { config: 'oui', section: 'global', values: { locale }})

    this.state.locale = locale

    if (locale === 'auto') {
      let language = navigator.language
      if (language === 'en-US')
        language = 'en'
      i18n.global.locale = language
    } else {
      i18n.global.locale = locale
    }
  }

  // 主机名设置
  async setHostname(hostname) {
    await this.call('uci', 'set', { config: 'system', section: '@system[0]', values: { hostname }})
    await this.reloadConfig('system')
    this.state.hostname = hostname
  }

  // 设备重连机制，用于在网络连接中断后检测服务器是否重新可用
  reconnect(delay) {

    // Promise封装，异步重连逻辑
    return new Promise(resolve => {
      let interval

      // 创建检测元素,利用图片加载机制检测服务器可达性
      const img = document.createElement('img')

      // 成功回调，
      img.addEventListener('load', () => {
        window.clearInterval(interval)        // 清除定时器
        img.remove()                          // 移除检测元素
        resolve()
      })

      // 延迟启动检测,等待指定延迟时间后开始检测
      window.setTimeout(() => {
        // 每秒尝试加载一次 favicon.ico
        interval = window.setInterval(() => {
          img.src = '/favicon.ico?r=' + Math.random()
        }, 1000)
      }, delay || 5000)
    })
  }

  //Vue插件安装
  install(app) {
    app.config.globalProperties.$oui = this
    app.config.globalProperties.$md5 = md5
    app.provide('$oui', this)
  }
}

export default new Oui()
