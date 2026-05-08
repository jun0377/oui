local M = {}
local log = require 'log'
local uci = require 'eco.uci'
local cjson = require 'cjson'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/wan.log'

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    return data
end

local function trim(s)
    if s == nil then
        return ''
    end
    return tostring(s):gsub('^%s+', ''):gsub('%s+$', '')
end

local function read_first_line(path)
    local f = io.open(path, 'r')
    if not f then
        return nil
    end
    local line = f:read('*l')
    f:close()
    return line
end

local function is_udhcpc_running(iface)
    local out = exec(string.format("ps w 2>/dev/null | grep '[u]dhcpc' | grep ' -i %s' | head -n 1", iface))
    return out and out:match('%S') ~= nil
end

local function derive_wan_status(c, section, iface, ifconfig_out, ip)
    local sec = trim(section)
    if sec ~= '' then
        local auto = c:get('network', sec, 'auto')
        if auto ~= nil and tostring(auto) == '0' then
            return '禁用'
        end
    end

    local carrier = read_first_line('/sys/class/net/' .. iface .. '/carrier')
    carrier = carrier ~= nil and trim(carrier) or ''
    local link_up
    if carrier == '0' then
        link_up = false
    elseif carrier == '1' then
        link_up = true
    else
        link_up = ifconfig_out:find('%f[%w]RUNNING%f[%W]') ~= nil
    end

    if link_up == false then
        return '网线未接入'
    end

    local has_ip = type(ip) == 'string' and ip ~= '' and ip ~= '-' and ip:match('^%d+%.%d+%.%d+%.%d+$') ~= nil
    if has_ip then
        return '正常'
    end

    local proto = sec ~= '' and c:get('network', sec, 'proto') or nil
    proto = trim(proto):lower()
    if proto == '' then
        proto = 'dhcp'
    end

    if proto == 'static' then
        return '获取IP失败'
    end

    if is_udhcpc_running(iface) then
        return '正在获取IP'
    end

    if ifconfig_out:find('%f[%w]UP%f[%W]') ~= nil then
        return '获取IP失败'
    end

    return '已启用'
end

-- 获取指定网口的状态: 
function M.getWanState(params)
    if type(params) ~= 'table' then
        log.error('getWanState params error!', params)
        return { code = -1, msg = 'params error' }
    end

    local iface = type(params.interface) == 'string' and params.interface or ''
    iface = iface:gsub('^%s+', ''):gsub('%s+$', '')
    if iface == '' then
        log.error('getWanState interface missing')
        return { code = -1, msg = 'interface missing' }
    end
    if not iface:match('^[%w_%.:%-]+$') then
        log.error('getWanState unsafe interface:', iface)
        return { code = -1, msg = 'unsafe interface' }
    end

    local out = exec(string.format('ifconfig %s 2>/dev/null', iface))
    if not out or out == '' then
        return { code = -1, msg = 'interface not found' }
    end

    local mac = out:match('HWaddr%s+([%x:]+)') or out:match('ether%s+([%x:]+)') or '-'
    local ip = out:match('inet addr:([%d%.]+)') or out:match('inet%s+addr:([%d%.]+)') or out:match('inet%s+([%d%.]+)') or '-'
    local mask = out:match('Mask:([%d%.]+)') or out:match('netmask%s+([%d%.]+)') or '-'
    local rxBytes = out:match('RX bytes:(%d+)') or '-'
    local txBytes = out:match('TX bytes:(%d+)') or '-'

    local section = type(params.section) == 'string' and params.section or ''
    section = section:gsub('^%s+', ''):gsub('%s+$', '')

    local c = uci.cursor()
    if section == '' then
        local all = c:get_all('network') or {}
        for sname, s in pairs(all) do
            if type(s) == 'table' and s['.type'] == 'interface' then
                local dev = s.device or s.ifname or ''
                if dev == iface then
                    section = s['.name'] or sname
                    break
                end
            end
        end
    end

    -- 网口的几种状态: 禁用 / 已启用 / 正常 / 网线未接入 / 正在获取IP / 获取IP失败
    local status = derive_wan_status(c, section, iface, out, ip)

    local gateway = '-'
    local ip4table = section ~= '' and c:get('network', section, 'ip4table') or nil
    if ip4table ~= nil then
        ip4table = trim(ip4table)
        if ip4table == '' then
            ip4table = nil
        end
    end

    if ip4table and ip4table:match('^%d+$') then
        local routeOut = exec(string.format("ip route show table %s 2>/dev/null | grep '^default ' | awk '{for(i=1;i<=NF;i++) if($i==\"via\"){print $(i+1); exit}}' | head -n 1 | tr -d '\\r\\n'", ip4table))
        if routeOut and routeOut ~= '' then
            gateway = routeOut
        end
    end

    if gateway == '-' and section ~= '' then
        local gw = c:get('network', section, 'gateway')
        if gw ~= nil then
            gw = trim(gw)
            if gw ~= '' then
                gateway = gw
            end
        end
    end

    if gateway == '-' then
        local routeOut = exec(string.format("ip route show default 2>/dev/null | grep ' dev %s' | awk '{print $3}' | head -n 1 | tr -d '\\r\\n'", iface))
        if routeOut and routeOut ~= '' then
            gateway = routeOut
        end
    end

    return {
        code = 0,
        interface = iface,
        section = section,
        status = status,
        ip = ip,
        mask = mask,
        gateway = gateway,
        mac = mac,
        rxBytes = rxBytes,
        txBytes = txBytes
    }
end

-- 保存配置并应用
function M.setWanConf(params)
    if type(params) ~= 'table' then
        log.error('setWanConf params error!', params)
        return { code = -1, msg = 'params error' }
    end

    local section = type(params.section) == 'string' and params.section or ''
    section = section:gsub('^%s+', ''):gsub('%s+$', '')
    if section == '' then
        log.error('setWanConf section missing')
        return { code = -1, msg = 'section missing' }
    end

    local proto = params.proto
    if proto == nil then
        proto = ''
    else
        proto = tostring(proto):gsub('^%s+', ''):gsub('%s+$', ''):lower()
    end
    if proto == 'dhcp' or proto == 'DHCP' then
        proto = 'dhcp'
    elseif proto == 'static' or proto == 'STATIC' then
        proto = 'static'
    else
        proto = proto == '' and 'dhcp' or proto
    end

    local ipaddr = params.ipaddr == nil and '' or tostring(params.ipaddr):gsub('^%s+', ''):gsub('%s+$', '')
    local netmask = params.netmask == nil and '' or tostring(params.netmask):gsub('^%s+', ''):gsub('%s+$', '')
    local gateway = params.gateway == nil and '' or tostring(params.gateway):gsub('^%s+', ''):gsub('%s+$', '')

    local enable = params.enable
    if enable ~= nil then
        enable = not not enable
    end

    local c = uci.cursor()
    c:set('network', section, 'proto', proto)
    if enable ~= nil then
        c:set('network', section, 'auto', enable and '1' or '0')
    end
    if proto == 'static' then
        c:set('network', section, 'ipaddr', ipaddr)
        c:set('network', section, 'netmask', netmask)
        c:set('network', section, 'gateway', gateway)
        log.info(section, proto, 'ip:', ipaddr, 'mask:', netmask, 'gateway:', gateway)
    else
        c:set('network', section, 'ipaddr', '')
        c:set('network', section, 'netmask', '')
        c:set('network', section, 'gateway', '')
        log.info(section, proto)
    end
    c:commit('network')

    if section:match('^[%w_%-]+$') then
        exec(string.format('ifdown %s 2>/dev/null', section))
        exec(string.format('ifup %s 2>/dev/null', section))
    else
        log.error('setWanConf unsafe section:', section)
    end

    return { code = 0 }
end

-- 获取指定网口的协议: 静态IP or DHCP
function M.getWanProto(params)
    local section
    if type(params) == 'table' and type(params.section) == 'string' and params.section ~= '' then
        section = params.section
        log.info('params.section', section)
    else
        log.error('params error!', params)
        return
    end

    local c = uci.cursor()
    local proto = c:get('network', section, 'proto')
    if proto == nil then
        proto = ''
        log.error(section, 'proto is nil!')
    else
        proto = tostring(proto):gsub('^%s+', ''):gsub('%s+$', ''):lower()
    end

    log.info(section, 'proto is', proto)
    if proto == 'static' then
        local interface = c:get('network', section, 'device')
        local ipaddr = c:get('network', section, 'ipaddr')
        local netmask = c:get('network', section, 'netmask')
        local gateway = c:get('network', section, 'gateway')

        ipaddr = ipaddr == nil and '' or tostring(ipaddr):gsub('^%s+', ''):gsub('%s+$', '')
        netmask = netmask == nil and '' or tostring(netmask):gsub('^%s+', ''):gsub('%s+$', '')
        gateway = gateway == nil and '' or tostring(gateway):gsub('^%s+', ''):gsub('%s+$', '')
        log.info(section, interface, "ip:", ipaddr, 'mask:', netmask, 'gateway:', gateway)
        return { proto = proto, ipaddr = ipaddr, netmask = netmask, gateway = gateway }
    end

    return { proto = proto }
end

-- 从uci配置文件获取所有WAN链路
function M.getAvailWan()
    local c = uci.cursor()
    local links = {}

    local function add_link(link)
        links[#links + 1] = link
    end

    local all = c:get_all('network') or {}
    for section, s in pairs(all) do
        if type(s) == 'table' and s['.type'] == 'interface' then
            local name = s['.name'] or section
            if not name or name == '' then
                goto continue
            end

            local auto = s.auto
            -- if auto ~= nil and tostring(auto) == '0' then
            --     goto continue
            -- end

            local proto = s.proto and tostring(s.proto) or ''
            if proto == '' or proto == 'none' then
                goto continue
            end

            local simn = name:match('^sim(%d+)$')
            if simn then
                local n = tonumber(simn)
                if n and n >= 1 then
                    add_link({
                        kind = 'sim',
                        name = name,
                        sim_index = n - 1,
                        proto = proto,
                        device = s.device or s.ifname or ''
                    })
                end
                goto continue
            end

            local wann = name:match('^wan(%d+)$')
            if wann or name == 'wan' then
                local n = tonumber(wann) or 0
                if n ~= nil then
                    add_link({
                        kind = 'wan',
                        name = name,
                        wan_index = n,
                        proto = proto,
                        device = s.device or s.ifname or ''
                    })
                end
            end
        end
        ::continue::
    end

    table.sort(links, function(a, b)
        local ak = a.kind == 'wan' and 0 or 1
        local bk = b.kind == 'wan' and 0 or 1
        if ak ~= bk then
            return ak < bk
        end

        if a.kind == 'wan' then
            return (a.wan_index or 0) < (b.wan_index or 0)
        end

        return (a.sim_index or 0) < (b.sim_index or 0)
    end)

    local ok, payload = pcall(cjson.encode, { links = links })
    if ok then
        log.info('getAvailWan result:', payload)
    else
        log.error('getAvailWan encode failed:', tostring(payload))
    end

    return { links = links }
end

return M

