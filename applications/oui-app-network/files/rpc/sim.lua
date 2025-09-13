local M = {}
local log = require 'log'
local uci = require 'eco.uci'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/sim.log'

-- SIM卡状态
local SimStatus = {
    [1] = {
        -- 模组信息
        usb = '',                            -- USB端口号
        alias = '5G-1',                         -- tag
        uciSection = 'SIM_5G_1',                -- UCI配置文件section命名规范
        module = '',                            -- 模组名称
        version = '',                           -- 模组版本
        imei = '',                              -- 模组的IMEI码
        ttyusb = '',                            -- 拨号节点
        interface = '',                         -- 接口名称

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
        status = '',                        -- 连接状态：离线、nosim(未插卡)、拨号中、在线
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
        usb = '',                        -- USB端口号
        alias = '5G-2',                     -- tag
        uciSection = 'SIM_5G_2',            -- UCI配置文件section命名规范
        module = '',                        -- 模组名称
        version = '',                       -- 模组版本
        imei = '',                          -- 模组的IMEI码
        ttyusb = '',                        -- 拨号节点
        interface = '',                     -- 接口名称

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区

        -- SIM卡状态
        status = 'offline',                 -- 连接状态：离线、nosim(未插卡)、拨号中、在线
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
        usb = '',                        -- USB端口号
        alias = '5G-3',                     -- tag
        uciSection = 'SIM_5G_3',            -- UCI配置文件section命名规范
        module = '',                        -- 模组名称
        version = '',                       -- 模组版本
        imei = '',                          -- 模组的IMEI码
        ttyusb = '',                        -- 拨号节点
        interface = '',                     -- 接口名称

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区

        -- SIM卡状态
        status = '',                        -- 连接状态：离线、nosim(未插卡)、拨号中、在线
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

local function exec(command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    return data
end

-- 获取指定网口的IP
function getInterfaceIP(interface)
    local cmd = string.format("ip addr show %s | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1  | tr -d '\n'", interface)
    log.info(cmd)
    return exec(cmd)
end

-- 获取模组对应的usb端点号
local function getSimUsb(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'usb')
end

-- 获取模组别名,如5G-1 5G-2 4G-1 4G-2
local function getSimAlias(index)
    return SimStatus[index].alias
end

-- 获取模组对应的模组名称
local function getSimModuleName(index)

    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'module')
end

-- 获取模组版本
local function getSimModuleVersion(index)

    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'moduleVersion')
end

-- 获取模组拨号节点
local function getSimNode(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'node')
end

-- 获取模组对应的接口
local function getSimInterface(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'interface')
end

-- 获取模组IMEI
local function getSimModuleIMEI(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'imei')
end

-- 获取SIM卡IMSI
local function getSimModuleIMSI(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'imsi')
end

-- 获取模组频段设置
local function getSimConfBand(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'band')
end

-- 获取模组入网方式设置
local function getSimConfNet(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'net')
end

-- 获取模组APN设置
local function getSimConfAPN(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'apn')
end

-- 获取模组鉴权设置
local function getSimConfAuth(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'auth')
end

-- 获取模组用户名设置
local function getSimConfUser(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'user')
end

-- 获取模组密码设置
local function getSimConfPasswd(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'passwd')
end

-- 获取模组小区设置
local function getSimConfCell(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'cell')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeStart(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeStart')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeEnd(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeEnd')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeMask(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeMask')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeGateway(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeGateway')
end

-- 获取模组连接状态
local function getSimStatusConnect(index)

    -- nosim
    local imsi = getSimModuleIMSI(index)
    if nil == imsi or "none" == imsi then
        SimStatus[index].status = 'nosim'
        return SimStatus[index].status
    end

    -- udhcpc
    local cmd = string.format("ps -w | grep 'udhcpc.*%s' | grep -v grep | awk '{print $1}'", SimStatus[index].interface)
    log.info(cmd)
    local pid = exec(cmd);
    if nil == pid or "" == pid then
        SimStatus[index].status = 'disconnected'
        return SimStatus[index].status
    end

    -- online
    local ip = getInterfaceIP(SimStatus[index].interface)
    if nil == ip or "" == ip then
        SimStatus[index].status = 'dialing'
    else
        log.info(SimStatus[index].interface, "IP:", ip)
        SimStatus[index].status = 'connected'
    end

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

-- 提取连接状态
local function parseSimUE(signal)
    local ue = signal:match('+QENG: "servingcell","([^"]+)"')
    -- log.info(ue)
    return ue
end

-- 提取SA网络信息
local function parseSA(signal)
    local sa = signal:match('.*"NR5G%-SA".*')
    if nil == sa or "" == sa then
        return nil
    end

    -- +QENG: "servingcell","LIMSRV","NR5G-SA","TDD",460,00,31494F003,35,16185B,504990,41,100,-84,-2,8,0,35,1
    local sa_pattern='"([^"]+)","([^"]+)","([^"]+)","([^"]+)",(%d+),(%d+),([^,]+),(%d+),([^,]+),(%d+),(%d+),(%d+),([%-]?%d+),([%-]?%d+),(%d+),(%d+),(%d+),(%d+)'
    local servingcell, status, technology, duplex_mode, MCC, MNC, cellID, PCID, TAC, 
        ARFCN, band, NR_DL_bandwidth, RSRP, RSRQ, SINR, 
        tx_power, srxlev, SCS = sa:match(sa_pattern)

    return {
        servingcell = servingcell,
        status = status,
        technology = technology,
        duplex_mode = duplex_mode,
        MCC = tonumber(MCC),
        MNC = tonumber(MNC),
        cellID = cellID,
        PCID = tonumber(PCID),
        TAC = TAC,
        ARFCN = tonumber(ARFCN),
        band = tonumber(band),
        NR_DL_bandwidth = tonumber(NR_DL_bandwidth),
        RSRP = tonumber(RSRP),
        RSRQ = tonumber(RSRQ),
        SINR = tonumber(SINR),
        tx_power = tonumber(tx_power),
        srxlev = tonumber(srxlev),
        SCS = tonumber(SCS)
    }
end

-- 提取NSA网络信息
local function parseNSA(signal)
    local nsa = signal:match('.*"NR5G%-NSA".*')
    if nil == nsa or "" == nsa then
        return nil
    end

    -- +QENG: "servingcell","NR5G-NSA",<MCC>,<MNC>,<PCID>,<cellID>,<TAC>,<band>,<arfcn>,<SCS>,<RSRP>,<RSRQ>,<SINR>
    local nsa_pattern='"([^"]+)","([^"]+)",(%d+),(%d+),(%d+),([^,]+),([^,]+),(%d+),(%d+),(%d+),([%-]?%d+),([%-]?%d+),([%-]?%d+)'
    local servingcell, technology, MCC, MNC, PCID, cellID, TAC,
        band, arfcn, SCS, RSRP, RSRQ, SINR = nsa:match(nsa_pattern)

    return {
        servingcell = servingcell,
        technology = technology,
        MCC = tonumber(MCC),
        MNC = tonumber(MNC),
        PCID = tonumber(PCID),
        cellID = cellID,
        TAC = TAC,
        band = tonumber(band),
        arfcn = tonumber(arfcn),
        SCS = tonumber(SCS),
        RSRP = tonumber(RSRP),
        RSRQ = tonumber(RSRQ),
        SINR = tonumber(SINR)
    }
end

-- 提取LTE网络信息
local function parseLTE(signal)
    local lte = signal:match('.*"LTE".*')
    if nil == lte or "" == lte then
        return nil
    end

    -- +QENG: "servingcell",<state>,"LTE",<is_tdd>,<MCC>,<MNC>,<cellID>,<PCID>,<earfcn>,<freq_band_ind>,<UL_bandwidth>,<DL_bandwidth>,<TAC>,<RSRP>,<RSRQ>,<RSSI>,<SINR>,<CQI>,<tx_power>,<srxlev>
    local lte_pattern='"([^"]+)","([^"]+)","([^"]+)",(%d+),(%d+),(%d+),([^,]+),(%d+),(%d+),(%d+),(%d+),(%d+),([^,]+),([%-]?%d+),([%-]?%d+),([%-]?%d+),([%-]?%d+),(%d+),([%-]?%d+),([%-]?%d+)'
    local servingcell, state, technology, is_tdd, MCC, MNC, cellID, PCID, earfcn, 
        freq_band_ind, UL_bandwidth, DL_bandwidth, TAC, RSRP, RSRQ, RSSI, 
        SINR, CQI, tx_power, srxlev = lte:match(lte_pattern)

    return {
        servingcell = servingcell,
        state = state,
        technology = technology,
        is_tdd = tonumber(is_tdd),
        MCC = tonumber(MCC),
        MNC = tonumber(MNC),
        cellID = cellID,
        PCID = tonumber(PCID),
        earfcn = tonumber(earfcn),
        freq_band_ind = tonumber(freq_band_ind),
        UL_bandwidth = tonumber(UL_bandwidth),
        DL_bandwidth = tonumber(DL_bandwidth),
        TAC = TAC,
        RSRP = tonumber(RSRP),
        RSRQ = tonumber(RSRQ),
        RSSI = tonumber(RSSI),
        SINR = tonumber(SINR),
        CQI = tonumber(CQI),
        tx_power = tonumber(tx_power),
        srxlev = tonumber(srxlev)
    }
end

-- 查询是否插卡
local function updateSimInsertStatus(ttyusb)
    local cmd = string.format("comgt -d %s -s /etc/gcom/getsimin.gcom", ttyusb)
    log.info(cmd)
    local sim = exec(cmd)
    local s = sim:match('+CPIN:%s*([^%s]+)')
    return s
end

-- 更新模组信号强度
local function updateSimStatusSignal(index)
    
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    local ttyusb = c:get('sim', section, 'node')
    
    -- sim ready ?
    local sim = updateSimInsertStatus(ttyusb)
    if nil == sim or "" == sim then
        SimStatus[index].status = 'nosim'
        SimStatus[index].netRealTime = ''
        SimStatus[index].cellRealTime = ''
        SimStatus[index].band = ''
        SimStatus[index].operator = ''
        SimStatus[index].signal = ''
        return
    end

    local cmd = string.format("comgt -d %s -s /etc/gcom/getstrength.gcom", ttyusb)
    log.info(cmd)
    local signal = exec(cmd)
    -- log.info(signal)
    parseSimUE(signal)
    local sa = parseSA(signal)
    local nsa = parseNSA(signal)
    local lte = parseLTE(signal)
    
    -- SA
    if nil ~= sa and nil == nsa and nil == lte then
        SimStatus[index].netRealTime = 'SA'
        SimStatus[index].cellRealTime = sa.cellID
        SimStatus[index].band = 'n'..sa.band
        SimStatus[index].operator = sa.MCC..sa.MNC
        SimStatus[index].signal = sa.RSRP
    -- NSA
    elseif nil == sa and nil ~= nsa and nil == lte then
        SimStatus[index].netRealTime = 'NSA'
        SimStatus[index].cellRealTime = nsa.cellID
        SimStatus[index].band = 'n'..nsa.band
        SimStatus[index].operator = nsa.MCC..nsa.MNC
        SimStatus[index].signal = nsa.RSRP
    -- NSA
    elseif nil == sa and nil ~= nsa and nil ~= lte then
        SimStatus[index].netRealTime = 'NSA'
        SimStatus[index].cellRealTime = nsa.cellID
        SimStatus[index].band = 'n'..nsa.band..' | b'..lte.freq_band_ind
        SimStatus[index].operator = nsa.MCC..nsa.MNC
        SimStatus[index].signal = nsa.RSRP
    -- LTE
    elseif nil == sa and nil == nsa and nil ~= lte then
        SimStatus[index].netRealTime = 'LTE'
        SimStatus[index].cellRealTime = lte.cellID
        SimStatus[index].band = 'b'..lte.freq_band_ind
        SimStatus[index].operator = lte.MCC..lte.MNC
        SimStatus[index].signal = lte.RSRP
    -- OFFLINE
    elseif nil == sa and nil == nsa and nil == lte then
        SimStatus[index].netRealTime = ''
        SimStatus[index].cellRealTime = ''
        SimStatus[index].band = ''
        SimStatus[index].operator = ''
        SimStatus[index].signal = ''
    end

end

-- 获取模组运营商
local function getSimStatusOperator(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'operator')
end

-- 获取模组实时频段
local function getSimStatusBand(index)

    -- TODO: 通过AT指令获取

    return SimStatus[index].bandRealTime
end

-- 获取模组实时小区
local function getSimStatusCell(index)

    -- TODO: 通过AT指令获取

    return SimStatus[index].cellRealTime
end

-- 获取模组ip
local function getSimStatusIP(index)
    
    -- TODO: 通过AT指令获取

    return SimStatus[index].ip
end

-- 获取模组掩码
local function getSimStatusMask(index)
    
    -- TODO: 通过AT指令获取

    return SimStatus[index].mask
end

-- 获取模组网关
local function getSimStatusGateway(index)
    
    -- TODO: 通过AT指令获取

    return SimStatus[index].gateway
end

-- 获取SIM卡状态：是否插卡、拨号状态、信号强度、运营商、频段、小区...
function M.getSimStatus(params)

    local index = tonumber(params.index) + 1

    -- 通过AT指令更新实时信号强度、频段、入网方式、小区id
    updateSimStatusSignal(index)

    -- 模组硬件信息
    SimStatus[index].usb = getSimUsb(index)
    SimStatus[index].alias = getSimAlias(index)
    SimStatus[index].module = getSimModuleName(index)
    SimStatus[index].version = getSimModuleVersion(index)
    SimStatus[index].imei = getSimModuleIMEI(index)
    SimStatus[index].imsi = getSimModuleIMSI(index)
    SimStatus[index].ttyusb = getSimNode(index)
    SimStatus[index].interface = getSimInterface(index)
    -- 模组配置信息
    SimStatus[index].bandSetting = getSimConfBand(index)
    SimStatus[index].netSetting = string.upper(getSimConfNet(index))
    SimStatus[index].apn = getSimConfAPN(index)
    SimStatus[index].auth = getSimConfAuth(index)
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

-- 更改配置
function M.changeSimSettings(params)
    log.info('change sim settings')

    return { code = 0 }
end


return M
