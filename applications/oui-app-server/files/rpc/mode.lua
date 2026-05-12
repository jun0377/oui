local M = {}

local uci = require 'eco.uci'
local log = require 'log'
local ubus = require 'eco.ubus'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/mode.log'

-- 异步执行命令
local function exec_async(command)
    log.info('cmd async', command)
    os.execute(string.format("( %s ) >/dev/null 2>/dev/null &", command))
end

local function get_channel_iface(ubus_conn, channel)
    if not ubus_conn or not channel then
        return ''
    end

    local status, err = ubus_conn:call('network.interface.' .. channel, 'status', {})
    if not status or type(status) ~= 'table' then
        log.warn('get channel status failed:', channel, err)
        return ''
    end

    return tostring(status.device or status.l3_device or '')
end


-- 获取所有可用链路
function M.getAllChannel()
    local c = uci.cursor()
    local channel_names = {}

    c:foreach('network', 'interface', function(section)
        if section['.name'] ~= nil then
            channel_names[#channel_names + 1] = tostring(section['.name'])
        end
    end)

    local channels = {}
    local ubus_conn = ubus.connect()

    for _, channel in ipairs(channel_names) do
        channels[#channels + 1] = {
            name = channel,
            iface = get_channel_iface(ubus_conn, channel)
        }
    end

    if ubus_conn then
        ubus_conn:close()
    end

    log.info('get all channel:', table.concat(channel_names, ','))
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
