
local _M = {
    _VERSION = '0.01',
}

function _M.debug(self, mess)
	ngx.log(ngx.DEBUG,mess)
end

function _M.error(self, mess)
	ngx.log(ngx.ERR,mess)
end


return _M
