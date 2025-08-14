local M = {}
local socket = require "socket"
local nixio = require "nixio"

function M.echo(params)
    return params
end

-- 获取服务器 IP 地址
function M.getServerIP()
    local ip = "127.0.0.1"
    
    return ip
end

return M
