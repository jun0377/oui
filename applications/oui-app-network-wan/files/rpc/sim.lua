local M = {}
local log = require 'log'
local uci = require 'eco.uci'

log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/sim.log'

local function exec(command)
    local pp = io.popen(command)
    if not pp then
        return ''
    end

    local data = pp:read("*a")
    pp:close()
    return data
end

-- 根据逻辑接口名来获取真实物理网口名, 如: wan0 -> eth0
local function get_interface(ifname)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end
    
    local cmd = string.format("ubus call network.interface.%s status 2>/dev/null | jsonfilter -e '@.device' | tr -d '\r\n'", ifname)
    return exec(cmd)
end

-- 获取指定网口的IP
function getInterfaceIP(interface)
    
    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end
    
    local cmd = string.format("ip addr show %s | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1  | tr -d '\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的掩码
function getInterfaceMask(interface)
    
    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end
    
    local cmd = string.format("ifconfig %s | grep 'Mask:' | awk -F 'Mask:' '{print $2}' | tr -d '\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的网关
function getInterfaceGateway(interface)
    
    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end

    local cmd = string.format("ip route show default | grep %s | awk '{print $3}'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取指定网口的mac地址
function getInterfaceMAC(interface)
    
    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end
    
    local cmd = string.format("cat /sys/class/net/%s/address | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取网口下行数据量
function getInterfaceRxBytes(interface)

    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end

    local cmd = string.format("cat /sys/class/net/%s/statistics/rx_bytes | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取网口上行数据量
function getInterfaceTxBytes(interface)

    if nil == interface or '' == interface then
        log.error('ifname is nil!')
        return false
    end
    
    local cmd = string.format("cat /sys/class/net/%s/statistics/tx_bytes | tr -d '\r\n'", interface)
    -- log.info(cmd)
    return exec(cmd)
end

-- 获取模组对应的usb端点号
local function getSimUsb(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end
    
    local c = uci.cursor()
    return c:get('sim', ifname, 'usb')
end

-- 获取模组拨号节点
local function getSimNode(ifname)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    local ttyUSB = c:get('sim', ifname, 'ttyUSB')
    if not ttyUSB or ttyUSB == '' then
        log.error(string.format("%s ttyUSB is not defined! (uci get sim.%s.ttyUSB)", ifname, ifname))
        return nil
    end

    local usb = c:get('sim', ifname, 'usb')
    if not usb or usb == '' then
        log.error(string.format("%s usb sysfs path is not defined!", ifname))
        return nil
    end

    local sysfs_path = string.format("%s/%s", usb, ttyUSB)
    local cmd = string.format("ls %s 2>/dev/null | grep ttyUSB | head -1 | tr -d '\r\n'", sysfs_path)
    local tty = exec(cmd)
    if tty == '' then
        log.error(string.format("%s can not find ttyUSB in %s", ifname, sysfs_path))
        return nil
    end

    return string.format("/dev/%s", tty)
end

-- 获取模组mac地址
local function getSimMac(ifname)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local interface = get_interface(ifname)
    return getInterfaceMAC(interface)
end

-- 获取模组频段设置
local function getSimConfBand(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'band')
end

-- 获取模组入网方式设置
local function getSimConfNet(ifname)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'net')
end

-- 获取模组APN设置
local function getSimConfAPN(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'apn')
end

-- 获取模组鉴权设置
local function getSimConfAuth(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'auth')
end

-- 获取模组用户名设置
local function getSimConfUser(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'user')
end

-- 获取模组密码设置
local function getSimConfPasswd(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'passwd')
end

-- 获取模组小区设置
local function getSimConfCell(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'cell')
end

-- 获取模组物理小区PCI设置
local function getSimConfPCI(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'pci')
end

-- 获取状态更新时间戳
local function getRealTimeStatusTimestamp(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/timestamp", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡状态
local function getRealTimeStatusSim(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/sim_status", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡国家码
local function getRealTimeStatusCountry(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/country", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡运营商mcc
local function getRealTimeStatusMCC(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/mcc", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡运营商mnc
local function getRealTimeStatusMNC(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/mnc", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡运营商字符串描述
local function getRealTimeStatusOperator(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/operator", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡工作频率
local function getRealTimeStatusFreq(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/freq", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡5G NR注册状态
local function getRealTimeStatus5GCore(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/C5GCore", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡LTE注册状态
local function getRealTimeStatus4GCore(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/LTECore", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡当前驻留小区信息
local function getRealTimeStatusMONSC(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/monsc", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡当前相邻小区信息
local function getRealTimeStatusMONNC(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/monnc", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置, Radio Access Technology无线接入技术
local function getModuleSettingsRAT(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/rat_setting", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置, Packet Data Protocol分组数据协议
local function getModuleSettingsPDP(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/pdp_setting", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置, auth: 鉴权设置,数据业务（PDP/PDN）建立时对 APN 的认证，常见于企业专网卡/物联网卡
local function getModuleSettingsAUTH(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/auth_setting", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置, NR锁频锁小区配置
local function getModuleSettingsNRLock(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/nrlock_setting", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置, LTE锁频锁小区配置
local function getModuleSettingsLTELock(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/ltelock_setting", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取模组厂商id
local function getSimVendor(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/vendor", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取模组型号
local function getSimModel(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/model", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取模组版本
local function getSimRevision(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/revision", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取模组imei
local function getSimIMEI(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/imei", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取SIM卡imei
local function getSimIMSI(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/imsi", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取SIM卡iccid
local function getSimICCID(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local f = io.open(string.format("/tmp/tracker-sim/%s/iccid", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "")
end

-- 获取网络接口信息
function M.getInterfaceStatus(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local interface = get_interface(ifname)
    
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
function M.getProductInfo(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local vendor = getSimVendor(ifname)
    local product = getSimModel(ifname)
    local revision = getSimRevision(ifname)
    local imei = getSimIMEI(ifname)
    local iccid = getSimICCID(ifname)
    local imsi = getSimIMSI(ifname)
    local ret = string.format(
        '{"vendor":"%s","product":"%s","revision":"%s","imei":"%s","iccid":"%s","imsi":"%s"}',
        vendor:gsub('"', '\\"'),
        product:gsub('"', '\\"'),
        revision:gsub('"', '\\"'),
        imei:gsub('"', '\\"'),
        iccid:gsub('"', '\\"'),
        imsi:gsub('"', '\\"')
    )
    -- log.info(ret)
    return ret
end

-- {
-- "timestamp": "$(date '+%H:%M:%S')",
-- "sim": "${CPIN_TEXT}",
-- "country":"${COUNTRY}",
-- "mcc":"${MCC}", "mnc":"${MNC}",
-- "operator_name":"$COPS",
-- "freqInfo":${HFREQINFO_JSON:-null},
-- "C5GCore":${C5GREG_JSON:-null},
-- "C4GCore":${CEREG_JSON:-null},
-- "monsc":{
--   "rat":"$RAT",
--   "nr":{"cell_id":"$NR_CELL_ID","arfcn":"$NR_ARFCN","scs":"$NR_SCS","pci":"$NR_PCI","tac":"$NR_TAC","rsrp":"$NR_RSRP","rsrq":"$NR_RSRQ","sinr":"$NR_SINR"},
--   "lte":{"cell_id":"$LTE_CELL_ID","arfcn":"$LTE_ARFCN","pci":"$LTE_PCI","tac":"$LTE_TAC","rsrp":"$LTE_RSRP","rsrq":"$LTE_RSRQ","rssi":"$LTE_RSSI"},
--   "wcdma":{"arfcn":"$WCDMA_ARFCN","pcs":"$WCDMA_PCS","cell_id":"$WCDMA_CELL_ID","lac":"$WCDMA_LAC","rscp":"$WCDMA_RSCP","rxlev":"$WCDMA_RXLEV","ecno":"$WCDMA_ECNO"}
-- },
-- "monnc":{"gsm":${NC_GSM_JSON:-[]},"wcdma":${NC_WCDMA_JSON:-[]},"lte":${NC_LTE_JSON:-[]},"nr":${NC_NR_JSON:-[]}},
-- }
-- 获取模组实时信息
function M.getStatus(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local timestamp = getRealTimeStatusTimestamp(ifname)
    local sim = getRealTimeStatusSim(ifname)
    local country = getRealTimeStatusCountry(ifname)
    local mcc = getRealTimeStatusMCC(ifname)
    local mnc = getRealTimeStatusMNC(ifname)
    local operator = getRealTimeStatusOperator(ifname)
    local freqInfo = getRealTimeStatusFreq(ifname)
    local C5GCore = getRealTimeStatus5GCore(ifname)
    local C4GCore = getRealTimeStatus4GCore(ifname)
    local monsc = getRealTimeStatusMONSC(ifname)
    local monnc = getRealTimeStatusMONNC(ifname)

    local function esc(s)
        return s:gsub('\\', '\\\\'):gsub('"', '\\"')
    end

    local ret = string.format(
        '{"timestamp":"%s","sim":"%s","country":"%s","mcc":"%s","mnc":"%s","operator_name":"%s","freqInfo":%s,"C5GCore":%s,"C4GCore":%s,"monsc":%s,"monnc":%s}',
        esc(timestamp),
        esc(sim),
        esc(country),
        esc(mcc),
        esc(mnc),
        esc(operator),
        freqInfo ~= "" and freqInfo or "null",
        C5GCore ~= "" and C5GCore or "null",
        C4GCore ~= "" and C4GCore or "null",
        monsc ~= "" and monsc or "null",
        monnc ~= "" and monnc or "null"
    )

    return ret
end

-- {
-- "rat": "${SETTINGS_NET}",
-- "pdp": ${PDP_JSON:-null},
-- "auth": ${AUTH_JSON:-null},
-- "nrfreqlock":${NR_FREQLOCK_JSON:-null},
-- "ltefreqlock":${LTE_FREQLOCK_JSON:-null}
-- }
-- 查询模组配置,是从模组内部查询到的配置,并不是uci配置
function M.getModuleSettings(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local rat = getModuleSettingsRAT(ifname)
    local pdp = getModuleSettingsPDP(ifname)
    local auth = getModuleSettingsAUTH(ifname)
    local nrfreqlock = getModuleSettingsNRLock(ifname)
    local ltefreqlock = getModuleSettingsLTELock(ifname)

    local ret = string.format(
        '{"rat":"%s","pdp":%s,"auth":%s,"nrfreqlock":%s,"ltefreqlock":%s}',
        rat:gsub('\\', '\\\\'):gsub('"', '\\"'),
        pdp ~= "" and pdp or "null",
        auth ~= "" and auth or "null",
        nrfreqlock ~= "" and nrfreqlock or "null",
        ltefreqlock ~= "" and ltefreqlock or "null"
    )

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
function M.getSimUciSettings(ifname)
    local cmd = string.format("ubus call uci get '{\"config\":\"sim\",\"section\":\"%s\"}' | jq -c '.values'", ifname)
    log.info(cmd)
    local ret = exec(cmd)
    -- log.info(ret)
    return ret
end

-- 更改入网方式
local function setSimNet(ifname, net)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end
    
    if nil == net or '' == net then
        log.error('net is nil!')
        return false
    end

    local sim_net = string.lower(net)
    if 'auto' ~= sim_net and 'sa' ~= sim_net and 'nsa' ~= sim_net and 'lte' ~= sim_net then
        log.error('unknown net:', sim_net)
        return false
    end
    
    local old_net = getSimConfNet(ifname)
    if sim_net == old_net then
        log.info(ifname, "net doesn't changed! net:", sim_net)
        return true
    end

    log.info(ifname, 'set net from', old_net, 'to', sim_net)
    local c = uci.cursor()
    c:set("sim", ifname, 'net', sim_net)
    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    
    dial(interface)
    
    return true
end

-- 更改apn
local function setSimAPN(ifname, apn)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == apn or '' == apn then
        log.error('apn is nil!')
        return false
    end

    local old_apn = getSimConfAPN(ifname)
    if old_apn == apn then
        log.info(ifname, "apn doesn't changed! apn:", apn)
        return true
    end

    log.info(ifname, 'set apn from ', old_apn, 'to', apn)
    local c = uci.cursor()
    c:set("sim", ifname, 'apn', apn)
    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)

    return true
end

-- 更改频段
local function setSimBand(ifname, band)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == band or '' == band then
        log.error('band is nil!')
        return false
    end

    local old_band = getSimConfBand(ifname)
    if old_band == band then
        log.info(ifname, "band doesn't changed! band:", band)
        return true
    end

    log.info(ifname, 'set band from ', old_band, 'to', band)
    local c = uci.cursor()
    c:set("sim", ifname, 'band', band)
    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)
end

-- 更改小区
local function setSimPCID(ifname, PCID)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local old_PCID = getSimConfPCI(ifname)
    if old_PCID == PCID then
        log.info(ifname, "PCID doesn't changed! PCID:", PCID)
        return true
    end

    log.info(ifname, 'set PCID from ', old_PCID, 'to', PCID)
    local c = uci.cursor()
    c:set("sim", ifname, 'pci', PCID)
    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)
end

-- 锁NR PCI小区
local function setSimNRPCID(ifname, PCID)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local c = uci.cursor()
    
    if (PCID.enabled) then
        c:set("sim", ifname, 'nrPciLock', 'true')
    else
        c:set("sim", ifname, 'nrPciLock', 'false')
        c:set("sim", ifname, 'nrPciPcid', 'none')
        c:set("sim", ifname, 'nrPciBand', 'none')
        c:set("sim", ifname, 'nrPciFreq', 'none')
        c:set("sim", ifname, 'nrPciScs', 'none')
        c:commit('sim')
        return true
    end

    c:set("sim", ifname, 'nrPciPcid', PCID.pcid)
    c:set("sim", ifname, 'nrPciBand', PCID.band)
    c:set("sim", ifname, 'nrPciFreq', PCID.freq)
    c:set("sim", ifname, 'nrPciScs', PCID.scs)

    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)

    return true
end

-- 锁LTE PCI小区
local function setSimLTEPCID(ifname, PCID)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == PCID or '' == PCID then
        log.error('PCID is nil!')
        return false
    end

    local c = uci.cursor()
    
    if (PCID.enabled) then
        c:set("sim", ifname, 'ltePciLock', 'true')
    else
        c:set("sim", ifname, 'ltePciLock', 'false')
        c:set("sim", ifname, 'ltePciPcid', 'none')
        c:set("sim", ifname, 'ltePciBand', 'none')
        c:set("sim", ifname, 'ltePciFreq', 'none')
        c:commit('sim')
        return
    end

    c:set("sim", ifname, 'ltePciPcid', PCID.pcid)
    c:set("sim", ifname, 'ltePciBand', PCID.band)
    c:set("sim", ifname, 'ltePciFreq', PCID.freq)

    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)
end

-- 更改鉴权、用户名、密码
local function setSimAuth(ifname, auth, apn, username, password)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end
    
    if nil == auth or '' == auth then
        log.error(ifname, 'unknown auth')
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

    local c = uci.cursor()
    c:set("sim", ifname, 'auth', auth)
    c:set("sim", ifname, 'apn', apn)
    c:set("sim", ifname, 'user', username)
    c:set("sim", ifname, 'passwd', password)
    c:commit('sim')

    local interface = c:get('sim', ifname, 'logicInterface')
    dial(interface)

end

-- 更改配置
function M.changeSimSettings(params)
    
    local ifname=params.alias

    log.info(string.format("index:%s %s net:%s", params.index, params.alias, params.net))
    log.info(string.format("index:%s %s apn:%s auth:%s username:%s passwd:%s", params.index, params.alias, params.apn, params.auth, params.username, params.password))
    log.info(string.format("index:%s %s nrBand:%s", params.index, params.alias, params.nrBand))
    log.info(string.format("index:%s %s lteBand:%s", params.index, params.alias, params.lteBand))
    log.info(string.format("index:%s %s NR PCI: enable:%s pcid:%s band:%s freq:%s scs:%s", params.index, params.alias, 
                        params.nr_pci.enabled, params.nr_pci.pcid,params.nr_pci.band,params.nr_pci.freq,params.nr_pci.scs))
    log.info(string.format("index:%s %s LTE PCI: enable:%s pcid:%s band:%s freq:%s", params.index, params.alias, 
                        params.lte_pci.enabled, params.lte_pci.pcid,params.lte_pci.band,params.lte_pci.freq))

    local index = tonumber(params.index) + 1

    setSimNet(ifname, params.net)
    setSimAPN(ifname, params.apn)
    -- setSimBand(index, params.band)
    setSimNRPCID(ifname, params.nr_pci)
    setSimLTEPCID(ifname, params.lte_pci)
    setSimAuth(ifname, params.auth, params.apn, params.username, params.password)

    return { code = 0 }
end

-- 更改链路使能
function M.changeSimEnable(params)

    local ifname = params.alias
    log.info(string.format("ifname:%s enable:%s", ifname, tostring(params.enable)))
    
    local c = uci.cursor()
    local interface = get_interface(ifname)
    if interface == nil or interface == '' then
        log.error(string.format("get_interface(%s) failed", ifname))
        return -1
    end

    local cmd = ''
    if params.enable then
        c:set("sim", ifname, 'enable', 'true')
        c:commit('sim')

        cmd = string.format('ifup %s', interface)
        exec(cmd)

        -- 触发拨号
        dial(interface)
    else
        c:set("sim", ifname, 'enable', 'false')
        c:commit('sim')
        
        cmd = string.format('ifdown %s', interface)
        exec(cmd)
    end

    return 0
end



return M
