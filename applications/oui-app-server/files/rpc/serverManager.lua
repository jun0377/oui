local M = {}
local uci = require 'eco.uci'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/tmp/serverManager.log'

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

    log.info('reachable', state.reachable, 'rtt_ms', state.rtt_ms, 'pkt_loss', state.pkt_loss)
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

-- 获取和服务器的连接状态，通过判断openvpn隧道是否建立来进行判断
function M.getConnectionState()

    local connState = {host_reachable = false, vpn_reachable = false}
    
    

    return connState
end

return M
