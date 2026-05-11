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

-- uci set openmptcprouter.vps.ip=xxx.xxx.xxx.xxx
function M.setServerIP(params)
    if params == nil or params.ip == nil then
        return -1
    end
    if not is_valid_ipv4(params.ip) then
        return -1
    end

    local server_ip = tostring(params.ip)
    log.info('server IP: ', server_ip)
    -- vps
    setVPSip(server_ip)
    -- shadowsocks
    setShadowsocksIP(server_ip)
    -- glorytun
    setGlorytunIP(server_ip)
    -- dsvpn
    setDsvpnIP(server_ip)
    -- mlvpn
    setMLVPNip(server_ip)
    -- openvpn
    setOpenVpnIP(server_ip)

    exec_async([[
        lock="/tmp/oui_serverManager_setServerIP.lock";
        if [ -e "$lock" ]; then exit 0; fi;
        echo $$ > "$lock";
        trap 'rm -f "$lock"' EXIT;
        sleep 2;
        env -i /bin/ubus call network reload;
        ip addr flush dev tun0;
        /etc/init.d/omr-tracker stop;
        /etc/init.d/mptcp restart;
        /etc/init.d/openmptcprouter-vps restart;
        /etc/init.d/shadowsocks-libev restart;
        /etc/init.d/shadowsocks-rust restart;
        /etc/init.d/glorytun restart;
        /etc/init.d/glorytun-udp restart;
        /etc/init.d/dsvpn restart;
        /etc/init.d/mlvpn restart;
        /etc/init.d/openvpn restart;
        /etc/init.d/omr-tracker start;
        /etc/init.d/omr-6in4 restart;
        /etc/init.d/vnstat restart;
        /etc/init.d/sysntpd restart;
    ]])

    return 0
end

-- uci get openmptcprouter.vps.port
function M.getServerPort()
    local c = uci.cursor()
    return c:get('openmptcprouter', 'vps', 'port')
end

-- uci set openmptcprouter.vps.port=xxx
function M.setServerPort(params)
    local c = uci.cursor()
    c:set('openmptcprouter', 'vps', 'port', params.port)
    return c:commit('openmptcprouter')
end

-- 获取服务器主机是否可达，比较耗时，需要在vue中异步获取
function M.getHostRtt()
    
    log.info('getHostRtt...')

    local server = M.getServerIP()
    return ping(nil, server[1])
end

-- 获取VPN隧道的连通性，比较耗时，需要在vue中异步获取
function M.getVPNrtt()
    
    log.info('getVPNrtt...')

    local state = {reachable = false, rtt_ms = 0, pkt_loss = 0}

    local cmd = "cat /proc/net/dev | grep tun0"
    local res = exec(cmd)
    if nil == res then
        log.warn('VPN interface tun0 not exist')
        return state
    end

    cmd = "ip addr show dev tun0 | grep \'inet \' | awk \'{print $2}\' | cut -d/ -f1 | tr -d \'\n\'"
    local src_ip = exec(cmd)
    if nil == src_ip then
        log.warn('VPN interface tun0 has no ip')
        return state
    end

    -- log.info(src_ip)

    res = ping(src_ip, '10.255.252.1')
    log.info('reachable = ', res.reachable, ' rtt_ms = ', res.rtt_ms)
    return res
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
