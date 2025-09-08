local rpc = require 'oui.rpc'
local uci = require 'eco.uci'

local M = {}

-- 加载uci配置文件
function M.load(params, session)
    local config = params.config
    local c = uci.cursor()

    -- 检查用户权限，至于有权限的用户才能访问
    if not rpc.acl_match(session, config, 'uci') then
        return nil, rpc.ERROR_CODE_PERMISSION_DENIED
    end

    return c:get_all(params.config)
end

-- 获取特定的配置值
function M.get(params, session)
    local c = uci.cursor()
    local config = params.config        -- 配置文件名
    local section = params.section      -- 配置段名
    local option = params.option        -- 配置选项名

    if not rpc.acl_match(session, config, 'uci') then
        return nil, rpc.ERROR_CODE_PERMISSION_DENIED
    end

    return c:get(config, section, option)
end

-- 获取bool类型的配置值
function M.get_bool(params, session)
    local val = get(params, session)
    return (val == "1" or val == "true" or val == "yes" or val == "on")
end

-- 设置特定的配置值
function M.set(params, session)
    local c = uci.cursor()
    local config = params.config            -- 配置文件名
    local section = params.section          -- 配置段名

    if not rpc.acl_match(session, config, 'uci') then
        return nil, rpc.ERROR_CODE_PERMISSION_DENIED
    end

    -- params.values是一个包含多个配置项的表结构
    for option, value in pairs(params.values) do
        c:set(config, section, option, value)
    end

    c:commit(config)
end

-- 删除配置段或选项
function M.delete(params, session)
    local c = uci.cursor()
    local config = params.config
    local section = params.section
    local options = params.options

    if not rpc.acl_match(session, config, 'uci') then
        return nil, rpc.ERROR_CODE_PERMISSION_DENIED
    end

    -- 指定了 options ，只删除特定选项
    if options then
        for _, option in ipairs(options) do
            c:delete(config, section, option)
        end
    -- 未指定 options , 删除整个配置段
    else
        c:delete(config, section)
    end

    c:commit(config)
end

-- 创建新的配置段及其选项
function M.add(params, session)
    local c = uci.cursor()
    local config = params.config
    local typ = params.type
    local name = params.name
    local values = params.values

    if not rpc.acl_match(session, config, 'uci') then
        return nil, rpc.ERROR_CODE_PERMISSION_DENIED
    end

    -- 指定了 name ，创建具名配置段
    if name then
        c:set(config, name, typ)
    -- 未指定 name ，系统自动匿名配置端
    else
        name = c:add(config, typ)
    end

    -- 创建该配置段的选项
    for option, value in pairs(values) do
        c:set(config, name, option, value)
    end

    c:commit(config)
end

return M
