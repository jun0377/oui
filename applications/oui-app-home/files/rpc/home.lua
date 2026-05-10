local M = {}

local uci = require 'eco.uci'
local ubus = require 'eco.ubus'
local cjson = require 'cjson'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/home.log'

-- 获取单卡模式设置
local function workModeSingleSettings()

    local c = uci.cursor()
    local channel = c:get('global', 'single', 'channel')
    local l3_device = 'N/A'

    if channel and channel ~= '' then
        local status = ubus.call(string.format('network.interface.%s', channel), 'status', {})
        l3_device = status.l3_device or status.device
    end

    return {
        channel = channel,
        ifname = l3_device
    }
end

-- 获取聚合模式设置
local function workModeAggregateSettings()
    return {
        detail = '聚合多链路带宽'
    }
end

-- 获取负载均衡模式设置
local function workModeBalanceSettings()
    return {
        detail = '多链路按权重分流'
    }
end

-- 工作模式配置信息
function M.workModeSettings()
    local c = uci.cursor()
    
    -- 工作模式
    local mode = c:get('global', 'global', 'mode')
    local handlers = {
        single = workModeSingleSettings,
        aggregate = workModeAggregateSettings,
        balance = workModeBalanceSettings
    }
    local getSettings = handlers[mode]
    local settings = getSettings()
    local ret  = { mode = mode, settings = settings }
    local ok, payload = pcall(cjson.encode, ret)
    if ok then
        log.info('home.workModeSettings ', payload)
    else
        log.err('home.workModeSettings encode failed: ', tostring(payload))
    end

    return ret
end

return M
