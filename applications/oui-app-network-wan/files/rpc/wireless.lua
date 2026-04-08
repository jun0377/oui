local M = {}
local log = require 'log'
local uci = require 'eco.uci'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/wireless.log'


function M.getSSID()
    local c = uci.cursor()
    return c:get('wireless', 'default_radio1', 'ssid')         -- uci get wireless.default_radio1.ssid
end

function M.setSSID(params)
    local c = uci.cursor()
    c:set('wireless', 'default_radio1', 'ssid', params.ssid)   -- uci get wireless.default_radio1.ssid=xxx
    return c:commit('wireless')
end

function M.getPassword()
    local c = uci.cursor()
    return c:get('wireless', 'default_radio1', 'key')         -- uci get wireless.default_radio1.key
end

function M.setPassword(params)
    local c = uci.cursor()
    c:set('wireless', 'default_radio1', 'key', params.password)         -- uci get wireless.default_radio1.key=xxx
    return c:commit('wireless')
end

return M
