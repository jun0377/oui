
-- 这个模块是 OUI 框架中负责用户界面配置管理的核心组件
-- 处理语言、主题和菜单的动态配置，确保用户只能访问有权限的功能模块

local file = require 'eco.file'
local rpc = require 'oui.rpc'
local cjson = require 'cjson'
local uci = require 'eco.uci'

-- 定义模块导出表
local M = {}

-- 获取系统语言设置
function M.get_locale()
    -- uci句柄
    local c = uci.cursor()
    local locale = c:get('oui', 'global', 'locale')

    return { locale = locale }
end

-- 获取系统主题设置
function M.get_theme()
    local c = uci.cursor()
    local theme = c:get('oui', 'global', 'theme')

    return { theme = theme }
end

-- 获取用户可访问菜单列表，进行权限验证
function M.get_menus(params, session)
    local menus = {}

    -- 遍历菜单配置目录中的所有文件
    for name in file.dir('/usr/share/oui/menu.d') do
        -- 使用正则表达式匹配JSON格式的菜单配置文件（以字母数字开头，.json结尾）
        if name:match('^%w.*%.json$') then
            -- 读取菜单配置文件的完整内容
            local data = file.readfile('/usr/share/oui/menu.d/' .. name)
            -- 将JSON字符串解析为Lua表结构
            local menu = cjson.decode(data)
            -- 遍历菜单配置文件中的每个菜单项
            for m, info in pairs(menu) do
                -- 检查当前会话是否有权限访问该菜单项（基于ACL权限控制）
                if rpc.acl_match(session, m, 'menu') then
                    -- 如果有权限，将菜单项添加到结果集中
                    menus[m] = info
                end
            end
        end
    end

    return { menus = menus }
end

return M
