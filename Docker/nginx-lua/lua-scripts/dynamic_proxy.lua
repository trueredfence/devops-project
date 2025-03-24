local mysql = require "resty.mysql"

local _M = {}

function _M.get_target(subdomain)

    -- ngx.log(ngx.ERR, "Received request for subdomain: ", subdomain)
    
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "Failed to create MySQL connection: ", err)
        return nil
    end

    db:set_timeout(1000)

    local ok, err, errcode, sqlstate = db:connect{
        host = "172.18.0.3",
        port = 3306,
        database = "l_bas",
        user = "root",
        password = "admin4680"
    }

    if not ok then
        ngx.log(ngx.ERR, "MySQL connection failed: ", err)
        return nil
    end

    local query = "SELECT website FROM domain_mappings WHERE subdomain = '" .. subdomain .. "' LIMIT 1"
     -- ngx.log(ngx.ERR, "Executing query: ", query)    
    local res, err = db:query(query)

    if not res or #res == 0 then
        return nil
    end

    local target = res[1].website
    db:set_keepalive(10000, 10)
    
    return target
end

return _M
