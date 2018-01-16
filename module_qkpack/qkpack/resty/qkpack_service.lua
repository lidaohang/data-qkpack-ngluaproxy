local qkpack_handler = require "resty.qkpack_handler"
local qkpack_common = require "resty.qkpack_common"

local new_tab = require "table.new"


local _M = {
    _VERSION = '0.01',
}


local function handle()

	local request = {}
	
	--ngx.log(ngx.ERR, string.format("mem %0.2fKB start", collectgarbage("count")))

	local rc = qkpack_handler:handle(request)
	if rc ~= qkpack_common.QKPACK_OK then
		return 
	end

	ngx.say(request.response_body)
	--ngx.log(ngx.ERR, string.format("mem %0.2fKB process", collectgarbage("count")))
	
	request.request_body = nil
	request.kvpair = nil
	request.multikvpair = nil
	request.sset_member = nil
	request.zset_member = nil
	request.zset_query = nil
	request.response_body = nil

	request = nil 

	--collectgarbage("setpause", 90)
	--collectgarbage("collect")

	--ngx.log(ngx.ERR, string.format("mem %0.2fKB end", collectgarbage("count")))
end

handle()


return _M
