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
    local c = uci.cursor()
    local interface = c:get('openvpn', 'omr', 'dev')               -- uci get openvpn.omr.dev
    return getInterfaceMask(interface)
end

-- get interface tun0 ip
function M.getLocalIP(params)
    local c = uci.cursor()
    local interface = c:get('openvpn', 'omr', 'dev')               -- uci get openvpn.omr.dev
    return getInterfaceIP(interface)
end

-- get interface tun0 port
function M.getLocalPort(prams)
    -- ss -tnp | grep openvpn | awk '{print $4}' | awk -F':' '{print $2}'
    local cmd = string.format("ss -tnp | grep openvpn | awk '{print $4}' | awk -F':' '{print $2}'")
    -- log.info(cmd)
    return exec(cmd)
end

return M
