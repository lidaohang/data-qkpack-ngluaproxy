local cjson = require "cjson"
local qkpack_redis = require "resty.qkpack_redis"
local qkpack_common = require "resty.qkpack_common"
local qkpack_acl = require "resty.qkpack_acl"
local qkpack_metrics = require "resty.qkpack_metrics"
local ljson_decoder = require 'json_decoder'
local http = require "resty.http"

local lower = string.lower
local decoder = ljson_decoder.new()

local _M = {
    _VERSION = '0.01',
}

--_M.key_count = 30
--_M.limit_count = 30


local  	key_count = 30
local	limit_count = 20

local function http_process(path,buffer)

	local							httpc = http.new()
	local							res,err = nil,nil
	local							res_body,body = nil,nil
	local							code = qkpack_common.QKPACK_RESPONSE_CODE_5XX_TIMEOUT
	
	httpc:set_timeout(60000)
	httpc:connect("127.0.0.1", 8015)

	res, err = httpc:request{
		path = path,
		method = "POST",
		body = buffer,
	}

	if not res then
		ngx.log(ngx.ERR, "failed to request: ", err)
		return qkpack_common.QKPACK_ERROR, err, code
	end

	res_body = res:read_body()
	if res_body == nil then
		ngx.log(ngx.ERR, "failed to request response body is nil ")
		return qkpack_common.QKPACK_ERROR, "", code
	end
	
	body = decoder:decode(res_body)
	code = body.e.code
	if code ~= qkpack_common.QKPACK_RESPONSE_CODE_OK then
		ngx.log(ngx.ERR, "response body code failed")
		return qkpack_common.QKPACK_ERROR, body.e.desc, code
	end
	
	local ok, err = httpc:set_keepalive(60000, 10000)
	if not ok then
		ngx.log(ngx.ERR,"failed to set keepalive: ", err)
		return qkpack_common.QKPACK_ERROR, err, code
	end

	return qkpack_common.QKPACK_OK,nil, code
end

local function response(request)
	
	local							data = nil
	local							buffer = nil
	local							err = nil

	request.cost =  ngx.now() * 1000 -  request.begin_time * 1000
	data = {
		e = {
				code=request.code,
				desc=request.desc,
		},
		cost = request.cost,
	}

	buffer, err = cjson.encode(data)
	if buffer == nil then
		ngx.say("json encode failed")
	end
	
	ngx.say(buffer)
end

local function thread_wait(request, thread_pool)
	
	local							rc = 0
	local							err = nil
	local							ok = nil
	local							code = 0
	local							thread_len = #thread_pool
	local							status = false
	
	for i = 1, thread_len do
		ok, rc, err, code = ngx.thread.wait(thread_pool[i])
		if ( not ok ) or rc ~= qkpack_common.QKPACK_OK  then
			ngx.log(ngx.ERR, "thread.wait is failed")
			status = true
			
			for j = i + 1, thread_len do
				local _, killErr = ngx.thread.kill(thread_pool[j])
				if killErr and killErr ~= 'already waited or killed' then
					ngx.log(ngx.ERR, killErr)
				end
			end
			
			break
		end
	end

	if status == true  then
		request.code = code
		request.desc = err ~= nil and err or ""
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end



local function split(request, ks, path, uri, ak)
	
	local								rc = 0
	local								code = 0
	local								data = nil
	local								err = nil
	local								buffer = nil
	local								thread = nil
	local								thread_pool = {}
	local								ks_list = nil
	local								count = 0
	local								ks_len = (ks ~= nil) and table.getn(ks) or 1
	
	local  								mod_count = math.mod(ks_len,key_count) ~= 0 and 1 or 0
	local  								loop_count = (ks_len < key_count) and 1 or (math.floor(ks_len / key_count) + mod_count)
	local  								start_count = 0
	local  								end_count = 0

	--metrics
	qkpack_metrics:user_timer(request)

	--ngx.log(ngx.DEBUG, "split--------------------------------------------")
	--ngx.log(ngx.DEBUG, "ks_len=",ks_len)
	--ngx.log(ngx.DEBUG, "loop_count=", loop_count)


	local num = 0
	for k=1, loop_count do
	
		start_count = end_count + 1
		end_count = end_count + key_count
		if end_count > ks_len then
			end_count = ks_len
		end
		
		if ks ~= nil then 
			
			ks_list = {}
			count = 0
			for i = start_count, end_count do		
				count = count + 1
				ks_list[count] = ks[i]
			end
		end

		data = {
			uri = uri,
			ak = ak,
			ks = ks_list,
		}
		
		buffer, err = cjson.encode(data)
		if buffer == nil then
			request.code = qkpack_common.QKPACK_RESPONSE_CODE_PARSE_ERROR
			request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
			return qkpack_common.QKPACK_ERROR
		end

		num = num + 1
		thread = ngx.thread.spawn(http_process, path, buffer)
		table.insert(thread_pool, thread)
		
		if num == limit_count or k == loop_count then
			
			--ngx.log(ngx.DEBUG, "-------------------------------------------")
			--ngx.log(ngx.DEBUG, "thread_pool=", #thread_pool)
			
			rc = thread_wait(request, thread_pool)
			if rc ~= qkpack_common.QKPACK_OK then
				qkpack_metrics:timer_stop()
				return qkpack_common.QKPACK_ERROR
			end
			num = 0
			thread_pool = {}
		end
	end

	qkpack_metrics:timer_stop()
	return qkpack_common.QKPACK_OK
end


local function process()

	local								rc = 0
	local								request = {}
	local								data = nil
	local								buffer = nil
	local 								ks = {}
	local 								path = nil
	local								uri = lower(ngx.var.uri)
	local								acl_uri = nil
	local								acl_ak = nil
	

	request.desc = ""
	request.begin_time = ngx.now()
	request.code = qkpack_common.QKPACK_RESPONSE_CODE_OK
	
	ngx.req.read_body()	
	data = ngx.req.get_body_data()
	if data == nil then
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_PARSE_ERROR
		request.desc = "no post buffer"
		response(request)
		return
	end
	
	buffer = decoder:decode(data)
	if buffer == nil then
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_PARSE_ERROR
		request.desc = qkpack_common.QKPACK_ERROR_JSON_FORMAT
		response(request)
		return
	end
	
	if uri == qkpack_common.QKPACK_URI_MSET then
	
		request.multikvpair = buffer
		ks = request.multikvpair.ks
		acl_uri = request.multikvpair.uri
		acl_ak = request.multikvpair.ak
			
		path = qkpack_common.QKPACK_URI_MSET.."/sub";
		request.metrics_command = qkpack_common.QKPACK_METRICS_MSET;

	elseif uri == qkpack_common.QKPACK_URI_ZFIXEDSET_BATCHADD then
	
		request.zset_member = buffer
		ks = request.zset_member.ks
		acl_uri = request.zset_member.uri
		acl_ak = request.zset_member.ak

		path = qkpack_common.QKPACK_URI_ZFIXEDSET_BATCHADD.."/sub";
		request.metrics_command = qkpack_common.QKPACK_METRICS_ZFIXEDSETBATCHADD;

	end
	
	rc = qkpack_acl:set_uri_id(request)
	if rc ~= qkpack_common.QKPACK_OK then
		request.uri_id = 0
	end


	rc = split(request, ks, path, acl_uri, acl_ak)
	if rc ~= qkpack_common.QKPACK_OK then
		response(request)
		return
	end
	
	response(request)

	request.zset_member = nil
	request.multikvpair = nil
	request = nil
	
end

process()

return _M
