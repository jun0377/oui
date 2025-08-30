local M = {}
local uci = require 'eco.uci'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/serverManager.log'

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    return data
end

-- ping ping -W 3 -c 3 -i 0.5 -I src dst
local function ping(src, dst)
    local state = {reachable = false, rtt_ms = 0, pkt_loss = 0}
    if not dst then
        log.error('Unknown ping dst')
        return state
    end

    local cmd = 'ping -W 3 -c 3 -i 0.5'
    if src then
        cmd = cmd .. ' -I ' .. src
    end

    cmd = cmd .. ' ' .. dst
    -- log.info(cmd)
    local ret = exec(cmd)
    if not ret then
        log.error(ret)
        return state
    end

    -- log.info(ret)

    local pkt_loss = string.match(ret, "(%d+)%% packet loss")
    if pkt_loss then
        state.pkt_loss = tonumber(pkt_loss)
        state.reachable = state.pkt_loss < 100
    end

    local rttmin, rtt_avg, rtt_max, rtt_mdev = string.match(ret, "min/avg/max/mdev = ([%d%.]+)/([%d%.]+)/([%d%.]+)/([%d%.]+) ms")
    if rtt_avg then
        state.rtt_ms = tonumber(rtt_avg)
    end

    -- log.info('reachable', state.reachable, 'rtt_ms', state.rtt_ms, 'pkt_loss', state.pkt_loss)
    return state
end

-- uci get openmptcprouter.vps.ip
function M.getServerIP()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'ip')
end

-- uci set openmptcprouter.vps.ip=xxx.xxx.xxx.xxx
function M.setServerIP(params)
    local c = uci.cursor()
    c:set('openmptcprouter', 'vps', 'ip', params.ip)
    return c:commit('openmptcprouter')
end

-- uci get openmptcprouter.vps.port
function M.getServerPort()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'port')
end

-- uci set openmptcprouter.vps.port=xxx
function M.setServerPort(params)
    local c = uci.cursor()
    c:set('openmptcprouter', 'vps', 'port', params.port)
    return c:commit('openmptcprouter')
end

-- 获取服务器主机是否可达，比较耗时，需要在vue中异步获取
function M.getHostRtt()
    
    log.info('getHostRtt...')

    local server = M.getServerIP()
    return ping(nil, server)
end

-- 获取VPN隧道的连通性，比较耗时，需要在vue中异步获取
function M.getVPNrtt()
    
    log.info('getVPNrtt...')

    local state = {reachable = false, rtt_ms = 0, pkt_loss = 0}

    local cmd = "cat /proc/net/dev | grep tun0"
    local res = exec(cmd)
    if nil == res then
        log.warn('VPN interface tun0 not exist')
        return state
    end

    cmd = "ip addr show dev tun0 | grep \'inet \' | awk \'{print $2}\' | cut -d/ -f1 | tr -d \'\n\'"
    local src_ip = exec(cmd)
    if nil == src_ip then
        log.warn('VPN interface tun0 has no ip')
        return state
    end

    -- log.info(src_ip)

    res = ping(src_ip, '10.255.252.1')
    log.info('reachable = ', res.reachable, ' rtt_ms = ', res.rtt_ms)
    return res
end

-- 获取服务器版本
function M.getServerVersion()
    local ver = {kernel = '6.6.83', software_version = '0.0.1'}
    return ver
end

return M
