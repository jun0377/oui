local M = {}
local log = require 'log'
local uci = require 'eco.uci'

log.level = 'trace'
log.usercolor = true
log.outfile = '/var/log/sim.log'

-- SIM卡状态
local Sim = {
    [1] = {
        settings = {
            usb = '',                               -- USB端口号
            interface = '',                         -- 接口名称
            alias = '5G-1',                         -- tag
            ttyusb = '',                            -- 拨号节点
            uciSection = 'SIM_5G_1',                -- UCI配置文件section命名规范
            band = '',                              -- 设置的频段
            net = '',                               -- 入网方式设置：AUTO/SA/NSA/LTE
            apn = '',                               -- apn
            auth = '',                              -- 鉴权
            user = '',                              -- 用户名
            passwd = '',                            -- 密码
            cellLocked = '',                        -- 锁小区
            pcidlocked = '',                        -- 锁物理小区pci
            dhcpRangeStart = '',                    -- DHCP地址池起始IP
            dhcpRanageEnd = '',                     -- DHCP地址池终止IP
            dhcpRangeMask = '',                     -- DHCP地址池掩码
            dhcpRangeGateway = '',                  -- DHCP地址池网关
        },
        status = {
            module = '',                            -- 模组名称
            version = '',                           -- 模组版本
            imei = '',                              -- 模组的IMEI码
            mac = '',                               -- mac地址
            status = '',                            -- 连接状态：离线、nosim(未插卡)、拨号中、在线
            timestamp = '',                         -- 状态更新时间
            rtt_ms = 0,                             -- 到服务器的延时
            net = '',                               -- 当设置为AUTO时，实时的入网方式
            rsrp_nr = 0,                            -- 5G信号强度RSRP
            rsrp_lte = 0,                           -- LTE信号强度RSRP
            sinr_nr = 0,                            -- 5G信噪比
            sinr_lte = 0,                           -- LTE信噪比
            operator = '',                          -- 运营商
            imsi = '',                              -- SIM卡的IMSI
            band = '',                              -- 实时频段
            cell_nr = '',                           -- 5G实时小区
            cell_lte = '',                          -- LTE实时小区
            pcid_nr = '',                           -- 5G物理小区ID
            pcid_lte = '',                          -- LTE物理小区ID
            ip = '',                                -- IP
            mask = '',                              -- 掩码
            gateway = '',                           -- 网关
        }
    },
    [2] = {
        settings = {
            usb = '',                               -- USB端口号
            interface = '',                         -- 接口名称
            alias = '5G-2',                         -- tag
            ttyusb = '',                            -- 拨号节点
            uciSection = 'SIM_5G_2',                -- UCI配置文件section命名规范
            band = '',                              -- 设置的频段
            net = '',                               -- 入网方式设置：AUTO/SA/NSA/LTE
            apn = '',                               -- apn
            auth = '',                              -- 鉴权
            user = '',                              -- 用户名
            passwd = '',                            -- 密码
            cellLocked = '',                        -- 锁小区
            pcidlocked = '',                        -- 锁物理小区pci
            dhcpRangeStart = '',                    -- DHCP地址池起始IP
            dhcpRanageEnd = '',                     -- DHCP地址池终止IP
            dhcpRangeMask = '',                     -- DHCP地址池掩码
            dhcpRangeGateway = '',                  -- DHCP地址池网关
        },
        status = {
            module = '',                            -- 模组名称
            version = '',                           -- 模组版本
            imei = '',                              -- 模组的IMEI码
            mac = '',                               -- mac地址
            status = '',                            -- 连接状态：离线、nosim(未插卡)、拨号中、在线
            timestamp = '',                         -- 状态更新时间
            rtt_ms = 0,                             -- 到服务器的延时
            net = '',                               -- 当设置为AUTO时，实时的入网方式
            rsrp_nr = 0,                            -- 5G信号强度RSRP
            rsrp_lte = 0,                           -- LTE信号强度RSRP
            sinr_nr = 0,                            -- 5G信噪比
            sinr_lte = 0,                           -- LTE信噪比
            operator = '',                          -- 运营商
            imsi = '',                              -- SIM卡的IMSI
            band = '',                              -- 实时频段
            cell_nr = '',                           -- 5G实时小区
            cell_lte = '',                          -- LTE实时小区
            pcid_nr = '',                           -- 5G物理小区ID
            pcid_lte = '',                          -- LTE物理小区ID
            ip = '',                                -- IP
            mask = '',                              -- 掩码
            gateway = '',                           -- 网关
        }
    },
    [3] = {
        settings = {
            usb = '',                               -- USB端口号
            interface = '',                         -- 接口名称
            alias = '5G-3',                         -- tag
            ttyusb = '',                            -- 拨号节点
            uciSection = 'SIM_5G_3',                -- UCI配置文件section命名规范
            band = '',                              -- 设置的频段
            net = '',                               -- 入网方式设置：AUTO/SA/NSA/LTE
            apn = '',                               -- apn
            auth = '',                              -- 鉴权
            user = '',                              -- 用户名
            passwd = '',                            -- 密码
            cellLocked = '',                       -- 锁小区
            pcidlocked = '',                        -- 锁物理小区pci
            dhcpRangeStart = '',                    -- DHCP地址池起始IP
            dhcpRanageEnd = '',                     -- DHCP地址池终止IP
            dhcpRangeMask = '',                     -- DHCP地址池掩码
            dhcpRangeGateway = '',                  -- DHCP地址池网关
        },
        status = {
            module = '',                            -- 模组名称
            version = '',                           -- 模组版本
            imei = '',                              -- 模组的IMEI码
            mac = '',                               -- mac地址
            status = '',                            -- 连接状态：离线、nosim(未插卡)、拨号中、在线
            timestamp = '',                         -- 状态更新时间
            rtt_ms = 0,                             -- 到服务器的延时
            net = '',                               -- 当设置为AUTO时，实时的入网方式
            rsrp_nr = 0,                            -- 5G信号强度RSRP
            rsrp_lte = 0,                           -- LTE信号强度RSRP
            sinr_nr = 0,                            -- 5G信噪比
            sinr_lte = 0,                           -- LTE信噪比
            operator = '',                          -- 运营商
            imsi = '',                              -- SIM卡的IMSI
            band = '',                              -- 实时频段
            cell_nr = '',                           -- 5G实时小区
            cell_lte = '',                          -- LTE实时小区
            pcid_nr = '',                           -- 5G物理小区ID
            pcid_lte = '',                          -- LTE物理小区ID
            ip = '',                                -- IP
            mask = '',                              -- 掩码
            gateway = '',                           -- 网关
        }
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
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'usb')
end

-- 获取模组别名,如5G-1 5G-2 4G-1 4G-2
local function getSimAlias(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'alias')
end

-- 获取模组对应的模组名称
local function getSimModuleName(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'module')
end

-- 获取模组版本
local function getSimModuleVersion(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'moduleVersion')
end

-- 获取模组拨号节点
local function getSimNode(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'node')
end

-- 获取模组对应的接口
local function getSimInterface(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'interface')
end

-- 获取模组mac地址
local function getSimMac(index)
    return getInterfaceMAC(Sim[index].settings.interface)
end

-- 获取模组频段设置
local function getSimConfBand(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'band')
end

-- 获取模组入网方式设置
local function getSimConfNet(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'net')
end

-- 获取模组APN设置
local function getSimConfAPN(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'apn')
end

-- 获取模组鉴权设置
local function getSimConfAuth(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'auth')
end

-- 获取模组用户名设置
local function getSimConfUser(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'user')
end

-- 获取模组密码设置
local function getSimConfPasswd(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'passwd')
end

-- 获取模组小区设置
local function getSimConfCell(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'cell')
end

-- 获取模组物理小区PCI设置
local function getSimConfPCI(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'pci')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeStart(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeStart')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeEnd(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeEnd')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeMask(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeMask')
end

-- 获取模组DHCP设置
local function getSimConfDhcpRangeGateway(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'dhcpRangeGateway')
end

-- 获取模组连接状态
local function getSimStatusConnect(index)

    -- nosim
    local imsi = Sim[index].status.imsi
    if nil == imsi or "none" == imsi then
        Sim[index].status.status = 'nosim'
        return Sim[index].status.status
    end

    -- udhcpc
    local cmd = string.format("ps -w | grep 'udhcpc.*%s' | grep -v grep | awk '{print $1}'", Sim[index].settings.interface)
    -- log.info(cmd)
    local pid = exec(cmd);
    if nil == pid or "" == pid then
        Sim[index].status.status = 'disconnected'
        return Sim[index].status.status
    end

    -- online
    local ip = getInterfaceIP(Sim[index].settings.interface)
    if nil == ip or "" == ip then
        Sim[index].status.status = 'dialing'
    else
        log.info(Sim[index].settings.interface, "IP:", ip)
        Sim[index].status.status = 'connected'
    end

    return Sim[index].status.status
end

-- 查询是否插卡
local function updateSimInsertStatus(interface)
    
    local file = '/var/'..interface..'.json'
    local simInsert = exec(string.format("jq '.sim' %s | tr -d '\r\n'", file))  -- jq '.sim' /var/usb0.json
    -- log.info('simInsert:', simInsert)
    return "true" == simInsert
end

-- 更新模组信号强度
function updateSimStatusSignal(index)
    
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    local ttyusb = c:get('sim', section, 'node')
    
    local interface = c:get('sim', section, 'interface')
    local file = '/var/'..interface..'.json'
    
    -- sim ready ?
    local simReady = updateSimInsertStatus(interface)    
    if not simReady then
        log.info(Sim[index].settings.alias, 'sim not insert!')
        Sim[index].status.status = 'nosim'
        Sim[index].status.timestamp = ''
        Sim[index].status.net = ''
        Sim[index].status.cell_nr = ''
        Sim[index].status.cell_lte = ''
        Sim[index].status.pcid_nr = ''
        Sim[index].status.pcid_lte = ''
        Sim[index].status.band = ''
        Sim[index].status.operator = ''
        Sim[index].status.rsrp_nr = ''
        Sim[index].status.rsrp_lte = ''
        Sim[index].status.sinr_nr = ''
        Sim[index].status.sinr_lte = ''
        Sim[index].status.ip = ''
        Sim[index].status.mask = ''
        Sim[index].status.gateway=''
        return 0
    end

    Sim[index].status.timestamp = exec(string.format("jq -r '.date' %s | tr -d '\r\n'", file))                   -- jq -r '.date' /var/usb0.json
    Sim[index].status.imsi = exec(string.format("jq -r '.imsi' %s | tr -d '\r\n'", file))                        -- jq -r '.imsi' /var/usb0.json
    Sim[index].status.imei = exec(string.format("jq -r '.imei' %s | tr -d '\r\n'", file))                        -- jq -r '.imei' /var/usb0.json 
    Sim[index].status.net = exec(string.format("jq -r '.net' %s | tr -d '\r\n'", file))                  -- jq -r '.net' /var/usb0.json
    Sim[index].status.band = exec(string.format("jq -r '.band' %s | tr -d '\r\n'", file))                -- jq -r '.band' /var/usb0.json
    Sim[index].status.cell_nr = exec(string.format("jq -r '.cell_nr' %s | tr -d '\r\n'", file))                  -- jq -r '.cell_nr' /var/usb0.json
    Sim[index].status.cell_lte = exec(string.format("jq -r '.cell_lte' %s | tr -d '\r\n'", file))                -- jq -r '.cell_lte' /var/usb0.json
    Sim[index].status.pcid_nr = exec(string.format("jq -r '.pcid_nr' %s | tr -d '\r\n'", file))            -- jq -r '.pcid_nr' /var/usb0.json
    Sim[index].status.pcid_lte = exec(string.format("jq -r '.pcid_lte' %s | tr -d '\r\n'", file))          -- jq -r '.pcid_lte' /var/usb0.json
    Sim[index].status.operator = exec(string.format("jq -r '.operator' %s | tr -d '\r\n'", file))                -- jq -r '.operator' /var/usb0.json
    Sim[index].status.rsrp_nr = exec(string.format("jq -r '.rsrp_nr' %s | tr -d '\r\n'", file))                  -- jq -r '.rsrp_nr' /var/usb0.json
    Sim[index].status.rsrp_lte = exec(string.format("jq -r '.rsrp_lte' %s | tr -d '\r\n'", file))                -- jq -r '.rsrp_lte' /var/usb0.json
    Sim[index].status.sinr_nr = exec(string.format("jq -r '.sinr_nr' %s | tr -d '\r\n'", file))                  -- jq -r '.sinr_nr' /var/usb0.json
    Sim[index].status.sinr_lte = exec(string.format("jq -r '.sinr_lte' %s | tr -d '\r\n'", file))                -- jq -r '.sinr_lte' /var/usb0.json
    Sim[index].status.ip = exec(string.format("jq -r '.ip' %s | tr -d '\r\n'", file))                            -- jq -r '.ip' /var/usb0.json
    Sim[index].status.mask = exec(string.format("jq -r '.mask' %s | tr -d '\r\n'", file))                        -- jq -r '.mask' /var/usb0.json
    Sim[index].status.gateway = exec(string.format("jq -r '.gw' %s | tr -d '\r\n'", file))                       -- jq -r '.gw' /var/usb0.json

    return 0
end

-- 获取模组运营商
local function getSimStatusOperator(index)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    return c:get('sim', section, 'operator')
end


-- 获取SIM卡状态：是否插卡、拨号状态、信号强度、运营商、频段、小区...
function M.getSimStatus(params)

    local index = tonumber(params.index) + 1

    -- 模组硬件信息
    Sim[index].settings.usb = getSimUsb(index)
    Sim[index].settings.alias = getSimAlias(index)
    Sim[index].settings.ttyusb = getSimNode(index)
    Sim[index].settings.interface = getSimInterface(index)
    Sim[index].settings.band = getSimConfBand(index)
    Sim[index].settings.net = string.upper(getSimConfNet(index))
    Sim[index].settings.apn = getSimConfAPN(index)
    Sim[index].settings.auth = getSimConfAuth(index)
    Sim[index].settings.user = getSimConfUser(index)
    Sim[index].settings.passwd = getSimConfPasswd(index)
    Sim[index].settings.cellLocked = getSimConfCell(index)
    Sim[index].settings.pcidlocked = getSimConfPCI(index)
    Sim[index].settings.dhcpRangeStart = getSimConfDhcpRangeStart(index)
    Sim[index].settings.dhcpRanageEnd = getSimConfDhcpRangeEnd(index)
    Sim[index].settings.dhcpRangeMask = getSimConfDhcpRangeMask(index)
    Sim[index].settings.dhcpRangeGateway = getSimConfDhcpRangeGateway(index)

    -- 通过AT指令更新实时信号强度、频段、入网方式、小区id
    updateSimStatusSignal(index)

    if nil == Sim[index].status.timestamp or '' == Sim[index].status.timestamp then
        Sim[index].status = 'error'
        return Sim[index]
    end

    Sim[index].status.module = getSimModuleName(index)
    Sim[index].status.version = getSimModuleVersion(index)
    Sim[index].status.mac = getSimMac(index)
    Sim[index].status.status = getSimStatusConnect(index)
    Sim[index].status.operator = getSimStatusOperator(index)

    return Sim[index]
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
        log.info(Sim[index].settings.alias, "net doesn't changed! net:", sim_net)
        return true
    end

    log.info(Sim[index].settings.alias, 'set net from', old_net, 'to', sim_net)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    c:set("sim", section, 'net', sim_net)
    c:commit('sim')

    Sim[index].settings.interface = c:get('sim', section, 'interface')
    dial(Sim[index].settings.interface)
end

-- 更改apn
local function setSimAPN(index, apn)
    if nil == apn or '' == apn then
        log.error('apn is nil!')
        return false
    end

    local old_apn = getSimConfAPN(index)
    if old_apn == apn then
        log.info(Sim[index].settings.alias, "apn doesn't changed! apn:", apn)
        return true
    end

    log.info(Sim[index].settings.alias, 'set apn from ', old_apn, 'to', apn)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    c:set("sim", section, 'apn', apn)
    c:commit('sim')

    Sim[index].settings.interface = c:get('sim', section, 'interface')
    dial(Sim[index].settings.interface)
end

-- 更改频段
local function setSimBand(index, band)
    if nil == band or '' == band then
        log.error('band is nil!')
        return false
    end

    local old_band = getSimConfBand(index)
    if old_band == band then
        log.info(Sim[index].settings.alias, "band doesn't changed! band:", band)
        return true
    end

    log.info(Sim[index].settings.alias, 'set band from ', old_band, 'to', band)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    c:set("sim", section, 'band', band)
    c:commit('sim')

    Sim[index].settings.interface = c:get('sim', section, 'interface')
    dial(Sim[index].settings.interface)
end

-- 更改小区
local function setSimPCID(index, PCID)
    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local old_PCID = getSimConfPCI(index)
    if old_PCID == PCID then
        log.info(Sim[index].settings.alias, "PCID doesn't changed! PCID:", PCID)
        return true
    end

    log.info(Sim[index].settings.alias, 'set PCID from ', old_PCID, 'to', PCID)
    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    c:set("sim", section, 'pci', PCID)
    c:commit('sim')

    Sim[index].settings.interface = c:get('sim', section, 'interface')
    dial(Sim[index].settings.interface)
end

-- 更改鉴权、用户名、密码
local function setSimAuth(index, auth, apn, username, password)
    if nil == auth or '' == auth then
        log.error(Sim[index].settings.alias, 'unknown auth')
        return
    end

    local old_auth = getSimConfAuth(index)
    local old_apn = getSimConfAPN(index)
    local old_username = getSimConfUser(index)
    local old_password = getSimConfPasswd(index)

    if old_auth == auth and old_apn == apn and old_username == username and old_password == password then
        log.info(Sim[index].settings.alias, 'Auth settings not changed! return now...')
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

    local section = Sim[index].settings.uciSection
    local c = uci.cursor()
    c:set("sim", section, 'auth', auth)
    c:set("sim", section, 'apn', apn)
    c:set("sim", section, 'user', username)
    c:set("sim", section, 'passwd', password)
    c:commit('sim')

    Sim[index].settings.interface = c:get('sim', section, 'interface')
    dial(Sim[index].settings.interface)

end

-- 更改配置
function M.changeSimSettings(params)
    
    log.info(string.format("index:%s %s net: %s apn:%s band:%s cell:%s pci:%s auth:%s username:%s password:%s",
        params.index + 1,
        Sim[params.index + 1].settings.alias,
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

-- 更改链路使能
function M.changeSimEnable(params)
    
    local index = params.index + 1
    log.info('params.enable', params.enable)
    log.info(string.format("index:%s enable:%s", tostring(index), tostring(params.enable)))
    
    local c = uci.cursor()
    local section = Sim[index].settings.uciSection
    local interface = c:get('sim', section, 'interface')
    local cmd = ''
    if params.enable then
        c:set("sim", section, 'enable', '1')
        c:commit('sim')

        cmd = string.format('ifup %s', interface)
        exec(cmd)
    else
        c:set("sim", section, 'enable', '0')
        c:commit('sim')
        
        cmd = string.format('ifdown %s', interface)
        exec(cmd)
    end

    return 0
end

return M
