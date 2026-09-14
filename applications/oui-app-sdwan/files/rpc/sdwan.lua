local M = {}

local uci = require 'eco.uci'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/sdwan.log'

function M.echo(params)
    return params
end

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    return data
end

-- 获取VPN隧道设备名: mqvpn 由 mqvpn.interface.tun_name 决定(默认 mqvpn0), 其它后端用 network.omrvpn.device(默认 tun0)
local function getTunnelDevice()
    local c = uci.cursor()
    if c:get('openmptcprouter', 'settings', 'vpn') == 'mqvpn' then
        local dev = c:get('mqvpn', 'interface', 'tun_name')
        if dev == nil or dev == '' then
            dev = 'mqvpn0'
        end
        return dev
    end

    local dev = c:get('network', 'omrvpn', 'device')
    if dev == nil or dev == '' then
        dev = 'tun0'
    end
    return dev
end

-- 获取指定网口的IP
function getInterfaceIP(interface)
    local cmd = string.format("ip addr show %s | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1  | tr -d '\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的掩码
function getInterfaceMask(interface)
    local cmd = string.format("ifconfig %s | grep 'Mask:' | awk -F 'Mask:' '{print $2}' | tr -d '\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- uci get openvpn.omr.remote
function M.getRemoteIP(params)
    local c = uci.cursor()
    return c:get('openvpn', 'omr', 'remote')
end

-- uci get openvpn.omr.port
function M.getRemotePort(params)
    local c = uci.cursor()
    return c:get('openvpn', 'omr', 'port')
end

-- tun0 mask
function M.getVirtualNet(params)
    local interface = getTunnelDevice()
    return getInterfaceMask(interface)
end

-- get interface tun0 ip
function M.getLocalIP(params)
    local interface = getTunnelDevice()
    return getInterfaceIP(interface)
end

-- get interface tun0 port
function M.getLocalPort(params)
    -- -- ss -tnp | grep openvpn | awk '{print $4}' | awk -F':' '{print $2}'
    -- local cmd = string.format("ss -tnp | grep openvpn | awk '{print $4}' | awk -F':' '{print $2}'")
    -- -- log.info(cmd)
    -- return exec(cmd)
    return 0
end

function M.getSubnet(params)
    local c = uci.cursor()
    local ip = c:get('network', 'lan', 'ipaddr')
    local mask = c:get('network', 'lan', 'netmask')
    local addr = string.format("%s / %s", ip, mask)
    return addr     -- "192.168.100.1/255.255.255.0"
end

function M.getTransBytes(params)
    local dev = getTunnelDevice()
    local cmd = string.format("ifconfig %s | grep 'TX bytes' | awk '{print $6}' | cut -d':' -f2", dev)
    local tx = exec(cmd)
    cmd = string.format("ifconfig %s | grep 'TX bytes' | awk '{print $2}' | cut -d':' -f2", dev)
    local rx = exec(cmd)
    return {
            tx_bytes = tx, 
            rx_bytes = rx
        }
end

function M.getStatusConnectStatus()
    
    connectStatus = {
        dead = 'openvpnDead',                           -- openvpnDead  - 进程未启动;
        broken = 'openvpnBroken',                       -- openvpnBroken - 未连接;
        normal = 'openvpnNormal',                       -- openvpnNormal - 正常
        unknown = 'openvpnUnknownStatus',               -- 未知状态,用于调试
    }

    -- 进程是否存在(mqvpn 模式下进程名为 mqvpn)
    local c = uci.cursor()
    local proc = c:get('openmptcprouter', 'settings', 'vpn') == 'mqvpn' and 'mqvpn' or 'openvpn'
    local cmd = "pidof " .. proc
    local pid = exec(cmd)
    if nil == pid or ' ' == pid then
        return connectStatus.dead
    end

    -- 接口是否存在,接口存在说明连接正常
    cmd = string.format("ls /sys/class/net/ | grep %s", getTunnelDevice())
    local exist = exec(cmd)
    if nil == exist or ' ' == exist then
        return connectStatus.broken
    else
        return connectStatus.normal
    end

    return connectStatus.unknown
end

function M.getStatusRTT()

    local local_ip = getInterfaceIP(getTunnelDevice())
    if nil == local_ip or ' ' == local_ip then
        return 0
    end

    local remote_ip = '10.255.252.1'
    local cmd = string.format("ping -W 2 -c 1 -I %s %s | awk -F'/' 'END {print $5}' | tr -d '\n'", local_ip, remote_ip)
    local rtt_ms = exec(cmd)
    log.info('cmd: ', cmd)
    log.info('rtt_ms ', rtt_ms)
    if nil == rtt_ms or ' ' == rtt_ms then
        return 9999
    end

    return tonumber(rtt_ms)
end

return M
