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
        mac = '',                               -- mac地址

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区
        pciSetting = '',                    -- 锁物理小区pci

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
        pciRealTime = '',                   -- 物理小区ID
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
        mac = '',                               -- mac地址

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区
        pciSetting = '',                    -- 锁物理小区pci

        -- SIM卡状态
        status = 'offline',                 -- 连接状态：离线、nosim(未插卡)、拨号中、在线
        netRealTime = '',                   -- 当设置为AUTO时，实时的入网方式
        signal = 0,                         -- 信号强度RSRP
        operator = '',                      -- 运营商
        imsi = '',                          -- SIM卡的IMSI
        bandRealTime = '',                  -- 实时频段
        cellRealTime = '',                  -- 实时小区
        pciRealTime = '',                   -- 物理小区ID
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
        mac = '',                               -- mac地址

        -- SIM卡可设置的参数
        bandSetting = '',                   -- 设置的频段
        netSetting = '',                    -- 入网方式设置：AUTO/SA/NSA/LTE
        apn = '',                           -- apn
        auth = '',                          -- 鉴权
        user = '',                          -- 用户名
        passwd = '',                        -- 密码
        cellSetting = '',                   -- 锁小区
        pciSetting = '',                    -- 锁物理小区pci

        -- SIM卡状态
        status = '',                        -- 连接状态：离线、nosim(未插卡)、拨号中、在线
        netRealTime = '',                   -- 当设置为AUTO时，实时的入网方式
        signal = 0,                         -- 信号强度RSRP
        operator = '',                      -- 运营商
        interface = '',                     -- 接口名称
        imsi = '',                          -- SIM卡的IMSI
        bandRealTime = '',                  -- 实时频段
        cellRealTime = '',                  -- 实时小区
        pciRealTime = '',                   -- 物理小区ID
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
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的掩码
function getInterfaceMask(interface)
    local cmd = string.format("ifconfig %s | grep 'Mask:' | awk -F 'Mask:' '{print $2}' | tr -d '\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的网关
function getInterfaceGateway(interface)
    local cmd = string.format("ip route show default | grep %s | awk '{print $3}'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的mac地址
function getInterfaceMAC(interface)
    local cmd = string.format("ifconfig %s | grep 'HWaddr' | awk '{print $5}' | tr -d '\r\n'", interface)
    -- log.info(cmd)
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

-- 获取模组mac地址
local function getSimMac(index)
    return getInterfaceMAC(SimStatus[index].interface)
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

-- 获取模组物理小区PCI设置
local function getSimConfPCI(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'pci')
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
    -- log.info(cmd)
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

    -- +QENG: "servingcell",<state>,"NR5G-SA",<duplex_mode>,<MCC>,<MNC>,<cellID>,<PCID>,<TAC>,<ARFCN>,<band>,<NR_DL_bandwidth>,<RSRP>,<RSRQ>,<SINR>,<tx_power>,<srxlev>,<SCS>
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
    local basename = string.match(ttyusb, "ttyUSB%d*")
    local cmd = string.format("[ ! -f \"/var/lock/LCK..%s\" ] && { echo -e 'AT+CIMI\r' | microcom %s -t 100 | tr -d '\r\n'; }", basename, ttyusb)
    log.info(cmd)
    local sim = exec(cmd)
    log.info(sim)
    local s = sim:find("OK")
    return s
end

-- 更新模组信号强度
function updateSimStatusSignal(index)
    
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    local ttyusb = c:get('sim', section, 'node')
    
    -- sim ready ?
    local sim = updateSimInsertStatus(ttyusb)    
    if nil == sim or "" == sim then
        log.info(SimStatus[index].alias, 'sim not insert!')
        SimStatus[index].status = 'nosim'
        SimStatus[index].netRealTime = ''
        SimStatus[index].cellRealTime = ''
        SimStatus[index].pciRealTime = ''
        SimStatus[index].band = ''
        SimStatus[index].operator = ''
        SimStatus[index].signal = ''
        return SimStatus[index]
    end

    local basename = string.match(ttyusb, "ttyUSB%d*")
    local cmd = string.format("[ ! -f \"/var/lock/LCK..%s\" ] && { echo -e 'AT+QENG=\"servingcell\"\r' | microcom %s -t 100 | tr -d '\r\n'; }", basename, ttyusb)
    log.info(ttyusb, "AT+QENG=\"servingcell\"")
    local signal = exec(cmd)
    log.info(signal)
    parseSimUE(signal)
    local sa = parseSA(signal)
    local nsa = parseNSA(signal)
    local lte = parseLTE(signal)
    
    -- SA
    if nil ~= sa and nil == nsa and nil == lte then
        SimStatus[index].netRealTime = 'SA'
        SimStatus[index].cellRealTime = sa.cellID
        if nil ~= sa.band then
            SimStatus[index].bandRealTime = 'n'..sa.band
        end
        SimStatus[index].pciRealTime = sa.PCID
        
        if nil ~= sa.MCC and nil ~= sa.MNC then
            SimStatus[index].operator = sa.MCC..sa.MNC
        end
        SimStatus[index].signal = sa.RSRP
    -- NSA
    elseif nil == sa and nil ~= nsa and nil == lte then
        SimStatus[index].netRealTime = 'NSA'
        SimStatus[index].cellRealTime = nsa.cellID
        SimStatus[index].bandRealTime = 'n'..nsa.band
        SimStatus[index].pciRealTime = nsa.PCID
        SimStatus[index].operator = nsa.MCC..nsa.MNC
        SimStatus[index].signal = nsa.RSRP
    -- NSA
    elseif nil == sa and nil ~= nsa and nil ~= lte then
        SimStatus[index].netRealTime = 'NSA'
        SimStatus[index].cellRealTime = nsa.cellID
        SimStatus[index].pciRealTime = nsa.PCID
        SimStatus[index].bandRealTime = 'n'..nsa.band..' | b'..lte.freq_band_ind
        SimStatus[index].operator = nsa.MCC..nsa.MNC
        SimStatus[index].signal = nsa.RSRP
    -- LTE
    elseif nil == sa and nil == nsa and nil ~= lte then
        SimStatus[index].netRealTime = 'LTE'
        SimStatus[index].cellRealTime = lte.cellID
        SimStatus[index].pciRealTime = lte.PCID
        SimStatus[index].bandRealTime = 'b'..lte.freq_band_ind
        SimStatus[index].operator = lte.MCC..lte.MNC
        SimStatus[index].signal = lte.RSRP
    -- OFFLINE
    elseif nil == sa and nil == nsa and nil == lte then
        SimStatus[index].netRealTime = ''
        SimStatus[index].cellRealTime = ''
        SimStatus[index].pciRealTime = ''
        SimStatus[index].bandRealTime = ''
        SimStatus[index].operator = ''
        SimStatus[index].signal = ''
    end

    return SimStatus[index]
end

-- 获取模组运营商
local function getSimStatusOperator(index)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'operator')
end

-- 获取模组实时频段
local function getSimStatusBand(index)
    return SimStatus[index].bandRealTime
end

-- 获取模组实时小区
local function getSimStatusCell(index)
    return SimStatus[index].cellRealTime
end

-- 实时物理小区PCID
local function getSimStatusPCI(index)
    return SimStatus[index].pciRealTime
end

-- 获取模组ip
local function getSimStatusIP(index)
    SimStatus[index].ip = getInterfaceIP(SimStatus[index].interface)
    return SimStatus[index].ip
end

-- 获取模组掩码
local function getSimStatusMask(index)
    return getInterfaceMask(SimStatus[index].interface)
end

-- 获取模组网关
local function getSimStatusGateway(index)
    return getInterfaceGateway(SimStatus[index].interface)
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
    SimStatus[index].mac = getSimMac(index)
    -- 模组配置信息
    SimStatus[index].bandSetting = getSimConfBand(index)
    SimStatus[index].netSetting = string.upper(getSimConfNet(index))
    SimStatus[index].apn = getSimConfAPN(index)
    SimStatus[index].auth = getSimConfAuth(index)
    SimStatus[index].user = getSimConfUser(index)
    SimStatus[index].passwd = getSimConfPasswd(index)
    SimStatus[index].cellSetting = getSimConfCell(index)
    SimStatus[index].pciSetting = getSimConfPCI(index)
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
    SimStatus[index].pciRealTime = getSimStatusPCI(index)
    SimStatus[index].ip = getSimStatusIP(index)
    SimStatus[index].mask = getSimStatusMask(index)
    SimStatus[index].gateway = getSimStatusGateway(index)

    return SimStatus[index]
end

-- 触发/lib/netifd/proto/ncm.sh，重新拨号
local function dial(interface)
    local cmd = string.format("ifdown %s;sleep 1;ifup %s", interface, interface)
    log.info(cmd)
    exec(cmd)
end

-- 更改入网方式
local function setSimNet(index, net)
    if nil == net or '' == net then
        log.error('net is nil!')
        return false
    end

    local sim_net = string.lower(net)
    if 'auto' ~= sim_net and 'sa' ~= sim_net and 'nsa' ~= sim_net and 'lte' ~= sim_net then
        log.error('unknown net:', sim_net)
        return false
    end
    
    local old_net = getSimConfNet(index)
    if sim_net == old_net then
        log.info(SimStatus[index].alias, "net doesn't changed! net:", sim_net)
        return true
    end

    log.info(SimStatus[index].alias, 'set net from', old_net, 'to', sim_net)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    c:set("sim", section, 'net', sim_net)
    c:commit('sim')

    SimStatus[index].interface = c:get('sim', section, 'interface')
    dial(SimStatus[index].interface)
end

-- 更改apn
local function setSimAPN(index, apn)
    if nil == apn or '' == apn then
        log.error('apn is nil!')
        return false
    end

    local old_apn = getSimConfAPN(index)
    if old_apn == apn then
        log.info(SimStatus[index].alias, "apn doesn't changed! apn:", apn)
        return true
    end

    log.info(SimStatus[index].alias, 'set apn from ', old_apn, 'to', apn)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    c:set("sim", section, 'apn', apn)
    c:commit('sim')

    SimStatus[index].interface = c:get('sim', section, 'interface')
    dial(SimStatus[index].interface)
end

-- 更改频段
local function setSimBand(index, band)
    if nil == band or '' == band then
        log.error('band is nil!')
        return false
    end

    local old_band = getSimConfBand(index)
    if old_band == band then
        log.info(SimStatus[index].alias, "band doesn't changed! band:", band)
        return true
    end

    log.info(SimStatus[index].alias, 'set band from ', old_band, 'to', band)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    c:set("sim", section, 'band', band)
    c:commit('sim')

    SimStatus[index].interface = c:get('sim', section, 'interface')
    dial(SimStatus[index].interface)
end

-- 更改小区
local function setSimPCID(index, PCID)
    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local old_PCID = getSimConfPCI(index)
    if old_PCID == PCID then
        log.info(SimStatus[index].alias, "PCID doesn't changed! PCID:", PCID)
        return true
    end

    log.info(SimStatus[index].alias, 'set PCID from ', old_PCID, 'to', PCID)
    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    c:set("sim", section, 'pci', PCID)
    c:commit('sim')

    SimStatus[index].interface = c:get('sim', section, 'interface')
    dial(SimStatus[index].interface)
end

-- 更改鉴权、用户名、密码
local function setSimAuth(index, auth, apn, username, password)
    if nil == auth or '' == auth then
        log.error(SimStatus[index].alias, 'unknown auth')
        return
    end

    local old_auth = getSimConfAuth(index)
    local old_apn = getSimConfAPN(index)
    local old_username = getSimConfUser(index)
    local old_password = getSimConfPasswd(index)

    if old_auth == auth and old_apn == apn and old_username == username and old_password == password then
        log.info(SimStatus[index].alias, 'Auth settings not chenged! return now...')
        return
    end

    if nil == apn then
        apn = ''
    end

    if nil == username then
        username = ''
    end

    if nil == password then
        password = ''
    end

    local section = SimStatus[index].uciSection
    local c = uci.cursor()
    c:set("sim", section, 'auth', auth)
    c:set("sim", section, 'apn', apn)
    c:set("sim", section, 'user', username)
    c:set("sim", section, 'passwd', password)
    c:commit('sim')

    SimStatus[index].interface = c:get('sim', section, 'interface')
    dial(SimStatus[index].interface)

end

-- 更改配置
function M.changeSimSettings(params)
    
    log.info(string.format("index:%s %s net: %s apn:%s band:%s cell:%s pci:%s auth:%s username:%s password:%s",
        params.index + 1,
        SimStatus[params.index + 1].alias,
        params.net,
        params.apn,
        params.band,
        params.cell,
        params.pci,
        params.auth,
        params.username,
        params.password))
    
    local index = params.index + 1

    setSimNet(index, params.net)
    setSimAPN(index, params.apn)
    setSimBand(index, params.band)
    setSimPCID(index, params.pci)
    setSimAuth(index, params.auth, params.apn, params.username, params.password)

    return { code = 0 }
end

return M
