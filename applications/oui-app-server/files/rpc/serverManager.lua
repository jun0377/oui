local M = {}
local uci = require 'eco.uci'
local util = require 'luci.util'
-- local nixio = require 'nixio'
-- local sys = require 'luci.sys'
-- local socket = require 'socket'


-- 服务器状态枚举
-- local ServerStatus = {
--     -- 未知
--     ServerStatusUnknown = 'Server Status Unknown',
--     -- 未设置服务器
--     ServerNotChoose = 'Server Not Choose',
--     -- 等待拨号成功,没有可用的路由
--     ServerNoRoute = 'No Route to Server',
--     -- 服务器不存在
--     ServerNotExist = 'Server Not Exist',
--     -- 服务器主机存在，但是服务进程不存在
--     ServerProcNotExist = 'Server Porc Not Exist',
--     -- 正在建立连接
--     ServerConnectiong = 'Server Connecting',
--     -- 连接被拒绝
--     ServerConnectNotAllow = 'Server Connect Not Allow',
--     -- 连接成功
--     ServerConnected = 'Server Connected',
-- }

local function ping(src, dst)

    local result = { reachable = false, rtt_ms = 0, packet_loss = 0}
    if nil == dst then
        return result
    end

    local ping_cmd = 'ping '
    if nil ~= src then
        ping_cmd = ping_cmd .. '-I ' .. src
    end

    ping_cmd = ping_cmd .. ' ' .. dst .. ' -c 3'

    -- print(ping_cmd)

    ping_state = exec(ping_cmd)

    if nil == ping_state then
        return result
    end

    -- print(ping_state)
    local packet_loss = string.match(ping_state, "(%d+)%% packet loss")
    -- print(packet_loss)
    if packet_loss then
        result.packet_loss = tonumber(packet_loss)
        result.reachable = result.packet_loss < 100
    end

    local rttmin, rtt_avg, rtt_max, rtt_mdev = string.match(ping_state, "min/avg/max/mdev = ([%d%.]+)/([%d%.]+)/([%d%.]+)/([%d%.]+) ms")
    -- print(rtt_avg)
    if rtt_avg then
        result.rtt_ms = tonumber(rtt_avg)
    end

    -- print('result.require=', result.reachable, ' result.rtt_ms=', result.rtt_ms, ' result.packet_loss=', result.packet_loss)
    return result
end

-- 服务器连接状态


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

-- 检查TCP连接
-- function M.checkTcpConnection(ip, port)
--     if not ip or not port then
--         return {connected = false, time = 0, error = "Missing IP or port"}
--     end
    
--     local tcp_stats = {}
--     local start_time = socket.gettime()
    
--     -- 创建TCP连接
--     local tcp = socket.tcp()
--     tcp:settimeout(3) -- 3秒超时
    
--     -- 尝试连接
--     local success, err = tcp:connect(ip, tonumber(port))
--     local end_time = socket.gettime()
    
--     -- 计算连接时间
--     tcp_stats.time = math.floor((end_time - start_time) * 1000) -- 毫秒
    
--     if success then
--         tcp_stats.connected = true
--         tcp_stats.error = nil
--         tcp:close()
--     else
--         tcp_stats.connected = false
--         tcp_stats.error = err or "Unknown error"
--     end
    
--     return tcp_stats
-- end

-- 一键检测服务器连接状态
-- function M.checkServerConnection()
--     local result = {}
    
--     -- 获取服务器IP和端口
--     result.ip = M.getServerIP()
--     result.port = M.getServerPort()
    
--     -- 如果没有设置IP，直接返回未配置状态
--     if not result.ip or result.ip == "" then
--         result.status = ServerStatus.ServerNotExist
--         result.connected = false
--         return result
--     end
    
--     -- 检查ping连通性
--     result.ping = M.pingServerIP()
    
--     -- 如果ping不通，返回无路由状态
--     if not result.ping.reachable then
--         result.status = ServerStatus.ServerNoRoute
--         result.connected = false
--         return result
--     end
    
--     -- 检查TCP连接
--     if not result.port or result.port == "" then
--         result.port = "22" -- 默认使用SSH端口
--     end
    
--     result.tcp = M.checkTcpConnection(result.ip, result.port)
    
--     -- 根据TCP连接结果设置状态
--     if not result.tcp.connected then
--         result.status = ServerStatus.ServerProcNotExist
--         result.connected = false
--     else
--         result.status = ServerStatus.ServerConnected
--         result.connected = true
--     end
    
--     return result
-- end

return M
