local M = {}
local log = require 'log'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/sim.log'

-- SIM卡状态
local SimStatus = {
    [1] = {
        -- 模组信息
        usb = '1-1',                            -- USB端口号
        alias = '5G-1',                         -- tag
        module = '',                            -- 模组名称
        version = '',                           -- 模组版本
        imei = '',                              -- 模组的IMEI码
        ttyusb = '/dev/ttyUSB2',                -- 拨号节点
        interface = 'usb0',                     -- 接口名称

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区

        -- DHCP地址池设置
        dhcpRangeStart = '',                -- DHCP地址池起始IP
        dhcpRanageEnd = '',                 -- DHCP地址池终止IP
        dhcpRangeMask = '',                 -- DHCP地址池掩码
        dhcpRangeGateway = '',              -- DHCP地址池网关

        -- SIM卡状态
        status = 'offline',                 -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',                   -- 当设置为AUTO时，实时的入网方式
        signal = 0,                         -- 信号强度RSRP
        operator = '',                      -- 运营商
        imsi = '',                          -- SIM卡的IMSI
        bandRealTime = '',                  -- 实时频段
        cellRealTime = '',                  -- 实时小区
        ip = '',                            -- IP
        mask = '',                          -- 掩码
        gateway = '',                       -- 网关
    },
    [2] = {
        -- 模组信息
        usb = '1-2',                        -- USB端口号
        alias = '5G-2',                     -- tag
        module = '',                        -- 模组名称
        version = '',                       -- 模组版本
        imei = '',                          -- 模组的IMEI码
        ttyusb = '/dev/ttyUSB7',            -- 拨号节点
        interface = 'usb1',                     -- 接口名称

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区

        -- SIM卡状态
        status = 'offline',                 -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',                   -- 当设置为AUTO时，实时的入网方式
        signal = 0,                         -- 信号强度RSRP
        operator = '',                      -- 运营商
        imsi = '',                          -- SIM卡的IMSI
        bandRealTime = '',                  -- 实时频段
        cellRealTime = '',                  -- 实时小区
        ip = '',                            -- IP
        mask = '',                          -- 掩码
        gateway = '',                       -- 网关
    },
    [3] = {
        -- 模组信息
        usb = '1-3',                        -- USB端口号
        alias = '5G-2',                     -- tag
        module = '',                        -- 模组名称
        version = '',                       -- 模组版本
        imei = '',                          -- 模组的IMEI码
        ttyusb = '/dev/ttyUSB12',           -- 拨号节点
        interface = 'usb2',                 -- 接口名称

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区

        -- SIM卡状态
        status = 'offline',                 -- 连接状态：离线、未插卡、拨号中、在线
        netRealTime = '',                   -- 当设置为AUTO时，实时的入网方式
        signal = 0,                         -- 信号强度RSRP
        operator = '',                      -- 运营商
        interface = '',                     -- 接口名称
        imsi = '',                          -- SIM卡的IMSI
        bandRealTime = '',                  -- 实时频段
        cellRealTime = '',                  -- 实时小区
        ip = '',                            -- IP
        mask = '',                          -- 掩码
        gateway = '',                       -- 网关
    }
}

-- 获取模组对应的usb端点号
local function getSimUsb(index)
    return SimStatus[index].usb
end

-- 获取模组别名
local function getSimAlias(index)
    return SimStatus[index].alias
end

-- 获取模组对应的模组名称
local function getSimModuleName(index)
    return SimStatus[index].module
end

-- 获取模组版本
local function getSimModuleVersion(index)
    return SimStatus[index].version
end

-- 获取模组拨号节点
local function getSimNode(index)
    return SimStatus[index].ttyusb
end

-- 获取模组对应的接口
local function getSimInterface(index)
    return SimStatus[index].interface
end

-- 获取模组IMEI
local function getSimModuleIMEI(index)
    return SimStatus[index].imei
end

-- 获取模组频段设置
local function getSimConfBand(index)
    return SimStatus[index].bandSetting
end

-- 获取模组入网方式设置
local function getSimConfNet(index)
    return SimStatus[index].netRealTime
end

-- 获取模组APN设置
local function getSimConfAPN(index)
    return SimStatus[index].apn
end

-- 获取模组用户名设置
local function getSimConfUser(index)
    return SimStatus[index].user
end

-- 获取模组密码设置
local function getSimConfPasswd(index)
    return SimStatus[index].passwd
end

-- 获取模组小区设置
local function getSimConfCell(index)
    return SimStatus[index].cellSetting
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeStart(index)
    return SimStatus[index].dhcpRangeStart
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeEnd(index)
    return SimStatus[index].dhcpRanageEnd
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeMask(index)
    return SimStatus[index].dhcpRangeMask
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeGateway(index)
    return SimStatus[index].dhcpRangeGateway
end

-- 获取模组连接状态
local function getSimStatusConnect(index)
    return SimStatus[index].status
end

-- 获取模组实时入网方式
local function getSimStatusNet(index)
    return SimStatus[index].netRealTime
end

-- 获取模组信号强度
local function getSimStatusSignal(index)
    return SimStatus[index].signal
end

-- 获取模组运营商
local function getSimStatusOperator(index)
    return SimStatus[index].operator
end

-- 获取模组实时频段
local function getSimStatusBand(index)
    return SimStatus[index].bandRealTime
end

-- 获取模组实时小区
local function getSimStatusCell(index)
    return SimStatus[index].cellRealTime
end

-- 获取模组ip
local function getSimStatusIP(index)
    return SimStatus[index].ip
end

-- 获取模组掩码
local function getSimStatusMask(index)
    return SimStatus[index].mask
end

-- 获取模组网关
local function getSimStatusGateway(index)
    return SimStatus[index].gateway
end

-- 获取SIM卡状态：是否插卡、拨号状态、信号强度、运营商、频段、小区...
function M.getSimStatus(params)

    local index = tonumber(params.index) + 1

    -- 模组硬件信息
    SimStatus[index].usb = getSimUsb(index)
    SimStatus[index].alias = getSimAlias(index)
    SimStatus[index].module = getSimModuleName(index)
    SimStatus[index].version = getSimModuleVersion(index)
    SimStatus[index].imei = getSimModuleIMEI(index)
    SimStatus[index].ttyusb = getSimNode(index)
    SimStatus[index].interface = getSimInterface(index)
    -- 模组配置信息
    SimStatus[index].bandSetting = getSimConfBand(index)
    SimStatus[index].netSetting = getSimConfNet(index)
    SimStatus[index].apn = getSimConfAPN(index)
    SimStatus[index].user = getSimConfUser(index)
    SimStatus[index].passwd = getSimConfPasswd(index)
    SimStatus[index].cellSetting = getSimConfCell(index)
    -- 模组dhcp设置
    SimStatus[index].dhcpRangeStart = getSimConfDhcpRangeStart(index)
    SimStatus[index].dhcpRanageEnd = getSimConfDhcpRangeEnd(index)
    SimStatus[index].dhcpRangeMask = getSimConfDhcpRangeMask(index)
    SimStatus[index].dhcpRangeGateway = getSimConfDhcpRangeGateway(index)
    -- 模组实时状态
    SimStatus[index].status = getSimStatusConnect(index)
    SimStatus[index].netRealTime = getSimStatusNet(index)
    SimStatus[index].signal = getSimStatusSignal(index)
    SimStatus[index].operator = getSimStatusOperator(index)
    SimStatus[index].bandRealTime = getSimStatusBand(index)
    SimStatus[index].cellRealTime = getSimStatusCell(index)
    SimStatus[index].ip = getSimStatusIP(index)
    SimStatus[index].mask = getSimStatusMask(index)
    SimStatus[index].gateway = getSimStatusGateway(index)

    return SimStatus[index]
end


return M
