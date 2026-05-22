local M = {}

local file = require 'eco.file'
local uci = require 'eco.uci'

function M.dhcp_leases()
    local c = uci.cursor()
    local leases = {}
    local leasefile = c:get('dhcp', '@dnsmasq[0]', 'leasefile') or '/tmp/dhcp.leases'

    if not file.access(leasefile) then
        return { leases = leases }
    end

    local now = os.time()
    for line in io.lines(leasefile) do
        local ts, mac, addr, name = line:match("(%S+) +(%S+) +(%S+) +(%S+)")
        local expire

        ts = tonumber(ts)
        if ts and ts > now then
            expire = ts - now
        elseif ts and ts > 0 then
            expire = 0
        else
            expire = -1
        end

        leases[#leases + 1] = {
            ipaddr = addr,
            macaddr = mac,
            hostname = name,
            expire = expire
        }
    end

    return { leases = leases }
end

return M
