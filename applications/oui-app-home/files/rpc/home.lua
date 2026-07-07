local M = {}

local uci = require 'eco.uci'
local ubus = require 'eco.ubus'
local cjson = require 'cjson'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/home.log'

local function exec(command)
    local pp = io.popen(command)
    if not pp then
        return ''
    end
    local data = pp:read('*a') or ''
    pp:close()
    return data
end

-- 获取单卡模式设置
local function workModeSingleSettings()
    
    local c = uci.cursor()
    local channel = c:get('global', 'single', 'channel')
    local l3_device = 'N/A'
    if channel and channel ~= '' then
        local status = ubus.call(string.format('network.interface.%s', channel), 'status', {})
        if status then
            l3_device = status.l3_device or status.device or l3_device
        end
    end

    -- 兜底: 从 tracker-sim 文件中获取接口名
    if channel and channel ~= '' and l3_device == 'N/A' then
        local f = io.open(string.format('/tmp/tracker-sim/%s/interface', channel), 'r')
        if f then
            local dev = f:read('*a')
            f:close()
            if dev then
                dev = dev:gsub('[\r\n]', '')
                if dev ~= '' then
                    l3_device = dev
                end
            end
        end
    end

    return {
        channel = channel,
        ifname = l3_device
    }

end

-- 获取聚合模式设置
local function workModeAggregateSettings()

    local c = uci.cursor()
    local vps_ip = c:get('openmptcprouter', 'vps', 'ip')
    local vps_port = c:get('openmptcprouter', 'vps', 'port')

    return {
        vps_ip = vps_ip,
        vps_port = vps_port,
    }

end

-- 获取负载均衡模式设置
local function workModeBalanceSettings()
    return {
        detail = '多链路按权重分流'
    }
end

-- 工作模式配置信息
function M.workModeSettings()
    local c = uci.cursor()
    
    -- 从UCI配置文件/etc/config/global获取工作模式
    local mode = c:get('global', 'global', 'mode')
    local handlers = {
        single = workModeSingleSettings,
        aggregate = workModeAggregateSettings,
        balance = workModeBalanceSettings
    }
    local getSettings = handlers[mode]
    local settings = getSettings()
    local ret  = { mode = mode, settings = settings }
    local ok, payload = pcall(cjson.encode, ret)
    if ok then
        log.info('home.workModeSettings ', payload)
    else
        log.err('home.workModeSettings encode failed: ', tostring(payload))
    end

    return ret
end

-- 管理平台连通性
function M.getServerStatus()
    local path = '/tmp/tracker-server/tracker-server.json'
    local ret = {
        status = 'ERROR',
        msg = 'tracker status file not found',
        ts = 0
    }

    local file = io.open(path, 'r')
    if not file then
        log.error('home.getServerStatus open failed: ', path)
        return ret
    end

    local content = file:read('*a')
    file:close()

    if not content or content == '' then
        ret.msg = 'tracker status file is empty'
        log.err('home.getServerStatus empty file: ', path)
        return ret
    end

    local ok, data = pcall(cjson.decode, content)
    if not ok or type(data) ~= 'table' then
        ret.msg = 'tracker status file decode failed'
        log.err('home.getServerStatus decode failed: ', tostring(data))
        return ret
    end

    -- 连接状态: OK / ERROR
    ret.status = tostring(data.status or ret.status)
    -- 异常信息
    ret.msg = tostring(data.msg or '')
    -- 时间戳
    ret.ts = tonumber(data.ts) or 0

    return ret
end

-- 获取OpenVPN组网状态
function M.getOpenVPNStatus()
    local rx_path = '/sys/class/net/tun0/statistics/rx_bytes'
    local tx_path = '/sys/class/net/tun0/statistics/tx_bytes'
    local ret = {
        running = false,
        connected = false,
        updated = '',
        rx_bytes = 0,
        tx_bytes = 0,
        msg = 'OpenVPN process not running'
    }

    -- 检查进程是否存在
    local pid = exec([[pgrep -f "openvpn.*omr|openvpn.*--config.*omr" 2>/dev/null | head -n 1]])
    ret.running = pid ~= nil and pid:match('%S') ~= nil

    -- 读取上下行数据量
    local function read_stat(path)
        local file = io.open(path, 'r')
        if not file then
            return nil
        end
        local value = file:read('*a')
        file:close()
        return tonumber((value or ''):match('%d+'))
    end

    local rx_bytes = read_stat(rx_path)
    local tx_bytes = read_stat(tx_path)
    if rx_bytes ~= nil then
        ret.rx_bytes = rx_bytes
    end
    if tx_bytes ~= nil then
        ret.tx_bytes = tx_bytes
    end
    if rx_bytes ~= nil or tx_bytes ~= nil then
        ret.updated = os.date('%Y-%m-%d %H:%M:%S')
    end

    if ret.running and rx_bytes ~= nil and tx_bytes ~= nil then
        ret.connected = true
        ret.msg = 'OpenVPN connected'
    elseif ret.running then
        ret.msg = 'OpenVPN is running but connect failed'
    else
        ret.msg = 'OpenVPN process not running'
    end

    return ret
end

-- 获取DNS解析状态
function M.getDNSStatus()
    local path = '/tmp/tracker-dns/tracker-dns.json'
    local ret = {
        running = false,
        resolved = false,
        resolver = '',
        query = 'openwrt.org',
        answer = '',
        updated = os.date('%Y-%m-%d %H:%M:%S'),
        msg = 'DNS service not running'
    }

    local file = io.open(path, 'r')
    if not file then
        log.err('home.getDNSStatus open failed: ', path)
        return ret
    end
    
    local content = file:read('*a')
    file:close()

    if not content or content == '' then
        log.err('home.getDNSStatus empty file: ', path)
        return ret
    end

    local ok, data = pcall(cjson.decode, content)
    if not ok or type(data) ~= 'table' then
        log.err('home.getDNSStatus decode failed: ', tostring(data))
        return ret
    end

    ret.running = data.running == true
    ret.resolved = data.resolved == true
    ret.resolver = tostring(data.resolver or '')
    ret.query = tostring(data.query or ret.query)
    ret.answer = tostring(data.answer or '')
    ret.updated = tostring(data.updated or ret.updated)
    ret.msg = tostring(data.msg or ret.msg)

    return ret
end

return M
