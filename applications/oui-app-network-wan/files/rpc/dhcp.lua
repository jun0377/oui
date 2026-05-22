local M = {}
local log = require 'log'
local uci = require 'eco.uci'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/dhcp.log'

function getGateway()
    local c = uci.cursor()
    return c:get('network', 'lan', 'ipaddr')         -- uci get network.lan.ipaddr
end

function getMask()
    local c = uci.cursor()
    return c:get('network', 'lan', 'netmask')         -- uci get network.lan.netmask
end

function getLanStart()
    local c = uci.cursor()
    return c:get('dhcp', 'lan', 'start')            -- uci get dhcp.lan.start
end

function getLanLimit()
    local c = uci.cursor()
    return c:get('dhcp', 'lan', 'limit')            -- uci get dhcp.lan.limit
end

local function parse_ipv4_string(value)
    if type(value) ~= 'string' then
        return nil
    end
    local a, b, c, d = value:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    a = tonumber(a)
    b = tonumber(b)
    c = tonumber(c)
    d = tonumber(d)
    if not a or not b or not c or not d then
        return nil
    end
    if a < 0 or a > 255 or b < 0 or b > 255 or c < 0 or c > 255 or d < 0 or d > 255 then
        return nil
    end
    return { a, b, c, d }
end

local function parse_ipv4_sections(sections)
    if type(sections) ~= 'table' then
        return nil
    end
    local a = tonumber(sections.section1)
    local b = tonumber(sections.section2)
    local c = tonumber(sections.section3)
    local d = tonumber(sections.section4)
    if not a or not b or not c or not d then
        return nil
    end
    if a < 0 or a > 255 or b < 0 or b > 255 or c < 0 or c > 255 or d < 0 or d > 255 then
        return nil
    end
    return { a, b, c, d }
end

local function ipv4_to_int(parts)
    return (((parts[1] << 24) | (parts[2] << 16) | (parts[3] << 8) | parts[4]) & 0xFFFFFFFF)
end

local function int_to_sections(value)
    local n = value & 0xFFFFFFFF
    local a = (n >> 24) & 0xFF
    local b = (n >> 16) & 0xFF
    local c = (n >> 8) & 0xFF
    local d = n & 0xFF
    return {
        section1 = tostring(a),
        section2 = tostring(b),
        section3 = tostring(c),
        section4 = tostring(d)
    }
end

function M.getDHCPSettings()

    local gateway_parts = parse_ipv4_string(getGateway() or '')
    local netmask_parts = parse_ipv4_string(getMask() or '')
    if not gateway_parts then
        gateway_parts = { 0, 0, 0, 0 }
    end
    if not netmask_parts then
        netmask_parts = { 0, 0, 0, 0 }
    end

    local ip_int = ipv4_to_int(gateway_parts)
    local mask_int = ipv4_to_int(netmask_parts)
    local network = (ip_int & mask_int) & 0xFFFFFFFF
    local start_offset = tonumber(getLanStart() or '') or 0
    local limit = tonumber(getLanLimit() or '') or 0
    if start_offset < 0 then
        start_offset = 0
    end
    if limit < 0 then
        limit = 0
    end

    local start_ip = (network + start_offset) & 0xFFFFFFFF
    local end_ip = start_ip
    if limit > 0 then
        end_ip = (start_ip + limit - 1) & 0xFFFFFFFF
    end

    local gateway = int_to_sections(ip_int)
    local netmask = int_to_sections(mask_int)
    local lanStart = int_to_sections(start_ip)
    local lanEnd = int_to_sections(end_ip)

    return  {
                gw = gateway,
                mask = netmask,
                dhcpStart = lanStart,
                dhcpEnd = lanEnd
            }
end

function M.setDHCPSettings(params)

    if type(params) ~= 'table' then
        return -1
    end

    local gateway_parts = parse_ipv4_sections(params.gw)
    local netmask_parts = parse_ipv4_sections(params.mask)
    local start_parts = parse_ipv4_sections(params.dhcpStart)
    local end_parts = parse_ipv4_sections(params.dhcpEnd)
    if not gateway_parts or not netmask_parts or not start_parts or not end_parts then
        return -1
    end

    local ip_int = ipv4_to_int(gateway_parts)
    local mask_int = ipv4_to_int(netmask_parts)
    if mask_int == 0 then
        return -1
    end
    local network = (ip_int & mask_int) & 0xFFFFFFFF
    local start_int = ipv4_to_int(start_parts)
    local end_int = ipv4_to_int(end_parts)
    if (start_int & mask_int) ~= network or (end_int & mask_int) ~= network then
        return -1
    end
    if end_int < start_int then
        return -1
    end

    local start_offset = start_int - network
    if start_offset < 0 then
        return -1
    end
    local limit = end_int - start_int + 1
    if limit <= 0 then
        return -1
    end

    local ipaddr = string.format("%d.%d.%d.%d", gateway_parts[1], gateway_parts[2], gateway_parts[3], gateway_parts[4])
    local netmask = string.format("%d.%d.%d.%d", netmask_parts[1], netmask_parts[2], netmask_parts[3], netmask_parts[4])

    local c = uci.cursor()
    c:set('network', 'lan', 'ipaddr', ipaddr)               -- uci set network.lan.ipaddr=192.168.100.1
    c:set("network", 'lan', 'netmask', netmask)             -- uci set network.lan.netmask=255.255.255.0
    c:commit('network')
    c:set("dhcp", 'lan', 'start', tostring(start_offset))                    -- uci get dhcp.lan.start
    c:set("dhcp", 'lan', 'limit', tostring(limit))                    -- uci get dhcp.lan.limit
    c:commit('dhcp')

    return 0
end

return M
