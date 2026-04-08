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
    local cmd = string.format("cat /sys/class/net/%s/address | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取网口下行数据量
function getInterfaceRxBytes(interface)
    local cmd = string.format("cat /sys/class/net/%s/statistics/rx_bytes | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取网口上行数据量
function getInterfaceTxBytes(interface)
    local cmd = string.format("cat /sys/class/net/%s/statistics/tx_bytes | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定USB好对应的网口名,如2-1对应eth2
function getInterfaceByUsb(usb)
    local cmd = string.format("ls /sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/%s/%s:2.0/net/ | tr -d '\r\n'", usb, usb)
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
    -- local section = Sim[index].settings.uciSection
    -- local c = uci.cursor()
    -- return c:get('sim', section, 'interface')
    local usb = getSimUsb(index)
    local interface = getInterfaceByUsb(usb)
    return interface
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


-- 获取网络接口信息
function M.getInterfaceStatus(params)
    local index = tonumber(params.index) + 1
    local interface = getSimInterface(index)
    
    if not interface or interface == "" then
        return { code = -1, msg = "Interface not found" }
    end

    local ip = getInterfaceIP(interface)
    local mask = getInterfaceMask(interface)
    local gateway = getInterfaceGateway(interface)
    local mac = getInterfaceMAC(interface)
    local rxBytes = getInterfaceRxBytes(interface)
    local txBytes = getInterfaceTxBytes(interface)

    return  {
            interface = interface,
            ip = ip,
            mask = mask,
            gateway = gateway,
            mac = mac,
            rxBytes = rxBytes,
            txBytes = txBytes,
            }
end

-- {
-- "vendor":"TD Tech Ltd.",
-- "product":"MT5700M-CN",
-- "revision":"V200R001C20B022",
-- "imei":"864640060183744",
-- "iccid":"89860322249103745837",
-- "imsi":"460115403693387"
-- }
-- 获取模组基本信息
function M.getProductInfo(params)
    local index = tonumber(params.index) + 1
    local node = getSimNode(index)
    local cmd = string.format("/usr/share/modemdata/product.sh %s", node)
    log.info(cmd)
    local ret = exec(cmd);
    -- log.info(ret)
    return ret
end

-- 获取模组实时信息
function M.getRealtimeStatus(params)
    local index = tonumber(params.index) + 1
    local node = getSimNode(index)
    local cmd = string.format("/usr/share/modemdata/params.sh %s", node)
    log.info(cmd)
    local ret = exec(cmd);
    -- log.info(ret)
    return ret
end

-- 获取模组内部配置信息
function M.getSettings(params)
    local index = tonumber(params.index) + 1
    local node = getSimNode(index)
    local cmd = string.format("/usr/share/modemdata/query_settings.sh %s", node)
    log.info(cmd)
    local ret = exec(cmd)
    -- log.info(ret)
    return ret
end

-- 获取SIM卡运营商 和 状态
function M.getStatus(params)
    local index = tonumber(params.index) + 1
    local node = getSimNode(index)
    local cmd = string.format("/usr/share/modemdata/params.sh %s", node)
    log.info(cmd)
    local ret = exec(cmd)
    -- log.info("status:", ret)
    return ret
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置
function M.getModuleSettings(params)
    local index = tonumber(params.index) + 1
    local node = getSimNode(index)
    local cmd = string.format("/usr/share/modemdata/query_settings.sh %s", node)
    log.info(cmd)
    local ret = exec(cmd)
    -- log.info(ret)
    return ret
end

-- 触发重新拨号
local function dial(interface)
    local cmd = string.format("ifup %s", interface)
    log.info(cmd)
    exec(cmd)
end

-- 从/etc/config/sim这个配置文件中查询配置
function M.getSimUciSettings(params)
    local index = tonumber(params.index) + 1
    local section = Sim[index].settings.uciSection
    local cmd = string.format("ubus call uci get '{\"config\":\"sim\",\"section\":\"%s\"}' | jq -c '.values'", section)
    log.info(cmd)
    local ret = exec(cmd)
    -- log.info(ret)
    return ret
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

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
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

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
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
    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
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

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
end

-- 锁NR PCI小区
local function setSimNRPCID(index, PCID)

    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local section = Sim[index].settings.uciSection

    local c = uci.cursor()
    
    if (PCID.enabled) then
        c:set("sim", section, 'nrPciLock', 'true')
    else
        c:set("sim", section, 'nrPciLock', 'false')
        c:set("sim", section, 'nrPciPcid', 'none')
        c:set("sim", section, 'nrPciBand', 'none')
        c:set("sim", section, 'nrPciFreq', 'none')
        c:set("sim", section, 'nrPciScs', 'none')
        c:commit('sim')
        return
    end

    c:set("sim", section, 'nrPciPcid', PCID.pcid)
    c:set("sim", section, 'nrPciBand', PCID.band)
    c:set("sim", section, 'nrPciFreq', PCID.freq)
    c:set("sim", section, 'nrPciScs', PCID.scs)

    c:commit('sim')

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
end

-- 锁LTE PCI小区
local function setSimLTEPCID(index, PCID)

    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local section = Sim[index].settings.uciSection

    local c = uci.cursor()
    
    if (PCID.enabled) then
        c:set("sim", section, 'ltePciLock', 'true')
    else
        c:set("sim", section, 'ltePciLock', 'false')
        c:set("sim", section, 'ltePciPcid', 'none')
        c:set("sim", section, 'ltePciBand', 'none')
        c:set("sim", section, 'ltePciFreq', 'none')
        c:commit('sim')
        return
    end

    c:set("sim", section, 'ltePciPcid', PCID.pcid)
    c:set("sim", section, 'ltePciBand', PCID.band)
    c:set("sim", section, 'ltePciFreq', PCID.freq)

    c:commit('sim')

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)
end

-- 更改鉴权、用户名、密码
local function setSimAuth(index, auth, apn, username, password)
    if nil == auth or '' == auth then
        log.error(Sim[index].settings.alias, 'unknown auth')
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

    local interface = c:get('sim', section, 'logicInterface')
    dial(interface)

end

-- 更改配置
function M.changeSimSettings(params)
    
    log.info(string.format("index:%s %s net:%s", params.index, params.alias, params.net))
    log.info(string.format("index:%s %s apn:%s auth:%s username:%s passwd:%s", params.index, params.alias, params.apn, params.auth, params.username, params.password))
    log.info(string.format("index:%s %s nrBand:%s", params.index, params.alias, params.nrBand))
    log.info(string.format("index:%s %s lteBand:%s", params.index, params.alias, params.lteBand))
    log.info(string.format("index:%s %s NR PCI: enable:%s pcid:%s band:%s freq:%s scs:%s", params.index, params.alias, 
                        params.nr_pci.enabled, params.nr_pci.pcid,params.nr_pci.band,params.nr_pci.freq,params.nr_pci.scs))
    log.info(string.format("index:%s %s LTE PCI: enable:%s pcid:%s band:%s freq:%s", params.index, params.alias, 
                        params.lte_pci.enabled, params.lte_pci.pcid,params.lte_pci.band,params.lte_pci.freq))

    local index = tonumber(params.index) + 1

    setSimNet(index, params.net)
    setSimAPN(index, params.apn)
    -- setSimBand(index, params.band)
    setSimNRPCID(index, params.nr_pci)
    setSimLTEPCID(index, params.lte_pci)
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

        -- 触发拨号
        dial(interface)
    else
        c:set("sim", section, 'enable', '0')
        c:commit('sim')
        
        cmd = string.format('ifdown %s', interface)
        exec(cmd)
    end

    return 0
end



return M
