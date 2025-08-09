local M = {}

function M.echo(params)
    return params
end

function M.setSim(params)

end

function M.getSimStatus(params, section)
    local result = {
        status = 'connected',
        signal = '-75',
        operator = 'China Mobile',
        interface = 'wwan0',
        imsi = '460001234567890',
        iccid = '89860012345678901234'
    }
    
    return result
end

return M
