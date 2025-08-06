local time = require 'eco.time'
local sys = require 'eco.sys'

-- lua模块模式
local M = {}

-- CPU 时间统计
function M.get_cpu_time()
    local result = {}

    for line in io.lines('/proc/stat') do
        local cpu = line:match('^(cpu%d?)')
        if cpu then
            local times = {}
            for field in line:gmatch('%S+') do
                if not field:match('cpu') then
                    times[#times + 1] = tonumber(field)
                end
            end
            result[cpu] = times
        end
    end

    return { times = result }
end

-- 系统升级
function M.sysupgrade(params)
    time.at(0.5, function()
        -- 是否保留配置
        local arg = params.keep and '' or '-n'
        os.execute('sysupgrade ' .. arg .. ' /tmp/firmware.bin')
    end)
end

-- 创建系统配置备份
function M.create_backup(params)
    -- 备份文件保存路径
    local path = params.path
    sys.exec('sysupgrade', '-b', path)
end

-- 列出备份内容
function M.list_backup(params)

    -- 备份文件路径
    local path = params.path
    -- 使用 tar -tzf 命令读取 tar 压缩包内容
    local f = io.popen('tar -tzf ' .. path)
    if not f then
        return
    end

    local files = f:read('*a')

    f:close()

    -- 返回文件列表字符串
    return { files = files }
end

-- 恢复系统配置备份
function M.restore_backup(params)

    -- 使用 sysupgrade -r 命令恢复
    os.execute('sysupgrade -r ' .. params.path)

    -- 延迟 0.5 秒后自动重启系统
    time.at(0.5, function()
        os.execute('reboot')
    end)
end

-- 恢复出厂设置
function M.reset()
    time.at(0.5, function()
        os.execute('firstboot -y && reboot')
    end)
end

return M
