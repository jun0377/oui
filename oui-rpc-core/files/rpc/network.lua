-- 模块的导出表
local M = {}

local ubus = require 'eco.ubus'
local file = require 'eco.file'
local uci = require 'eco.uci'

-- DHCP 租约管理
function M.dhcp_leases()
    -- 创建UCI配置系统游标，用于读取系统配置
    local c = uci.cursor()
    -- 初始化空的租约数组，用于存储解析后的租约信息
    local leases = {}
    -- 从UCI配置中获取dnsmasq的租约文件路径，如果未配置则使用默认路径
    local leasefile = c:get('dhcp', '@dnsmasq[0]', 'leasefile') or '/tmp/dhcp.leases'

    -- 检查租约文件是否存在且可访问
    if not file.access(leasefile) then
        -- 如果文件不存在，返回空的租约列表
        return { leases = leases }
    end

    -- 获取当前Unix时间戳（秒），用于计算租约剩余时间
    local now = os.time()

    -- 逐行读取租约文件内容
    for line in io.lines(leasefile) do
        -- 使用正则表达式解析每行的租约信息：时间戳 MAC地址 IP地址 主机名
        local ts, mac, addr, name = line:match("(%S+) +(%S+) +(%S+) +(%S+)")
        -- 声明过期时间变量
        local expire

        -- 将字符串格式的时间戳转换为数字
        ts = tonumber(ts)

        -- 根据时间戳计算租约过期状态
        -- 租约未过期：计算剩余秒数
        if ts > now then
            expire = ts - now
        -- 租约已过期但曾经有效：标记为已过期
        elseif ts > 0 then
            expire = 0
        -- 永久租约（时间戳为0）：标记为永不过期
        else
            expire = -1
        end

        -- 将解析的租约信息添加到数组中
        leases[#leases + 1] = {
            ipaddr = addr,
            macaddr = mac,
            hostname = name,
            expire = expire
        }
    end

    -- 返回包含所有租约信息的标准化数据结构
    return { leases = leases }
end

-- 网络接口管理
local function get_networks()
    local status = ubus.call('network.interface', 'dump', {})
    return status.interface
end

-- 根据路由目标和掩码过滤网络接口
local function get_networks_by_route(target, mask)
    local networks = get_networks()
    local r = {}

    for _, network in ipairs(networks) do
        for _, route in ipairs(network.route or {}) do
            if route.target == target and route.mask == mask then
                r[#r + 1] = network
                break
            end
        end
    end

    return r
end

-- 获取所有网络接口
function M.get_networks()
    return { networks = get_networks() }
end

-- 获取 IPv4 WAN 接口
function M.get_wan_networks()
    return { networks = get_networks_by_route('0.0.0.0', 0) }
end

-- 获取 IPv6 WAN 接口
function M.get_wan6_networks()
    return { networks = get_networks_by_route('::', 0) }
end

return M
