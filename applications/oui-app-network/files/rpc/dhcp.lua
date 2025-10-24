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
    local ip1, ip2, ip3, ip4 = gateway:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local netmask = getMask()
    local mask1, mask2, mask3, mask4 = netmask:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local lanStart = getLanStart()
    local lanEnd = getLanLimit()

    gateway = {
        section1 = ip1,
        section2 = ip2,
        section3 = ip3,
        section4 = ip4
    }

    netmask = {
        section1 = mask1,
        section2 = mask2,
        section3 = mask3,
        section4 = mask4
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
    local netmask = params.mask
    local dhcpStart = params.dhcpStart
    local dhcpEnd = params.dhcpEnd

    local ipaddr = string.format("%s.%s.%s.%s", gateway.section1, gateway.section2, gateway.section3, gateway.section4)
    local mask = string.format("%s.%s.%s.%s", netmask.section1, netmask.section2, netmask.section3, netmask.section4)
    local start = dhcpStart.section4
    local limit = dhcpEnd.section4

    local c = uci.cursor()
    c:set('network', 'lan', 'ipaddr', gw)                 -- uci set network.lan.ipaddr=192.168.100.1
    c:set("network", lan, 'apn', apn)                       -- uci get network.lan.netmask=255.255.255.0
    c:set("sim", section, 'user', username)
    c:set("sim", section, 'passwd', password)

end

return M