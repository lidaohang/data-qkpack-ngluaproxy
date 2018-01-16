local cjson = require "cjson"
local qkpack_json = require "resty.qkpack_json"
local qkpack_common = require "resty.qkpack_common"

local lower = string.lower
local tostring = tostring


local _M = {
    _VERSION = '0.01',
}

local function parser_request_uri(self, request)

	local								uri = lower(ngx.var.uri)


	if uri == qkpack_common.QKPACK_URI_GET then
	
		request.metrics_command = qkpack_common.QKPACK_METRICS_GET
		request.command_type = qkpack_common.REDIS_GET
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ
	
	elseif uri == qkpack_common.QKPACK_URI_SET then
	
		request.metrics_command = qkpack_common.QKPACK_METRICS_SET
		request.command_type = qkpack_common.REDIS_SET
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE
	
	elseif uri == qkpack_common.QKPACK_URI_DEL then
		
		request.metrics_command = qkpack_common.QKPACK_METRICS_DEL;
		request.command_type = qkpack_common.REDIS_DEL;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
		
	elseif uri == qkpack_common.QKPACK_URI_TTL then
	
		request.metrics_command = qkpack_common.QKPACK_METRICS_TTL;
		request.command_type = qkpack_common.REDIS_TTL;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_INCR then
	
		request.metrics_command = qkpack_common.QKPACK_METRICS_INCR;
		request.command_type = qkpack_common.REDIS_INCR;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_INCRBY then

		request.metrics_command = qkpack_common.QKPACK_METRICS_INCRBY;
		request.command_type = qkpack_common.REDIS_INCRBY;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_SET_SADD then

		request.metrics_command =  qkpack_common.QKPACK_METRICS_SADD;
		request.command_type = qkpack_common.REDIS_SADD;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_SET_SREM then

		request.metrics_command = qkpack_common.QKPACK_METRICS_SREM;
		request.command_type = qkpack_common.REDIS_SREM;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
		
	elseif uri == qkpack_common.QKPACK_URI_SET_SCARD then

		request.metrics_command = qkpack_common.QKPACK_METRICS_SCARD; 
		request.command_type = qkpack_common.REDIS_SCARD;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_SET_SMEMBERS then

		request.metrics_command = qkpack_common.QKPACK_METRICS_SMEMBERS;
		request.command_type = qkpack_common.REDIS_SMEMBERS;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_SET_SISMEMBER then

		request.metrics_command = qkpack_common.QKPACK_METRICS_SISMEMBER;
		request.command_type = qkpack_common.REDIS_SISMEMBER;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_MGET then

		request.metrics_command = qkpack_common.QKPACK_METRICS_MGET;
		request.command_type = qkpack_common.REDIS_MGET;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_MSET then

		request.metrics_command = qkpack_common.QKPACK_METRICS_MSET;
		request.command_type = qkpack_common.REDIS_MSET;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_ADD then

		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETADD;
		request.command_type = qkpack_common.REDIS_ZADD;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_BATCHADD then

		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETBATCHADD;
		request.command_type = qkpack_common.REDIS_ZBATCHADD;
		request.operation_type = qkpack_common.QKPACK_OPERATION_WRITE;
	
	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_GETBYSCORE then

		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETGETBYSCORE;
		request.command_type = qkpack_common.REDIS_ZRANGEBYSCORE;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_GETBYRANK then

		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETGETBYRANK;
		request.command_type = qkpack_common.REDIS_ZRANGE;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_BATCHGETBYSCORE then

		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETBATCHGETBYSCORE;
		request.command_type = qkpack_common.REDIS_BATCHZRANGEBYSCORE;
		request.operation_type = qkpack_common.QKPACK_OPERATION_READ;
	
	else
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_ILLEGAL_RIGHT;
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end



local function parser_request_body(self, request)
	ngx.req.read_body()
	local data = ngx.req.get_body_data()
	if data == nil then
		return qkpack_common.QKPACK_ERROR
	end
	
	request.request_body = data
	return qkpack_common.QKPACK_OK
end


function _M.parser_request(self, request)
	
	--ngx.log(ngx.DEBUG,"parser_request begin-----------------------------------------------")
	
	local								rc = 0
	local								command_type = nil
	
	request.code = 0
	request.desc = ""
	request.begin_time = ngx.now()
    
	rc = parser_request_uri(self, request)
		if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	--ngx.log(ngx.DEBUG, "parser_request_uri is ok")

	rc = parser_request_body(self, request)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	--ngx.log(ngx.DEBUG, "parser_request_body is ok")

	command_type = request.command_type
	
	if command_type == qkpack_common.REDIS_GET or
		command_type == qkpack_common.REDIS_SET or
		command_type == qkpack_common.REDIS_TTL or 
		command_type == qkpack_common.REDIS_DEL or
		command_type == qkpack_common.REDIS_INCR  or
		command_type == qkpack_common.REDIS_INCRBY then
		
		rc = qkpack_json:read_json_kvpair(request)

	elseif command_type == qkpack_common.REDIS_MGET or 
		command_type == qkpack_common.REDIS_MSET then

		rc = qkpack_json:read_json_multikvpair(request)

	elseif command_type == qkpack_common.REDIS_SADD or 
		command_type == qkpack_common.REDIS_SREM or
		command_type == qkpack_common.REDIS_SCARD or
		command_type == qkpack_common.REDIS_SMEMBERS or
		command_type == qkpack_common.REDIS_SISMEMBER then
		
		rc = qkpack_json:read_json_set(request)

	elseif command_type == qkpack_common.REDIS_ZADD or
		command_type == qkpack_common.REDIS_ZBATCHADD or
		command_type == qkpack_common.REDIS_ZRANGEBYSCORE or
		command_type == qkpack_common.REDIS_ZRANGE or 
		command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
		
		rc = qkpack_json:read_json_zset(request)

	else
		return qkpack_common.QKPACK_ERROR
	end
	
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	--ngx.log(ngx.DEBUG,"parser_request end-----------------------------------------------")

	return qkpack_common.QKPACK_OK
end

function _M.parser_response(self, request)
	
	--ngx.log(ngx.DEBUG,"parser_response begin-----------------------------------------------")
	
	local								rc = 0
	local								command_type = request.command_type
	
	request.cost =  ngx.now() * 1000 -  request.begin_time * 1000

	if command_type == qkpack_common.REDIS_GET or 
		command_type == qkpack_common.REDIS_SET or 
		command_type == qkpack_common.REDIS_TTL or
		command_type == qkpack_common.REDIS_DEL or
		command_type == qkpack_common.REDIS_INCR or
		command_type == qkpack_common.REDIS_INCRBY then
		
		rc = qkpack_json:write_json_kvpair(request)
	
	elseif command_type == qkpack_common.REDIS_MGET  or
		command_type == qkpack_common.REDIS_MSET then
		
		rc = qkpack_json:write_json_multikvpair(request)	
	
	elseif command_type == qkpack_common.REDIS_SADD or 
		command_type == qkpack_common.REDIS_SREM or
		command_type == qkpack_common.REDIS_SCARD or
		command_type == qkpack_common.REDIS_SMEMBERS or
		command_type == qkpack_common.REDIS_SISMEMBER then
		
		rc = qkpack_json:write_json_set(request)
	
	elseif command_type == qkpack_common.REDIS_ZADD or
		command_type == qkpack_common.REDIS_ZBATCHADD or
		command_type == qkpack_common.REDIS_ZRANGEBYSCORE or
		command_type == qkpack_common.REDIS_ZRANGE or 
		command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
		
		rc = qkpack_json:write_json_zset(request)
	
	else
		return qkpack_common.QKPACK_ERROR
	end

	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	--ngx.log(ngx.DEBUG,"parser_response end-----------------------------------------------")
	
	return qkpack_common.QKPACK_OK
end


function _M.parser_error(self, request)
	
	local								data = nil
	request.cost =  ngx.now() * 1000 -  request.begin_time * 1000
	
	if request.code == qkpack_common.QKPACK_RESPONSE_CODE_OK then
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_UNKNOWN
	end
	
	data = {
		e = {
			code=request.code, 
			desc=request.desc,
		},
		cost = request.cost,
	}

	local buffer, err = cjson.encode(data)
	if buffer == nil then
		return qkpack_common.QKPACK_ERROR
	end
	
	request.response_body = buffer
			
	ngx.log(ngx.ERR, "code=["..tostring(request.code).."],desc=["..request.desc.."]")
	ngx.log(ngx.ERR, request.request_body)
	
	return qkpack_common.QKPACK_OK
end


return _M
