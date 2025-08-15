local M = {}
local uci = require 'eco.uci'



-- 更新服务器端口,只是用来在系统开机时获取服务器IP
local function updateServerPort()
    local c = uci.cursor()

    -- uci get openmptcprouter.vps.port
    return c:get('openmptcprouter', 'vps', 'port')
    
end

-- uci get openmptcprouter.vps.ip
function M.getServerIP()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'ip')
end

-- uci get openmptcprouter.vps.port
function M.getServerPort()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'port')
end

return M
