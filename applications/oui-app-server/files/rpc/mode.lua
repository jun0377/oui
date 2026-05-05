local M = {}

local uci = require 'eco.uci'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/mode.log'

-- 异步执行命令
local function exec_async(command)
    log.info('cmd async', command)
    os.execute(string.format("( %s ) >/dev/null 2>/dev/null &", command))
end

-- 获取所有可用链路
function M.getAllChannel()
    local c = uci.cursor()
    local channels = {}
    c:foreach('network', 'interface', function(section)
        if section['.name'] ~= nil then
            channels[#channels + 1] = tostring(section['.name'])
        end
    end)
    log.info('get all channel:', table.concat(channels, ','))
    return channels
end

-- 获取工作模式
function M.getMode()
    local c = uci.cursor()
    local mode = c:get('global', 'global', 'mode')
    log.info('get mode: ', mode)
    return mode
end

-- 设置工作模式
function M.setMode(params)
    log.info('set mode:', params.mode)
    if params == nil or params.mode == nil then
        return -1
    end
    local mode = tostring(params.mode)
    local c = uci.cursor()
    c:set('global', 'global', 'mode', mode)
    c:commit('global')

    exec_async('/etc/init.d/openmptcprouter-vps restart')
end

-- 获取单卡模式所用链路
function M.getSingleChannel()
    local c = uci.cursor()
    local channel = c:get('global', 'single', 'channel')
    log.info('get single channel:', channel)
    return channel
end

-- 设置单卡模式所用链路
function M.setSingleChannel(params)
    log.info('set single channel:', params.channel)
    if params == nil or params.channel == nil then
        return -1
    end

    local channel = tostring(params.channel)
    local c = uci.cursor()
    c:set('global', 'single', 'channel', channel)
    c:commit('global')
    exec_async('/etc/init.d/openmptcprouter-vps restart')
end

return M
