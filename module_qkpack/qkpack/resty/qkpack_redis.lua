local redis_cluster = require "resty.redis_cluster"
local qkpack_acl = require "resty.qkpack_acl"
local qkpack_common = require "resty.qkpack_common"
local qkpack_snappy = require "resty.qkpack_snappy"
local qkpack_metrics = require "resty.qkpack_metrics"

local len = string.len


local _M = {
    _VERSION = '0.01',
}


_M.add_multikv_script="for i=1, table.getn(KEYS) do \n redis.call('SET', KEYS[i], ARGV[i], 'EX', ARGV[table.getn(KEYS)+i]) \n end \n return 'OK' \n"
_M.incr_by_script="local incrResult \n incrResult = redis.call('INCRBY', KEYS[1], ARGV[1]) \n redis.call('EXPIRE', KEYS[1], ARGV[2]) \n return incrResult \n"
_M.add_rset_script="local i=3 \n local before=redis.call('SCARD', KEYS[1]) \n while i<3+ARGV[2] do \n redis.call('SADD', KEYS[1], ARGV[i]) \n i=i+1 \n end \n redis.call('EXPIRE', KEYS[1], ARGV[1]) \n local after=redis.call('SCARD', KEYS[1]) \n return after-before \n"
_M.add_zset_script="local i=4 \n while i<4+2*ARGV[3] do \n   redis.call('ZADD', KEYS[1], ARGV[i], ARGV[i+1]) \n   while redis.call('ZCARD', KEYS[1]) > tonumber(ARGV[1]) do \n     redis.call('ZREMRANGEBYRANK', KEYS[1], 0, 0) \n   end \n    i=i+2 \n end \n redis.call('EXPIRE', KEYS[1], ARGV[2]) \n return 'OK' \n "


_M.add_multikv_name ="addMultiKVScript"
_M.incr_by_name = "incrByScript"
_M.add_rset_name = "addRSetScript"
_M.add_zset_name = "addZSetScript"

_M.add_multikv_script_sha = {}
_M.incr_by_script_sha = {}
_M.add_rset_script_sha = {}
_M.add_zset_script_sha = {}


local function script_load(self, redis,node_name, slotid, flag) 
	
	if self.add_multikv_script_sha[node_name] == nil or flag == 0 then

		local res, err = redis:send_cluster_command(slotid,"script","load",self.add_multikv_script)
		if not res then
			ngx.log(ngx.ERR, "send_cluster_command add_multikv_script failed  ", err)
			return qkpack_common.QKPACK_ERROR
		end
		self.add_multikv_script_sha[node_name] = res
		
		--ngx.log(ngx.DEBUG,"script_load add_multikv_script_sha "..res)
	end
	
	if self.incr_by_script_sha[node_name] ==  nil or flag == 0 then
	
		local res, err = redis:send_cluster_command(slotid,"script","load",self.incr_by_script)
		if not res then
			ngx.log(ngx.ERR, "send_cluster_command incr_by_script failed  ", err)
			return qkpack_common.QKPACK_ERROR
		end
		self.incr_by_script_sha[node_name] = res
		
		--ngx.log(ngx.DEBUG,"script_load incr_by_script_sha "..res)
	end

	if self.add_rset_script_sha[node_name] ==  nil or flag == 0 then
	
		local res, err = redis:send_cluster_command(slotid,"script","load",self.add_rset_script)
		if not res then
			ngx.log(ngx.ERR, "send_cluster_command add_rset_script failed  ", err)
			return qkpack_common.QKPACK_ERROR
		end
		self.add_rset_script_sha[node_name] = res
		
		--ngx.log(ngx.DEBUG,"script_load add_rset_script_sha "..res)
	end

	
	if self.add_zset_script_sha[node_name] == nil or flag == 0 then
		
		local res, err = redis:send_cluster_command(slotid,"script","load",self.add_zset_script)
		if not res then
			ngx.log(ngx.ERR, "send_cluster_command add_zset_script failed  ", err)
			return qkpack_common.QKPACK_ERROR
		end
		self.add_zset_script_sha[node_name] = res
		
		--ngx.log(ngx.DEBUG,"script_load add_zset_script_sha "..res)
	end

	return qkpack_common.QKPACK_OK
end

local function thread_wait(self,thread_pool)
	
	local							rc = 0
	local							ok = nil
	local							miss, res = nil, nil
	local							thread_len = #thread_pool
	local							status = false
	
	for i = 1, thread_len do
		ok, rc, res = ngx.thread.wait(thread_pool[i])
		if res ~= nil then
			miss = res
		end
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
		return qkpack_common.QKPACK_ERROR
	end
	
	if miss == nil then
		return qkpack_common.QKPACK_OK
	end
	
	return qkpack_common.QKPACK_OK, miss
end



--GET
local function get(self, redis , request)
	
	local								b = true
	local								val,value = nil,nil
	local 								res,err = nil, nil
	local								key	= request.kvpair.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	
	--metrics timer
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_GET_COMMAND, namespace_key)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command get failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end

	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	if res == nil or res == ngx.null then
		--metrics
		request.metrics_command = qkpack_common.QKPACK_METRICS_GETMISS
		qkpack_metrics:user_meter(request)
	end
	
	b, val = qkpack_snappy:uncompress_value(res)
	if b == true then
		value = val
	else
		value = res
	end
	
	request.kvpair.v = value
	return qkpack_common.QKPACK_OK
end

--SET
local function set(self, redis , request)
	
	local								b = true
	local								val,compress_val = nil,nil
	local 								res,err = nil, nil
	local								key	= request.kvpair.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								exptime	= request.exptime
	local								value = request.kvpair.v
	local								compress_threshold = request.compress_threshold

	b, val = qkpack_snappy:compress_value(value, compress_threshold)	
	if b == true then
		compress_val = val
	else
		compress_val = value
	end
	
	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_SET_COMMAND, namespace_key, exptime, compress_val)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command set failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	

	request.kvpair.v = res
	return qkpack_common.QKPACK_OK
end

--TTL
local function ttl(self, redis , request)
	
	local 								res,err = nil, nil
	local								key	= request.kvpair.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	
	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_TTL_COMMAND, namespace_key)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command ttl failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
		
	request.kvpair.v = res
	return qkpack_common.QKPACK_OK
end

--DEL
local function del(self, redis , request)
	
	local 								res,err = nil, nil
	local								key	= request.kvpair.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	
	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_DEL_COMMAND, namespace_key)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command del failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
		
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	request.kvpair.v = res
	return qkpack_common.QKPACK_OK
end

--incrBy
local function incrBy(self, redis , request)
	
	local								rc = 0
	local								port = 0
	local								slotid = -1
	local								list = {}
	local								value = nil
	local 								res,err = nil, nil
	local								ip,node_name = nil, nil
	local								key	= request.kvpair.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								command_type = request.command_type
	local								exptime = request.exptime

	if command_type == qkpack_common.REDIS_INCR then
		value = "1"
	else
		value = request.kvpair.v
		request.script_name = self.incr_by_name;
	end

	slotid = redis:keyslot(namespace_key)

	ip,port = redis:get_node_by_slot(slotid)
	node_name = ip..tostring(port)

	rc = script_load(self, redis, node_name, slotid, flag)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	--add sha
	table.insert(list, self.incr_by_script_sha[node_name])
	
	--add key num
	table.insert(list, "1")

	--add key
	table.insert(list, namespace_key)

	--add value
	table.insert(list, value)

	--add exptime
	table.insert(list, tostring(exptime))

	--metrics
	qkpack_metrics:user_timer(request)

	res, err = redis:send_cluster_command(slotid,qkpack_common.REDIS_SCRIPT_EVALSHA_COMMAND, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command incrBy or incr failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
		
	request.kvpair.v = res
	return qkpack_common.QKPACK_OK
end


local function mget(self, redis, request, keys, slotid)
	
	local								b = true
	local								ks_len = 0
	local								values_len = 0
	local 								values,err = nil, nil
	local								val, value = nil, nil
	local								namespace = request.namespace
	local								keys_len = table.getn(keys)
	local								newstr = nil

	--request.script_name = qkpack_common.QKPACK_METRICS_G_MGET;
	
	if request.multikvpair ~= nil then
		ks_len = table.getn(request.multikvpair.ks)
	elseif request.zset_member ~= nil then 
		ks_len = table.getn(request.zset_member.mbs)
	else
		return qkpack_common.QKPACK_ERROR
	end

	values, err = redis:send_cluster_command(slotid, qkpack_common.REDIS_MGET_COMMAND, unpack(keys))
	if not values then
		ngx.log(ngx.ERR, "send_cluster_command mget failed  ", err)
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end

	values_len = table.getn(values)
	if keys_len ~= values_len then
		return qkpack_common.QKPACK_ERROR
	end

	local miss = false
	local val_temp = nil	
	for i=1,values_len do

		for j=1,ks_len do
			val_temp = values[i]
			

			if request.command_type == qkpack_common.REDIS_ZRANGEBYSCORE or
				request.command_type == qkpack_common.REDIS_ZRANGE or
				request.command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
				
				newstr = string.sub(keys[i], 3)
				if request.zset_member.mbs[j] ~= nil and request.zset_member.mbs[j]["mb"] == newstr then
					
					b, val = qkpack_snappy:uncompress_value(val_temp)
					if b == true then
						value = val
					else
						value = val_temp
					end

					if value == nil or value == ngx.null then
						miss = true	
						table.remove(request.zset_member.mbs,j)
					else 
						request.zset_member.mbs[j]["v"] = value
					end
				end
			else
				newstr = string.sub(keys[i], 3)
				if request.multikvpair.ks[j] ~= nil  and request.multikvpair.ks[j]["k"] == newstr then
					
					b, val = qkpack_snappy:uncompress_value(val_temp)
					if b == true then
						value = val
					else
						value = val_temp
					end

					if value == nil or value == ngx.null then
						miss = true
						table.remove(request.multikvpair.ks,j)
					else 
						request.multikvpair.ks[j]["v"] = value
					end
				end
			end
		end
	end
	
	if miss == false then
		return qkpack_common.QKPACK_OK
	end
	
	return qkpack_common.QKPACK_OK , miss
end


--mget
local function multi_mget(self, redis, request)
	
	local 								rc = 0
	local								slot,slot_child = -1,-1
	local								status,ks_len = 0,0
	local 								ok,ks,miss = nil, nil, nil
	local								key,key_name = nil, nil
	local								keys_list = nil
	local								namespace_key = nil
	local								slots = {}
	local								slots_len = 0
	local								ks_slot = {}
	local								thread_pool = {}
	local								thread = nil
	local								namespace = request.namespace

	if request.command_type == qkpack_common.REDIS_ZRANGEBYSCORE or
		request.command_type == qkpack_common.REDIS_ZRANGE or
		request.command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then

		ks = request.zset_member.mbs
		key_name = "mb"
	else
		
		ks = request.multikvpair.ks
		key_name = "k"
	end
	
	ks_len = table.getn(ks)
	--计算slots数量
	for i=1,ks_len do
		key = ks[i][key_name]
		if key ~= nil then
			
			namespace_key = namespace..key
			slot = redis_cluster:keyslot(namespace_key)
			ks_slot[i] = slot
			status = 0
			
			slots_len = table.getn(slots)
			for j=1, slots_len do
				if slot == slots[j] then
					status = 1
					break
				end
			end

			if slots_len == 0 or status == 0 then
				table.insert(slots,slot)
			end
		end
	end

	if request.command_type == qkpack_common.REDIS_MGET then
		--metrics timer
		request.script_name = qkpack_common.QKPACK_METRICS_G_MGET;
		qkpack_metrics:user_timer(request)
	end

	--计算批量发送的keys
	slots_len = table.getn(slots)
	for i=1,slots_len do
			
		keys_list = {}
		for j=1,ks_len do
			
			key = ks[j][key_name]
			if key ~= nil then
				
				namespace_key = namespace..key
				slot_child = ks_slot[j]  --redis_cluster:keyslot(namespace_key)
				if slots[i] == slot_child then
					table.insert(keys_list,namespace_key)
				end

			end
		end	
		
		thread = ngx.thread.spawn(mget, self, redis, request, keys_list, slots[i])
		table.insert(thread_pool, thread)
	end

	--批量发送keys返回的结果状态
	rc, miss = thread_wait(self, thread_pool)
	if rc ~= qkpack_common.QKPACK_OK then
		if request.command_type == qkpack_common.REDIS_MGET then
			--metrics timer stop
			qkpack_metrics:timer_stop()
		end

		return qkpack_common.QKPACK_ERROR
	end
	
	if request.command_type == qkpack_common.REDIS_MGET then
		--metrics timer stop
		qkpack_metrics:timer_stop()
	end
	
	if miss == nil or miss == false then
		return qkpack_common.QKPACK_OK
	end
	
	local dim_name = nil
	if request.command_type == qkpack_common.REDIS_ZRANGEBYSCORE or
		request.command_type == qkpack_common.REDIS_ZRANGE or
		request.command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
		
		dim_name = request.command_type == qkpack_common.REDIS_ZRANGEBYSCORE and
	       	qkpack_common.QKPACK_METRICS_ZFIXEDSETGETBYSCOREMISS or qkpack_common.QKPACK_METRICS_ZFIXEDSETGETBYRANKMISS
	else
		dim_name = qkpack_common.QKPACK_METRICS_MGETMISS	
	end	
	
	--metrics
	request.metrics_command = dim_name
	qkpack_metrics:user_meter(request)
	
	return qkpack_common.QKPACK_OK
end


local function mset(self, redis, request, kv_list, slotid)
	
	local								rc = 0
	local								b = true
	local								port = 0
	local								list = {}
	local								ip,node_name = nil,nil
	local								val,compress_val = nil,nil
	local 								res,err = nil, nil
	local								kv_list_len = table.getn(kv_list)
	local								exptime = request.exptime
	local								compress_threshold = request.compress_threshold

	--request.script_name = self.add_multikv_name;

	ip,port = redis:get_node_by_slot(slotid)
	node_name = ip..tostring(port)
	
	rc = script_load(self, redis, node_name, slotid, flag)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	--add sha
	table.insert(list, self.add_multikv_script_sha[node_name])
	
	--add key num
	table.insert(list, kv_list_len)

	--add key
	local kv_list_len  = table.getn(kv_list)
	for i=1, kv_list_len do
		table.insert(list, kv_list[i]["key"])
	end

	--add value
	for i=1,kv_list_len do
		b, val = qkpack_snappy:compress_value(kv_list[i]["value"], compress_threshold)	
		if b == true then
			compress_val = val
		else
			compress_val = kv_list[i]["value"]
		end
	
		table.insert(list, compress_val)
	end

	--add exptime
	for i=1,kv_list_len do
		table.insert(list, tostring(exptime))
	end

	res, err = redis:send_cluster_command(slotid,qkpack_common.REDIS_SCRIPT_EVALSHA_COMMAND, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command mset failed  ", err)
	
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end

local function multi_mset(self, redis, request)
	
	local 								rc = 0
	local 								ok = nil
	local								slot,status = 0,0
	local								key_name = nil
	local								key,value = nil,nil
	local								ks = {}
	local								ks_slot = {}
	local								slots = {}
	local								slots_len = 0
	local								kv_list	= nil
	local								thread = nil
	local								thread_pool = {}
	local								namespace_key = nil
	local								namespace = request.namespace
	
	if request.command_type == qkpack_common.REDIS_ZADD or
		request.command_type == qkpack_common.REDIS_ZBATCHADD then

		ks = request.zset_member.mbs
		key_name = "mb"
	else
		ks = request.multikvpair.ks
		key_name = "k"
	end

	--计算slots数量
	local ks_len = table.getn(ks)
	for i=1, ks_len do
		
		key = ks[i][key_name]
		if key ~= nil then

			namespace_key = namespace..key
			slot = redis_cluster:keyslot(namespace_key)
			ks_slot[i] = slot
			status = 0	
			
			slots_len = table.getn(slots)	
			for j=1, slots_len do
				
				if slot == slots[j] then
					status = 1
					break
				end
			end
			
			if slots_len == 0 or status == 0  then
				table.insert(slots,slot)
			end
		end
	end

	if request.command_type == qkpack_common.REDIS_MSET then
		request.script_name = self.add_multikv_name;
		qkpack_metrics:user_timer(request)
	end

	
	slots_len = table.getn(slots)
	for i=1, slots_len do
			
		kv_list = {}
		for j=1,ks_len do
			
			key = ks[j][key_name]
			value = ks[j]["v"]

			if key ~= nil and value ~= nil then
				
				namespace_key = namespace..key
				slot_child = ks_slot[j] --redis_cluster:keyslot(namespace_key)
				if slots[i] == slot_child then
					table.insert(kv_list,{key=namespace_key,value=value})
				end

			end
		end	
		
		thread = ngx.thread.spawn(mset, self, redis, request, kv_list, slots[i])
		table.insert(thread_pool, thread)

	end

	rc = thread_wait(self, thread_pool)
	if rc ~= qkpack_common.QKPACK_OK then
		if request.command_type == qkpack_common.REDIS_MSET then
			--metrics timer stop
			qkpack_metrics:timer_stop()
		end

		return qkpack_common.QKPACK_ERROR
	end
	
	if request.command_type == qkpack_common.REDIS_MSET then
		--metrics timer stop
		qkpack_metrics:timer_stop()
	end

	return qkpack_common.QKPACK_OK
end


--SADD
local function sadd(self, redis , request)
	
	local								rc = 0
	local								port = 0
	local								slotid = -1
	local								list = {}
	local								b = true
	local 								res,err = nil, nil
	local								ip,node_name = nil, nil
	local								val,compress_val = nil,nil
	local								key	= request.sset_member.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								exptime = request.exptime	
	local								mbs = request.sset_member.mbs
	local								compress_threshold = request.compress_threshold
	
	request.script_name = self.add_rset_name;

	slotid = redis:keyslot(namespace_key)
	ip,port = redis:get_node_by_slot(slotid)
	node_name = ip..tostring(port)

	rc = script_load(self, redis, node_name, slotid, flag)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_common.QKPACK_ERROR
	end

	--add sha
	table.insert(list, self.add_rset_script_sha[node_name])

	--add key num
	table.insert(list, "1")

	--add key
	table.insert(list, namespace_key)

	--add exptime
	table.insert(list, tostring(exptime))
	
	--add mbs count
	table.insert(list, tostring(table.getn(mbs)))

	for _,v in pairs(mbs) do

		b, val = qkpack_snappy:compress_value(v, compress_threshold)	
		if b == true then
			compress_val = val
		else
			compress_val = v
		end
		
		table.insert(list, compress_val)	
	end

	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(slotid,qkpack_common.REDIS_SCRIPT_EVALSHA_COMMAND, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command sadd failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	request.sset_member.data = res
	return qkpack_common.QKPACK_OK
end


--SREM
local function srem(self, redis , request)
		
	local								rc = 0
	local								list = {}
	local								b = true
	local 								res,err = nil, nil
	local								val,compress_val = nil,nil
	local								key	= request.sset_member.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								mbs = request.sset_member.mbs
	local								compress_threshold = request.compress_threshold

	--add key
	table.insert(list, namespace_key)

	--add mbs
	for _,v in pairs(mbs) do
		b, val = qkpack_snappy:compress_value(v, compress_threshold)	
		if b == true then
			compress_val = val
		else
			compress_val = v
		end
		
		table.insert(list, compress_val)
	end

	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_SREM_COMMAND, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command srem failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end

	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	request.sset_member.data = res
	return qkpack_common.QKPACK_OK
end


--SCARD
local function scard(self, redis , request)
		
	local								rc = 0
	local 								res,err = nil, nil
	local								key	= request.sset_member.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key

	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_SCARD_COMMAND, namespace_key)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command scard failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()

	request.sset_member.data = res
	return qkpack_common.QKPACK_OK
end


--SMEMBERS
local function smembers(self, redis , request)
	
	--ngx.log(ngx.DEBUG, "smembers------------------------------------------------------")
		
	local								rc = 0
	local  								mbs = {}
	local								b = true
	local								res_len = 0
	local 								res,err = nil, nil
	local								val,value = nil,nil
	local								key	= request.sset_member.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key

	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_SMEMBERS_COMMAND, namespace_key)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command smembers failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()

		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()

	res_len = table.getn(res)
	for i = 1, res_len do
		
		b, val = qkpack_snappy:uncompress_value(res[i])
		if b == true then
			value = val
		else
			value = res[i]
		end
		
		mbs[i] = value
	end
	
	if res_len == 0 then
		--metrics
		request.metrics_command = qkpack_common.QKPACK_METRICS_SMEMBERSMISS
		qkpack_metrics:user_meter(request)
	end
	
	
	request.sset_member.mbs = mbs
	return qkpack_common.QKPACK_OK
end


--SISMEMBER
local function sismember(self, redis , request)
	
	--ngx.log(ngx.DEBUG, "sismember------------------------------------------------------------------------")
		
	local								rc = 0
	local								b = true
	local 								res,err = nil, nil
	local								val,compress_val = nil,nil
	local								key	= request.sset_member.k 
	local								value = request.sset_member.v 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								compress_threshold = request.compress_threshold
	
	b, val = qkpack_snappy:compress_value(value, compress_threshold)	
	if b == true then
		compress_val = val
	else
		compress_val = value
	end
	
	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, qkpack_common.REDIS_SISMEMBER_COMMAND, namespace_key, compress_val)
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command sismember failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	request.sset_member.data = res == 1 and true or false
	return qkpack_common.QKPACK_OK
end


local function zadd_process(self, redis, request)
		
	local								rc = 0
	local								port,slotid = 0,-1
	local 								res,err = nil, nil
	local								ip,node_name = nil,nil
	local								list = {}
	local								key	= request.zset_member.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								exptime = request.exptime	
	local								limit = request.limit
	local								mbs = request.zset_member.mbs
	local								mbs_count = table.getn(mbs)

	slotid = redis:keyslot(namespace_key)
	ip,port = redis:get_node_by_slot(slotid)
	node_name = ip..tostring(port)

	rc = script_load(self, redis, node_name, slotid, flag)
	if rc ~= qkpack_common.QKPACK_OK then

		ngx.log(ngx.ERR, "script_load is error")
		return qkpack_common.QKPACK_ERROR
	end

	--add sha
	table.insert(list, self.add_zset_script_sha[node_name])

	--add key num
	table.insert(list, "1")

	--add key
	table.insert(list, namespace_key)

	--add limit
	table.insert(list, tostring(limit))
	
	--add exptime
	table.insert(list, tostring(exptime))
	
	--add mbs count
	table.insert(list, tostring(mbs_count))

	for i = 1, mbs_count do
		table.insert(list, mbs[i]["sc"])  
		table.insert(list, namespace..mbs[i]["mb"])
	end	
	
	res, err = redis:send_cluster_command(slotid,qkpack_common.REDIS_SCRIPT_EVALSHA_COMMAND, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command zadd failed  ", err)
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR
	end
	
	return qkpack_common.QKPACK_OK
end


--ZADD
local function zadd(self, redis , request)
	
	local								rc = 0
	local								ok = nil
	local								thread = nil
	local								zset_member = request.zset_member

	rc, res = qkpack_acl:get_zset_limit(zset_member.uri, zset_member.ak, len(zset_member.k))
	if rc ~= qkpack_common.QKPACK_OK then
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_ILLEGAL_RIGHT
		request.desc = res
		return qkpack_common.QKPACK_ERROR
	end
	request.limit = res

	request.script_name = self.add_zset_name;
	--metrics
	qkpack_metrics:user_timer(request)
	
	thread = ngx.thread.spawn(zadd_process, self, redis, request)
	
	ok, rc = ngx.thread.wait(thread)
	if ( not ok ) or rc ~= qkpack_common.QKPACK_OK then
		--metrics timer stop
		qkpack_metrics:timer_stop()
	
		return qkpack_common.QKPACK_ERROR
	end
	
	rc = multi_mset(self, redis, request)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "send_cluster_command zadd->mset failed ")
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		return qkpack_common.QKPACK_ERROR
	end

	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	return qkpack_common.QKPACK_OK
end


--multi_zadd
local function multi_zadd(self, redis, request)

	local								rc = 0
	local								ok = nil
	local								thread = nil
	local								mbs_temp = nil
	local								mbs_temp_len = 0
	local								request_sub = nil
	local								mbs  = {}
	local								thread_pool = {}
	local								zset_member = {}
	local								ks = request.zset_member.ks
	local								compress_threshold = request.compress_threshold

	request.script_name = self.add_zset_name;
	--metrics
	--qkpack_metrics:user_timer(request)

	local uri = request.zset_member.uri
	local ak = request.zset_member.ak
	local ks_len = table.getn(ks)

	--ngx.log(ngx.DEBUG, "multi_zadd---------------------------------------")
	--ngx.log(ngx.DEBUG, ks_len)

	for i = 1, ks_len do
		request_sub = {}
		
		request_sub.zset_member = ks[i]
		request_sub.namespace = request.namespace
		request_sub.exptime = request.exptime
		request_sub.begin_time = request.begin_time
		
		rc, res = qkpack_acl:get_zset_limit(uri,ak,len(request_sub.zset_member.k))
		if rc ~= qkpack_common.QKPACK_OK then
			request.code = qkpack_common.QKPACK_RESPONSE_CODE_ILLEGAL_RIGHT
			request.desc = res
			
			ngx.log(ngx.ERR, res)
			return qkpack_common.QKPACK_ERROR
		end
		request_sub.limit = res

		thread = ngx.thread.spawn(zadd_process, self, redis, request_sub)
		table.insert(thread_pool, thread)
	
		mbs_temp = request_sub.zset_member.mbs
		mbs_temp_len = table.getn(mbs_temp)
		for j = 1, mbs_temp_len do
			table.insert(mbs, { mb = mbs_temp[j]["mb"], v = mbs_temp[j]["v"]  })
		end
	end

	rc = thread_wait(self, thread_pool)
	if rc ~= qkpack_common.QKPACK_OK then
		--qkpack_metrics:timer_stop()
		return qkpack_common.QKPACK_ERROR
	end
		
	--metrics timer stop
	--qkpack_metrics:timer_stop()
	
	request_sub = {}
	zset_member = {}
	
	request_sub.namespace = request.namespace
	request_sub.exptime = request.exptime
	request_sub.command_type = request.command_type

	zset_member.mbs = mbs
	request_sub.zset_member = zset_member
	request_sub.compress_threshold = compress_threshold
	request_sub.begin_time = request.begin_time

	rc = multi_mset(self, redis, request_sub)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "send_cluster_command multi_zadd->mset failed ")
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK	
end


--getbyscore process
local function zset_getbyscore_process(self, redis, request)

	local								rc = 0
	local								list = {}
	local								command = nil
	local 								res,err = nil, nil
	local								zset_query = request.zset_query
	local								key	= zset_query.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key

	if zset_query.asc then
		command = qkpack_common.REDIS_ZRANGEBYSCORE_COMMAND
	else
		command = qkpack_common.REDIS_ZREVRANGEBYSCORE_COMMAND
	end

	--request.script_name = qkpack_common.QKPACK_METRICS_G_ZRANGE

	--add namespace_key
	table.insert(list, namespace_key)

	if zset_query.asc then
		--add min
		table.insert(list, tostring(zset_query.min))

		--add max
		table.insert(list, tostring(zset_query.max))
	else
		--add max
		table.insert(list, tostring(zset_query.max))
		
		--add min
		table.insert(list, tostring(zset_query.min))
	end

	if zset_query.ws then
		
		--add withscores
		table.insert(list, qkpack_common.REDIS_ZRANGE_WITHSCORES_COMMAND)
	end

	res, err = redis:send_cluster_command(nil, command, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command zset_getbyscore failed  ", err)
		
		request.desc = err
		return qkpack_common.QKPACK_ERROR, nil
	end
	
	return qkpack_common.QKPACK_OK, res
end


--getbyscore
local function zset_getbyscore(self, redis, request)
	
	local								rc = 0
	local								thread = nil
	local								ok, res = nil,nil
	local								member,score = nil,nil
	local   							zset_member = {}
	local								mbs = {}
	local								namespace = request.namespace
	local								newstr = nil

	request.script_name = qkpack_common.QKPACK_METRICS_G_ZRANGE
	--metrics
	qkpack_metrics:user_timer(request)
	
	thread = ngx.thread.spawn(zset_getbyscore_process, self, redis, request)
	
	ok, rc, res = ngx.thread.wait(thread)
	if ( not ok ) or rc ~= qkpack_common.QKPACK_OK then
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	local res_len = table.getn(res)	
	for i = 1, res_len do
		
		if i % 2 == 0 then
			score = res[i]
			newstr = string.sub(member, 3)
			table.insert(mbs, {mb = newstr, sc = tonumber(score), v = "" })
		else 
			member = res[i]
		end

	end
	
	zset_member.mbs = mbs
	request.zset_member = zset_member

	rc = multi_mget(self, redis, request)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "send_cluster_command getbyscore->mget failed ")
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end

local function multi_zset_getbyscore(self, redis, request)
	
	local								rc = 0
	local								ok,res = nil,nil
	local								res_len = 0
	local								ks = request.zset_query.ks
	local								thread = nil
	local								thread_pool = {}
	local   							zset_member = {}
	local								mbs = {}
	local								member,score = nil,nil
	local								namespace = request.namespace
	local								newstr = nil

	request.script_name = qkpack_common.QKPACK_METRICS_G_ZRANGE
	--metrics
	qkpack_metrics:user_timer(request)

	local ks_len = table.getn(ks)
	for i = 1, ks_len do
		request_sub = {}
		
		request_sub.zset_query = ks[i]
		request_sub.namespace = request.namespace
		
		thread = ngx.thread.spawn(zset_getbyscore_process, self, redis, request_sub)
		table.insert(thread_pool, thread)
	end
	
	local				request_list = {}
	local				request_sub = {}
	local				thread_pool_size = table.getn(thread_pool)
	for i = 1, thread_pool_size do

		request_sub = {}
		mbs = {}
		zset_member = {}

		request_sub.command_type = request.command_type
		request_sub.namespace = request.namespace
		request_sub.k = ks[i]["k"]
		
		ok, rc, res = ngx.thread.wait(thread_pool[i]) 
		if ( not ok ) or rc ~= qkpack_common.QKPACK_OK then
			--metrics timer stop
			qkpack_metrics:timer_stop()
			
			for j = i + 1, thread_len do
				local _, killErr = ngx.thread.kill(thread_pool[j])
				if killErr and killErr ~= 'already waited or killed' then
					ngx.log(ngx.ERR, killErr)
				end
			end
		
			return qkpack_common.QKPACK_ERROR
		end
		
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		res_len = table.getn(res)
		for i = 1, res_len do
			if i % 2 == 0 then
				score = res[i]
				newstr = string.sub(member, 3)
				table.insert(mbs, {mb = newstr, sc = tonumber(score), v = "" })
			else 
				member = res[i]
			end
		end

		zset_member.mbs = mbs
		request_sub.zset_member = zset_member

		rc = multi_mget(self, redis, request_sub)
		if rc ~= qkpack_common.QKPACK_OK then
			ngx.log(ngx.ERR, "send_cluster_command multi_zset_getbyscore->mget failed ")
			return qkpack_common.QKPACK_ERROR
		end
		
		table.insert(request_list, 
			{k = request_sub.k, mc = table.getn(request_sub.zset_member.mbs), mbs = request_sub.zset_member.mbs} )
	end
	
	request.zset_member_list = request_list
	return qkpack_common.QKPACK_OK
end


--getbyrank
local function zset_getbyrank(self, redis, request)

	local								rc = 0
	local 								res, err = nil,nil
	local								command = nil
	local								list = {}
	local								zset_query = request.zset_query
	local								key	= zset_query.k 
	local								namespace = request.namespace
	local								namespace_key = namespace..key
	local								newstr = nil

	if zset_query.asc then
		command = qkpack_common.REDIS_ZRANGE_COMMAND
	else
		command = qkpack_common.REDIS_ZREVRANGE_COMMAND
	end

	request.script_name = qkpack_common.QKPACK_METRICS_G_ZRANGE

	--add namespace_key
	table.insert(list, namespace_key)

	--add min
	table.insert(list, tostring(zset_query.min))

	--add max
	table.insert(list, tostring(zset_query.max))

	--add withscores
	if zset_query.ws then
		table.insert(list, qkpack_common.REDIS_ZRANGE_WITHSCORES_COMMAND)
	end
	
	--metrics
	qkpack_metrics:user_timer(request)
	
	res, err = redis:send_cluster_command(nil, command, unpack(list))
	if not res then
		ngx.log(ngx.ERR, "send_cluster_command zset_getbyrank failed  ", err)
		--metrics timer stop
		qkpack_metrics:timer_stop()
		
		request.desc = res
		return qkpack_common.QKPACK_ERROR
	end
	
	--metrics timer stop
	qkpack_metrics:timer_stop()
	
	local   zset_member = {}
	local	mbs = {}
	local	member = nil
	local	score = nil
	local	res_len = table.getn(res)

	for i = 1, res_len do
		
		if i % 2 == 0 then
			score = res[i]
			newstr = string.sub(member, 3)
			table.insert(mbs, {mb = newstr, sc = tonumber(score), v = "" })
		else 
			member = res[i]
		end

	end
	
	zset_member.mbs = mbs
	request.zset_member = zset_member

	rc = multi_mget(self, redis, request)
	if rc ~= qkpack_common.QKPACK_OK then
		ngx.log(ngx.ERR, "send_cluster_command getbyrank->mget failed ")
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end

_M.cluster_list = {}

function _M.process(self, request)

	--ngx.log(ngx.DEBUG,"process begin-----------------------------------------------")

	local								rc = 0
	local 								cluster_id = request.cluster_name
	local 								command_type = request.command_type
	
	local opt = { 
		timeout = 120000,
		keepalive_size = 20000,
		keepalive_duration = 60000
	}
	

	local redis = redis_cluster:new(cluster_id, request.node_list, opt)
	--if self.cluster_list[cluster_id] == nil then
        --	self.cluster_list[cluster_id] = true
		redis:initialize()
        --end

	
	if command_type == qkpack_common.REDIS_GET then

		rc = get(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SET then
		
		rc = set(self, redis, request)

	elseif command_type == qkpack_common.REDIS_DEL then

		rc = del(self, redis, request)

	elseif command_type == qkpack_common.REDIS_TTL then

		rc = ttl(self, redis, request)

	elseif command_type == qkpack_common.REDIS_INCR or
		command_type == qkpack_common.REDIS_INCRBY then

		rc = incrBy(self, redis, request)

	elseif command_type == qkpack_common.REDIS_MGET then
	
		rc = multi_mget(self, redis, request)
	
	elseif command_type == qkpack_common.REDIS_MSET then

		rc = multi_mset(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SADD then

		rc = sadd(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SREM then

		rc = srem(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SCARD then

		rc = scard(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SMEMBERS then

		rc = smembers(self, redis, request)

	elseif command_type == qkpack_common.REDIS_SISMEMBER then

		rc = sismember(self, redis, request)

	elseif command_type == qkpack_common.REDIS_ZADD then
	
		rc = zadd(self, redis, request)

	elseif command_type == qkpack_common.REDIS_ZBATCHADD then
	
		rc = multi_zadd(self, redis, request)

	elseif command_type == qkpack_common.REDIS_ZRANGEBYSCORE then	

		rc = zset_getbyscore(self, redis, request)

	elseif command_type == qkpack_common.REDIS_ZRANGE then

		rc = zset_getbyrank(self, redis, request)
	
	elseif command_type == qkpack_common.REDIS_BATCHZRANGEBYSCORE then
		
		rc = multi_zset_getbyscore(self, redis, request)

	end

	
	if rc ~= qkpack_common.QKPACK_OK then
		request.code =  request.code == 0 and qkpack_common.QKPACK_RESPONSE_CODE_REDIS_STORAGE_ERROR or request.code
		return qkpack_common.QKPACK_ERROR
	end

	return qkpack_common.QKPACK_OK
end


return _M
