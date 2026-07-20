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

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    return (data or ''):gsub("[\r\n]+$", "")
end

local function trim(s)
    if s == nil then
        return ''
    end
    return tostring(s):gsub('^%s+', ''):gsub('%s+$', '')
end

-- 从 sysfs 中读取网口设备名（兼容未激活的接口）
local function get_device_from_sysfs(c, channel)
    -- 优先从 sim 配置获取 USB 路径（与 wan.lua 中 get_sim_device 逻辑相同）
    local usb = c:get('sim', channel, 'usb')
    usb = trim(usb)
    if usb ~= '' then
        local net_dir = trim(exec(string.format(
            "find '%s' -maxdepth 2 -type d -name net 2>/dev/null | head -n 1 | tr -d '\\r\\n'",
            usb:gsub("'", [['"'"']])
        )))
        local device = trim(exec(string.format(
            "ls '%s' 2>/dev/null | head -n 1 | tr -d '\\r\\n'",
            net_dir ~= '' and net_dir or '/nonexistent'
        )))
        if device ~= '' then
            return device
        end
    end

    -- 回退到 network 配置中的 device/ifname
    local dev = c:get('network', channel, 'device') or c:get('network', channel, 'ifname')
    return trim(dev)
end

local function get_channel_iface(ubus_conn, channel)
    if not channel then
        return ''
    end

    -- 优先通过 ubus 获取活跃接口的设备名
    if ubus_conn then
        local status, err = ubus_conn:call('network.interface.' .. channel, 'status', {})
        if status and type(status) == 'table' then
            local device = tostring(status.device or status.l3_device or '')
            if device ~= '' then
                return device
            end
        end
    end

    -- ubus 失败时回退到 sysfs/UCI 读取（兼容未激活/未插卡的接口）
    local c = uci.cursor()
    return get_device_from_sysfs(c, channel)
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

-- 获取负载均衡权重
function M.getBalanceWeights()
    local c = uci.cursor()
    local section = 'balance'
    local weights = {}

    c:foreach('global', 'balance', function(s)
        for k, v in pairs(s) do
            if k:match('_weight$') then
                local channel = k:gsub('_weight$', '')
                weights[channel] = tonumber(v) or 0
            end
        end
    end)

    -- 如果 foreach 没拿到数据 (比如 section 类型不是 balance 或者 section 不存在)
    -- 尝试直接根据 section 名获取
    if next(weights) == nil then
        local options = c:get_all('global', section)
        if options then
            for k, v in pairs(options) do
                if k:match('_weight$') then
                    local channel = k:gsub('_weight$', '')
                    weights[channel] = tonumber(v) or 0
                end
            end
        end
    end

    log.info('get balance weights count:', #weights)
    return weights
end

-- 设置负载均衡权重
function M.setBalanceWeight(params)
    if params == nil or params.weights == nil then
        return -1
    end

    local c = uci.cursor()
    local section = 'balance'

    -- 如果 section 不存在则创建
    if not c:get('global', section) then
        c:set('global', section, 'balance')
    end

    for channel, weight in pairs(params.weights) do
        local option = tostring(channel) .. '_weight'
        c:set('global', section, option, tostring(weight))
        log.info('set balance weight:', channel, weight)
    end

    c:commit('global')
    exec_async('/etc/init.d/openmptcprouter-vps restart')
    return 0
end

-- 获取某个网口上的连接数
function M.getIfContrackCnt(params)
    if not params then
        return 0
    end

    local ubus_conn = nil
    local channel_ip = {}

    local function get_channel_ipv4(channel)
        if not ubus_conn or not channel then
            return nil
        end
        local status = ubus_conn:call('network.interface.' .. tostring(channel), 'status', {})
        if not status or type(status) ~= 'table' then
            return nil
        end
        local ipv4 = status['ipv4-address'] or status["ipv4-address"]
        if type(ipv4) == 'table' and ipv4[1] and ipv4[1].address then
            return tostring(ipv4[1].address)
        end
        return nil
    end

    local channels = nil
    if type(params.channels) == 'table' then
        channels = params.channels
    elseif params.channel ~= nil then
        channels = { params.channel }
    end

    if not channels or #channels == 0 then
        return 0
    end

    ubus_conn = ubus.connect()
    if ubus_conn then
        for _, channel in ipairs(channels) do
            if channel and tostring(channel) ~= '' then
                local ip = get_channel_ipv4(channel)
                if ip and ip ~= '' then
                    channel_ip[tostring(channel)] = ip
                end
            end
        end
        ubus_conn:close()
    end

    local file = io.open('/proc/net/nf_conntrack', 'r')
    if not file then
        if type(params.channels) == 'table' then
            return { total = 0, by_channel = {} }
        end
        return 0
    end

    local ip_to_channels = {}
    for channel, ip in pairs(channel_ip) do
        if not ip_to_channels[ip] then
            ip_to_channels[ip] = { channel }
        else
            ip_to_channels[ip][#ip_to_channels[ip] + 1] = channel
        end
    end

    local all_total = 0
    local by_channel = {}
    for _, channel in ipairs(channels) do
        by_channel[tostring(channel)] = 0
    end

    for line in file:lines() do
        all_total = all_total + 1
        local touched = {}
        for ip in line:gmatch('src=([%d%.]+)') do
            if ip_to_channels[ip] then
                for _, channel in ipairs(ip_to_channels[ip]) do
                    touched[channel] = true
                end
            end
        end
        for ip in line:gmatch('dst=([%d%.]+)') do
            if ip_to_channels[ip] then
                for _, channel in ipairs(ip_to_channels[ip]) do
                    touched[channel] = true
                end
            end
        end
        for channel, _ in pairs(touched) do
            by_channel[channel] = (by_channel[channel] or 0) + 1
        end
    end

    file:close()

    if type(params.channels) == 'table' then
        local selected_total = 0
        for _, channel in ipairs(channels) do
            selected_total = selected_total + (tonumber(by_channel[tostring(channel)] or 0) or 0)
        end

        local others = all_total - selected_total
        if others < 0 then
            others = 0
        end

        return { total = selected_total, all_total = all_total, others = others, by_channel = by_channel }
    end

    local single = tostring(params.channel or channels[1])
    return tonumber(by_channel[single] or 0) or 0
end

return M
