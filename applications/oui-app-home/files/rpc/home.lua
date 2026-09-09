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

    -- 检查进程是否存在（[o] 防止 grep 匹配自身，ps w 显示完整命令行）
    local pid = exec([[ps w | grep -E "[o]penvpn.*omr" | grep -v grep | awk '{print $1}' | head -n 1]])
    pid = pid:gsub('[\r\n]', '')
    ret.running = pid ~= ''

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

-- ==================== 网络接口状态聚合(方案B) ====================
-- 将首页"网络接口状态"原本的 1 次 getAvailWan + 每链路多次 RPC,
-- 收敛为一次 RPC; 后端全程进程内取数(eco.uci / eco.ubus / io.open),
-- 不再在单线程 httpd 内产生阻塞性 io.popen 子进程。

local function trim_str(s)
    if s == nil then
        return ''
    end
    return tostring(s):gsub('^%s+', ''):gsub('%s+$', '')
end

-- 读取文件内容并去除行尾换行
local function read_file(path)
    local f = io.open(path, 'r')
    if not f then
        return ''
    end
    local data = f:read('*a')
    f:close()
    if not data then
        return ''
    end
    return data:gsub('[\r\n]', '')
end

-- 读取 /tmp/tracker-sim/<ifname>/<fname>
local function read_sim_file(ifname, fname)
    return read_file(string.format('/tmp/tracker-sim/%s/%s', ifname, fname))
end

-- 子网前缀 -> 点分掩码 (24 -> 255.255.255.0)
local function mask_from_prefix(prefix)
    local n = tonumber(prefix)
    if not n or n < 0 or n > 32 then
        return ''
    end
    local parts = {}
    for i = 1, 4 do
        local bits = n >= 8 and 8 or (n > 0 and n or 0)
        parts[i] = tostring((0xff << (8 - bits)) & 0xff)
        n = n - bits
    end
    return table.concat(parts, '.')
end

-- 查询 netifd 接口状态(进程内 ubus, 非阻塞)
local function netifd_status(ifname)
    local ok, status = pcall(ubus.call, string.format('network.interface.%s', ifname), 'status', {})
    if not ok or type(status) ~= 'table' then
        return nil
    end
    return status
end

-- 从 netifd 状态解析默认网关, 兜底取 uci 静态配置的 gateway
local function resolve_gateway(status, ifname)
    if type(status) == 'table' and type(status.route) == 'table' then
        for _, r in ipairs(status.route) do
            if type(r) == 'table' and r.target == '0.0.0.0' then
                local gw = trim_str(r.nexthop)
                if gw ~= '' and gw ~= '0.0.0.0' then
                    return gw
                end
            end
        end
    end

    if ifname and ifname ~= '' then
        local c = uci.cursor()
        local gw = trim_str(c:get('network', ifname, 'gateway'))
        if gw ~= '' then
            return gw
        end
    end
    return ''
end

-- 聚合单个接口的运行状态(基于 netifd + sysfs, 不产生子进程)
local function collect_iface_status(ifname, cfgdev)
    local status = netifd_status(ifname)
    local dev, ip, mask = '', '', ''
    local up = false
    local code = -1

    if status then
        code = 0
        up = status.up == true
        dev = trim_str(status.l3_device)
        if dev == '' then
            dev = trim_str(status.device)
        end
        if type(status['ipv4-address']) == 'table' then
            for _, a in ipairs(status['ipv4-address']) do
                if type(a) == 'table' then
                    local addr = trim_str(a.address)
                    if addr ~= '' and addr ~= '0.0.0.0' then
                        ip = addr
                        mask = mask_from_prefix(a.mask)
                        break
                    end
                end
            end
        end
    end

    if dev == '' then
        dev = trim_str(cfgdev)
    end

    local rxBytes, txBytes = '', ''
    if dev ~= '' then
        rxBytes = read_file(string.format('/sys/class/net/%s/statistics/rx_bytes', dev))
        txBytes = read_file(string.format('/sys/class/net/%s/statistics/tx_bytes', dev))
    end

    return {
        code = code,
        interface = dev,
        up = up,
        ip = ip,
        mask = mask,
        gateway = resolve_gateway(status, ifname),
        rxBytes = rxBytes,
        txBytes = txBytes
    }
end

-- 读取 uci sim 段全部 option(等价于 sim.getSimUciSettings)
local function sim_section_values(ifname)
    local values = {}
    local c = uci.cursor()
    local sec = c:get_all('sim', ifname)
    if type(sec) == 'table' then
        for k, v in pairs(sec) do
            if k:sub(1, 1) ~= '.' then
                values[k] = v
            end
        end
    end
    return values
end

-- 读取 plmn json, 返回 country / mcc / mnc / operator(等价于 sim.readPlmnInfo)
local function read_sim_plmn(ifname)
    local country, mcc, mnc, operator = '', '', '', ''
    local data = read_sim_file(ifname, 'plmn')
    if data ~= '' then
        local ok, plmn = pcall(cjson.decode, data)
        if ok and type(plmn) == 'table' then
            country = trim_str(plmn.country)
            local p = plmn.plmn
            if type(p) == 'string' and p ~= '' then
                if #p >= 3 then mcc = p:sub(1, 3) end
                if #p >= 5 then mnc = p:sub(4) end
            end
            operator = trim_str(plmn.long_name)
        end
    end
    return country, mcc, mnc, operator
end

-- 通过ICCID前6位(IIN)反推运营商, 仅限中国大陆(与 sim.lua 保持一致)
local sim_iin_map = {
    ['898600'] = '中国移动', ['898602'] = '中国移动',
    ['898604'] = '中国移动', ['898607'] = '中国移动',
    ['898601'] = '中国联通', ['898606'] = '中国联通',
    ['898609'] = '中国联通',
    ['898603'] = '中国电信', ['898611'] = '中国电信',
    ['898615'] = '中国广电',
}
local function operator_from_iccid(iccid)
    if type(iccid) ~= 'string' or #iccid < 6 then
        return '', ''
    end
    local operator = sim_iin_map[iccid:sub(1, 6)]
    if operator then
        return operator, 'CN'
    end
    return '', ''
end

-- 仅保留合法 JSON 文本(与 sim.getStatus 中 jsonval 语义一致), 其余置 null
local function to_json_value(raw)
    local head = raw:match('^%s*(%S)')
    if head == '{' or head == '[' then
        local ok, obj = pcall(cjson.decode, raw)
        if ok then
            return obj
        end
    end
    return cjson.null
end

-- 聚合 sim 链路(等价于 sim.getSimUciSettings + getInterfaceStatus + getStatus + getProductInfo)
local function collect_sim_link(name)
    local tracker_dev = read_sim_file(name, 'interface')
    local runtime = collect_iface_status(name, tracker_dev)
    local dev = tracker_dev
    if dev == '' then
        dev = runtime.interface
    end

    local settings = sim_section_values(name)

    -- 模组是否被系统识别: 通过 sysfs 目录检查
    -- 有的设备可能未安装模组或模组未上电
    -- root@MP-Router:~# uci get sim.sim1.usb
    -- /sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1
    -- root@MP-Router:~# ls /sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1
    -- ls: /sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1: No such file or directory
    local moduleExist = false
    local usb = trim_str(settings.usb)
    if usb ~= '' then
        local f = io.open(usb, 'r')
        if f then
            f:close()
            moduleExist = true
        end
    end

    -- 产品信息(等价于 sim.getProductInfo)
    local product = {
        vendor = read_sim_file(name, 'vendor'),
        product = read_sim_file(name, 'model'),
        revision = read_sim_file(name, 'revision'),
        imei = read_sim_file(name, 'imei'),
        iccid = read_sim_file(name, 'iccid'),
        imsi = read_sim_file(name, 'imsi')
    }

    -- 实时状态(等价于 sim.getStatus)
    local country, mcc, mnc, operator = read_sim_plmn(name)
    if operator == '' then
        operator, country = operator_from_iccid(product.iccid)
    end
    local simStatus = {
        timestamp = read_sim_file(name, 'timestamp'),
        now = os.date('%Y-%m-%d %H:%M:%S'),
        sim = read_sim_file(name, 'sim_status'),
        country = country,
        mcc = mcc,
        mnc = mnc,
        operator_name = operator,
        freqInfo = to_json_value(read_sim_file(name, 'freq')),
        C5GCore = to_json_value(read_sim_file(name, 'C5GREG')),
        C4GCore = to_json_value(read_sim_file(name, 'CLTEREG')),
        monsc = to_json_value(read_sim_file(name, 'monsc')),
        monnc = to_json_value(read_sim_file(name, 'monnc')),
        hcsq = to_json_value(read_sim_file(name, 'hcsq'))
    }

    return {
        kind = 'sim',
        name = name,
        device = dev,
        moduleExist = moduleExist,
        settings = settings,
        product = product,
        simStatus = simStatus,
        status = runtime
    }
end

-- 聚合 wan 链路(字段对齐 wan.getWanState)
local function collect_wan_link(name, cfgdev)
    local runtime = collect_iface_status(name, cfgdev)
    runtime.status = (runtime.code == 0 and runtime.ip ~= '' and runtime.ip ~= '-') and '正常' or '-'
    return {
        kind = 'wan',
        name = name,
        device = runtime.interface,
        status = runtime
    }
end

-- 枚举 /etc/config/network 的逻辑接口并聚合运行状态, 一次返回全部链路
function M.getInterfaceOverview()
    local c = uci.cursor()
    local all = c:get_all('network') or {}
    local wan_links, sim_links = {}, {}

    for section, s in pairs(all) do
        if type(s) == 'table' and s['.type'] == 'interface' then
            local name = s['.name'] or section
            if name and name ~= '' then
                local proto = trim_str(s.proto)
                if proto ~= '' and proto ~= 'none' then
                    local cfgdev = trim_str(s.device)
                    if cfgdev == '' then
                        cfgdev = trim_str(s.ifname)
                    end

                    local simn = name:match('^sim(%d+)$')
                    if simn then
                        sim_links[#sim_links + 1] = collect_sim_link(name)
                    else
                        local wann = name:match('^wan(%d+)$')
                        if wann or name == 'wan' then
                            wan_links[#wan_links + 1] = collect_wan_link(name, cfgdev)
                        end
                    end
                end
            end
        end
    end

    table.sort(wan_links, function(a, b)
        local ai = tonumber((a.name):match('^wan(%d+)$')) or 0
        local bi = tonumber((b.name):match('^wan(%d+)$')) or 0
        return ai < bi
    end)
    table.sort(sim_links, function(a, b)
        local ai = tonumber((a.name):match('^sim(%d+)$')) or 0
        local bi = tonumber((b.name):match('^sim(%d+)$')) or 0
        return ai < bi
    end)

    local links = {}
    for _, l in ipairs(wan_links) do
        links[#links + 1] = l
    end
    for _, l in ipairs(sim_links) do
        links[#links + 1] = l
    end

    return { code = 0, links = links }
end

return M
