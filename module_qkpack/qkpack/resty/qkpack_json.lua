local cjson = require "cjson"
--local cjson_safe = require "cjson.safe"
local qkpack_validate = require "resty.qkpack_validate"
local qkpack_common = require "resty.qkpack_common"

local ljson_decoder = require 'json_decoder'
local decoder = ljson_decoder.new()


local _M = {
    _VERSION = '0.01',
}


--GET,SET,TTL,DEL,INCR,INCRBY
function _M.read_json_kvpair(self, request)
	
	local								rc = 0
	local								data = nil
	local								err = nil
	local								buffer = nil
	
	data = request.request_body
	if data == nil then
		return qkpack_common.QKPACK_ERROR
	end

	--buffer, err = cjson_safe.decode(data)
	buffer = decoder:decode(data)
	if buffer == nil then
		request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
		return qkpack_common.QKPACK_ERROR
	end
	
	request.kvpair = buffer
	
	rc = qkpack_validate:validate_kvpair(request)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end


--GET,SET,DEL,TTL,INCR,INCRBY
function _M.write_json_kvpair(self, request)

	local								data = nil
	local								err = nil
	local								buffer = nil
	local								kvpair = request.kvpair
	
	if kvpair == nil then
		return qkpack_common.QKPACK_ERROR
	end
	
	if request.command_type == qkpack_common.REDIS_GET then
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			k = kvpair.k,
			v = kvpair.v,
		}
	else
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			data = kvpair.v,
		}
	end

	buffer, err = cjson.encode(data)
	if buffer == nil then
		return qkpack_common.QKPACK_ERROR
	end

	request.response_body = buffer
	return qkpack_common.QKPACK_OK
end


--MGET,MSET
function _M.read_json_multikvpair(self, request)

	local								data = nil
	local								err = nil
	local								buffer = nil

	data = request.request_body
	if data == nil then
		return qkpack_common.QKPACK_ERROR
	end

	--buffer, err = cjson_safe.decode(data)
	buffer = decoder:decode(data)
	if buffer == nil then
		request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
		return qkpack_common.QKPACK_ERROR
	end
	
	request.multikvpair = buffer
	
	rc = qkpack_validate:validate_multikvpair(request)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end


--MGET,MSET
function _M.write_json_multikvpair(self, request)

	local								data = nil
	local								err = nil
	local								buffer = nil
	local 								multikvpair = request.multikvpair
	
	if multikvpair == nil then
		return qkpack_common.QKPACK_ERROR
	end

	if request.command_type == qkpack_common.REDIS_MSET then
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
		}
	else
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			ks = multikvpair.ks,
		}
	end

	buffer, err = cjson.encode(data)
	if buffer == nil then
		return qkpack_common.QKPACK_ERROR
	end

	request.response_body = buffer
	return qkpack_common.QKPACK_OK
end


--SADD,SCARD,SREM,SMEMBERS,SISMEMBER
function _M.read_json_set(self, request)

	local								rc = 0
	local								data = nil
	local								err = nil
	local								buffer = nil

	data = request.request_body
	if data == nil then
		return qkpack_common.QKPACK_ERROR
	end

	--buffer, err = cjson_safe.decode(data)
	buffer = decoder:decode(data)
	if buffer == nil then
		request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
		return qkpack_common.QKPACK_ERROR
	end
	
	request.sset_member = buffer
	
	rc = qkpack_validate:validate_set(request)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end


--SADD,SCARD,SREM,SMEMBERS,SISMEMBER
function _M.write_json_set(self, request)

	local								data = nil
	local								err = nil
	local								buffer = nil
	local								sset_member = request.sset_member
	
	if sset_member == nil then
		return qkpack_common.QKPACK_ERROR
	end

	if request.command_type == qkpack_common.REDIS_SMEMBERS then
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			k = sset_member.k,
			mbs = sset_member.mbs,
		}
	else --SADD,SCARD,SREM,SISMEMBER
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			data = sset_member.data,
		}
	end

	cjson.encode_empty_table_as_object(false)
	buffer, err = cjson.encode(data)
	if buffer == nil then
		return qkpack_common.QKPACK_ERROR
	end

	request.response_body = buffer
	return qkpack_common.QKPACK_OK
end


--ZADD,ZBATCHADD,ZRANGEBYSCORE,ZRANGE,BATCHZRANGEBYSCORE
function _M.read_json_zset(self, request)
	
	local								rc = 0
	local								data = nil
	local								err = nil
	local								buffer = nil
	local								command_type = request.command_type
	
	data = request.request_body
	if data == nil then
		return qkpack_common.QKPACK_ERROR
	end

	--buffer, err = cjson_safe.decode(data)
	buffer = decoder:decode(data)
	if buffer == nil then
		request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
		return qkpack_common.QKPACK_ERROR
	end
	

	if command_type == qkpack_common.REDIS_ZADD then
	
		request.zset_member = buffer
		rc = qkpack_validate:validate_zset(request)
	
	elseif command_type == qkpack_common.REDIS_ZBATCHADD then
	
		request.zset_member = buffer
		rc = qkpack_validate:validate_zset_list(request)

	elseif command_type == qkpack_common.REDIS_ZRANGE or
		command_type == qkpack_common.REDIS_ZRANGEBYSCORE then

		request.zset_query = buffer
		rc = qkpack_validate:validate_zset_query(request)

	elseif command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
	
		request.zset_query = buffer
		rc = qkpack_validate:validate_zset_query_list(request)

	end

	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end


--ZADD,ZBATCHADD,ZRANGEBYSCORE,ZRANGE,BATCHZRANGEBYSCORE
function _M.write_json_zset(self, request)
	
	local								rc = 0
	local								data = nil
	local								err = nil
	local								buffer = nil
	local								command_type = request.command_type
	
	if command_type == qkpack_common.REDIS_ZRANGE or
		command_type == qkpack_common.REDIS_ZRANGEBYSCORE then

		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			k = request.zset_query.k,
			mc = table.getn(request.zset_member.mbs),
			mbs = request.zset_member.mbs,
		}
	elseif command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then

		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
			kc = table.getn(request.zset_member_list),
			ks = request.zset_member_list,
		}
	else 
		data = {
			e = {
				code=request.code, 
				desc=request.desc,
			},
			cost = request.cost,
		}
	end

	cjson.encode_empty_table_as_object(false)
	buffer, err = cjson.encode(data)
	if buffer == nil then
		return qkpack_common.QKPACK_ERROR
	end

	request.response_body = buffer
	return qkpack_common.QKPACK_OK
end


return _M
