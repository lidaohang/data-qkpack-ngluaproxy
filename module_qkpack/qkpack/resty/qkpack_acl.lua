local bit = require "bit"
local ljson_decoder = require 'json_decoder'
local decoder = ljson_decoder.new()

--local cjson_safe = require "cjson.safe"
local qkpack_common = require "resty.qkpack_common"

local band = bit.band
local len = string.len
local find = string.find
local tonumber = tonumber

local new_tab = require "table.new"

local _M = {
    _VERSION = '0.01',
}

_M.acl_url = "http://10.100.14.152:8080/data-auth-http-server/httpServer/authority"
_M.table_acl = {}


local function split(str, sep, plain)

	local								b, res = 0, {}
	sep = sep or '%s+'

	assert(type(sep) == 'string')
	assert(type(str) == 'string')

	if #sep == 0 then
		for i = 1, #str do
			res[#res + 1] = string.sub(str, i, i)
		end
		return res
	end

	while b <= #str do
		local e, e2 = string.find(str, sep, b, plain)
		if e then
			res[#res + 1] = string.sub(str, b, e-1)
			b = e2 + 1
			if b > #str then res[#res + 1] = "" end
		else
			res[#res + 1] = string.sub(str, b)
			break
		end
	end
	return res
end


local function set_namespace(self, request, uri)

	local								rc = 0
	local								t = nil
	local								f = nil
	local								namespace = nil
	
	f,_ = find(tostring(uri), tostring(qkpack_common.QKPACK_ACL_URI_FORMAT))
	if f == nil then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_FORMAT
		return qkpack_common.QKPACK_ERROR
	end

	t = split(uri, "/", true)
	if type(t) ~= "table" or table.getn(t) ~= 4 then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NAMESPACE_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end

	namespace = t[4]

	if  len(namespace) ~= qkpack_common.QKPACK_ACL_NAMESPACE_LENGTH  then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NAMESPACE_LENGTH;
		return qkpack_common.QKPACK_ERROR;
	end

	request.cluster_name = t[3]
	request.namespace = namespace

	return qkpack_common.QKPACK_OK	
end


local function get_node_list(self, request, route, acl)
	
	local								rc = 0
	local								t = nil
	local								x_real_ip =  ngx.var.server_addr
	local								key = nil
	local								node_list = nil

	if acl.node_list ~= nil then
		return qkpack_common.QKPACK_OK
	end

	acl.node_list = {}


	if route == nil or route == ngx.null or type(route) ~= "table" then
		ngx.log(ngx.ERR, "acl route is nil")
		return qkpack_common.QKPACK_ERROR
	end

	t = split(x_real_ip, ".", true)
	if t == nil then
		ngx.log(ngx.ERR, "split t is nil")
		return qkpack_common.QKPACK_ERROR
	end
	
	key =  t[1].."."..t[2]

	local temp_name = nil
	for k,v in pairs(route) do
		if k == "client" then
			for k1,v1 in pairs(v) do
				if k1 == key then
					temp_name = v1
					break
				end
			end
		end
	end
	
	if temp_name == nil then
	
		for k,v in pairs(route) do
			if k == "default" then
				node_list = v
				break
			end
		end
	
	else
		for k,v in pairs(route) do
			if k == "server" then
				for k1,v1 in pairs(v) do
					if k1 == temp_name then
						node_list = v1
						break
					end
				end
			end
		end
	end
	
	if node_list == nil then
		return qkpack_common.QKPACK_ERROR
	end

	t = split(node_list, ",", true)
	for _,v in pairs(t) do
		local node = split(v, ":", true)
		table.insert(acl.node_list, { node[1], tonumber(node[2]) } )	
	end

	request.node_list = acl.node_list
	return qkpack_common.QKPACK_OK
end

--get exptime
local function get_exptime(self, request, quotation)

	if quotation == nil then
		return qkpack_common.QKPACK_ERROR
	end

	for k,v in pairs(quotation) do

		if k == "expire" then
			request.exptime = v
		end

		if k == "compressThreshold" then
			request.compress_threshold = v
		end
	end
	
	if request.exptime == nil or request.exptime <= 0 then
		return qkpack_common.QKPACK_ERROR
	end
	
	
	
	return qkpack_common.QKPACK_OK
end

--set acl
local function set_acl(self, uri, ak )
		
	local								rc = 0
	local								key = nil
	local								data

	if uri == nil or ak == nil then
		return nil
	end


	key = uri.."&&"..ak
	if self.table_acl[key] ~= nil then
		return self.table_acl[key]
	end

	data = "{\"app_key\":\""..ak.."\",\"uri\":\""..uri.."\"}"
	
	local http = require "resty.http"
	local httpc = http.new()

	local res, err = httpc:request_uri(self.acl_url, {
		method = "POST",
		body = data,
		headers = {
			["Content-Type"] = "application/json;charset=UTF-8",
		}
	})

	if res == nil or res.status ~= 200 or res.body == nil  then
		return nil
	end
	

	local buffer, err = decoder:decode(res.body)
	if buffer == nil then
		return nil
	end
	
	if buffer.uri_id == -1 then
		return nil
	end

	self.table_acl[key] = buffer
	return self.table_acl[key]
end



--get_zset_limit
function _M.get_zset_limit(self, uri, ak, ken_len)
	
	--ngx.log(ngx.DEBUG, "get_zset_limit begin---------------------------------------------------")

	local								acl = nil
	local								quotation = nil
	local								status = false	
	local								limit = 0
	local								k_len = tonumber(ken_len)

	--request acl
	acl = set_acl(self, uri, ak)
	if acl == nil then
		return qkpack_common.QKPACK_ERROR, "acl is nil"
	end

	quotation = acl.quotation	
	if quotation == nil then
		return qkpack_common.QKPACK_ERROR, "quotation is nil"
	end

	for k,v in pairs(quotation) do
		if k == "limitPolicies" then

			for _,v1 in pairs(v) do
				
				if k_len >= v1["min"] and k_len <= v1["max"] then	
					status = true
					limit = v1["limit"]
					break
				end
			
			end
		
		end
	end

	if status == false then
		return qkpack_common.QKPACK_ERROR, qkpack_common.QKPACK_ERROR_ACL_LIMITPOLICIES_LIMIT
	end
	
	--ngx.log(ngx.DEBUG, "get_zset_limit end---------------------------------------------------")

	return qkpack_common.QKPACK_OK, limit
end

function _M.set_uri_id(self, request)
	
    	local                               				rc = 0	
	local								acl = nil
	local								data = nil

	if request.kvpair ~= nil then
		data = request.kvpair
	elseif request.multikvpair ~= nil then
		data = request.multikvpair
	elseif request.sset_member ~= nil then
		data = request.sset_member
	elseif request.zset_member ~= nil then
		data = request.zset_member
	elseif request.zset_query ~= nil then
		data = request.zset_query
	end

	if data == nil then
		ngx.log(ngx.ERR, "data is nil")
		return qkpack_common.QKPACK_ERROR
	end
	
	--set namespace,cluster_name
	rc =  set_namespace(self, request, data.uri)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "set_namespace is error")
		return qkpack_common.QKPACK_ERROR
	end

	--request acl
	acl = set_acl(self, data.uri, data.ak)
	if acl == nil then
		ngx.log(ngx.ERR, "set_acl is nil")
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NO_AUTH
		return qkpack_common.QKPACK_ERROR
	end

	request.uri_id = acl.uri_id
	return qkpack_common.QKPACK_OK
end




function _M.process(self, request)
	
	--ngx.log(ngx.DEBUG, "process begin---------------------------------------------------")

    	local                               				rc = 0	
	local								acl = nil
	local								data = nil

	if request.kvpair ~= nil then
		data = request.kvpair
	elseif request.multikvpair ~= nil then
		data = request.multikvpair
	elseif request.sset_member ~= nil then
		data = request.sset_member
	elseif request.zset_member ~= nil then
		data = request.zset_member
	elseif request.zset_query ~= nil then
		data = request.zset_query
	end

	if data == nil then
		ngx.log(ngx.ERR, "data is nil")
		return qkpack_common.QKPACK_ERROR
	end

	--set namespace,cluster_name
	rc =  set_namespace(self, request, data.uri)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "set_namespace is error")
		return qkpack_common.QKPACK_ERROR
	end

	--request acl
	acl = set_acl(self, data.uri, data.ak)
	if acl == nil then
		ngx.log(ngx.ERR, "set_acl is nil")
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NO_AUTH
		return qkpack_common.QKPACK_ERROR
	end

	--get node list
	rc = get_node_list(self, request, acl.route, acl)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "get_node_list is error")
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NO_AUTH
		return qkpack_common.QKPACK_ERROR
	end


	--auth
	request.uri_id = acl.uri_id
	local auth = band(acl.operation , request.operation_type) 
	if  (auth == 0) or (not auth) then
	
		request.desc = 	
		request.operation_type == qkpack_common.QKPACK_OPERATION_READ and 
		qkpack_common.QKPACK_ERROR_INTERFACE_OPERATION_READ or 
		qkpack_common.QKPACK_ERROR_INTERFACE_OPERATION_WRITE

		return qkpack_common.QKPACK_ERROR
	end

	--get exptime
	rc = get_exptime(self, request, acl.quotation)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "get_node_list is error")
		return qkpack_common.QKPACK_ERROR
	end

	--todo check interface timeout

	--ngx.log(ngx.DEBUG, "process end---------------------------------------------------")
	
	return qkpack_common.QKPACK_OK	
end


return _M
