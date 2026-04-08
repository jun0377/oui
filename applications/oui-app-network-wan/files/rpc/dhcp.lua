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

function M.getDHCPSettings()

    local gateway = getGateway()
    local gw1, gw2, gw3, gw4 = gateway:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local netmask = getMask()
    local mask1, mask2, mask3, mask4 = netmask:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local start = getLanStart()
    local limit = getLanLimit()

    gateway = {
        section1 = gw1,
        section2 = gw2,
        section3 = gw3,
        section4 = gw4
    }

    netmask = {
        section1 = mask1,
        section2 = mask2,
        section3 = mask3,
        section4 = mask4
    }

    lanStart = {
        section1 = gw1,
        section2 = gw2,
        section3 = gw3,
        section4 = start
    }

    lanEnd = {
        section1 = gw1,
        section2 = gw2,
        section3 = gw3,
        section4 = limit
    }

    return  {
                gw = gateway,
                mask = netmask,
                dhcpStart = lanStart,
                dhcpEnd = lanEnd
            }
end

function M.setDHCPSettings(params)

    local gateway = params.gw
    local mask = params.mask
    local dhcpStart = params.dhcpStart
    local dhcpEnd = params.dhcpEnd

    local ipaddr = string.format("%s.%s.%s.%s", gateway.section1, gateway.section2, gateway.section3, gateway.section4)
    local netmask = string.format("%s.%s.%s.%s", mask.section1, mask.section2, mask.section3, mask.section4)
    local start = dhcpStart.section4
    local limit = dhcpEnd.section4

    local c = uci.cursor()
    c:set('network', 'lan', 'ipaddr', ipaddr)               -- uci set network.lan.ipaddr=192.168.100.1
    c:set("network", 'lan', 'netmask', netmask)             -- uci set network.lan.netmask=255.255.255.0
    c:commit('network')
    c:set("dhcp", 'lan', 'start', start)                    -- uci get dhcp.lan.start
    c:set("dhcp", 'lan', 'limit', limit)                    -- uci get dhcp.lan.limit
    c:commit('dhcp')

    return 0
end

return M