local M = {}
local log = require 'log'
local uci = require 'eco.uci'
local cjson = require 'cjson'

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

-- 从RPC参数中提取ifname（兼容 table 如 {ifname="sim1"} 和字符串 "sim1"）
local function getIfname(params)
    if type(params) == "table" then
        return params.ifname or params.alias or nil
    end
    return params
end

-- 根据逻辑接口名来获取真实物理网口名, 如: sim1 -> eth1
local function get_interface(ifname)
    
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end
    
    -- 优先从 tracker-sim 的 interface 文件中读取
    local f = io.open(string.format("/tmp/tracker-sim/%s/interface", ifname), "r")
    if f then
        local dev = f:read("*a")
        f:close()
        dev = dev:gsub("[\r\n]", "")
        if dev ~= "" then
            return dev
        end
    end

    -- fallback: 通过 ubus 查询
    local cmd = string.format("ubus call network.interface.%s status 2>/dev/null | jsonfilter -e '@.device' | tr -d '\r\n'", ifname)
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

-- 获取 NR 锁频段设置
local function getSimConfNRBand(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'nrBandLock')
end

-- 获取 LTE 锁频段设置
local function getSimConfLTEBand(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    return c:get('sim', ifname, 'lteBandLock')
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

-- 读取 plmn JSON 文件，一次获取 country / mcc / mnc / operator
local function readPlmnInfo(ifname)
    if nil == ifname or '' == ifname then
        return "", "", "", ""
    end
    local f = io.open(string.format("/tmp/tracker-sim/%s/plmn", ifname), "r")
    if not f then
        return "", "", "", ""
    end
    local data = f:read("*a")
    f:close()
    local ok, plmn = pcall(cjson.decode, data)
    if not ok or type(plmn) ~= "table" then
        return "", "", "", ""
    end
    local country = plmn.country or ""
    local mcc = ""
    local mnc = ""
    local p = plmn.plmn
    if p and type(p) == "string" then
        if #p >= 3 then mcc = p:sub(1, 3) end
        if #p >= 5 then mnc = p:sub(4) end
    end
    local operator = plmn.long_name or ""
    return country, mcc, mnc, operator
end

-- 通过ICCID前6位(IIN)来获取运营商，仅限中国大陆
local operator_iin_map = {
    ["898600"] = "中国移动",
    ["898602"] = "中国移动",
    ["898604"] = "中国移动",
    ["898607"] = "中国移动",
    ["898601"] = "中国联通",
    ["898606"] = "中国联通",
    ["898609"] = "中国联通",
    ["898603"] = "中国电信",
    ["898611"] = "中国电信",
    ["898615"] = "中国广电",
}
local function getOpenatorFromICCID(iccid)
    if not iccid or iccid == "" then
        return "", ""
    end
    if #iccid < 6 then
        return "", ""
    end
    local prefix = iccid:sub(1, 6)
    local operator = operator_iin_map[prefix]
    if operator then
        return operator, "CN"
    end
    return "", ""
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

    local f = io.open(string.format("/tmp/tracker-sim/%s/C5GREG", ifname), "r")
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

    local f = io.open(string.format("/tmp/tracker-sim/%s/CLTEREG", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    return data:gsub("[\r\n]", "") 
end

-- 获取SIM卡实时信号强度
local function getRealTimeStatusHCSQ(ifname)
    if nil == ifname or '' == ifname then
        return ""
    end
    local f = io.open(string.format("/tmp/tracker-sim/%s/hcsq", ifname), "r")
    if not f then
        return ""
    end
    local data = f:read("*a")
    f:close()
    if not data then
        return ""
    end
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
    data = data:gsub("[\r\n]", "")

    -- 清理 AT 指令响应噪声（如 AT^NRFREQLOCK?、OK 等）
    local ok, parsed = pcall(cjson.decode, data)
    if ok and parsed and type(parsed) == "table" then
        if parsed.band and type(parsed.band) == "table" then
            local clean = {}
            for _, v in ipairs(parsed.band) do
                local s = tostring(v)
                -- 只保留纯数字的频段值
                if s:match("^%d+$") then
                    table.insert(clean, s)
                end
            end
            parsed.band = clean
        end
        return cjson.encode(parsed)
    end

    return data
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
    data = data:gsub("[\r\n]", "")

    -- 清理 AT 指令响应噪声（如 AT^LTEFREQLOCK?、OK 等）
    local ok, parsed = pcall(cjson.decode, data)
    if ok and parsed and type(parsed) == "table" then
        if parsed.band and type(parsed.band) == "table" then
            local clean = {}
            for _, v in ipairs(parsed.band) do
                local s = tostring(v)
                if s:match("^%d+$") then
                    table.insert(clean, s)
                end
            end
            parsed.band = clean
        end
        return cjson.encode(parsed)
    end

    return data
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
    ifname = getIfname(ifname)

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
        vendor:gsub('\\', '\\\\'):gsub('"', '\\"'),
        product:gsub('\\', '\\\\'):gsub('"', '\\"'),
        revision:gsub('\\', '\\\\'):gsub('"', '\\"'),
        imei:gsub('\\', '\\\\'):gsub('"', '\\"'),
        iccid:gsub('\\', '\\\\'):gsub('"', '\\"'),
        imsi:gsub('\\', '\\\\'):gsub('"', '\\"')
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
    ifname = getIfname(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    -- log.info('ifname', ifname)

    local timestamp = getRealTimeStatusTimestamp(ifname)
    local sim = getRealTimeStatusSim(ifname)
    local country, mcc, mnc, operator = readPlmnInfo(ifname)
    if operator == "" then
        local iccid = getSimICCID(ifname)
        operator, country = getOpenatorFromICCID(iccid)
    end
    local freqInfo = getRealTimeStatusFreq(ifname)
    local C5GCore = getRealTimeStatus5GCore(ifname)
    local C4GCore = getRealTimeStatus4GCore(ifname)
    local monsc = getRealTimeStatusMONSC(ifname)
    local monnc = getRealTimeStatusMONNC(ifname)
    local hcsq = getRealTimeStatusHCSQ(ifname)

    local function esc(s)
        return s:gsub('\\', '\\\\'):gsub('"', '\\"')
    end

    local function jsonval(s)
        if s == "" then
            return "null"
        end
        local head = s:match("^%s*(%S)")
        if head == "{" or head == "[" then
            return s
        end
        return "null"
    end

    local ret = string.format(
        '{"timestamp":"%s","sim":"%s","country":"%s","mcc":"%s","mnc":"%s","operator_name":"%s","freqInfo":%s,"C5GCore":%s,"C4GCore":%s,"monsc":%s,"monnc":%s,"hcsq":%s}',
        esc(timestamp),
        esc(sim),
        esc(country),
        esc(mcc),
        esc(mnc),
        esc(operator),
        jsonval(freqInfo),
        jsonval(C5GCore),
        jsonval(C4GCore),
        jsonval(monsc),
        jsonval(monnc),
        jsonval(hcsq)
    )

    -- log.info(ret)

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
    ifname = getIfname(ifname)

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

-- 获取网口实时信息
function M.getInterfaceStatus(params)
    local interface = getIfname(params)

    if nil == interface or '' == interface then
        log.error('interface is nil!')
        return cjson.encode({ code = -1, msg = "Invalid interface name" })
    end

    -- 根据逻辑接口名获取真实物理网口名
    local dev = get_interface(interface)
    if dev ~= nil and dev ~= "" and dev ~= false then
        interface = dev
    end

    local function readFile(path)
        local f = io.open(path, "r")
        if not f then
            return ""
        end
        local data = f:read("*a")
        f:close()
        if not data then
            return ""
        end
        return data:gsub("[\r\n]", "")
    end

    -- 链路状态: up / down
    local carrier = readFile(string.format("/sys/class/net/%s/carrier", interface))
    local operstate = readFile(string.format("/sys/class/net/%s/operstate", interface))
    local up = (carrier == "1" and operstate == "up")

    -- MAC地址
    local mac = readFile(string.format("/sys/class/net/%s/address", interface))

    -- 收发字节数
    local rxBytes = readFile(string.format("/sys/class/net/%s/statistics/rx_bytes", interface))
    local txBytes = readFile(string.format("/sys/class/net/%s/statistics/tx_bytes", interface))

    -- IP / 掩码 / 网关
    local ipOut = exec(string.format("ip -o -4 addr show %s 2>/dev/null", interface))
    local ip, cidrNum = ipOut:match("inet%s+(%d+%.%d+%.%d+%.%d+)/(%d+)")
    local ip = ip or ""
    local gateway = exec(string.format("ip -4 route show default dev %s 2>/dev/null | awk 'NR==1{print $3}'", interface)):gsub("[\r\n]", "")

    -- CIDR 转掩码
    local mask = ""
    if ip and cidrNum then
        local n = tonumber(cidrNum)
        if n then
            local parts = { 0, 0, 0, 0 }
            for i = 1, #parts do
                local bits = n >= 8 and 8 or (n > 0 and n or 0)
                parts[i] = (0xff << (8 - bits)) & 0xff
                n = n - bits
            end
            mask = string.format("%d.%d.%d.%d", parts[1], parts[2], parts[3], parts[4])
        end
    end

    return cjson.encode({
        interface = interface,
        up = up,
        mac = mac,
        rxBytes = rxBytes,
        txBytes = txBytes,
        ip = ip,
        mask = mask,
        gateway = gateway
    })
end

-- 触发重新拨号
local function dial(ifname)
    local cmd = string.format("ifup %s", ifname)
    log.info(cmd)
    exec(cmd)
end

-- 从/etc/config/sim这个配置文件中查询配置
function M.getSimUciSettings(ifname)
    ifname = getIfname(ifname)
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
    
    dial(ifname)
    
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

    dial(ifname)

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

    dial(ifname)
    return true
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

    dial(ifname)
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
        c:set("sim", ifname, 'nrPciLockEnable', 'locked')
    else
        c:set("sim", ifname, 'nrPciLockEnable', 'unlocked')
        c:set("sim", ifname, 'nrPciPcid', 'unlocked')
        c:set("sim", ifname, 'nrPciBand', 'unlocked')
        c:set("sim", ifname, 'nrPciFreq', 'unlocked')
        c:set("sim", ifname, 'nrPciScs', 'unlocked')
        c:commit('sim')
        return true
    end

    c:set("sim", ifname, 'nrPciPcid', PCID.pcid)
    c:set("sim", ifname, 'nrPciBand', PCID.band)
    c:set("sim", ifname, 'nrPciFreq', PCID.freq)
    c:set("sim", ifname, 'nrPciScs', PCID.scs)

    c:commit('sim')

    dial(ifname)

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
        c:set("sim", ifname, 'ltePciLockEnable', 'locked')
    else
        c:set("sim", ifname, 'ltePciLockEnable', 'unlocked')
        c:set("sim", ifname, 'ltePciPcid', 'unlocked')
        c:set("sim", ifname, 'ltePciBand', 'unlocked')
        c:set("sim", ifname, 'ltePciFreq', 'unlocked')
        c:commit('sim')
        return
    end

    c:set("sim", ifname, 'ltePciPcid', PCID.pcid)
    c:set("sim", ifname, 'ltePciBand', PCID.band)
    c:set("sim", ifname, 'ltePciFreq', PCID.freq)

    c:commit('sim')

    dial(ifname)
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

    dial(ifname)
    return true
end

-- 更改NR锁频段配置
local function setSimNRBand(ifname, nrBandLock)
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == nrBandLock or '' == nrBandLock then
        nrBandLock = 'unlocked'
    end

    log.info(ifname, 'set nrBandLock from ', getSimConfNRBand(ifname), 'to', nrBandLock)
    local c = uci.cursor()
    c:set("sim", ifname, 'nrBandLock', nrBandLock)
    c:commit('sim')
    return true
end

-- 更改LTE锁频段配置
local function setSimLTEBand(ifname, lteBandLock)
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == lteBandLock or '' == lteBandLock then
        lteBandLock = 'unlocked'
    end

    log.info(ifname, 'set lteBandLock from ', getSimConfLTEBand(ifname), 'to', lteBandLock)
    local c = uci.cursor()
    c:set("sim", ifname, 'lteBandLock', lteBandLock)
    c:commit('sim')
    return true
end

-- 更改配置
function M.changeSimSettings(params)
    
    local ifname = getIfname(params)

    log.info(string.format("index:%s %s net:%s", params.index, params.alias, params.net))
    log.info(string.format("index:%s %s apn:%s auth:%s username:%s passwd:%s", params.index, params.alias, params.apn, params.auth, params.username, params.password))
    log.info(string.format("index:%s %s nrBandLock:%s", params.index, params.alias, params.nrBand))
    log.info(string.format("index:%s %s lteBandLock:%s", params.index, params.alias, params.lteBand))
    log.info(string.format("index:%s %s NR PCI Lock: enable:%s pcid:%s band:%s freq:%s scs:%s", params.index, params.alias, 
                        params.nr_pci.enabled, params.nr_pci.pcid,params.nr_pci.band,params.nr_pci.freq,params.nr_pci.scs))
    log.info(string.format("index:%s %s LTE PCI Lock: enable:%s pcid:%s band:%s freq:%s", params.index, params.alias, 
                        params.lte_pci.enabled, params.lte_pci.pcid,params.lte_pci.band,params.lte_pci.freq))

    setSimNRBand(ifname, params.nrBand)
    setSimLTEBand(ifname, params.lteBand)
    setSimNet(ifname, params.net)
    setSimAPN(ifname, params.apn)
    setSimNRPCID(ifname, params.nr_pci)
    setSimLTEPCID(ifname, params.lte_pci)
    setSimAuth(ifname, params.auth, params.apn, params.username, params.password)

    return { code = 0 }
end

-- 更改链路使能
function M.changeSimEnable(params)

    local ifname = getIfname(params)
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
        dial(ifname)
    else
        c:set("sim", ifname, 'enable', 'false')
        c:commit('sim')
        
        cmd = string.format('ifdown %s', ifname)
        exec(cmd)
    end

    return 0
end



return M
