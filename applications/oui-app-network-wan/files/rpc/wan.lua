local M = {}
local log = require 'log'
local uci = require 'eco.uci'
local cjson = require 'cjson'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/wan.log'


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
            if auto ~= nil and tostring(auto) == '0' then
                goto continue
            end

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

