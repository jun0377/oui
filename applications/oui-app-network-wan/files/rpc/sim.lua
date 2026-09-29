local M = {}
local log = require 'log'
local uci = require 'eco.uci'
local ubus = require 'eco.ubus'
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
    -- local f = io.open(string.format("/tmp/tracker-sim/%s/interface", ifname), "r")
    -- if f then
    --     local dev = f:read("*a")
    --     f:close()
    --     dev = dev:gsub("[\r\n]", "")
    --     if dev ~= "" then
    --         return dev
    --     end
    -- end

    -- 通过 ubus 查询
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

-- 获取自动优选小区开关
local function getSimConfPCIAutoSelect(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    -- c:get()会额外返回选项类型, 这里只取的值
    local value = c:get('sim', ifname, 'pciAutoSelect')
    return value
end

-- 获取自动优选小区探测超时时间(秒)
local function getSimConfPCIAutoSelectTimeout(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    local value = c:get('sim', ifname, 'pciAutoSelectTimeout')
    return value
end

-- 获取自动优选小区排除的小区PCI列表(十进制, 000为占位符)
local function getSimConfPCIAutoSelectExclude(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local c = uci.cursor()
    local value = c:get('sim', ifname, 'pciAutoSelectExclude')
    return value
end

-- 优选小区探测文件路径
-- 探测结果仅本次运行有效, 由tracker-sim保存在tmpfs中, 不写入UCI配置文件
local function getPciAutoSelectFile(ifname)
    return string.format("/tmp/tracker-sim/%s/autoPciSelect", ifname)
end

-- 获取自动优选小区探测状态
-- 探测中返回剩余秒数与已探测轮次; 探测完成后返回tracker-sim选出的最稳定NR/LTE小区
local function getPciAutoSelectStatus(ifname)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local enabled = getSimConfPCIAutoSelect(ifname)
    local timeout = tonumber(getSimConfPCIAutoSelectTimeout(ifname)) or 60

    local status = {
        enabled = (enabled == '1' or enabled == 'true'),
        running = false,
        remain = 0,
        round = 0,
        timeout = timeout,
        reason = ''
    }

    local f = io.open(getPciAutoSelectFile(ifname), "r")
    if not f then
        -- 已开启但探测文件尚未生成, 等待tracker-sim开始探测
        if status.enabled then
            status.running = true
            status.remain = timeout
        end
        return status
    end

    local raw = f:read("*a")
    f:close()

    local ok, probe = pcall(cjson.decode, raw or '')
    if not ok or type(probe) ~= 'table' then
        log.error(string.format("%s autoPciSelect file is invalid", ifname))
        return status
    end

    status.timeout = tonumber(probe.timeout) or timeout
    status.round = type(probe.pci_data) == 'table' and #probe.pci_data or 0

    local start_ts = tonumber(probe.start_timestamp) or 0
    local stop_ts = tonumber(probe.stop_timestamp) or 0
    if stop_ts == 0 and start_ts > 0 then
        -- 探测中: 剩余时间按文件中记录的开始时间推算, 前端不再自行计时
        local elapsed = os.time() - start_ts
        status.running = elapsed < status.timeout
        status.remain = status.running and (status.timeout - elapsed) or 0
    end

    if type(probe.result) == 'table' then
        status.reason = probe.result.reason or ''
        status.nr = probe.result.nr
        status.lte = probe.result.lte
        status.finished_at = probe.result.timestamp
    end

    return status
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
    -- 路由器当前时间, 用于前端校准与浏览器时钟的偏移
    local now = os.date("%Y-%m-%d %H:%M:%S")
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

    -- 模组是否被系统识别: 检查 uci sim.<name>.usb 指向的 sysfs 目录是否存在
    -- (有的设备可能未安装模组或模组未上电)
    local moduleExist = false
    local usb = getSimUsb(ifname)
    if usb and usb ~= '' then
        local f = io.open(usb, 'r')
        if f then
            f:close()
            moduleExist = true
        end
    end

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
        '{"timestamp":"%s","now":"%s","sim":"%s","country":"%s","mcc":"%s","mnc":"%s","operator_name":"%s","freqInfo":%s,"C5GCore":%s,"C4GCore":%s,"monsc":%s,"monnc":%s,"hcsq":%s,"moduleExist":%s}',
        esc(timestamp),
        esc(now),
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
        jsonval(hcsq),
        tostring(moduleExist)
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
    ip = ip or ""
    local gateway = exec(string.format("ip -4 route show default dev %s 2>/dev/null | awk '/via/ {for(i=1;i<=NF;i++) if($i==\"via\"){print $(i+1); exit}}'", interface)):gsub("[\r\n]", "")
    -- 兜底: 主路由表查不到时查所有路由表
    if not gateway:match("^%d+%.%d+%.%d+%.%d+$") then
        gateway = exec(string.format("ip -4 route show table all 2>/dev/null | grep 'default via' | grep 'dev %s' | head -1 | awk '{for(i=1;i<=NF;i++) if($i==\"via\"){print $(i+1); exit}}'", interface)):gsub("[\r\n]", "")
    end
    
    if not gateway:match("^%d+%.%d+%.%d+%.%d+$") then
        gateway = ""
    end

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
    -- log.info(cmd)
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

    if nil == PCID then
        log.error('PCID is nil!')
        return false
    end

    local c = uci.cursor()

    -- 清除旧的列表值
    c:delete("sim", ifname, 'nrPciPcid')
    c:delete("sim", ifname, 'nrPciBand')
    c:delete("sim", ifname, 'nrPciFreq')
    c:delete("sim", ifname, 'nrPciScs')
    c:delete("sim", ifname, 'nrPciForbidFlag')

    if not PCID.enabled then
        c:set("sim", ifname, 'nrPciLockEnable', 'unlocked')
        c:commit('sim')
        return true
    end

    c:set("sim", ifname, 'nrPciLockEnable', 'locked')

    -- 重选切换: reSelEnabled=true 允许重选 → forbidFlag=0; reSelEnabled=false 禁止重选 → forbidFlag=1
    local forbidFlag = PCID.reSelEnabled ~= false and '0' or '1'
    c:set("sim", ifname, 'nrPciForbidFlag', forbidFlag)

    local items = PCID.items
    if not items or #items == 0 then
        c:commit('sim')
        return true
    end

    local pcid_list = {}
    local band_list = {}
    local freq_list = {}
    local scs_list = {}

    for _, item in ipairs(items) do
        if item and item.pcid and item.pcid ~= '' then
            table.insert(pcid_list, tostring(item.pcid))
            table.insert(band_list, tostring(item.band or ''))
            table.insert(freq_list, tostring(item.freq or ''))
            table.insert(scs_list, tostring(item.scs or ''))
        end
    end

    if #pcid_list > 0 then
        c:set("sim", ifname, 'nrPciPcid', pcid_list)
        c:set("sim", ifname, 'nrPciBand', band_list)
        c:set("sim", ifname, 'nrPciFreq', freq_list)
        c:set("sim", ifname, 'nrPciScs', scs_list)
    end

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

    -- 清除旧的列表值
    c:delete("sim", ifname, 'ltePciPcid')
    c:delete("sim", ifname, 'ltePciBand')
    c:delete("sim", ifname, 'ltePciFreq')
    c:delete("sim", ifname, 'ltePciForbidFlag')

    if not PCID.enabled then
        c:set("sim", ifname, 'ltePciLockEnable', 'unlocked')
        c:commit('sim')
        return true
    end

    c:set("sim", ifname, 'ltePciLockEnable', 'locked')

    -- 重选切换: reSelEnabled=true 允许重选 → forbidFlag=0; reSelEnabled=false 禁止重选 → forbidFlag=1
    local forbidFlag = PCID.reSelEnabled ~= false and '0' or '1'
    c:set("sim", ifname, 'ltePciForbidFlag', forbidFlag)

    local items = PCID.items
    if not items or #items == 0 then
        c:commit('sim')
        return true
    end

    local pcid_list = {}
    local band_list = {}
    local freq_list = {}

    for _, item in ipairs(items) do
        if item and item.pcid and item.pcid ~= '' then
            table.insert(pcid_list, tostring(item.pcid))
            table.insert(band_list, tostring(item.band or ''))
            table.insert(freq_list, tostring(item.freq or ''))
        end
    end

    if #pcid_list > 0 then
        c:set("sim", ifname, 'ltePciPcid', pcid_list)
        c:set("sim", ifname, 'ltePciBand', band_list)
        c:set("sim", ifname, 'ltePciFreq', freq_list)
    end

    c:commit('sim')

    dial(ifname)

    return true
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

-- 更改自动优选小区配置
-- pciMode: prefer=自动优选小区(写入pciAutoSelect=1) / 其他=手动锁小区(pciAutoSelect=0)
-- prefer: { timeout=探测超时秒数, exclude_pcis={排除的小区PCI(十进制)} }
-- 参数发生变化时复位探测文件并重新拨号, 由tracker-sim重新探测优选
local function setSimPCIAutoSelect(ifname, pciMode, prefer)

    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    if nil == pciMode or '' == pciMode then
        log.info(ifname, "pciMode is nil, skip pciAutoSelect!")
        return true
    end

    prefer = prefer or {}
    local enabled = (pciMode == 'prefer') and '1' or '0'
    local timeout = tonumber(prefer.timeout) or 60

    -- 排除的小区PCI列表(十进制), 没有有效值时写入占位符000
    local exclude_list = {}
    local items = prefer.exclude_pcis
    if type(items) == 'table' then
        for _, item in ipairs(items) do
            local pci = tostring(item or ''):gsub('%s+', '')
            if pci ~= '' then
                table.insert(exclude_list, pci)
            end
        end
    end
    if #exclude_list == 0 then
        exclude_list = { '000' }
    end

    local c = uci.cursor()
    local old_enabled = tostring(getSimConfPCIAutoSelect(ifname) or '')
    local old_timeout = tonumber(getSimConfPCIAutoSelectTimeout(ifname)) or 60
    local old_exclude = getSimConfPCIAutoSelectExclude(ifname)
    if type(old_exclude) ~= 'table' then
        old_exclude = { tostring(old_exclude or '') }
    end

    -- 只有参数变化时才复位探测
    local changed = (old_enabled ~= enabled)
        or (old_timeout ~= timeout)
        or (table.concat(old_exclude, ',') ~= table.concat(exclude_list, ','))

    c:set("sim", ifname, 'pciAutoSelect', enabled)
    c:set("sim", ifname, 'pciAutoSelectTimeout', tostring(timeout))
    c:delete("sim", ifname, 'pciAutoSelectExclude')
    c:set("sim", ifname, 'pciAutoSelectExclude', exclude_list)
    c:commit('sim')

    if not changed then
        log.info(ifname, "pciAutoSelect settings doesn't changed!")
        return true
    end

    log.info(ifname, 'set pciAutoSelect:', enabled, 'timeout:', timeout, 'exclude:', table.concat(exclude_list, ' '))

    -- 复位探测文件并重新拨号: 解除上一次优选锁定的小区, 由tracker-sim重新探测
    exec(string.format("rm -f %s", getPciAutoSelectFile(ifname)))
    dial(ifname)

    return true
end

-- 更改配置
function M.changeSimSettings(params)
    
    local ifname = getIfname(params)

    log.info(string.format("index:%s %s net:%s", params.index, params.alias, params.net))
    log.info(string.format("index:%s %s apn:%s auth:%s username:%s passwd:%s", params.index, params.alias, params.apn, params.auth, params.username, params.password))
    log.info(string.format("index:%s %s nrBandLock:%s", params.index, params.alias, params.nrBand))
    log.info(string.format("index:%s %s lteBandLock:%s", params.index, params.alias, params.lteBand))
    log.info(string.format("index:%s %s NR PCI Lock: enable:%s items:%s", params.index, params.alias,
                        tostring(params.nr_pci and params.nr_pci.enabled), tostring(#((params.nr_pci and params.nr_pci.items) or {}))))
    log.info(string.format("index:%s %s LTE PCI Lock: enable:%s items:%s", params.index, params.alias,
                        tostring(params.lte_pci and params.lte_pci.enabled), tostring(#((params.lte_pci and params.lte_pci.items) or {}))))
    log.info(string.format("index:%s %s pciMode:%s pciPrefer:%s", params.index, params.alias,
                        tostring(params.pci_mode), cjson.encode(params.pci_prefer or {})))

    setSimNRBand(ifname, params.nrBand)
    setSimLTEBand(ifname, params.lteBand)
    setSimNet(ifname, params.net)
    setSimAPN(ifname, params.apn)
    setSimNRPCID(ifname, params.nr_pci)
    setSimLTEPCID(ifname, params.lte_pci)
    setSimAuth(ifname, params.auth, params.apn, params.username, params.password)
    setSimPCIAutoSelect(ifname, params.pci_mode, params.pci_prefer)

    return { code = 0 }
end

-- 更改链路使能
function M.changeSimEnable(params)

    if not params then
        log.error('changeSimEnable: params is nil')
        return -1
    end

    local ifname = getIfname(params)
    log.info(string.format("ifname:%s enable:%s", ifname, tostring(params.enable)))

    if not ifname then
        log.error('changeSimEnable: ifname is nil')
        return -1
    end
    
    local c = uci.cursor()

    if params.enable then
        c:set("sim", ifname, 'enable', 'true')
        c:commit('sim')

        -- 触发拨号(ifup 逻辑接口, 如 ifup sim1)
        dial(ifname)
    else
        c:set("sim", ifname, 'enable', 'false')
        c:commit('sim')

        exec(string.format('ifdown %s', ifname))
    end

    return 0
end

local function readAtLogEntries(path, entries)
    local f = io.open(path, "r")
    if not f then
        return
    end

    for line in f:lines() do
        if line ~= "" then
            local ok, item = pcall(cjson.decode, line)
            if ok and type(item) == "table" and tonumber(item.seq) then
                item.seq = tonumber(item.seq)
                item.ts = item.ts or ""
                item.tty = item.tty or ""
                item.cmd = item.cmd or ""
                item.res = item.res or ""
                table.insert(entries, item)
            end
        end
    end

    f:close()
end

-- 获取 AT 指令日志（按 seq 增量传输）
function M.getAtLogs(params)
    local ifname = getIfname(params)
    if not ifname then
        return cjson.encode({ entries = {}, next_seq = 0, has_more = false, gap = false })
    end

    local after_seq = 0
    local limit = 80
    if type(params) == "table" then
        after_seq = tonumber(params.after_seq) or 0
        limit = tonumber(params.limit) or 80
    end
    if limit < 1 then
        limit = 1
    elseif limit > 200 then
        limit = 200
    end

    local log_dir = string.format("/tmp/tracker-sim/%s", ifname)
    local entries = {}
    readAtLogEntries(string.format("%s/at_log.jsonl.1", log_dir), entries)
    readAtLogEntries(string.format("%s/at_log.jsonl", log_dir), entries)

    if #entries == 0 then
        return cjson.encode({ entries = {}, next_seq = after_seq, has_more = false, gap = false })
    end

    table.sort(entries, function(a, b)
        return (a.seq or 0) < (b.seq or 0)
    end)

    local earliest_seq = entries[1].seq or 0
    local gap = (after_seq > 0 and earliest_seq > (after_seq + 1))
    local result = {}
    local has_more = false

    if after_seq <= 0 then
        local start_index = math.max(1, #entries - limit + 1)
        for i = start_index, #entries do
            result[#result + 1] = entries[i]
        end
        has_more = false
    else
        for _, entry in ipairs(entries) do
            if entry.seq > after_seq then
                result[#result + 1] = entry
                if #result >= limit then
                    break
                end
            end
        end

        local last_sent_seq = result[#result] and result[#result].seq or after_seq
        for _, entry in ipairs(entries) do
            if entry.seq > last_sent_seq then
                has_more = true
                break
            end
        end
    end

    local next_seq = result[#result] and result[#result].seq or after_seq
    return cjson.encode({
        entries = result,
        next_seq = next_seq,
        has_more = has_more,
        gap = gap,
        earliest_seq = earliest_seq
    })
end


-- ==================== sim 链路状态聚合(方案B) ====================
-- 一次 RPC 返回 sim 的实时状态/产品信息/接口运行数据, 内部基于
-- netifd(eco.ubus) + sysfs(io.open) 进程内取数, 不产生阻塞性子进程,
-- 供页面以每秒一次的频率轮询, 避免拖慢单线程 httpd。

local function prefix_mask_str(prefix)
    local n = tonumber(prefix)
    if not n or n < 0 or n > 32 then
        return ''
    end
    local parts = {}
    for i = 1, 4 do
        local bits = n >= 8 and 8 or (n > 0 and n or 0)
        parts[i] = tostring((0xff << (8 - bits)) & 0xff)
        n = n - bits
    end
    return table.concat(parts, '.')
end

local function read_trim(path)
    local f = io.open(path, 'r')
    if not f then
        return ''
    end
    local data = f:read('*a')
    f:close()
    return (data or ''):gsub('[\r\n]', '')
end

-- 兜底: 从策略路由表获取默认网关
-- openmptcprouter 将各 WAN 的默认路由放入独立 table(main 表通常没有, 如 table 6: default via x dev wwan0)
-- 表号优先取 uci network.<ifname>.ip4table, 否则按源地址从 ip rule 推导(对应规则: from <local_ip> lookup <T>)
local function resolve_gateway_from_ip_route(ifname, local_ip)
    if nil == ifname or '' == ifname or nil == local_ip or '' == local_ip then
        return ''
    end

    local c = uci.cursor()
    local tbl = c:get('network', ifname, 'ip4table') or ''
    tbl = tostring(tbl):gsub('^%s+', ''):gsub('%s+$', '')

    if tbl == '' then
        for line in exec('ip rule show'):gmatch('[^\r\n]+') do
            local from_ip = line:match('^%s*%d+:%s+from%s+(%S+)')
            if from_ip and from_ip == local_ip then
                tbl = line:match('lookup%s+(%S+)') or ''
                if tbl ~= '' then
                    break
                end
            end
        end
    end

    if not tbl:match('^%d+$') then
        return ''
    end

    local gw = exec(string.format("ip route show table %s 2>/dev/null", tbl)):match('default%s+via%s+(%S+)')
    if gw and gw ~= '0.0.0.0' and gw:match('^%d+%.%d+%.%d+%.%d+$') then
        return gw
    end
    return ''
end

-- 一次拉取 sim 链路的全部展示数据(字段对齐 getStatus + getProductInfo + getInterfaceStatus)
function M.getOverview(ifname)
    ifname = getIfname(ifname)
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return false
    end

    local ret = {}

    -- 1) sim 实时状态(纯文件读, 复用 M.getStatus)
    local ok, st = pcall(cjson.decode, M.getStatus(ifname))
    if ok and type(st) == 'table' then
        ret.timestamp = st.timestamp
        ret.now = st.now
        ret.sim = st.sim
        ret.country = st.country
        ret.mcc = st.mcc
        ret.mnc = st.mnc
        ret.operator_name = st.operator_name
        ret.freqInfo = st.freqInfo
        ret.C5GCore = st.C5GCore
        ret.C4GCore = st.C4GCore
        ret.monsc = st.monsc
        ret.monnc = st.monnc
        ret.hcsq = st.hcsq
        ret.moduleExist = (st.moduleExist == true)
    end

    -- 2) 产品信息(纯文件读, 复用 M.getProductInfo)
    local ok2, pt = pcall(cjson.decode, M.getProductInfo(ifname))
    if ok2 and type(pt) == 'table' then
        ret.vendor = pt.vendor
        ret.product = pt.product
        ret.revision = pt.revision
        ret.imei = pt.imei
        ret.iccid = pt.iccid
        ret.imsi = pt.imsi
    end

    -- 3) 接口运行状态(基于 netifd + sysfs; 网关缺失时兜底查策略路由表)
    local code = -1
    local up = false
    local ip, mask, gateway, mac = '', '', '', ''
    local rxBytes, txBytes = '', ''
    local dev = ''

    local ok3, ns = pcall(ubus.call, string.format('network.interface.%s', ifname), 'status', {})
    if ok3 and type(ns) == 'table' then
        code = 0
        up = ns.up == true
        dev = ns.l3_device or ns.device or ''
        if type(ns['ipv4-address']) == 'table' then
            for _, a in ipairs(ns['ipv4-address']) do
                if type(a) == 'table' and a.address and a.address ~= '0.0.0.0' then
                    ip = a.address
                    mask = prefix_mask_str(a.mask)
                    break
                end
            end
        end
        if type(ns.route) == 'table' then
            for _, r in ipairs(ns.route) do
                if type(r) == 'table' and r.target == '0.0.0.0' and r.nexthop and r.nexthop ~= '0.0.0.0' then
                    gateway = r.nexthop
                    break
                end
            end
        end
    end
    if gateway == '' then
        gateway = resolve_gateway_from_ip_route(ifname, ip)
    end
    if dev == '' then
        -- 兜底: 模组 tracker 记录的接口名
        dev = read_trim(string.format('/tmp/tracker-sim/%s/interface', ifname))
    end
    if dev ~= '' then
        mac = read_trim(string.format('/sys/class/net/%s/address', dev))
        rxBytes = read_trim(string.format('/sys/class/net/%s/statistics/rx_bytes', dev))
        txBytes = read_trim(string.format('/sys/class/net/%s/statistics/tx_bytes', dev))
    end

    ret.code = code
    ret.up = up
    ret.ip = ip
    ret.mask = mask
    ret.gateway = gateway
    ret.mac = mac
    ret.rxBytes = rxBytes
    ret.txBytes = txBytes

    -- 4) 使能标志(取UCI配置; 列表页状态列依赖它, 放入轮询数据避免开关后状态滞后)
    local c = uci.cursor()
    local enable = tostring(c:get('sim', ifname, 'enable') or '')
    ret.enable = (enable == '1' or enable == 'true')

    -- 5) 自动优选小区探测状态(探测结果仅本次运行有效, 不写入UCI)
    ret.pciAutoSelect = getPciAutoSelectStatus(ifname)

    return ret
end

-- 立即重选: 复位优选小区的探测文件并重新拨号, 由tracker-sim重新探测并优选
function M.pciAutoSelectReselect(params)

    local ifname = getIfname(params)
    if nil == ifname or '' == ifname then
        log.error('ifname is nil!')
        return -1
    end

    local enabled = getSimConfPCIAutoSelect(ifname)
    if enabled ~= '1' and enabled ~= 'true' then
        log.error(string.format("%s autoPciSelect is not enabled!", ifname))
        return -1
    end

    exec(string.format("rm -f %s", getPciAutoSelectFile(ifname)))
    log.info(string.format("%s pciAutoSelect reselect, remove %s", ifname, getPciAutoSelectFile(ifname)))

    -- 重新拨号以解除上一次优选锁定的小区, 使模组能自由驻留并重新探测
    exec(string.format("( sleep 2; ifdown %s; sleep 2; ifup %s ) >/dev/null 2>&1 &", ifname, ifname))

    return 0
end


return M
