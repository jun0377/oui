local M = {}

local file = require 'eco.file'

local VERSION_FILE = '/etc/version'

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    data = data:gsub("[\r\n]+$", "")
    return data
end

function M.get_version()
    local result = {
        version = '',
        build_timestamp = '',
        commit = ''
    }

    if not file.access(VERSION_FILE) then
        return result
    end

    result.version = exec("jsonfilter -i " .. VERSION_FILE .. " -e '@.version' 2>/dev/null")
    result.build_timestamp = exec("jsonfilter -i " .. VERSION_FILE .. " -e '@.build_timestamp' 2>/dev/null")
    result.commit = exec("jsonfilter -i " .. VERSION_FILE .. " -e '@.commit' 2>/dev/null")

    return result
end

return M
