local hex = require 'eco.encoding.hex'
local md5 = require 'eco.hash.md5'
local time = require 'eco.time'
local file = require 'eco.file'
local log = require 'eco.log'
local cjson = require 'cjson'
local uci = require 'eco.uci'

-- 缓存 table.concat 函数，提高性能
local concat = table.concat
-- 缓存 math.random 函数，用于生成随机数
local random = math.random

-- 定义模块 M，包含错误码
local M = {
    ERROR_CODE_NOT_FOUND         = -1,
    ERROR_CODE_INVALID_ARGUMENT  = -2,
    ERROR_CODE_UNAUTHORIZED      = -3,
    ERROR_CODE_PERMISSION_DENIED = -4,
    ERROR_CODE_LOAD_SCRIPT       = -5,
    ERROR_CODE_UNKNOWN           = -6
}

-- 会话超时时间，单位秒（5分钟）
local SESSION_TIMEOUT = 300
-- 最大 nonce 数量限制，防止内存泄漏
local MAX_NONCE_CNT = 5

-- 存储无需认证的函数列表，格式：{模块名: {函数名: true}}
local no_auth_funcs = {}
-- 缓存已加载的 RPC 模块函数，格式：{模块名: 模块表}
local funcs = {}
-- 存储访问控制列表，格式：{ACL名称: ACL规则}
local acls = {}
-- 存储临时 nonce 值，用于登录验证，格式：{nonce: 定时器}
local nonces = {}
-- 存储活跃会话，格式：{会话ID: 会话对象}
local sessions = {}
-- Lua 代码缓存开关，控制是否缓存已加载的模块
local lua_code_cache = true

-- 生成指定长度的随机字符串
-- @param n: 字符串长度
-- @return: 随机字符串
local function random_string(n)
    -- 定义字符集：数字、小写字母、大写字母
    local t = {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    }
    -- 初始化结果数组
    local s = {}
    -- 字符集中随机选择一个字符添加到结果中，循环生成指定长度的随机字符
    for _ = 1, n do
        s[#s + 1] = t[random(#t)]
    end

    -- 将字符数组连接成字符串并返回
    return concat(s)
end

-- 初始化 RPC 模块
-- 从 UCI 配置中读取相关设置
function M.init()
    local c = uci.cursor()

    -- 读取 Lua 代码缓存配置，默认启用（值不为 '0' 即启用）
    lua_code_cache = c:get('oui', 'global', 'lua_code_cache') ~= '0'

    -- 遍历 UCI 配置中的 'no-auth' 段，构建无需认证的函数列表
    c:foreach('oui', 'no-auth', function(s)
        no_auth_funcs[s.module] = {}

        for _, func in ipairs(s.func or {}) do
            no_auth_funcs[s.module][func] = true
        end
    end)
end

-- 创建用于登录验证的 nonce 值
-- @return: nonce 字符串，失败返回 nil
function M.create_nonce()
    local cnt = #nonces

    if cnt > MAX_NONCE_CNT then
        log.err('The number of nonce too more than ' .. MAX_NONCE_CNT)
        return nil
    end

    local nonce = random_string(32)

    -- expires in 2s
    nonces[nonce] = time.at(2.0, function() nonces[nonce] = nil end)

    return nonce
end

-- 创建用户会话
-- @param username: 用户名
-- @param acl: 访问控制列表名称
-- @param remote_addr: 客户端远程地址
-- @return: 会话ID
function M.create_session(username, acl, remote_addr)
    -- 生成32位随机字符串作为会话ID
    local sid = random_string(32)
    -- 创建会话对象
    local session = {
        -- 设置会话超时定时器，到期自动删除会话
        tmr = time.at(SESSION_TIMEOUT, function() sessions[sid] = nil end),
        -- 记录客户端远程地址
        remote_addr = remote_addr,
        -- 记录用户名
        username = username,
        -- 关联用户的访问控制规则
        acls = acls[acl],
        -- 记录 ACL 名称
        acl = acl
    }

    -- 将会话存储到会话表中
    sessions[sid] = session

    return sid
end

-- 用户登录验证
-- @param username: 用户名
-- @param password: 密码（MD5哈希值）
-- @return: 成功返回 ACL 名称，失败返回 nil
function M.login(username, password)
    local c = uci.cursor()
    local valid = false
    local acl

    -- 遍历 UCI 配置中的用户列表
    c:foreach('oui', 'user', function(s)
        -- 检查用户名是否存在
        if s.username == username then
            -- 如果用户没有设置密码，无密码登录
            if not s.password then
                acl = s.acl
                valid = true
                return false
            end

            -- 遍历所有有效的 nonce 值
            for nonce in pairs(nonces) do
                -- 验证密码：将用户密码和 nonce 拼接后计算 MD5，与提供的密码比较
                if hex.encode(md5.sum(table.concat({s.password, nonce}, ':'))) == password then
                    acl = s.acl
                    valid = true
                    return false
                end
            end
            return false
        end
    end)

    -- 验证失败，返回 nil
    if not valid then
        return nil
    end

    -- 验证成功，返回用户的 ACL
    return acl
end

-- 获取会话信息并刷新超时时间
-- @param sid: 会话ID
-- @return: 会话对象，不存在返回 nil
function M.get_session(sid)
    local s = sessions[sid]
    if s then s.tmr:set(SESSION_TIMEOUT) end
    return s
end

-- 删除指定会话
-- @param sid: 会话ID
function M.delete_session(sid)
    sessions[sid] = nil
end

-- 获取所有访问控制列表
-- @return: ACL 表
function M.get_acls()
    return acls
end

-- 加载访问控制列表配置
-- 从 /usr/share/oui/acl 目录读取所有 JSON 格式的 ACL 文件
function M.load_acl()
    acls = {}

    for name in file.dir('/usr/share/oui/acl') do
        local acl = name:match('(.*).json')
        if acl then
            local data = file.readfile('/usr/share/oui/acl/' .. name)
            acls[acl] = cjson.decode(data)
        end
    end
end

-- 判断是否为本地会话
-- @param session: 会话对象
-- @return: 本地会话返回 true，否则返回 false
local function is_local_session(session)
    return session.remote_addr == '127.0.0.1' or session.remote_addr == '::1'
end

-- 判断指定模块和函数是否需要认证
-- @param session: 会话对象
-- @param mod: 模块名
-- @param func: 函数名
-- @return: 需要认证返回 true，否则返回 false
local function need_auth(session, mod, func)
    if is_local_session(session) then
        return false
    end

    return not no_auth_funcs[mod] or not no_auth_funcs[mod][func]
end

-- 访问控制列表匹配检查
-- @param session: 会话对象
-- @param content: 要检查的内容（通常是 "模块.函数" 格式）
-- @param class: ACL 类别（如 'rpc'）
-- @return: 允许访问返回 true，否则返回 false
function M.acl_match(session, content, class)
    if is_local_session(session) then
        return true
    end

    if not session.acls then
        return false
    end

    if not session.acls[class] then return false end

    local matchs = session.acls[class].matchs
    if not matchs then
        return false
    end

    for _, pattern in ipairs(matchs) do
        if content:match(pattern) then
            return not session.acls[class].reverse
        end
    end

    return session.acls[class].reverse
end

-- 调用 RPC 函数
-- @param mod: 模块名
-- @param func: 函数名
-- @param args: 函数参数
-- @param session: 会话对象
-- @return: 函数返回值和错误代码
function M.call(mod, func, args, session)
    -- 如果禁用代码缓存或模块未加载
    if not lua_code_cache or not funcs[mod] then
        -- 构造模块脚本路径
        local script = '/usr/share/oui/rpc/' .. mod .. '.lua'

        -- 检查脚本文件是否存在
        if not file.access(script) then
            log.err('module "' .. mod .. '" not found')
            return nil, M.ERROR_CODE_NOT_FOUND
        end

        -- 使用 pcall 安全加载脚本文件
        local ok, tb = pcall(dofile, script)
        if not ok then
            log.err('load module "' .. mod .. '":', tb)
            return nil, M.ERROR_CODE_LOAD_SCRIPT
        end

        -- 如果返回值是表，缓存模块函数
        if type(tb) == 'table' then
            funcs[mod] = tb
        end
    end

    -- 检查模块和函数是否存在
    if not funcs[mod] or not funcs[mod][func] then
        log.err('module "' .. mod .. '.' .. func .. '" not found')
        return nil, M.ERROR_CODE_NOT_FOUND
    end

    -- 检查是否需要认证
    if need_auth(session, mod, func) then
        if not session.username then
            return nil, M.ERROR_CODE_UNAUTHORIZED
        end

        -- 检查 ACL 权限
        if not M.acl_match(session, mod .. '.' .. func, 'rpc') then
            return nil, M.ERROR_CODE_PERMISSION_DENIED
        end
    end

    -- 调用目标函数并返回结果
    return funcs[mod][func](args, session)
end

return M
