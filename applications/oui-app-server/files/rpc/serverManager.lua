local M = {}
local uci = require 'eco.uci'
local log = require 'log'

-- log
log.level = 'trace'
log.usecolor = true
log.outfile = '/var/log/serverManager.log'

local function exec(command)
    log.info('cmd', command)
    local pp = io.popen(command)
    local data = pp:read("*a")
    pp:close()
    log.info('cmd', command, 'done')
    return data
end

-- 异步执行命令
local function exec_async(command)
    log.info('cmd async', command)
    os.execute(string.format("( %s ) >/dev/null 2>/dev/null &", command))
end

-- 重启 openmptcprouter-vps。
-- 一次保存会连续触发多次重启请求(服务器IP/传输模式等)，并发执行会互相打断，
-- 这里用 flock 串行化: 已有重启在跑时只登记 pending，由持锁的流程结束后补跑一次，
-- 保证最后一次配置一定被应用。
local function restart_vps_async()
    exec_async([[
        if ! command -v flock >/dev/null 2>&1 || ! exec 9>'/tmp/oui_vps_restart.lock'; then
            /etc/init.d/openmptcprouter-vps restart
            exit 0
        fi
        if ! flock -n 9; then
            : > '/tmp/oui_vps_restart.pending'
            exit 0
        fi
        while :; do
            rm -f '/tmp/oui_vps_restart.pending'
            /etc/init.d/openmptcprouter-vps restart
            [ -f '/tmp/oui_vps_restart.pending' ] || break
        done
    ]])
end

local PING_CACHE_DIR = '/tmp/oui_ping_cache'
local PING_CACHE_TTL = 5

local function get_ping_default_state()
    return {reachable = false, rtt_ms = 0, pkt_loss = 0}
end

local function get_ping_cache_file(src, dst)
    local key = string.format('%s__%s', tostring(src or 'default'), tostring(dst or 'unknown'))
    key = key:gsub('[^%w%-_%.]', '_')
    return string.format('%s/%s.state', PING_CACHE_DIR, key)
end

local function read_ping_cache(src, dst)
    local path = get_ping_cache_file(src, dst)
    local file = io.open(path, 'r')
    if not file then
        return nil
    end

    local cache = {}
    for line in file:lines() do
        local key, value = line:match('^([%w_]+)=(.*)$')
        if key then
            cache[key] = value
        end
    end
    file:close()

    local timestamp = tonumber(cache.timestamp)
    if not timestamp then
        return nil
    end

    return {
        timestamp = timestamp,
        reachable = tonumber(cache.reachable) == 1,
        rtt_ms = tonumber(cache.rtt_ms) or 0,
        pkt_loss = tonumber(cache.pkt_loss) or 0
    }
end

local function trigger_ping_refresh(src, dst)
    -- dst may be a table (UCI list), convert to string
    if type(dst) == 'table' then
        dst = dst[1]
    end

    local cache_file = get_ping_cache_file(src, dst)
    local cmd = 'ping -W 3 -c 3 -i 0.5'
    if src then
        cmd = cmd .. ' -I ' .. src
    end
    cmd = cmd .. ' ' .. dst

    exec_async(string.format([[
        mkdir -p '%s'
        tmp_file='%s.tmp.'$$
        output="$( %s 2>&1 )"
        pkt_loss="$(printf '%%s\n' "$output" | sed -n 's/.* \([0-9][0-9]*\)%% packet loss.*/\1/p' | tail -n 1)"
        rtt_avg="$(printf '%%s\n' "$output" | sed -n 's/.*min\/avg\/max\/mdev = [0-9.]*\/\([0-9.][0-9.]*\)\/.*/\1/p' | tail -n 1)"
        reachable=0
        if [ -n "$pkt_loss" ] && [ "$pkt_loss" -lt 100 ]; then
            reachable=1
        fi
        {
            echo "timestamp=$(date +%%s)"
            echo "reachable=$reachable"
            echo "rtt_ms=${rtt_avg:-0}"
            echo "pkt_loss=${pkt_loss:-0}"
        } > "$tmp_file"
        mv "$tmp_file" '%s'
    ]], PING_CACHE_DIR, cache_file, cmd, cache_file))
end

local function is_valid_ipv4(ip)
    if not ip then
        return false
    end
    ip = tostring(ip)
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then
        return false
    end
    a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    if not a or not b or not c or not d then
        return false
    end
    if a < 0 or a > 255 then
        return false
    end
    if b < 0 or b > 255 then
        return false
    end
    if c < 0 or c > 255 then
        return false
    end
    if d < 0 or d > 255 then
        return false
    end
    return true
end

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

-- ping ping -W 3 -c 3 -i 0.5 -I src dst
local function ping(src, dst)
    local state = get_ping_default_state()
    if not dst then
        log.error('Unknown ping dst')
        return state
    end

    local cache = read_ping_cache(src, dst)
    if cache then
        local age = os.time() - cache.timestamp
        if age >= 0 and age <= PING_CACHE_TTL then
            state.reachable = cache.reachable
            state.rtt_ms = cache.rtt_ms
            state.pkt_loss = cache.pkt_loss
        else
            state.rtt_ms = 0
        end
    end

    trigger_ping_refresh(src, dst)
    return state
end

-- shadowsocks
local function setShadowsocksIP(server_ip)
    log.info('set shadowsocks ip: ', server_ip)
    local c = uci.cursor()
    c:set("shadowsocks-libev","sss0","server",server_ip)
    c:commit('shadowsocks-libev')
    c:set("shadowsocks-rust","sss0","server",server_ip)
    c:commit('shadowsocks-rust')
end

-- glorytun
local function setGlorytunIP(server_ip)
    log.info('set glorytun vpn: ', server_ip)
    local c = uci.cursor()
    c:set("glorytun","vpn","host",server_ip)
    c:commit('glorytun')
    c:set("glorytun-udp","vpn","host",server_ip)
    c:commit('glorytun-udp')
end

-- dsvpn
local function setDsvpnIP(server_ip)
    log.info('set DSVPN ip: ', server_ip)
    local c = uci.cursor()
    c:set("dsvpn","vpn","host",server_ip)
    c:commit('dsvpn')
end

-- mlvpn
local function setMLVPNip(server_ip)
    log.info('set MLVPN ip: ', server_ip)
    local c = uci.cursor()
    c:set("mlvpn","general","host",server_ip)
    c:commit('mlvpn')
end

-- openvpn
local function setOpenVpnIP(server_ip)
    log.info('set OpenVPN ip: ', server_ip)
    local cmd = "uci -q del openvpn.omr.remote"
    exec(cmd)

    cmd = "uci -q add_list openvpn.omr.remote=" .. server_ip
    exec(cmd)

    cmd = "uci commit openvpn"
    exec(cmd)
end

-- openmptcprouter vps
local function setVPSip(server_ip)
    log.info('set vps ip: ', server_ip)

    local cmd = "uci del openmptcprouter.vps.ip"
    exec(cmd)

    cmd = "uci add_list openmptcprouter.vps.ip=" .. server_ip
    exec(cmd)

    cmd = "uci commit openmptcprouter"
    exec(cmd)
end

-- uci get openmptcprouter.vps.ip
function M.getServerIP()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'ip')
end

-- uci get openmptcprouter.vps.port
function M.getServerPort()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'port')
end

-- 获取聚合模式配置: 服务器IP/端口 + 传输模式(openvpn->tcp, mqvpn->udp)
function M.getAggregateConfig()
    local c = uci.cursor()
    local vpn = c:get('openmptcprouter', 'settings', 'vpn')

    return {
        ip = c:get('openmptcprouter', 'vps', 'ip') or '',
        port = tonumber(c:get('openmptcprouter', 'vps', 'port')) or 0,
        -- settings.vpn 为空时聚合模式默认使用 mqvpn
        transport = vpn == 'openvpn' and 'tcp' or 'udp'
    }
end

-- 保存聚合模式配置: 工作模式 + 服务器IP/端口 + 传输模式
-- 合并为一次下发, 只重启一次服务
function M.applyAggregateConfig(params)
    if params == nil or params.ip == nil or params.port == nil or params.transport == nil then
        return -1
    end
    if not is_valid_ipv4(params.ip) then
        log.error('invalid server ip: ', tostring(params.ip))
        return -1
    end

    local server_port = tonumber(params.port)
    if not server_port or server_port < 0 or server_port > 65535 then
        log.error('invalid server port: ', tostring(params.port))
        return -1
    end

    local transport = trim(params.transport):lower()
    local vpn
    if transport == 'tcp' then
        vpn = 'openvpn'
    elseif transport == 'udp' then
        vpn = 'mqvpn'
    else
        log.error('unknown transport mode: ', transport)
        return -1
    end

    local mode = trim(params.mode)
    if mode == '' then
        mode = 'aggregate'
    end

    local server_ip = tostring(params.ip)
    log.info('apply aggregate config: mode=', mode, ' ip=', server_ip, ' port=', server_port, ' vpn=', vpn)

    -- 服务器地址下发到各 VPN 后端(内部各自 commit)
    setVPSip(server_ip)
    setShadowsocksIP(server_ip)
    setGlorytunIP(server_ip)
    setDsvpnIP(server_ip)
    setMLVPNip(server_ip)
    setOpenVpnIP(server_ip)

    -- 上面已改动过配置文件, cursor 必须在之后创建, 否则会用旧数据覆盖刚写入的内容
    local c = uci.cursor()
    c:set('global', 'global', 'mode', mode)
    c:set('openmptcprouter', 'vps', 'port', tostring(server_port))
    c:set('openmptcprouter', 'settings', 'vpn', vpn)

    local mode_committed = c:commit('global')
    local vps_committed = c:commit('openmptcprouter')
    if not mode_committed or not vps_committed then
        log.error('commit failed, mode=', tostring(mode_committed), ' vps=', tostring(vps_committed))
        return -1
    end

    -- 配置变化后由 openmptcprouter-vps 重新下发配置并重启相关服务
    restart_vps_async()

    return 0
end

-- 获取服务器主机是否可达，比较耗时，需要在vue中异步获取
function M.getHostRtt()
    
    log.info('getHostRtt...')

    local server = M.getServerIP()
    if not server then
        return nil
    end
    return ping(nil, server)
end

-- 获取VPN隧道的连通性，比较耗时，需要在vue中异步获取
function M.getVPNrtt()
    
    log.info('getVPNrtt from /tmp/tracker-ovpn/tracker-ovpn.json')

    local state = {reachable = false, rtt_ms = 0, pkt_loss = 0}

    -- 从 omr-tracker 保存的 JSON 文件中读取 omrvpn 探测结果
    local json_file = '/tmp/tracker-ovpn/tracker-ovpn.json'

    local status = exec("jsonfilter -i " .. json_file .. " -e '@.status' 2>/dev/null")
    if nil == status or status == "" then
        log.warn('tracker-ovpn.json not available')
        return state
    end
    status = status:gsub("[\r\n]", "")

    local latency = exec("jsonfilter -i " .. json_file .. " -e '@.latency' 2>/dev/null")
    if latency then
        latency = latency:gsub("[\r\n]", "")
        state.rtt_ms = tonumber(latency) or 0
    end

    local loss = exec("jsonfilter -i " .. json_file .. " -e '@.loss' 2>/dev/null")
    if loss then
        loss = loss:gsub("[\r\n]", "")
        state.pkt_loss = tonumber(loss) or 0
    end

    state.reachable = (status == "OK")

    log.info('reachable = ', state.reachable, ' rtt_ms = ', state.rtt_ms, ' pkt_loss = ', state.pkt_loss)
    return state
end

-- 获取服务器节点信息
function M.getServerNode()

    local isp = exec("jq -r '.isp' /etc/vps_info")
    if not isp then
        log.error('/etc/vps_info json parse failed!')
        return nil
    end

    local regionName = exec("jq -r '.regionName' /etc/vps_info")
    if not regionName then
        log.error('/etc/vps_info json parse failed!')
        return nil
    end

    -- {    
    --      "status":"success",
    --      "country":"China",
    --      "countryCode":"CN",
    --      "region":"SH",
    --      "regionName":"Shanghai",
    --      "city":"Shanghai",
    --      "zip":"",
    --      "lat":31.2222,
    --      "lon":121.4581,
    --      "timezone":"Asia/Shanghai",
    --      "isp":"Hangzhou Alibaba Advertising Co., Ltd.",
    --      "org":"Alibaba.com LLC",
    --      "as":"AS37963 Hangzhou Alibaba Advertising Co.,Ltd.",
    --      "query":"8.153.200.211"
    -- }

    return isp .. ' ' .. regionName
end

-- 获取服务器版本
function M.getServerVersion()
    local file = io.open('/etc/vps_version', 'r')
    if not file then
        log.error('/etc/vps_version not exist!')
        return 'unknown'
    end

    local version = file:read('*a')
    file:close()

    return version
end

-- 获取服务器公告信息
function M.getServerAnnourcement()
    local file = io.open('/etc/vps_annourcement', 'r')
    if not file then
        log.error('/etc/vps_annourcementn not exist!')
        return 'none'
    end

    local annourcement = file:read('*a')
    file:close()

    return annourcement
end

return M
