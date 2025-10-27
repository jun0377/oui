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

-- shadowsocks
local function setShadowsocksIP(server_ip)
    log.info('set shadowsocks ip: ', server_ip)
    local c = uci.cursor()
    c:set("shadowsocks-libev","sss0","server",server_ip)
    c:commit('shadowsocks-libev')
    c:set("shadowsocks-rust","sss0","server",server_ip)
    c:commit('shadowsocks-rust')

    exec("/etc/init.d/shadowsocks-libev restart >/dev/null 2>/dev/null")
    exec("/etc/init.d/shadowsocks-rust restart >/dev/null 2>/dev/null")
end

-- glorytun
local function setGlorytunIP(server_ip)
    log.info('set glorytun vpn: ', server_ip)
    local c = uci.cursor()
    c:set("glorytun","vpn","host",server_ip)
    c:commit('glorytun')
    c:set("glorytun-udp","vpn","host",server_ip)
    c:commit('glorytun-udp')

    exec("/etc/init.d/glorytun restart >/dev/null 2>/dev/null")
	exec("/etc/init.d/glorytun-udp restart >/dev/null 2>/dev/null")
end

-- dsvpn
local function setDsvpnIP(server_ip)
    log.info('set DSVPN ip: ', server_ip)
    local c = uci.cursor()
    c:set("dsvpn","vpn","host",server_ip)
    c:commit('dsvpn')

    exec("/etc/init.d/dsvpn restart >/dev/null 2>/dev/null")
end

-- mlvpn
local function setMLVPNip(server_ip)
    log.info('set MLVPN ip: ', server_ip)
    local c = uci.cursor()
    c:set("mlvpn","general","host",server_ip)
    c:commit('mlvpn')

    exec("/etc/init.d/mlvpn restart >/dev/null 2>/dev/null")
end

-- openvpn
local function setOpenVpnIP(server_ip)
    log.info('set OpenVPN ip: ', server_ip)
    local cmd = "uci -q del openvpn.omr.remote"
    log.info(cmd)
    exec(cmd)
    cmd = "uci -q add_list openvpn.omr.remote=" .. server_ip
    log.info(cmd)
    exec(cmd)
    cmd = "uci commit openvpn"
    log.info(cmd)
    exec(cmd)
    exec("/etc/init.d/openvpn restart >/dev/null 2>/dev/null")
end

-- openmptcprouter vps
local function setVPSip(server_ip)
    log.info('set vps ip: ', server_ip)

    exec("uci del openmptcprouter.vps.ip")
    exec("uci add_list openmptcprouter.vps.ip=" .. server_ip)
    exec('uci commit openmptcprouter')

    exec("/etc/init.d/openmptcprouter-vps restart >/dev/null 2>/dev/null")
end

-- uci get openmptcprouter.vps.ip
function M.getServerIP()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'ip')
end

-- uci set openmptcprouter.vps.ip=xxx.xxx.xxx.xxx
function M.setServerIP(params)

    exec("(env -i /bin/ubus call network reload) >/dev/null 2>/dev/null")
    exec("ip addr flush dev tun0 >/dev/null 2>/dev/null")
    exec("/etc/init.d/omr-tracker stop >/dev/null 2>/dev/null")
    exec("/etc/init.d/mptcp restart >/dev/null 2>/dev/null")

    log.info('server IP: ', params.ip)
    -- vps
    setVPSip(params.ip)
    -- shadowsocks
    setShadowsocksIP(params.ip)
    -- glorytun
    setGlorytunIP(params.ip)
    -- dsvpn
    setDsvpnIP(params.ip)
    -- mlvpn
    setMLVPNip(params.ip)
    -- openvpn
    setOpenVpnIP(params.ip)

    exec("/etc/init.d/omr-tracker start >/dev/null 2>/dev/null")
    exec("/etc/init.d/omr-6in4 restart >/dev/null 2>/dev/null")
    exec("/etc/init.d/vnstat restart >/dev/null 2>/dev/null")
    exec("/etc/init.d/sysntpd restart >/dev/null 2>/dev/null")

    return 0
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
    return ping(nil, server[1])
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
