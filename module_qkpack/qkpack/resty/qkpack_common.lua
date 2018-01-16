local new_tab = require "table.new"

local _M = {
    _VERSION = '0.01',
}


--[[ /******************************************
	*状态
	*
******************************************/ --]]

_M.QKPACK_HTTP_OK	=													200

_M.QKPACK_OK		=													0
_M.QKPACK_ERROR		=				   							    	-1
_M.QKPACK_AGAIN		=				   							    	-2
_M.QKPACK_UPSTREAM_INVALID_HEADER     =								    40

_M.REDIS_OK			=													0
_M.REDIS_ERROR		=												    -1
_M.REDIS_AGAIN		=												    -2
_M.REDIS_MOVED		=													2
_M.REDIS_ASK		=													3
_M.REDIS_ASKING		=													4
_M.REDIS_ASKING_END	=													5
_M.REDIS_TRYAGAIN	=													6
_M.REDIS_CLUSTER	=													40


_M.INT_LEN			=													11
_M.LONG_LEN			=													21


--[[ /******************************************
	*读写
	*
******************************************/ --]]

_M.QKPACK_OPERATION_READ		=										1
_M.QKPACK_OPERATION_WRITE		=										2
_M.QKPACK_OPERATION_RW			=										3

--[[ /******************************************
	*cluster nodes
	*
******************************************/ --]]

_M.CLUSTER_NODES_ID				=										0
_M.CLUSTER_NODES_ADDR			=										1
_M.CLUSTER_NODES_ROLE			=										2
_M.CLUSTER_NODES_SID			=										3
_M.CLUSTER_NODES_CONNECTED		=										7
_M.CLUSTER_NODES_LENGTH			=										8
_M.CLUSTER_NODES_SLAVE_LEN		=										7


--[[ /******************************************
	*全局配置文件
	*
******************************************/ --]]

_M.QKPACK_CONF_ACL_URL			=										"aclUrl"
_M.QKPACK_CONF_TIMEOUT			=										"timeout"
_M.QKPACK_CONF_ADD_ZSET_SCRIPT	=										"addZSetScript"
_M.QKPACK_CONF_ADD_MULTIKV_SCRIPT		=								"addMultiKVScript"
_M.QKPACK_CONF_INCRBY_SCRIPT			=								"incrByScript"
_M.QKPACK_CONF_ADD_RSET_SCRIPT			=								"addRSetScript"


--[[ /******************************************
	*ACL配置
	*
******************************************/ --]]
_M.QKPACK_ACL_URI_FORMAT		=										"qkd://"
_M.QKPACK_ACL_URI_ID			=										"uri_id"
_M.QKPACK_ACL_OPERATION			=										"operation"
_M.QKPACK_ACL_QUOTATION			=										"quotation"
_M.QKPACK_ACL_QUOTATION_EXPIRE	=										"expire"
_M.QKPACK_ACL_QUOTATION_COMMPRESSTHRESHOLD 		=						"compressThreshold"
_M.QKPACK_ACL_QUOTATION_LIMITPOLICIES			=						"limitPolicies"
_M.QKPACK_ACL_QUOTATION_LIMITPOLICIES_MIN		=						"min"
_M.QKPACK_ACL_QUOTATION_LIMITPOLICIES_MAX		=						"max"
_M.QKPACK_ACL_QUOTATION_LIMITPOLICIES_LIMIT		=						"limit"
_M.QKPACK_ACL_QUOTATION_TIMEOUTS				=						"timeouts"
_M.QKPACK_ACL_QUOTATION_TIMEOUTS_INTERFACENAME	=						"interfaceName"
_M.QKPACK_ACL_QUOTATION_TIMEOUTS_TIMEOUT		=						"timeout"
_M.QKPACK_ACL_QUOTATION_TIMEOUTS_TRIES			=						"tries"

_M.QKPACK_ACL_QUOTATION_LIMITSLENGTH					=				"limitsLength"
_M.QKPACK_ACL_QUOTATION_LIMITSLENGTH_INTERFACENAME		=				"interfaceName"
_M.QKPACK_ACL_QUOTATION_LIMITSLENGTH_KEYLEN				=				"keylen"
_M.QKPACK_ACL_QUOTATION_LIMITSLENGTH_VALLEN				=				"vallen"
_M.QKPACK_ACL_QUOTATION_LIMITSLENGTH_DATALEN			=				"datalen"


_M.QKPACK_ACL_ROUTE										=				"route"
_M.QKPACK_ACL_ROUTE_DEFAULT								=				"default"
_M.QKPACK_ACL_ROUTE_CLIENT								=				"client"
_M.QKPACK_ACL_ROUTE_SERVER								=				"server"

_M.QKPACK_ACL_NAMESPACE_LENGTH							=				2

--[[ /******************************************
	*JSON配置
	*
******************************************/ --]]

--_M.QKPACK_JSON_URI										=				"uri"
--_M.QKPACK_JSON_AK										=				"ak"
--_M.QKPACK_JSON_KEY										=				"k"
--_M.QKPACK_JSON_VALUE									=				"v"
--_M.QKPACK_JSON_KEYS										=				"ks"
--_M.QKPACK_JSON_MBS										=				"mbs"
--_M.QKPACK_JSON_MB										=				"mb"
--_M.QKPACK_JSON_SC										=				"sc"
--_M.QKPACK_JSON_V										=				"v"
--_M.QKPACK_JSON_MIN										=				"min"
--_M.QKPACK_JSON_MAX										=				"max"
--_M.QKPACK_JSON_WS										=				"ws"
--_M.QKPACK_JSON_ASC										=				"asc"
--_M.QKPACK_JSON_DATA										=				"data"
--_M.QKPACK_JSON_CODE										=				"code"
--_M.QKPACK_JSON_DESC										=				"desc"
--_M.QKPACK_JSON_E										=				"e" 
--_M.QKPACK_JSON_COST										=				"cost"
--_M.QKPACK_JSON_MC										=				"mc"
--_M.QKPACK_JSON_KC										=				"kc"



--[[ /******************************************
	*redis命令名称
	*
******************************************/ --]]

_M.REDIS_PING_COMMAND									=				"ping"
_M.REDIS_SET_COMMAND									=				"setex"
_M.REDIS_GET_COMMAND									=				"get"
_M.REDIS_TTL_COMMAND									=				"ttl"
_M.REDIS_DEL_COMMAND									=				"del"
_M.REDIS_INCR_COMMAND									=				"incr"
_M.REDIS_INCRBY_COMMAND									=				"incrby"
_M.REDIS_MGET_COMMAND									=				"mget"
_M.REDIS_SADD_COMMAND									=				"sadd"
_M.REDIS_SREM_COMMAND									=				"srem"
_M.REDIS_SCARD_COMMAND									=				"scard"
_M.REDIS_SMEMBERS_COMMAND								=				"smembers"
_M.REDIS_SISMEMBER_COMMAND								=				"sismember"
_M.REDIS_ZRANGE_COMMAND									=				"zrange"
_M.REDIS_ZREVRANGE_COMMAND								=				"zrevrange"
_M.REDIS_ZRANGEBYSCORE_COMMAND							=				"zrangebyscore"
_M.REDIS_ZREVRANGEBYSCORE_COMMAND						=				"zrevrangebyscore"
_M.REDIS_ZRANGE_WITHSCORES_COMMAND						=				"withscores"
_M.REDIS_SCRIPT_EVALSHA_COMMAND							=				"evalsha"


--[[ /******************************************
	*请求URI
	*
******************************************/ --]]

_M.QKPACK_URI_GET										=				"/hdp/kvstore/kv/get"
_M.QKPACK_URI_SET										=				"/hdp/kvstore/kv/set"
_M.QKPACK_URI_DEL										=				"/hdp/kvstore/kv/del"
_M.QKPACK_URI_TTL										=				"/hdp/kvstore/kv/ttl"
_M.QKPACK_URI_INCR										=				"/hdp/kvstore/kv/incr"
_M.QKPACK_URI_INCRBY									=				"/hdp/kvstore/kv/incrby"
_M.QKPACK_URI_MGET										=				"/hdp/kvstore/kv/mget"
_M.QKPACK_URI_MSET										=				"/hdp/kvstore/kv/mset"

_M.QKPACK_URI_SET_SADD									=				"/hdp/kvstore/set/sadd"
_M.QKPACK_URI_SET_SREM									=				"/hdp/kvstore/set/srem"
_M.QKPACK_URI_SET_SCARD									=				"/hdp/kvstore/set/scard"
_M.QKPACK_URI_SET_SMEMBERS								=				"/hdp/kvstore/set/smembers"
_M.QKPACK_URI_SET_SISMEMBER								=				"/hdp/kvstore/set/sismember"

_M.QKPACK_URI_ZFIXEDSET_ADD								=				"/hdp/kvstore/zfixedset/add"
_M.QKPACK_URI_ZFIXEDSET_BATCHADD						=				"/hdp/kvstore/zfixedset/batchadd"
_M.QKPACK_URI_ZFIXEDSET_GETBYSCORE						=				"/hdp/kvstore/zfixedset/getbyscore"
_M.QKPACK_URI_ZFIXEDSET_GETBYRANK						=				"/hdp/kvstore/zfixedset/getbyrank"
_M.QKPACK_URI_ZFIXEDSET_BATCHGETBYSCORE					=				"/hdp/kvstore/zfixedset/batchgetbyscore"


--[[ /******************************************
	*子请求
	*
******************************************/ --]]

_M.QKPACK_SUBREQUEST_START								=				0
_M.QKPACK_SUBREQUEST_MGET								=				1
_M.QKPACK_SUBREQUEST_MSET								=				2
_M.QKPACK_SUBREQUEST_ZFIXEDSET_ADD						=				3
_M.QKPACK_SUBREQUEST_ZFIXEDSET_BATCHADD					=				4
_M.QKPACK_SUBREQUEST_ZFIXEDSET_GETBYSCORE				=				5
_M.QKPACK_SUBREQUEST_ZFIXEDSET_BATCHGETBYSCORE			=				6
_M.QKPACK_SUBREQUEST_DONE								=				7



--[[ /*****************************************
	 * 错误码
	 * 
*****************************************/ --]]

_M.QKPACK_RESPONSE_CODE_OK								=				0
_M.QKPACK_RESPONSE_CODE_UNKNOWN							=				1000
_M.QKPACK_RESPONSE_CODE_PARSE_ERROR						=				2000
_M.QKPACK_RESPONSE_CODE_ILLEGAL_RIGHT					=				3000
_M.QKPACK_RESPONSE_CODE_5XX_TIMEOUT						=				4000
_M.QKPACK_RESPONSE_CODE_REDIS_STORAGE_ERROR				=				5000

--[[ /*****************************************
	 * 错误提示
	 * 
*****************************************/ --]]
_M.QKPACK_ERROR_JSON_FORMAT								=				"json format is illegal"

_M.QKPACK_ERROR_INTERFACE_OPERATION_READ				=				"interface operation to read"
_M.QKPACK_ERROR_INTERFACE_OPERATION_WRITE				=				"interface operation to write"


_M.QKPACK_ERROR_KVPAIR_KEY_NOT_EXIST					=				"kvpair key not exist"
_M.QKPACK_ERROR_KVPAIR_KEY_NOT_EMPTY					=				"kvpair key may not be empty"
_M.QKPACK_ERROR_KVPAIR_VALUE_NOT_EXIST					=				"kvpair value not exist"
_M.QKPACK_ERROR_KVPAIR_VALUE_NOT_EMPTY					=				"kvpair value may not be empty"
_M.QKPACK_ERROR_KVPAIR_KEYS_NOT_EXIST					=				"kvpair ks not exist"
_M.QKPACK_ERROR_KVPAIR_KEYS_NOT_EMPTY					=				"kvpair ks may not be empty"
_M.QKPACK_ERROR_KVPAIR_NUMERIC_VALUE					=				"kvpair value must be a number"

_M. QKPACK_ERROR_TTL_KEY_NO_EXPIRE						=				"kvpair the key exists but has no associated expire"
_M. QKPACK_ERROR_TTL_KEY_NOT_EXIST						=				"kvpair the key does not exist"


_M.QKPACK_ERROR_SET_KEY_NOT_EXIST						=				"set key not exist"
_M.QKPACK_ERROR_SET_KEY_NOT_EMPTY						=				"set key may not be empty"
_M.QKPACK_ERROR_SET_VALUE_NOT_EXIST						=				"set value not exist"
_M.QKPACK_ERROR_SET_VALUE_NOT_EMPTY						=				"set value may not be empty"
_M.QKPACK_ERROR_SET_MEMBERS_NOT_EXIST					=				"set mbs not exist"
_M.QKPACK_ERROR_SET_MEMBERS_NOT_EMPTY					=				"set mbs may not be empty"
_M.QKPACK_ERROR_SET_MEMBERS_VALUE_NOT_EMPTY				=				"set mbs value may not be empty"


_M.QKPACK_ERROR_ZSET_KEY_NOT_EXIST						=				"zset key not exist"
_M.QKPACK_ERROR_ZSET_KEY_NOT_EMPTY						=				"zset key may not be empty"
_M.QKPACK_ERROR_ZSET_MEMBERS_NOT_EXIST					=				"zset mbs not exist"
_M.QKPACK_ERROR_ZSET_MEMBERS_NOT_EMPTY					=				"zset mbs may not be empty"
_M.QKPACK_ERROR_ZSET_MEMBERS_MEMBER_NOT_EXIST 			=				"zset member not exist"
_M.QKPACK_ERROR_ZSET_MEMBERS_MEMBER_NOT_EMPTY			=				"zset member may not be empty"
_M.QKPACK_ERROR_ZSET_MEMBERS_SCORE_NOT_EXIST			=				"zset score not exist"
_M.QKPACK_ERROR_ZSET_MEMBERS_VALUE_NOT_EXIST			=				"zset value not exist"
_M.QKPACK_ERROR_ZSET_MEMBERS_VALUE_NOT_EMPTY			=				"zset value may not be empty"

_M.QKPACK_ERROR_ZSET_KEYS_NOT_EXIST						=				"zset ks not exist"
_M.QKPACK_ERROR_ZSET_KEYS_NOT_EMPTY						=				"zset ks may not be empty"

_M.QKPACK_ERROR_ZSET_QUERY_KEY_NOT_EXIST				=				"zset query key not exist"
_M.QKPACK_ERROR_ZSET_QUERY_KEY_NOT_EMPTY				=				"zset query key may not be empty"
_M.QKPACK_ERROR_ZSET_QUERY_MIN_NOT_EXIST				=				"zset query min not exist"
_M.QKPACK_ERROR_ZSET_QUERY_MAX_NOT_EXIST				=				"zset query max not exist"

_M.QKPACK_ERROR_ZSET_QUERIES_NOT_EXIST					=				"zset queries not exist"
_M.QKPACK_ERROR_ZSET_QUERIES_NOT_EMPTY					=				"zset queries may not be empty"


_M.QKPACK_ERROR_ACL_NOT_NULL							=				"acl obj may not be null"
_M.QKPACK_ERROR_ACL_URI_NOT_EXIST						=				"acl uri not exist"
_M.QKPACK_ERROR_ACL_APPKEY_NOT_EXIST					=				"acl appkey not exist"
_M.QKPACK_ERROR_ACL_URI_NOT_EMPTY						=				"acl uri may not be empty"
_M.QKPACK_ERROR_ACL_APPKEY_NOT_EMPTY					=				"acl appkey may not be empty"
_M.QKPACK_ERROR_ACL_NO_AUTH								=				"acl unauthorized"
_M.QKPACK_ERROR_ACL_FORMAT								=				"acl format illegal"

_M. QKPACK_ERROR_ACL_LIMITPOLICIES						=				"acl limit member count too big"
_M. QKPACK_ERROR_ACL_LIMITSLENGTH_KEYLEN				=				"acl limit keylen too big"
_M. QKPACK_ERROR_ACL_LIMITSLENGTH_VALLEN				=				"acl limit vallen too big"
_M. QKPACK_ERROR_ACL_LIMITSLENGTH_DATALEN				=				"acl limit datalen too big"
_M. QKPACK_ERROR_ACL_NAMESPACE_NOT_EMPTY				=				"acl namespace may not be empty"
_M. QKPACK_ERROR_ACL_NAMESPACE_LENGTH					=				"acl namespace length must be equal to 2"
_M. QKPACK_ERROR_ACL_LIMITPOLICIES_LIMIT				=				"key length could not match limit policy keyLength="


_M. QKPACK_ERROR_ACL_ROUTE_NOT_BLANK					=				"acl route may not be empty"
_M. QKPACK_ERROR_ACL_ROUTE_NOT_MATCH					=				"acl route must match {regexp}"
_M. QKPACK_ERROR_ACL_COMPRESS_THRESHOLD					=				"acl compress threshold must be greater than or equal to {value}"


--[[ /******************************************
	*场景ID
	*
******************************************/ --]]
_M.QKPACK_USERSCENE_SYS_ID								=				 "23"
_M.QKPACK_USERSCENE_SCE_ID								=				 "1533"
_M.QKPACK_GLOBALSCENE_G_SYS_ID							=				 "23"
_M.QKPACK_GLOBALSCENE_G_SCE_ID							=				 "1534"


--[[ /******************************************
	*埋点维度
	*
******************************************/ --]]

_M.QKPACK_METRICS_G_ZRANGE								=				"ZRANGE"
_M.QKPACK_METRICS_G_MGET								=				"MGET"

_M.QKPACK_METRICS_GET									=				"get"
_M.QKPACK_METRICS_GETMISS								=				"getMiss"
_M.QKPACK_METRICS_SET									=				"set"
_M.QKPACK_METRICS_DEL									=				"del"
_M.QKPACK_METRICS_TTL									=				"ttl"
_M.QKPACK_METRICS_INCR									=				"incr"
_M.QKPACK_METRICS_INCRBY								=				"incrBy"
_M.QKPACK_METRICS_MGET									=				"mget"
_M.QKPACK_METRICS_MGETMISS								=				"mgetMiss"
_M.QKPACK_METRICS_MSET									=				"mset"

_M.QKPACK_METRICS_SADD									=				"sadd"
_M.QKPACK_METRICS_SREM									=				"srem"
_M.QKPACK_METRICS_SCARD									=				"scard"
_M.QKPACK_METRICS_SMEMBERS								=				"smembers"
_M.QKPACK_METRICS_SMEMBERSMISS							=				"smembersMiss"
_M.QKPACK_METRICS_SISMEMBER								=				"sismember"
		
_M.QKPACK_METRICS_ZFIXEDSETADD							=				"zfixedsetAdd"
_M.QKPACK_METRICS_ZFIXEDSETBATCHADD						=				"zfixedsetBatchAdd"
_M.QKPACK_METRICS_ZFIXEDSETGETBYSCORE					=				"zfixedsetGetByScore"
_M.QKPACK_METRICS_ZFIXEDSETGETBYSCOREMISS				=				"zfixedsetGetByScoreMiss"
_M.QKPACK_METRICS_ZFIXEDSETGETBYRANK					=				"zfixedsetGetByRank"
_M.QKPACK_METRICS_ZFIXEDSETGETBYRANKMISS				=				"zfixedsetGetByRankMiss"
_M.QKPACK_METRICS_ZFIXEDSETBATCHGETBYSCORE				=				"zfixedsetBatchGetByScore"
		
_M.QKPACK_METRICS_QPS									=				"QPS"
_M.QKPACK_METRICS_TPS									=				"TPS"
--_M.MISS = "MISS";
-- data status
_M.QKPACK_METRICS_KEY_LEN								=				"KEYLEN"
_M.QKPACK_METRICS_VAL_LEN								=				"VALLEN"

--error code distribution
_M.QKPACK_METRICS_JSON_PARSER_ERROR_METER				=				"E_JPASER"
_M.QKPACK_METRICS_ACL_ERROR_METER						=				"E_ACLER"
_M.QKPACK_METRICS_CLUSTER_NODES_ERROR_METER				=				"E_CLUSERNODESER"
_M.QKPACK_METRICS_REDIS_PROTO_ERROR_METER				=				"E_REDISPROTOER"
_M.QKPACK_METRICS_UNKNOWN_ERROR_METER					=				"E_UNKNOWN"

_M.QKPACK_METRICS_REDIS_STORAGE_ERROR_METER				=				"E_REDISERR"
_M.QKPACK_METRICS_5XX_ERROR_METER						=				"E_5xxER"


--[[ /******************************************
	*metrics name
	*
******************************************/ --]]
--metrics
--_M.QKPACK_METRICS_SYSNAME								=				"sysName"
--
----meters
--_M.QKPACK_METRICS_METERS								=				"meters"
--_M.QKPACK_METRICS_METERS_NAME							=				"name"
--_M.QKPACK_METRICS_METERS_COUNT							=				"count"
--_M.QKPACK_METRICS_METERS_M15_RATE						=				"m15_rate"
--_M.QKPACK_METRICS_METERS_M1_RATE						=				"m1_rate"
--_M.QKPACK_METRICS_METERS_M5_RATE						=				"m5_rate"
--_M.QKPACK_METRICS_METERS_MEAN_RATE						=				"mean_rate"
--_M.QKPACK_METRICS_METERS_UNITS							=				"units"
--
----timers
--_M.QKPACK_METRICS_TIMERS								=				"timers"
--_M.QKPACK_METRICS_TIMERS_NAME							=				"name"
--_M.QKPACK_METRICS_TIMERS_COUNT							=				"count"
--_M.QKPACK_METRICS_TIMERS_MAX							=				"max"
--_M.QKPACK_METRICS_TIMERS_MEAN							=				"mean"
--_M.QKPACK_METRICS_TIMERS_MIN							=				"min"
--_M.QKPACK_METRICS_TIMERS_P50							=				"p50"
--_M.QKPACK_METRICS_TIMERS_P75							=				"p75"
--_M.QKPACK_METRICS_TIMERS_P95							=				"p95"
--_M.QKPACK_METRICS_TIMERS_P98							=				"p98"
--_M.QKPACK_METRICS_TIMERS_P99							=				"p99"
--_M.QKPACK_METRICS_TIMERS_P999							=				"p999"
--_M.QKPACK_METRICS_TIMERS_STDDEV							=				"stddev"
--_M.QKPACK_METRICS_TIMERS_M15_RATE						=				"m15_rate"
--_M.QKPACK_METRICS_TIMERS_M1_RATE						=				"m1_rate"
--_M.QKPACK_METRICS_TIMERS_M5_RATE						=				"m5_rate"
--_M.QKPACK_METRICS_TIMERS_MEAN_RATE						=				"mean_rate"
--_M.QKPACK_METRICS_TIMERS_DURATION_UNITS					=				"duration_units"
--_M.QKPACK_METRICS_TIMERS_RATE_UNITS						=				"rate_units"
--

--[[ /******************************************
	*redis命令类型
	*
******************************************/ --]]

_M.REDIS_EXISTS = 0
_M.REDIS_PTTL = 1
_M.REDIS_TTL = 2
_M.REDIS_TYPE = 3
_M.REDIS_BITCOUNT = 4
_M.REDIS_GET = 5
_M.REDIS_GETBIT = 6
_M.REDIS_GETRANGE = 7
_M.REDIS_GETSET = 8
_M.REDIS_STRLEN = 9
_M.REDIS_HEXISTS = 10
_M.REDIS_HGET = 11
_M.REDIS_HGETALL = 12
_M.REDIS_HKEYS = 13
_M.REDIS_HLEN = 14
_M.REDIS_HVALS = 15
_M.REDIS_LINDEX = 16                 --[[ /* redis requests - lists */ --]]
_M.REDIS_LLEN = 17
_M.REDIS_LRANGE = 18
_M.REDIS_SCARD = 19
_M.REDIS_SISMEMBER = 20
_M.REDIS_SMEMBERS = 21
_M.REDIS_SRANDMEMBER = 22
_M.REDIS_ZCARD = 23
_M.REDIS_ZCOUNT = 24
_M.REDIS_ZRANGE = 25
_M.REDIS_ZRANGEBYSCORE = 26
_M.REDIS_BATCHZRANGEBYSCORE = 27
_M.REDIS_ZREVRANGE = 28
_M.REDIS_ZREVRANGEBYSCORE = 29
_M.REDIS_ZREVRANK = 30
_M.REDIS_ZSCORE = 31

_M.REDIS_DEL = 32                    --[[ /* redis commands - keys */ --]]
_M.REDIS_EXPIRE = 33
_M.REDIS_EXPIREAT = 34
_M.REDIS_PEXPIRE = 35
_M.REDIS_PEXPIREAT = 36
_M.REDIS_PERSIST = 37
_M.REDIS_APPEND = 38                 --[[ /* redis requests - string */ --]]
_M.REDIS_DECR = 39
_M.REDIS_DECRBY = 40
_M.REDIS_INCR = 41
_M.REDIS_INCRBY = 42
_M.REDIS_INCRBYFLOAT = 43
_M.REDIS_PSETEX = 44
_M.REDIS_SET = 45
_M.REDIS_SETBIT = 46
_M.REDIS_SETEX = 47
_M.REDIS_SETNX = 48
_M.REDIS_SETRANGE = 49
_M.REDIS_HDEL = 50                   --[[ /* redis requests - hashes */ --]]
_M.REDIS_HINCRBY = 51
_M.REDIS_HINCRBYFLOAT = 52
_M.REDIS_HSET = 53
_M.REDIS_HSETNX = 54
_M.REDIS_LINSERT = 55
_M.REDIS_LPOP = 56
_M.REDIS_LPUSH = 57
_M.REDIS_LPUSHX = 58
_M.REDIS_LREM = 59
_M.REDIS_LSET = 60
_M.REDIS_LTRIM = 61
_M.REDIS_RPOP = 62
_M.REDIS_RPUSH = 63
_M.REDIS_RPUSHX = 64
_M.REDIS_SADD = 65                   --[[ /* redis requests - sets */ --]]
_M.REDIS_SPOP = 66
_M.REDIS_SREM = 67
_M.REDIS_ZADD = 68                   --[[ /* redis requests - sorted sets */ --]]
_M.REDIS_ZBATCHADD = 69
_M.REDIS_ZINCRBY = 70
_M.REDIS_ZRANK = 71
_M.REDIS_ZREM = 72
_M.REDIS_ZREMRANGEBYRANK = 73
_M.REDIS_ZREMRANGEBYSCORE = 74
_M.REDIS_MGET = 75
_M.REDIS_MSET = 76
_M.REDIS_CLUSTER_NODES = 77
_M.REDIS_UNKNOWN = 78





return _M
