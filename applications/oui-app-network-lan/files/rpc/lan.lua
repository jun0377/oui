local M = {}

local file = require 'eco.file'
local uci = require 'eco.uci'

function M.dhcp_leases()
    local c = uci.cursor()
    local leases = {}
    local dhcp_macs = {}
    local leasefile = c:get('dhcp', '@dnsmasq[0]', 'leasefile') or '/tmp/dhcp.leases'

    -- 1. 读取 DHCP 租约
    if file.access(leasefile) then
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

            -- 记录 DHCP 分配的 MAC，后续 ARP 表去重用
            if mac then
                dhcp_macs[mac:lower()] = true
            end
        end
    end

    -- 2. 读取 ARP 表，补充静态 IP 设备
    local lan_ip = c:get('network', 'lan', 'ipaddr') or '192.168.100.1'
    -- 提取 LAN 子网前缀 (取前三段)
    local lan_prefix = lan_ip:match("^(%d+%.%d+%.%d+)%.")
    if lan_prefix and file.access('/proc/net/arp') then
        for line in io.lines('/proc/net/arp') do
            -- IP address  HW type  Flags  HW address  Mask  Device
            local ip, hwtype, flags, mac, mask, dev = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
            if ip and mac and dev then
                -- 仅取 br-lan 接口、Flags=0x2（已解析）、同子网 IP、排除路由器自身
                if dev == 'br-lan' and flags == '0x2' and ip ~= lan_ip and ip:match("^" .. lan_prefix .. "%.") then
                    local mac_lower = mac:lower()
                    -- 去重：已在 DHCP 列表中的跳过
                    if not dhcp_macs[mac_lower] then
                        leases[#leases + 1] = {
                            ipaddr = ip,
                            macaddr = mac,
                            hostname = '*',
                            expire = '静态IP'
                        }
                        dhcp_macs[mac_lower] = true
                    end
                end
            end
        end
    end

    return { leases = leases }
end

return M
