local M = {}
local uci = require 'eco.uci'
-- local nixio = require 'nixio'
-- local sys = require 'luci.sys'
-- local socket = require 'socket'


-- 服务器状态枚举
local ServerStatus = {
    -- 未知
    ServerStatusUnknown = 'Server Status Unknown',
    -- 未设置服务器
    ServerNotChoose = 'Server Not Choose',
    -- 等待拨号成功,没有可用的路由
    ServerNoRoute = 'No Route to Server',
    -- 服务器不存在
    ServerNotExist = 'Server Not Exist',
    -- 服务器主机存在，但是服务进程不存在
    ServerProcNotExist = 'Server Porc Not Exist',
    -- 正在建立连接
    ServerConnectiong = 'Server Connecting',
    -- 连接被拒绝
    ServerConnectNotAllow = 'Server Connect Not Allow',
    -- 连接成功
    ServerConnected = 'Server Connected',
}

-- local function ping(src_ip, dst_ip)
    
--     local ping_stats = { reachable=false, rtt_ms=0 }

--     if not dst_ip then
--         return ping_stats
--     end
    
--     local ping_cmd = "ping -c 3 -W 3"
    
--     -- 如果指定了源IP，添加源IP参数
--     if src_ip then
--         ping_cmd = ping_cmd .. " -I " .. src_ip
--     end
    
--     -- 目的IP
--     ping_cmd = ping_cmd .. " " .. dst_ip
--     local ping_output = sys.exec(ping_cmd)
    
--     -- 解析ping结果
--     ping_stats.reachable = (ping_output:match("0%% packet loss") ~= nil)

--     -- 提取往返时间
--     local rtt = ping_output:match("min/avg/max/mdev = ([%d%.]+)/([%d%.]+)/([%d%.]+)/([%d%.]+)")
--     ping_stats.rtt_ms = rtt and tonumber(rtt) or 0
--     return ping_stats
-- end

-- 服务器连接状态
-- function M.getServerConnectStatus()

--     local server = {
--         status = ServerStatusUnknown,
--         connected = false,
--         serverIP = nil,
--         ping = {
--                 reachable = false,
--                 time = 0,
--             }
--     }

--     -- 获取服务器IP
--     local serverIP = M.getServerIP()

--     -- 未设置服务器
--     if not serverIP or serverIP == "" then
--         server.status = ServerNotChoose
--         return status
--     end
    
--     -- 检查是否可以ping通
--     server.ping = M.ping(nil, serverIP)
--     if not server.ping.reachable then
--         server.status = ServerStatus.ServerNoRoute
--         return server
--     end
    
--     -- 检查端口是否开放
--     -- $ nc -z -v 192.168.10.150 1-1000
--     -- 192.168.10.150 [192.168.10.150] 22 (ssh) open
--     -- 192.168.10.150 [192.168.10.150] 139 (netbios-ssn) open
--     -- 192.168.10.150 [192.168.10.150] 445 (microsoft-ds) open
    
--     -- 检查VPN隧道是否建立


    
--     return server

-- end

-- uci get openmptcprouter.vps.ip
function M.getServerIP()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'ip')
end

-- uci set openmptcprouter.vps.ip=xxx.xxx.xxx.xxx
function M.setServerIP(ip)
    local c = uci.cursor()
    c:set('openmptcprouter', 'vps', 'ip', ip)
    return c:commit('openmptcprouter')
end

-- uci get openmptcprouter.vps.port
function M.getServerPort()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'port')
end

-- uci set openmptcprouter.vps.port=xxx
function M.setServerPort(port)
    local c = uci.cursor()
    c:set('openmptcprouter', 'vps', 'port', port)
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
