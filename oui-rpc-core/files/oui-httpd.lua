#!/usr/bin/env eco

-- 核心的HTTP服务器实现，基于eco异步框架

-- SPDX-License-Identifier: MIT
-- Author: Jianhui Zhao <zhaojh329@gmail.com>

local hex = require 'eco.encoding.hex'              -- 十六进制编码库
local http = require 'eco.http.server'              -- HTTP 服务器库
local md5 = require 'eco.hash.md5'                  -- MD5 哈希算法库
local time = require 'eco.time'                     -- 时间处理库
local file = require 'eco.file'                     -- 文件操作库
local sys = require 'eco.sys'                       -- 系统调用库
local log = require 'eco.log'                       -- 日志记录库
local cjson = require 'cjson'                       -- JSON 编解码库
local uci = require 'eco.uci'                       -- UCI 配置管理库

local rpc = require 'oui.rpc'                       -- OUI RPC 框架核心库

-- 设置全局异常处理钩子
eco.panic_hook = function(err)
    log.err('panic:', err)
end

-- 定义 RPC 方法表，存储所有可用的 RPC 方法
local rpc_methods = {}

-- challenge方法，用户校验
rpc_methods['challenge'] = function(con, req, params)
    -- 检查用户名参数是否为字符串类型
    if type(params.username) ~= 'string' then
        log.err('call challenge: username is required')
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- uci句柄
    local c = uci.cursor()
    -- 标记是否找到用户
    local found = false

    -- 遍历 oui 配置文件中的所有 user 配置段，检查用户名是否存在
    c:foreach('oui', 'user', function(s)
        if s.username == params.username then
            found = true
            return false
        end
    end)

    -- 如果用户不存在，返回未授权错误
    if not found then
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- 创建认证随机数（nonce）
    local nonce = rpc.create_nonce()
    if not nonce then
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- 返回 JSON 格式的 nonce 给客户端
    con:send(cjson.encode({ nonce = nonce }))
end

-- 实现 login 方法：处理用户登录请求
rpc_methods['login'] = function(con, req, params)
    local username = params.username
    local password = params.password

    -- 验证用户名
    if type(username) ~= 'string' then
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- 用户权限验证
    local acl = rpc.login(username, password)
    if not acl then
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- 创建会话
    local sid = rpc.create_session(username, acl, con:remote_addr().ipaddr)

    -- 返回会话 ID 给客户端
    con:send(cjson.encode({ sid = sid }))
end

-- 实现 logout 方法：处理用户登出请求
rpc_methods['logout'] = function(con, req, params)
    local sid = params.sid

    -- 如果会话 ID 有效，删除对应的会话
    if type(sid) == 'string' then
        rpc.delete_session(sid)
    end
end

-- 实现 alive 方法：检查会话是否仍然有效
rpc_methods['alive'] = function(con, req, params)
    local sid = params.sid
    local alive = false

    -- 检查会话是否存在且有效
    if type(sid) == 'string' and rpc.get_session(sid) then
        alive = true
    end

    con:send(cjson.encode({ alive = alive }))
end

-- 实现 call 方法：通用 RPC 方法调用处理器
rpc_methods['call'] = function(con, req, params)
    local sid = params[1]
    local mod = params[2]
    local func = params[3]
    local args = params[4] or {}

    -- 验证所有必需参数的类型
    if type(sid) ~= 'string' or type(mod) ~= 'string' or type(func) ~= 'string' or type(args) ~= 'table' then
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 获取会话信息，如果会话不存在则创建临时会话（包含客户端 IP）
    local session = rpc.get_session(sid) or { remote_addr = con:remote_addr().ipaddr }

    -- 调用指定的 RPC 方法
    local result, err = rpc.call(mod, func, args, session)
    -- 根据不同的错误码返回相应的 HTTP 状态码
    if type(err) == 'number' then
        if err == rpc.ERROR_CODE_INVALID_ARGUMENT then
            return con:send_error(http.STATUS_BAD_REQUEST)
        end

        if err == rpc.ERROR_CODE_NOT_FOUND then
            return con:send_error(http.STATUS_NOT_FOUND)
        end

        if err == rpc.ERROR_CODE_UNAUTHORIZED then
            return con:send_error(http.STATUS_UNAUTHORIZED)
        end

        if err == rpc.ERROR_CODE_PERMISSION_DENIED then
            return con:send_error(http.STATUS_FORBIDDEN)
        end

        return con:send_error(http.STATUS_INTERNAL_SERVER_ERROR)
    end

    -- 将结果编码为 JSON，并将空对象 {} 替换为空数组 []
    if result then
        local resp = cjson.encode({ result = result }):gsub('{}','[]')
        con:send(resp)
    else
        con:send('{}')
    end
end

-- RPC 请求处理函数
local function handle_rpc(con, req)
    -- 只接受 POST 请求
    if req.method ~= 'POST' then
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 读取请求体内容
    local body, err = con:read_body()
    if not body then
        log.err('read body fail:', err)
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 尝试解析 JSON 请求体
    local ok, msg = pcall(cjson.decode, body)
    if not ok or type(msg) ~= 'table' or type(msg.method) ~= 'string' then
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 验证参数字段
    if type(msg.params or {}) ~= 'table' then
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 检查请求的方法是否支持
    if not rpc_methods[msg.method] then
        log.err('Oui: Not supported rpc method: ', msg.method)
        return con:send_error(http.STATUS_NOT_FOUND)
    end

    -- 调用对应的 RPC 方法处理器
    rpc_methods[msg.method](con, req, msg.params or {})
end

-- 文件上传处理函数
local function handle_upload(con, req)
    local part, sid, f, md5ctx
    local total = 0     -- 已上传字节总数

    while true do
        -- 读取表单数据块
        local typ, data = con:read_formdata(req)
        -- 处理头部信息
        if typ == 'header' then
            if data[1] == 'content-disposition' then
                part = data[2]:match('name="([%w_-]+)"')
            end
        -- 处理数据体
        elseif typ == 'body' then
            -- 会话 ID 字段，验证会话是否有效
            if part == 'sid' then
                sid = data[1]
                if not rpc.get_session(sid) then
                    return con:send_error(http.STATUS_UNAUTHORIZED)
                end
            -- 文件路径字段，打开目标文件进行写入
            elseif part == 'path' then
                f = io.open(data[1], 'w')
                if not f then
                    return con:send_error(http.STATUS_FORBIDDEN)
                end

                md5ctx = md5.new()
            -- 文件内容字段，写入文件数据，并更新MD5值
            elseif part == 'file' then
                if not f then
                    return con:send_error(http.STATUS_BAD_REQUEST)
                end

                if not sid then
                    return con:send_error(http.STATUS_UNAUTHORIZED)
                end

                f:write(data[1])

                md5ctx:update(data[1])
                total = total + #data[1]
            end
        -- 结束
        elseif typ == 'end' then
            break
        else
            return con:send_error(http.STATUS_BAD_REQUEST)
        end
    end

    -- 关闭文件
    if f then f:close() end

    -- 文件创建失败
    if not f then
        return con:send_error(http.STATUS_BAD_REQUEST)
    end

    -- 返回上传结果：文件大小和 MD5 值
    con:send(cjson.encode({ size = total, md5 = hex.encode(md5ctx:final()) }))
end

-- 文件下载处理函数
local function handle_download(con, req)
    -- 获取文件路径
    local path = req.query['path']
    if not path then
        return con:send_error(http.STATUS_BAD_REQUEST, 'no "path" in query')
    end

    -- 获取会话 ID
    local sid = req.query['sid']
    if not sid then
        return con:send_error(http.STATUS_BAD_REQUEST, 'no "sid" in query')
    end

    -- 验证会话有效性
    if not rpc.get_session(sid) then
        return con:send_error(http.STATUS_UNAUTHORIZED)
    end

    -- 设置响应头为二进制流
    con:add_header('content-type', 'application/octet-stream')
    -- 发送文件内容
    con:send_file(path)
end

-- 主 HTTP 请求处理器
local function http_handler(con, req)
    -- 请求路径
    local path = req.path

    -- 根据路径分发到不同的处理器
    if path == '/oui-rpc' then
        handle_rpc(con, req)                    -- RPC 调用处理
    elseif path == '/oui-upload' then
        handle_upload(con, req)                 -- 文件上传处理
    elseif path == '/oui-download' then
        handle_download(con, req)               -- 文件下载处理
    else
        con:serve_file(req)                     -- 静态文件服务
    end
end

-- 解析监听地址字符串
local function parse_listen_addr(str)
    -- 使用正则表达式提取 IP 和端口
    local ip, port = str:match('^%[?([%d%.:]+)%]?:(%d+)$')
    if not ip then
        return nil
    end

    -- IPv4 地址
    if ip:match('^%d+%.%d+%.%d+%.%d+$') then
        return ip, tonumber(port)
    -- IPv6 地址
    elseif ip:match('^%[?[%x:]+%]?$') then
        return ip:gsub('^%[?([a-fA-F0-9:]+)%]?$', '%1'), tonumber(port), true
    else
        return nil
    end
end

-- 启动 HTTP 服务监听
local function listen_http(addr, global_options, ssl)
    local options = {}

    -- 复制全局选项到本地选项
    for k, v in pairs(global_options) do
        options[k] = v
    end

    -- 解析监听地址
    local ipaddr, port, ipv6 = parse_listen_addr(addr)
    if not ipaddr then
        log.err('invalid addr:' .. addr)
        return
    end

    options.ipv6 = ipv6

    -- 记录监听信息
    if ssl then
        log.info('listen https:', addr)
    else
        log.info('listen http:', addr)
    end

    -- 在协程中启动 HTTP 服务器
    eco.run(function()
        local srv, err = http.listen(ipaddr, port, options, http_handler)
        if not srv then
            log.err(err)
            return
        end
    end)
end

-- 解析配置文件并启动服务
local function parse_config()
    local c = uci.cursor()

    -- 默认服务器选项
    local options = {
        docroot = '/www',                   -- 文档根目录
        index = 'oui.html',                 -- 默认首页文件
        reuseaddr = true,                   -- 允许地址重用
        gzip = true                         -- 启用 gzip 压缩
    }

    -- 遍历 oui 配置文件中的 httpd 配置段
    c:foreach('oui', 'httpd', function(s)
        -- 设置日志级别
        log.set_level(log[s.log_level or 'INFO'])

        -- 设置日志文件路径
        if s.log_path then
            log.set_path(s.log_path)
        end

        -- 配置 HTTP Keep-Alive 超时
        options.http_keepalive = tonumber(s.http_keepalive or 0)
        options.tcp_keepalive = tonumber(s.tcp_keepalive or 0)

        -- 启动 HTTP 服务监听
        for _, addr in ipairs(s.listen_http or {}) do
            listen_http(addr, options)
        end

        -- HTTPS 证书和密钥文件路径
        local cert = '/etc/oui-httpd.crt'
        local key = '/etc/oui-httpd.key'

        -- 启动 HTTPS 服务监听
        if s.listen_https and file.access(cert) and file.access(key) then
            options.cert = cert
            options.key = key

            for _, addr in ipairs(s.listen_https) do
                listen_http(addr, options, true)
            end
        end

        return false
    end)
end

-- 程序主入口
rpc.init()
-- 加载访问控制列表
rpc.load_acl()

-- 解析配置并启动服务
parse_config()

-- 注册 SIGINT 信号处理器（Ctrl+C）
sys.signal(sys.SIGINT, function()
    log.info('\nGot SIGINT, now quit')
    eco.unloop()
end)

-- 注册 SIGTERM 信号处理器（终止信号）
sys.signal(sys.SIGTERM, function()
    log.info('\nGot SIGTERM, now quit')
    eco.unloop()
end)

while true do
    time.sleep(1)
end
