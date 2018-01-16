local qkpack_log = require "resty.qkpack_log"
local qkpack_common = require "resty.qkpack_common"

local string = string
local len = string.len
local table = table
local gsub = string.gsub
local tostring = tostring


local _M = {
    _VERSION = '0.01',
}


local function trime(self, s) 
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end  

local function validate_null(self, key)
	if key == nil or key == ngx.null then
		return true
	else
		return false
	end
end


local function validate_acl(self, request, acl)

	--ngx.log(ngx.DEBUG,"validate_acl begin-------------------------------------")
	
	if validate_null(self,acl)  then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NOT_NULL
		return qkpack_common.QKPACK_ERROR
	end

	--ngx.log(ngx.DEBUG,"validate_acl acl ~= nil -------------------------------------")
	
	if validate_null(self,acl.uri) and validate_null(self,acl.ak) then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NOT_NULL
		return qkpack_common.QKPACK_ERROR
	end

	if validate_null(self,acl.uri) or type(acl.uri) ~= "string" then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_URI_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if validate_null(self,acl.ak) or type(acl.ak) ~= "string" then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_APPKEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	local uri_len = len(acl.uri)
	local uri_len1 = len(trime(self,acl.uri))

	local ak_len = len(acl.ak)
	local ak_len1 = len(trime(self,acl.ak))

	if (uri_len == 0 or uri_len1 == 0) and (ak_len == 0 or ak_len1 == 0) then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_NOT_NULL
		return qkpack_common.QKPACK_ERROR
	end

	if uri_len == 0 or uri_len1 == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_URI_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	if ak_len == 0 or ak_len1 == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ACL_APPKEY_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	--ngx.log(ngx.DEBUG,"validate_acl end-------------------------------------")
	
	return qkpack_common.QKPACK_OK
end

local function validate_key(self,request, key)
	
	if validate_null(self,key) then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_KEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if len(key) == 0 or len(trime(self,key)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_KEY_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end

local function validate_value(self,request, value)
	
	if validate_null(self,value) then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_VALUE_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	local num = tonumber(value)

	if request.command_type == qkpack_common.REDIS_INCRBY
      	and num == nil or num == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_NUMERIC_VALUE
		return qkpack_common.QKPACK_ERROR

	elseif len(value) == 0 or len(trime(self,value)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_VALUE_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end

function _M.validate_kvpair(self, request)
	
	--ngx.log(ngx.DEBUG,"validate_kvpair begin-------------------------------------")
	
	local kvpair = request.kvpair
	
	local rc = validate_acl(self, request, kvpair)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	
	rc = validate_key(self, request, kvpair.k)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	if request.command_type == qkpack_common.REDIS_INCRBY 
	or request.command_type == qkpack_common.REDIS_SET
	then
		rc = validate_value(self, request, kvpair.v)
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
	end
	
	return qkpack_common.QKPACK_OK
end



function _M.validate_multikvpair(self, request)
	
	
	local command_type = request.command_type

	local multikvpair = request.multikvpair
	
	local rc = validate_acl(self, request, multikvpair)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	
	local ks = multikvpair.ks
	if validate_null(self,ks) then
		request.desc = qkpack_common.QKPACK_ERROR_KVPAIR_KEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	
	for key,value in pairs(ks) do
		
		for k,v in pairs(value) do

			if  k == "k" then
				rc = validate_key(self, request, v)
				if rc ~= qkpack_common.QKPACK_OK then
					return qkpack_common.QKPACK_ERROR
				end
			
			elseif k == "v" and command_type == qkpack_common.REDIS_MSET then
				rc = validate_value(self, request,  v)
				if rc ~= qkpack_common.QKPACK_OK then
					return qkpack_common.QKPACK_ERROR
				end
			end
		end
	end

	if command_type == qkpack_common.REDIS_MSET and  ks[1]["v"] == nil then

		rc = validate_value(self, request,  nil)
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
	end
	
	--ngx.log(ngx.DEBUG,"validate_multikvpair end-------------------------------------")
	return qkpack_common.QKPACK_OK
end



local function validate_set_key(self,request, key)
	
	if validate_null(self,key) then
		request.desc = qkpack_common.QKPACK_ERROR_SET_KEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if len(key) == 0 or len(trime(self,key)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_SET_KEY_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end

local function validate_set_value(self,request, value)
	
	if validate_null(self,value) then
		request.desc = qkpack_common.QKPACK_ERROR_SET_VALUE_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	if len(value) == 0 or len(trime(self,value)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_SET_VALUE_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end



--validate set
function _M.validate_set(self, request)
	
	local sset_member = request.sset_member
	
	local rc = validate_acl(self, request, sset_member)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	
	rc = validate_set_key(self, request, sset_member.k)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	if request.command_type == qkpack_common.REDIS_SADD or
	request.command_type == qkpack_common.REDIS_SREM then

		if validate_null(self,sset_member.mbs) then
			request.desc = qkpack_common.QKPACK_ERROR_SET_MEMBERS_NOT_EXIST	
			return qkpack_common.QKPACK_ERROR
		end
		
		if type(sset_member.mbs) ~= "table" or table.getn(sset_member.mbs) == 0 then
			request.desc =  qkpack_common.QKPACK_ERROR_SET_MEMBERS_NOT_EMPTY
			return qkpack_common.QKPACK_ERROR
		end	

		for _,v in pairs(sset_member.mbs) do
				
			if  validate_null(self,v) or
			len(v) == 0 or
			len(trime(self,v)) == 0
			then
				request.desc = qkpack_common.QKPACK_ERROR_SET_MEMBERS_VALUE_NOT_EMPTY	
				return qkpack_common.QKPACK_ERROR
			end
		end

	end	
		
		
	if request.command_type == qkpack_common.REDIS_SISMEMBER then

		rc = validate_set_value(self, request, sset_member.v)
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
	end
	
	return qkpack_common.QKPACK_OK
end


--zset key
local function validate_zset_key(self,request, key)
	
	if validate_null(self,key) then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if len(key) == 0 or len(trime(self,key)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEY_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end


--zset mbs
local function validate_zset_mbs(self,request, mbs)
	
	if validate_null(self,mbs)  then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if type(mbs) ~= "table" or table.getn(mbs) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end


--member, value, score
local function validate_zset_mbs_list(self, request, member, value, score)
	
	if validate_null(self,member) then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_MEMBER_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	if len(member) == 0 or len(trime(self,member)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_MEMBER_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end

	if validate_null(self,value) then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_VALUE_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	if len(value) == 0 or len(trime(self,value)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_VALUE_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end

	if validate_null(self,score) or type(score) ~= "number" then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_MEMBERS_SCORE_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	

	return qkpack_common.QKPACK_OK
end




--validate zset
function _M.validate_zset(self, request)
	
	--ngx.log(ngx.DEBUG,"validate_zset begin-------------------------------------")
	
	local zset_member = request.zset_member
	local mbs = zset_member.mbs
	
	local rc = validate_acl(self, request, zset_member)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	
	rc = validate_zset_key(self, request, zset_member.k)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end
	
	rc = validate_zset_mbs(self, request, mbs)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	
	for i = 1, table.getn(mbs) do
	
		rc = validate_zset_mbs_list(self, request, mbs[i]["mb"], mbs[i]["v"], mbs[i]["sc"])
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
	end


	return qkpack_common.QKPACK_OK
end



--validate zset list
function _M.validate_zset_list(self, request)
	
	--ngx.log(ngx.DEBUG,"validate_zset_list begin-------------------------------------")
	
	local						rc = 0
	local						zset_member = request.zset_member
	local						ks = zset_member.ks
	local						mbs = {}
	local						mbs_len = 0
	local						ks_len = 0


	rc = validate_acl(self, request, zset_member)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end


	if validate_null(self,ks) or type(ks) ~= "table" then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEYS_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	ks_len = table.getn(ks)
	if ks_len == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEYS_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end

	for i = 1, ks_len do
		
		rc = validate_zset_key(self, request, ks[i]["k"])
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
		
		mbs = ks[i]["mbs"]

		rc = validate_zset_mbs(self, request, mbs)
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end
	
		mbs_len = table.getn(mbs)
		for i = 1, mbs_len do
		
			rc = validate_zset_mbs_list(self, request, mbs[i]["mb"], mbs[i]["v"], mbs[i]["sc"])
			if rc ~= qkpack_common.QKPACK_OK then
				return qkpack_common.QKPACK_ERROR
			end
		end

	end

	return qkpack_common.QKPACK_OK
end

	
--validate zset query
local function validate_query(self, request, key, min, max)
	
	--ngx.log(ngx.DEBUG,"validate_query begin-------------------------------------")
	
	if validate_null(self,key) then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_QUERY_KEY_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	if len(key) == 0 or len(trime(self,key)) == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_QUERY_KEY_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end
	
	if validate_null(self,min) or type(min) ~= "number"  then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_QUERY_MIN_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	if validate_null(self,max) or type(max) ~= "number" then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_QUERY_MAX_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end

	
	return qkpack_common.QKPACK_OK
end	
	
	
function _M.validate_zset_query(self, request)
	
	--ngx.log(ngx.DEBUG,"validate_zset_query begin-------------------------------------")
	
	local						rc = 0
	local						zset_query = request.zset_query
	local						k = zset_query.k
	local						min = zset_query.min
	local						max = zset_query.max
	local						asc = zset_query.asc


	local rc = validate_acl(self, request, zset_query)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	rc =  validate_query(self, request, k, min, max)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	request.zset_query.ws = true

	if validate_null(self,asc) or type(asc) ~= "boolean" then
		zset_query.asc =  false
	end

	return qkpack_common.QKPACK_OK
end	


function _M.validate_zset_query_list(self, request)
	
	--ngx.log(ngx.DEBUG,"validate_zset_query begin-------------------------------------")
	
	local						rc = 0
	local						zset_query = request.zset_query
	local						ks = zset_query.ks			

	local rc = validate_acl(self, request, zset_query)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	if validate_null(self,ks)  or type(ks) ~= "table" then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEYS_NOT_EXIST
		return qkpack_common.QKPACK_ERROR
	end
	
	local ks_len = table.getn(ks)
	if ks_len == 0 then
		request.desc = qkpack_common.QKPACK_ERROR_ZSET_KEYS_NOT_EMPTY
		return qkpack_common.QKPACK_ERROR
	end

	for i = 1, ks_len do

		rc =  validate_query(self, request, ks[i]["k"], ks[i]["min"], ks[i]["max"])
		if rc ~= qkpack_common.QKPACK_OK then
			return qkpack_common.QKPACK_ERROR
		end

		request.zset_query.ks[i]["ws"] = true

		if validate_null(self,ks[i]["asc"]) or type(ks[i]["asc"]) ~= "boolean" then
			request.zset_query.ks[i]["asc"] =  false
		end	
	end

	return qkpack_common.QKPACK_OK
end	
	
	
	
return _M
