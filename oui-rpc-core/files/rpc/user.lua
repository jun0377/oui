
-- 用户认证和授权系统的核心组件，为整个管理界面提供了安全可靠的用户管理功能

local hex = require 'eco.encoding.hex'
local md5 = require 'eco.hash.md5'
local uci = require 'eco.uci'

local M = {}

-- 获获取系统中所有用户的信息
function M.get_users()
    local c = uci.cursor()
    local users = {}

    -- 遍历 oui 配置文件中所有 user 类型的配置段
    c:foreach('oui', 'user', function(s)
        -- 提取每个用户的关键信息：用户名、权限组、内部ID
        users[#users + 1] = {
            username = s.username,
            acl = s.acl,
            id = s['.name']
        }
    end)

    return { users = users }
end

-- 删除用户
function M.del_user(params)
    local c = uci.cursor()
    -- 要删除的用户ID
    local id = params.id

    c:delete('oui', id)
    c:commit('oui')
end

-- 修改用户信息
function M.change(params)
    local c = uci.cursor()
    local password = params.password
    local acl = params.acl
    local id = params.id

    local username = c:get('oui', id, 'username')
    if username then
        -- 密码加密 ：使用 username:password 格式进行 MD5 哈希
        c:set('oui', id, 'password', hex.encode(md5.sum(username .. ':' .. password)))
        c:set('oui', id, 'acl', acl or '')
        c:commit('oui')
    end
end

-- 添加新用户
function M.add_user(params)
    local c = uci.cursor()
    local username = params.username
    local password = params.password
    local acl = params.acl
    local exist = false

    -- 重复性检查 ：遍历现有用户，确保用户名唯一
    c:foreach('oui', 'user', function(s)
        if s.username == username then
            exist = true
            return false
        end
    end)

    if exist then
        return { code = 1, errors = 'already exist' }
    end

    -- 添加用户
    local sid = c:add('oui', 'user')
    c:set('oui', sid, 'username', username) 
    c:set('oui', sid, 'password', hex.encode(md5.sum(username .. ':' .. password)))
    c:set('oui', sid, 'acl', acl or '')
    c:commit('oui')

    return { code = 0 }
end

return M
