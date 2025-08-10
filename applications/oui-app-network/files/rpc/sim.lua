local M = {}
local nixio = require "nixio"

-- SIM卡状态
local SimStatus = {
    [1] = {

        -- USB端口号
        usb = '1-1',

        -- 模组信息
        module = '',            -- 模组名称
        version = '',           -- 模组版本
        imei = '',              -- 模组的IMEI码
        ttyusb = '',            -- 拨号节点

        -- SIM卡可设置的参数
        bandSetting = '',       -- 设置的频段
        netSetting = '',        -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',               -- apn
        auth = '',              -- 鉴权
        user = '',              -- 用户名
        passwd = '',            -- 密码
        cellSetting = '',       -- 锁小区

        -- DHCP地址池设置
        dhcpRangeStart = '',    -- DHCP地址池起始IP
        dhcpRanageEnd = '',     -- DHCP地址池终止IP
        dhcpRangeMask = '',     -- DHCP地址池掩码
        dhcpRangeGateway = '',  -- DHCP地址池网关

        -- SIM卡状态
        status = 'offline',     -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',       -- 当设置为AUTO时，实时的入网方式
        signal = 0,             -- 信号强度RSRP
        operator = '',          -- 运营商
        interface = '',         -- 接口名称
        imsi = '',              -- SIM卡的IMSI
        bandRealTime = '',      -- 实时频段
        cellRealTime = '',      -- 实时小区
        ip = '',                -- IP
        mask = '',              -- 掩码
        gateway = '',           -- 网关
    },
    [2] = {

        -- USB端口号
        usb = '1-2',

        -- 模组信息
        module = '',            -- 模组名称
        version = '',           -- 模组版本
        imei = '',              -- 模组的IMEI码
        ttyusb = '',            -- 拨号节点

        -- SIM卡可设置的参数
        bandSetting = '',       -- 设置的频段
        netSetting = '',        -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',               -- apn
        auth = '',              -- 鉴权
        user = '',              -- 用户名
        passwd = '',            -- 密码
        cellSetting = '',       -- 锁小区

        -- SIM卡状态
        status = 'offline',     -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',       -- 当设置为AUTO时，实时的入网方式
        signal = 0,             -- 信号强度RSRP
        operator = '',          -- 运营商
        interface = '',         -- 接口名称
        imsi = '',              -- SIM卡的IMSI
        bandRealTime = '',      -- 实时频段
        cellRealTime = '',      -- 实时小区
        ip = '',                -- IP
        mask = '',              -- 掩码
        gateway = '',           -- 网关
    },
    [3] = {

        -- USB端口号
        usb = '1-3',

        -- 模组信息
        module = '',            -- 模组名称
        version = '',           -- 模组版本
        imei = '',              -- 模组的IMEI码
        ttyusb = '',            -- 拨号节点

        -- SIM卡可设置的参数
        bandSetting = '',       -- 设置的频段
        netSetting = '',        -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',               -- apn
        auth = '',              -- 鉴权
        user = '',              -- 用户名
        passwd = '',            -- 密码
        cellSetting = '',       -- 锁小区

        -- SIM卡状态
        status = 'offline',     -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',       -- 当设置为AUTO时，实时的入网方式
        signal = 0,             -- 信号强度RSRP
        operator = '',          -- 运营商
        interface = '',         -- 接口名称
        imsi = '',              -- SIM卡的IMSI
        bandRealTime = '',      -- 实时频段
        cellRealTime = '',      -- 实时小区
        ip = '',                -- IP
        mask = '',              -- 掩码
        gateway = '',           -- 网关
    }
}

-- 获取接口名称
local function getModuleInterface(index, usb_point)
    if SimStatus[index].interface ~= '' then
        return SimStatus[index].interface
    end

    -- TODO: 根据usb端口号，从sysfs中获取接口名称
    local interface = ''
    return interface
end

-- 获取模组名称
local function getModuleName(index, usb_point)

    if SimStatus[index].module ~= '' then
        return SimStatus[index].module
    end

    -- TODO: 根据usb端口号，从sysfs中获取模组名
    local moduleName = ''

    return moduleName
end

-- 获取模组拨号节点
local function getModuleNode(index, usb_point)

    if SimStatus[index].ttyusb ~= '' then
        return SimStatus[index].ttyusb
    end

    -- TODO: 根据usb端口号，从sysfs中获取拨号节点
    local ttyUSB = ''

    return ttyUSB
end

-- 获取模组版本号
local function getModuleVersion(index, tty)

    if SimStatus[index].version ~= '' then
        return SimStatus[index].version
    end

    -- TODO: 通过AT指令获取模组版本号
    local version = ''

    return version
end

-- 获取模组IMEI
local function getModuleIMEI(index, tty)

    if SimStatus[index].imei ~= '' then
        return SimStatus[index].imei
    end

    -- TODO: 通过AT指令获取IMEI
    local imei = ''

    return imei
end

-- 获取模组信息
local function updateModuleInfo()
    
    local moduleCnt = #SimStatus
    for i = 1, moduleCnt do
        -- usb端口号
        local usb = SimStatus[i].usb
        -- 接口名称
        SimStatus[i].interface = getModuleInterface(i, usb)
        -- 获取模组名称
        SimStatus[i].module = getModuleName(i, usb)
        -- 获取模组拨号节点
        SimStatus[i].ttyusb = getModuleNode(i, usb)
        -- 获取模组版本
        SimStatus[i].version = getModuleVersion(i, SimStatus[i].ttyusb)
        -- 获取模组IMEI
        SimStatus[i].imei = getModuleIMEI(i, SimStatus[i].ttyusb)

    end

end

-- 获取SIM卡 IMSI
local function getSimIMSI(index)

    if SimStatus[index].imsi ~= '' then
        return SimStatus[index].imsi
    end

    -- TODO: AT指令获取IMSI
    local imsi = ''

    return imsi
end

-- 获取SIM卡运营商
local function getSimOperator(index)

    if SimStatus[index].operator ~= '' then
        return SimStatus[index].operator
    end

    -- TODO: AT指令获取IMSI
    local operator = ''

    return operator
end

-- 获取SIM卡信号强度、实时频段...
local function updateSimSignal(index)

    -- TODO: AT指令获取信号强度

end

-- 获取SIM卡IP
local function updateSimIP(index)

    interface = SimStatus[index].interface

    -- TODO: 获取接口IP

end

-- 获取SIM卡掩码
local function updateSimMask(index)

    interface = SimStatus[index].interface

    -- TODO: 获取接口掩码

end

-- 获取SIM卡网关
local function updateSimGateway(index)

    interface = SimStatus[index].interface

    -- TODO: 获取接口网关

end

-- 获取SIM卡状态
local function updateSimInfo()

    local moduleCnt = #SimStatus
    for i = 1, moduleCnt do
        -- 获取SIM卡 IMSI
        SimStatus[i].imsi = getSimIMSI(i)
        -- 获取SIM卡运营商
        SimStatus[i].operator = getSimOperator(i)
        -- 获取SIM卡信号强度、实时频段...
        updateSimSignal(i)
        -- 获取SIM卡IP
        SimStatus[i].ip = updateSimIP(i)
        -- 获取SIM卡掩码
        SimStatus[i].mask = updateSimMask(i)
        -- 获取SIM卡网关
        SimStatus[i].gateway = updateSimGateway(i)
    end
end

-- 更新 模组 及 SIM卡 状态的函数
local function updateSimStatus()
    while true do
        
        -- 获取模组信息
        updateModuleInfo()
        -- 更新SIM卡状态
        updateSimInfo()
        -- 等待5秒
        nixio.nanosleep(5, 0)
    end
end

-- 设置入网方式
function M.setSimNet(index, net)

    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置入网方式

end

-- 设置入网方式
function M.setSimAPN(index, APN)

    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置APN

end

-- 设置鉴权方式
function M.setSimAuth(index, auth)

    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置鉴权方式

end

-- 设置鉴权方式
function M.setSimUser(index, auth)

    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置用户名、密码

end

-- 设置频段
function M.setSimUser(index, band)

    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置频段

end

-- 设置小区
function M.setSimCell(index, cell)
    
    -- 拨号节点
    tty = SimStatus[index].ttyusb
    
    -- TODO: AT指令设置小区

end

-- 设置DHCP地址池
function M.setDhcpRange(index, dhcpRange)

    -- 拨号节点
    tty = SimStatus[index].ttyusb

    -- TODO: AT指令设置DHCP地址池

    
end

-- 获取SIM卡状态：是否插卡、拨号状态、信号强度、运营商、频段、小区...
function M.getSimStatus(params, section)
    return SimStatus
end

local statusThread = nil

-- 启动状态更新线程
function M.startStatusThread()

    if not statusThread or coroutine.status(statusThread) == "dead" then
        statusThread = coroutine.create(updateSimStatus)
        coroutine.resume(statusThread)
    end

end

-- 自动启动状态更新线程
M.startStatusThread()

return M
